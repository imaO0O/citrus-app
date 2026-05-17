import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/calendar_bloc.dart';
import '../../../models/calendar_event.dart';
import '../../../core/utils/app_size.dart';

class CalendarDetailPage extends StatefulWidget {
  final CalendarEventModel? event;
  final DateTime? date;

  CalendarDetailPage({
    Key? key,
    this.event,
    this.date,
  }) : super(key: key);

  @override
  State<CalendarDetailPage> createState() => _CalendarDetailPageState();
}

class _CalendarDetailPageState extends State<CalendarDetailPage> {
  @override
  Widget build(BuildContext context) {
    final displayDate = widget.event?.eventDate ?? widget.date ?? DateTime.now();
    final title = widget.event != null
        ? widget.event!.title
        : 'События на ${DateFormat('dd MMMM yyyy').format(displayDate)}';

    return BlocListener<CalendarBloc, CalendarState>(
      listener: (context, state) {
        // После удаления события — закрываем страницу
        if (state is CalendarLoaded && widget.event != null) {
          final eventsForDay = state.getEventsForDay(widget.event!.eventDate);
          final exists = eventsForDay.any((e) => e.id == widget.event!.id);
          if (!exists && mounted) {
            // Событие удалено — закрываем страницу
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: widget.event != null
              ? [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showEditEventDialog(context, widget.event!),
                    tooltip: 'Редактировать',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, widget.event!),
                    tooltip: 'Удалить',
                  ),
                ]
              : null,
        ),
        body: widget.event != null
            ? _buildEventDetails(context, widget.event!)
            : _buildDayEvents(context, displayDate),
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, CalendarEventModel event) {
    return SingleChildScrollView(
      padding: AppSize.padding(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(event),
          AppSize.gapH(16),
          _buildTimeSection(event),
          AppSize.gapH(16),
          _buildNotificationSection(event),
          AppSize.gapH(24),
          _buildActionButtons(context, event),
        ],
      ),
    );
  }

  Widget _buildInfoCard(CalendarEventModel event) {
    return Card(
      child: Padding(
        padding: AppSize.padding(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.event, color: Colors.blue[700]),
                ),
                AppSize.gapW(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: AppSize.s(20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'ru_RU').format(event.eventDate),
                        style: TextStyle(
                          fontSize: AppSize.s(14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              Divider(height: 24),
              Text(
                'Описание',
                style: TextStyle(
                  fontSize: AppSize.s(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSize.gapH(8),
              Text(
                event.description!,
                style: TextStyle(
                  fontSize: AppSize.s(14),
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(CalendarEventModel event) {
    final hasStartTime = event.startTime != null;
    final hasEndTime = event.endTime != null;
    
    print('_buildTimeSection: startTime=${event.startTime}, endTime=${event.endTime}');
    print('_buildTimeSection: eventDate=${event.eventDate}');

    if (!hasStartTime && !hasEndTime) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: AppSize.padding(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[700]),
                AppSize.gapW(12),
                Text(
                  'Время',
                  style: TextStyle(
                    fontSize: AppSize.s(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSize.gapH(12),
            Row(
              children: [
                if (hasStartTime) ...[
                  Chip(
                    avatar: Icon(Icons.play_arrow, size: 16, color: Colors.blue[700]),
                    label: Text(event.startTime!.substring(0, 5)),
                    backgroundColor: Colors.blue[50],
                  ),
                  AppSize.gapW(8),
                ],
                if (hasEndTime) ...[
                  Chip(
                    avatar: Icon(Icons.stop, size: 16, color: Colors.red[700]),
                    label: Text(event.endTime!.substring(0, 5)),
                    backgroundColor: Colors.red[50],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(CalendarEventModel event) {
    return Card(
      child: Padding(
        padding: AppSize.padding(16),
        child: Row(
          children: [
            Icon(
              event.notificationEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: event.notificationEnabled
                  ? Colors.orange[700]
                  : Colors.grey[400],
            ),
            AppSize.gapW(12),
            Text(
              event.notificationEnabled
                  ? 'Уведомление включено'
                  : 'Уведомление отключено',
              style: TextStyle(
                fontSize: AppSize.s(14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CalendarEventModel event) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEditEventDialog(context, event),
            icon: Icon(Icons.edit),
            label: Text('Редактировать событие'),
            style: ElevatedButton.styleFrom(
              padding: AppSize.paddingH(0, 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppSize.radius(12),
              ),
            ),
          ),
        ),
        AppSize.gapH(12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, event),
            icon: Icon(Icons.delete, color: Colors.red),
            label: Text(
              'Удалить событие',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: AppSize.paddingH(0, 16),
              side: BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: AppSize.radius(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayEvents(BuildContext context, DateTime date) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoaded) {
          final events = state.getEventsForDay(date);

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  AppSize.gapH(16),
                  Text(
                    'Нет событий на ${DateFormat('dd MMMM yyyy', 'ru_RU').format(date)}',
                    style: TextStyle(
                      fontSize: AppSize.s(16),
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppSize.padding(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventListItem(context, event);
            },
          );
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEventListItem(BuildContext context, CalendarEventModel event) {
    return Card(
      margin: AppSize.paddingOnly(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.event, color: Colors.blue[700]),
        ),
        title: Text(
          event.title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null && event.description!.isNotEmpty) ...[
              Text(
                event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              AppSize.gapH(4),
            ],
            if (event.startTime != null)
              Text(
                'Начало: ${event.startTime!.substring(0, 5)}',
                style: TextStyle(fontSize: AppSize.s(12), color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: event.notificationEnabled
            ? Icon(Icons.notifications_active, size: 20, color: Colors.orange[700])
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarDetailPage(event: event),
            ),
          );
        },
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, CalendarEventModel event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description ?? '');
    TimeOfDay? selectedTime;
    
    // Парсим startTime если есть
    if (event.startTime != null && event.startTime!.isNotEmpty) {
      try {
        final selectedTime = TimeOfDay(
          hour: int.parse(event.startTime!.substring(0, 2)),
          minute: int.parse(event.startTime!.substring(3, 5)),
        );
      } catch (e) {
        print('_showEditEventDialog: ошибка парсинга startTime: $e');
      }
    }
    
    print('_showEditEventDialog: исходное startTime=${event.startTime}, parsed=$selectedTime');
    
    bool notificationEnabled = event.notificationEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(left: AppSize.w(16), top: AppSize.h(16), right: AppSize.w(16), bottom: MediaQuery.of(context).viewInsets.bottom + AppSize.h(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Редактировать событие',
                        style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSize.gapH(16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  AppSize.gapH(16),
                  ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text('Время события'),
                    subtitle: Text(
                      selectedTime != null
                          ? 'Выбрано: ${selectedTime!.format(context)}'
                          : 'Не выбрано',
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setModalState(() {
                          final selectedTime = time;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    title: Text('Уведомление'),
                    value: notificationEnabled,
                    onChanged: (value) {
                      setModalState(() {
                        final notificationEnabled = value;
                      });
                    },
                    secondary: Icon(Icons.notifications),
                  ),
                  AppSize.gapH(16),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Введите название события')),
                        );
                        return;
                      }

                      final updatedEvent = CalendarEventModel(
                        id: event.id,
                        userId: event.userId,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        eventDate: DateTime(
                          event.eventDate.year,
                          event.eventDate.month,
                          event.eventDate.day,
                          selectedTime?.hour ?? 12,
                          selectedTime?.minute ?? 0,
                        ),
                        startTime: selectedTime != null
                            ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'
                            : null,
                        endTime: null,
                        notificationEnabled: notificationEnabled,
                      );

                      print('_showEditEventDialog: сохраняем startTime=${updatedEvent.startTime}');

                      context.read<CalendarBloc>().add(UpdateEvent(updatedEvent));
                      
                      // Закрываем модалку и возвращаемся с обновлённым событием
                      Navigator.pop(context);
                      Navigator.pop(context, updatedEvent);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Событие обновлено'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: AppSize.paddingH(0, 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSize.radius(12),
                      ),
                    ),
                    child: Text('Сохранить изменения'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CalendarEventModel event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Удаление события'),
        content: Text('Вы уверены, что хотите удалить событие "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // Закрываем диалог подтверждения
              Navigator.of(context).pop();
              // BLoC сам закроет страницу после удаления через BlocListener
              context.read<CalendarBloc>().add(DeleteEvent(event.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
