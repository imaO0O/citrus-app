import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../bloc/calendar_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../models/calendar_event.dart';
import 'calendar_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    // Загружаем календарь после проверки авторизации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        print('CalendarPage: инициализация для авторизованного пользователя');
        print('  - userId: ${authState.user.id}');
        print('  - token: "${authState.user.token}"');
        print('  - token isEmpty: ${authState.user.token.isEmpty}');
        context.read<CalendarBloc>().updateUserId(authState.user.id, token: authState.user.token);
      } else {
        print('CalendarPage: инициализация для неавторизованного пользователя');
        context.read<CalendarBloc>().add(LoadCalendar(month: _focusedDay));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarBloc, CalendarState>(
      listener: (context, state) {
        // Показываем сообщение после удаления события
        if (state is CalendarLoaded) {
          // Проверяем, было ли только что удалено событие (через флаг в state)
          // Для простоты - показываем сообщение при каждом обновлении
          // В реальном приложении лучше использовать отдельный флаг
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // При входе или выходе обновляем userId в календаре
          if (state is AuthAuthenticated) {
            print('CalendarPage: пользователь вошёл');
            print('  - userId: ${state.user.id}');
            print('  - email: ${state.user.email}');
            print('  - token: ${state.user.token}');
            print('  - token length: ${state.user.token.length}');
            context.read<CalendarBloc>().updateUserId(state.user.id, token: state.user.token);
          } else if (state is AuthUnauthenticated) {
            print('CalendarPage: пользователь вышел');
            context.read<CalendarBloc>().updateUserId('unknown', token: null);
          }
        },
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Календарь'),
          actions: [
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
                context.read<CalendarBloc>().add(SelectDay(DateTime.now()));
              },
              tooltip: 'Сегодня',
            ),
          ],
        ),
        body: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            if (state is CalendarLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CalendarError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CalendarBloc>().add(LoadCalendar(month: _focusedDay));
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is CalendarLoaded) {
              return Column(
                children: [
                  _buildCalendar(state),
                  const Divider(height: 1),
                  _buildEventsList(state),
                ],
              );
            }

            return const Center(
              child: Text('Нажмите "Загрузить" для отображения календаря'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'calendar_page_fab',
          onPressed: () => _showAddEventDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    ),
    );
  }

  Widget _buildCalendar(CalendarLoaded state) {
    return TableCalendar<CalendarEventModel>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      eventLoader: (day) => state.getEventsForDay(day),
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        formatButtonTextStyle: TextStyle(color: Colors.white),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: Colors.red[700]),
        holidayTextStyle: TextStyle(color: Colors.red[700]),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.blue[200],
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        context.read<CalendarBloc>().add(SelectDay(selectedDay));
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        final now = DateTime.now();
        final focusedMonth = DateTime(focusedDay.year, focusedDay.month, 1);
        final nowMonth = DateTime(now.year, now.month, 1);
        
        setState(() {
          _focusedDay = focusedDay;
          // Если месяц в прошлом — выбираем последний день месяца
          if (focusedMonth.isBefore(nowMonth)) {
            _selectedDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
          }
          // Если месяц в будущем — выбираем 1 число
          else if (focusedMonth.isAfter(nowMonth)) {
            _selectedDay = DateTime(focusedDay.year, focusedDay.month, 1);
          }
          // Если текущий месяц — оставляем сегодня
          else {
            _selectedDay = now;
          }
        });
      },
    );
  }

  Widget _buildEventsList(CalendarLoaded state) {
    // Показываем события текущего месяца (_focusedDay из виджета)
    final events = state.getEventsForMonth(_focusedDay);
    print('_buildEventsList: всего событий в state: ${state.events.values.expand((e) => e).length}');
    print('_buildEventsList: событий текущего месяца (_focusedDay=$_focusedDay): ${events.length}');
    for (final event in events) {
      print('_buildEventsList: событие: ${event.title} на ${event.eventDate}');
    }

    return Expanded(
      child: events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет событий на ${DateFormat('MMMM yyyy').format(_focusedDay)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddEventDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить событие'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: events.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventCard(event);
              },
            ),
    );
  }

  Widget _buildEventCard(CalendarEventModel event) {
    final hasTime = event.startTime != null;
    final timeText = hasTime
        ? event.startTime!.substring(0, 5)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            timeText ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: event.description != null && event.description!.isNotEmpty
            ? Text(
                event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: event.notificationEnabled
            ? Icon(Icons.notifications_active, size: 20, color: Colors.orange[700])
            : null,
        onTap: () => _showEventDetails(context, event),
      ),
    );
  }

  Future<void> _showEventDetails(BuildContext context, CalendarEventModel event) async {
    // Просто открываем детали - BLoC сам обновит состояние при удалении
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarDetailPage(event: event),
      ),
    );
    // Обновляем UI после возврата
    if (mounted) {
      setState(() {});
    }
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;
    bool notificationEnabled = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                      'Новое событие',
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
                    hintText: 'Введите название события',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    hintText: 'Введите описание (необязательно)',
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
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      selectedTime = time;
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Уведомление'),
                  subtitle: const Text('Напомнить о событии'),
                  value: notificationEnabled,
                  onChanged: (value) {
                    notificationEnabled = value;
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

                    final authState = context.read<AuthBloc>().state;
                    final userId = authState is AuthAuthenticated
                        ? authState.user.id
                        : 'unknown';
                    final token = authState is AuthAuthenticated
                        ? authState.user.token
                        : null;

                    final event = CalendarEventModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: userId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      eventDate: DateTime(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                        selectedTime?.hour ?? 12,
                        selectedTime?.minute ?? 0,
                      ),
                      startTime: selectedTime != null
                          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'
                          : null,
                      endTime: null,
                      notificationEnabled: notificationEnabled,
                    );

                    // Создаем репозиторий с токеном если его нет
                    final calendarBloc = context.read<CalendarBloc>();
                    // Передаём токен в репозиторий
                    calendarBloc.updateUserId(userId, token: token);
                    calendarBloc.add(AddEvent(event));
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Событие добавлено'),
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
                  child: const Text('Добавить событие'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
