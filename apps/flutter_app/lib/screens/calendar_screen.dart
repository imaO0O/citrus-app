import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_colors.dart';
import '../features/calendar/bloc/calendar_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../models/calendar_event.dart';
import '../screens/models/mood.dart';
import '../core/utils/app_size.dart';

class CalendarScreen extends StatefulWidget {
  CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with WidgetsBindingObserver {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  bool _hasLoadedOnce = false;

  final List<String> _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _loadCalendar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Обновляем данные при возврате в приложение
    if (state == AppLifecycleState.resumed) {
      _loadCalendar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadCalendar() {
    context.read<CalendarBloc>().add(LoadCalendar(month: _focusedMonth));
    _hasLoadedOnce = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && !_hasLoadedOnce) {
      _loadCalendar();
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    context.read<CalendarBloc>().add(LoadCalendar(month: _focusedMonth));
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    context.read<CalendarBloc>().add(LoadCalendar(month: _focusedMonth));
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];

    int weekday = firstDay.weekday;
    for (int i = 0; i < weekday - 1; i++) {
      days.add(firstDay.subtract(Duration(days: weekday - 1 - i)));
    }

    for (int i = 0; i < lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }

    while (days.length % 7 != 0) {
      days.add(DateTime(month.year, month.month + 1, days.length - lastDay.day + 1));
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            if (state is CalendarLoading) {
              return Center(child: CircularProgressIndicator(color: AppColors.citrusOrange));
            }

            if (state is CalendarError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                    AppSize.gapH(16),
                    Text(state.message, style: TextStyle(color: AppColors.mutedForeground)),
                    AppSize.gapH(16),
                    ElevatedButton(onPressed: _loadCalendar, child: Text('Повторить')),
                  ],
                ),
              );
            }

            final days = _getDaysInMonth(_focusedMonth);
            final today = DateTime.now();
            final events = state is CalendarLoaded ? state.getEventsForMonth(_focusedMonth) : <CalendarEventModel>[];
            final eventsByDay = state is CalendarLoaded ? state.events : <DateTime, List<CalendarEventModel>>{};
            final moodAverages = state is CalendarLoaded ? state.moodAverages : <DateTime, double>{};

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthNavigation(),
                    AppSize.gapH(16),
                    _buildWeekdayHeaders(),
                    AppSize.gapH(8),
                    _buildCalendarGrid(days, today, eventsByDay, moodAverages),
                    if (_selectedDay != null) ...[
                      AppSize.gapH(16),
                      _buildSelectedDayPanel(eventsByDay),
                    ],
                    if (_selectedDay != null) AppSize.gapH(24),
                    _buildEventsList(events),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.citrusOrange,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _prevMonth,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: AppSize.radius(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Icon(Icons.chevron_left, color: AppColors.foreground, size: 18),
          ),
        ),
        Text(
          '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
          style: TextStyle(
            fontSize: AppSize.s(18),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.foreground,
          ),
        ),
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: AppSize.radius(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Icon(Icons.chevron_right, color: AppColors.foreground, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 4,
      padding: EdgeInsets.zero,
      children: weekdays
          .map((day) => Center(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSize.s(12),
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> days, DateTime today, Map<DateTime, List<CalendarEventModel>> eventsByDay, Map<DateTime, double> moodAverages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final isCurrentMonth = day.month == _focusedMonth.month;
        final isToday = _isSameDay(day, today);
        final isSelected = _selectedDay != null && _isSameDay(day, _selectedDay!);
        final dayKey = DateTime(day.year, day.month, day.day);
        final dayEvents = eventsByDay[dayKey] ?? [];
        final hasEvents = dayEvents.isNotEmpty;
        final avgMood = moodAverages[dayKey];
        final hasMood = avgMood != null && isCurrentMonth;

        Color bgColor = Colors.transparent;
        Color borderColor = Colors.transparent;

        if (isSelected) {
          final bgColor = AppColors.citrusOrange.withValues(alpha: 0.2);
          final borderColor = AppColors.citrusOrange.withValues(alpha: 0.5);
        } else if (isToday) {
          final bgColor = AppColors.citrusOrange.withValues(alpha: 0.08);
          final borderColor = AppColors.citrusOrange.withValues(alpha: 0.25);
        }

        // Определяем цвет фона на основе среднего настроения
        if (hasMood && !isSelected) {
          // Округляем до ближайшего целого moodId
          final roundedMoodId = avgMood!.round().clamp(0, Mood.all.length - 1);
          final moodColor = Mood.all[roundedMoodId].color;
          final bgColor = moodColor.withValues(alpha: 0.15);
        }

        return GestureDetector(
          onTap: isCurrentMonth ? () => setState(() => _selectedDay = day) : null,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppSize.radius(8),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCurrentMonth ? '${day.day}' : '',
                  style: TextStyle(
                    fontSize: AppSize.s(14),
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isCurrentMonth ? AppColors.foreground : AppColors.dimForeground,
                  ),
                ),
                if (hasMood)
                  Container(
                    margin: AppSize.paddingOnly(top: 2),
                    child: Text(
                      _getMoodEmoji(avgMood!),
                      style: TextStyle(fontSize: AppSize.s(12)),
                    ),
                  )
                else if (hasEvents && isCurrentMonth)
                  Container(
                    margin: AppSize.paddingOnly(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.citrusOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMoodEmoji(double avgMood) {
    final roundedMoodId = avgMood.round().clamp(0, Mood.all.length - 1);
    return Mood.all[roundedMoodId].emoji;
  }

  Widget _buildSelectedDayPanel(Map<DateTime, List<CalendarEventModel>> eventsByDay) {
    final selected = _selectedDay!;
    final dayKey = DateTime(selected.year, selected.month, selected.day);
    final dayEvents = eventsByDay[dayKey] ?? [];

    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selected.day} ${_monthNames[selected.month - 1]}',
                style: TextStyle(
                  fontSize: AppSize.s(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddEventDialog(context, selected),
                child: Container(
                  padding: AppSize.paddingH(12, 6),
                  decoration: BoxDecoration(
                    color: AppColors.citrusOrange.withValues(alpha: 0.15),
                    borderRadius: AppSize.radius(12),
                  ),
                  child: Text(
                    'Добавить',
                    style: TextStyle(
                      fontSize: AppSize.s(13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.citrusOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (dayEvents.isNotEmpty) ...[
            AppSize.gapH(12),
            ...dayEvents.map((event) => _buildEventCard(event)),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEventModel event, {bool showActions = false}) {
    return Container(
      margin: AppSize.paddingOnly(bottom: 8),
      padding: AppSize.padding(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: AppSize.radius(12),
      ),
      child: Row(
        children: [
          Text('📌', style: TextStyle(fontSize: AppSize.s(18))),
          AppSize.gapW(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(fontSize: AppSize.s(14), color: AppColors.foreground),
                ),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(
                    event.description!,
                    style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (event.startTime != null)
            Padding(
              padding: AppSize.paddingOnly(right: 8),
              child: Text(
                event.startTime!.substring(0, 5),
                style: TextStyle(fontSize: AppSize.s(12), color: AppColors.dimForeground),
              ),
            ),
          if (showActions) ...[
            IconButton(
              icon: Icon(Icons.edit, size: 18),
              color: AppColors.citrusOrange,
              onPressed: () => _showEditEventDialog(context, event),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 18),
              color: AppColors.destructive,
              onPressed: () => _confirmDeleteEvent(context, event),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSize.padding(32),
          child: Column(
            children: [
              Icon(Icons.event_note, size: 48, color: AppColors.dimForeground),
              AppSize.gapH(8),
              Text(
                'Нет событий',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'СОБЫТИЯ МЕСЯЦА',
          style: TextStyle(
            fontSize: AppSize.s(11),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.mutedForeground,
          ),
        ),
        AppSize.gapH(12),
        ...events.take(10).map((event) => _buildEventCard(event, showActions: true)),
      ],
    );
  }

  void _showAddEventDialog(BuildContext context, [DateTime? selectedDate]) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;
    bool notificationEnabled = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: AppSize.radius(16),
          side: BorderSide(color: AppColors.citrusOrange.withValues(alpha: 0.2)),
        ),
        title: Text(
          'Новое событие',
          style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: AppColors.foreground),
                decoration: InputDecoration(
                  hintText: 'Название события',
                  hintStyle: TextStyle(color: AppColors.mutedForeground),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: AppSize.radius(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                autofocus: true,
              ),
              AppSize.gapH(12),
              TextField(
                controller: descriptionController,
                style: TextStyle(color: AppColors.foreground),
                decoration: InputDecoration(
                  hintText: 'Описание (необязательно)',
                  hintStyle: TextStyle(color: AppColors.mutedForeground),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: AppSize.radius(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              AppSize.gapH(12),
              ListTile(
                leading: Icon(Icons.access_time, color: AppColors.mutedForeground),
                title: Text('Время', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                subtitle: Text(
                  selectedTime != null ? 'Выбрано: ${selectedTime!.format(context)}' : 'Не выбрано',
                  style: TextStyle(color: AppColors.foreground),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = time);
                  }
                },
              ),
              SwitchListTile(
                secondary: Icon(
                  notificationEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: notificationEnabled ? AppColors.citrusOrange : AppColors.mutedForeground,
                ),
                title: Text('Напоминание', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14))),
                subtitle: Text(
                  notificationEnabled ? 'Уведомление перед событием' : 'Без уведомления',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12)),
                ),
                value: notificationEnabled,
                activeColor: AppColors.citrusOrange,
                onChanged: (v) => setDialogState(() => notificationEnabled = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Введите название')),
                );
                return;
              }

              final authState = context.read<AuthBloc>().state;
              final userId = authState is AuthAuthenticated ? authState.user.id : 'unknown';
              final day = selectedDate ?? _selectedDay ?? DateTime.now();

              final event = CalendarEventModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: userId,
                title: titleController.text.trim(),
                description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                eventDate: DateTime(
                  day.year,
                  day.month,
                  day.day,
                  selectedTime?.hour ?? 12,
                  selectedTime?.minute ?? 0,
                ),
                startTime: selectedTime != null
                    ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'
                    : null,
                endTime: null,
                notificationEnabled: notificationEnabled,
              );

              context.read<CalendarBloc>().add(AddEvent(event));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Событие добавлено'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.citrusOrange),
            child: Text('Сохранить'),
          ),
        ],
        ),
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, CalendarEventModel event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description ?? '');
    TimeOfDay? selectedTime;
    if (event.startTime != null) {
      final parts = event.startTime!.split(':');
      final selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    bool notificationEnabled = event.notificationEnabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: AppSize.radius(16),
            side: BorderSide(color: AppColors.citrusOrange.withValues(alpha: 0.2)),
          ),
          title: Text(
            'Редактировать событие',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: AppColors.foreground),
                  decoration: InputDecoration(
                    hintText: 'Название',
                    hintStyle: TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: AppSize.radius(12), borderSide: BorderSide.none),
                  ),
                  autofocus: true,
                ),
                AppSize.gapH(12),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: AppColors.foreground),
                  decoration: InputDecoration(
                    hintText: 'Описание',
                    hintStyle: TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: AppSize.radius(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 3,
                ),
                AppSize.gapH(12),
                ListTile(
                  leading: Icon(Icons.access_time, color: AppColors.mutedForeground),
                  title: Text('Время', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                  subtitle: Text(
                    selectedTime != null ? 'Выбрано: ${selectedTime!.format(context)}' : 'Не выбрано',
                    style: TextStyle(color: AppColors.foreground),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) setModalState(() => selectedTime = time);
                  },
                ),
                SwitchListTile(
                  secondary: Icon(
                    notificationEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: notificationEnabled ? AppColors.citrusOrange : AppColors.mutedForeground,
                  ),
                  title: Text('Напоминание', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14))),
                  subtitle: Text(
                    notificationEnabled ? 'Уведомление перед событием' : 'Без уведомления',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12)),
                  ),
                  value: notificationEnabled,
                  activeColor: AppColors.citrusOrange,
                  onChanged: (v) => setModalState(() => notificationEnabled = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                final updated = CalendarEventModel(
                  id: event.id,
                  userId: event.userId,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  eventDate: event.eventDate,
                  startTime: selectedTime != null
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'
                      : event.startTime,
                  endTime: event.endTime,
                  notificationEnabled: notificationEnabled,
                );
                context.read<CalendarBloc>().add(UpdateEvent(updated));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Событие обновлено'), backgroundColor: Colors.green));
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusOrange),
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, CalendarEventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: AppSize.radius(16), side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.3))),
        title: Text('Удалить событие?', style: TextStyle(color: AppColors.foreground)),
        content: Text('«${event.title}» будет удалено навсегда.', style: TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
          FilledButton(
            onPressed: () {
              context.read<CalendarBloc>().add(DeleteEvent(event.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Событие удалено'), backgroundColor: Colors.orange));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
