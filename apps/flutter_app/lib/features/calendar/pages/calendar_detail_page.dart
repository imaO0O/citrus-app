import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/calendar_bloc.dart';
import '../../../models/calendar_event.dart';

class CalendarDetailPage extends StatefulWidget {
  final CalendarEventModel? event;
  final DateTime? date;

  const CalendarDetailPage({
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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: widget.event != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditEventDialog(context, widget.event!),
                  tooltip: 'Редактировать',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, widget.event!),
                  tooltip: 'Удалить',
                ),
              ]
            : null,
      ),
      body: widget.event != null
          ? _buildEventDetails(context, widget.event!)
          : _buildDayEvents(context, displayDate),
    );
  }

  Widget _buildEventDetails(BuildContext context, CalendarEventModel event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(event),
          const SizedBox(height: 16),
          _buildTimeSection(event),
          const SizedBox(height: 16),
          _buildNotificationSection(event),
          const SizedBox(height: 24),
          _buildActionButtons(context, event),
        ],
      ),
    );
  }

  Widget _buildInfoCard(CalendarEventModel event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.event, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'ru_RU').format(event.eventDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Описание',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: TextStyle(
                  fontSize: 14,
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

    if (!hasStartTime && !hasEndTime) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Text(
                  'Время',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasStartTime) ...[
                  Chip(
                    avatar: Icon(Icons.play_arrow, size: 16, color: Colors.blue[700]),
                    label: Text(event.startTime!.substring(0, 5)),
                    backgroundColor: Colors.blue[50],
                  ),
                  const SizedBox(width: 8),
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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 12),
            Text(
              event.notificationEnabled
                  ? 'Уведомление включено'
                  : 'Уведомление отключено',
              style: const TextStyle(
                fontSize: 14,
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
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать событие'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, event),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              'Удалить событие',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 16),
                  Text(
                    'Нет событий на ${DateFormat('dd MMMM yyyy', 'ru_RU').format(date)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventListItem(context, event);
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEventListItem(BuildContext context, CalendarEventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.event, color: Colors.blue[700]),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
              const SizedBox(height: 4),
            ],
            if (event.startTime != null)
              Text(
                'Начало: ${event.startTime!.substring(0, 5)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    TimeOfDay? selectedTime = event.startTime != null
        ? TimeOfDay(
            hour: int.parse(event.startTime!.substring(0, 2)),
            minute: int.parse(event.startTime!.substring(3, 5)),
          )
        : null;
    bool notificationEnabled = event.notificationEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Редактировать событие',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Время события'),
                    subtitle: Text(
                      selectedTime != null
                          ? 'Выбрано: ${selectedTime!.format(context)}'
                          : 'Не выбрано',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Уведомление'),
                    value: notificationEnabled,
                    onChanged: (value) {
                      setModalState(() {
                        notificationEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Введите название события')),
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
                            : event.startTime,
                        endTime: event.endTime,
                        notificationEnabled: notificationEnabled,
                      );

                      context.read<CalendarBloc>().add(UpdateEvent(updatedEvent));
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Событие обновлено'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Сохранить изменения'),
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
        title: const Text('Удаление события'),
        content: Text('Вы уверены, что хотите удалить событие "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Закрываем диалог подтверждения
              Navigator.of(context).pop();
              
              // Показывем индикатор загрузки
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                // Удаляем событие
                context.read<CalendarBloc>().add(DeleteEvent(event.id));
                
                // Закрываем индикатор и CalendarDetailPage
                if (context.mounted) {
                  Navigator.of(context).pop(); // Закрыть индикатор
                  Navigator.of(context).pop(); // Закрыть CalendarDetailPage
                }
                
                // Показываем сообщение
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Событие удалено'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Закрыть индикатор
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
