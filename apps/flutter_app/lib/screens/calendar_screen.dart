import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../features/calendar/bloc/calendar_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../models/calendar_event.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  final List<String> _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDay = DateTime.now();
    _loadCalendar();
  }

  void _loadCalendar() {
    context.read<CalendarBloc>().add(LoadCalendar(month: _focusedMonth));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
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
              return const Center(child: CircularProgressIndicator(color: AppColors.citrusOrange));
            }

            if (state is CalendarError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: AppColors.mutedForeground)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadCalendar, child: const Text('Повторить')),
                  ],
                ),
              );
            }

            final days = _getDaysInMonth(_focusedMonth);
            final today = DateTime.now();
            final events = state is CalendarLoaded ? state.getEventsForMonth(_focusedMonth) : <CalendarEventModel>[];
            final eventsByDay = state is CalendarLoaded ? state.events : <DateTime, List<CalendarEventModel>>{};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthNavigation(),
                    const SizedBox(height: 16),
                    _buildWeekdayHeaders(),
                    const SizedBox(height: 8),
                    _buildCalendarGrid(days, today, eventsByDay),
                    if (_selectedDay != null) ...[
                      const SizedBox(height: 16),
                      _buildSelectedDayPanel(eventsByDay),
                    ],
                    if (_selectedDay != null) const SizedBox(height: 24),
                    _buildEventsList(events),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.citrusOrange,
        child: const Icon(Icons.add),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: const Icon(Icons.chevron_left, color: AppColors.foreground, size: 18),
          ),
        ),
        Text(
          '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
          style: const TextStyle(
            fontSize: 18,
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: const Icon(Icons.chevron_right, color: AppColors.foreground, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 4,
      padding: EdgeInsets.zero,
      children: weekdays
          .map((day) => Center(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> days, DateTime today, Map<DateTime, List<CalendarEventModel>> eventsByDay) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

        Color bgColor = Colors.transparent;
        Color borderColor = Colors.transparent;

        if (isSelected) {
          bgColor = AppColors.citrusOrange.withOpacity(0.2);
          borderColor = AppColors.citrusOrange.withOpacity(0.5);
        } else if (isToday) {
          bgColor = AppColors.citrusOrange.withOpacity(0.08);
          borderColor = AppColors.citrusOrange.withOpacity(0.25);
        }

        return GestureDetector(
          onTap: isCurrentMonth ? () => setState(() => _selectedDay = day) : null,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCurrentMonth ? '${day.day}' : '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isCurrentMonth ? AppColors.foreground : AppColors.dimForeground,
                  ),
                ),
                if (hasEvents && isCurrentMonth)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
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

  Widget _buildSelectedDayPanel(Map<DateTime, List<CalendarEventModel>> eventsByDay) {
    final selected = _selectedDay!;
    final dayKey = DateTime(selected.year, selected.month, selected.day);
    final dayEvents = eventsByDay[dayKey] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selected.day} ${_monthNames[selected.month - 1]}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddEventDialog(context, selected),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.citrusOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Добавить',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.citrusOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (dayEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...dayEvents.map((event) => _buildEventCard(event)),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('📌', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                ),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(
                    event.description!,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (event.startTime != null)
            Text(
              event.startTime!.substring(0, 5),
              style: const TextStyle(fontSize: 12, color: AppColors.dimForeground),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.event_note, size: 48, color: AppColors.dimForeground),
              const SizedBox(height: 8),
              const Text(
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
        const Text(
          'СОБЫТИЯ МЕСЯЦА',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        ...events.take(10).map((event) => _buildEventCard(event)),
      ],
    );
  }

  void _showAddEventDialog(BuildContext context, [DateTime? selectedDate]) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.citrusOrange.withOpacity(0.2)),
        ),
        title: const Text(
          'Новое событие',
          style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.foreground),
                decoration: InputDecoration(
                  hintText: 'Название события',
                  hintStyle: const TextStyle(color: AppColors.mutedForeground),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: AppColors.foreground),
                decoration: InputDecoration(
                  hintText: 'Описание (необязательно)',
                  hintStyle: const TextStyle(color: AppColors.mutedForeground),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.access_time, color: AppColors.mutedForeground),
                title: const Text('Время', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                subtitle: Text(
                  selectedTime != null ? 'Выбрано: ${selectedTime!.format(context)}' : 'Не выбрано',
                  style: const TextStyle(color: AppColors.foreground),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название')),
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
                notificationEnabled: false,
              );

              context.read<CalendarBloc>().add(AddEvent(event));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Событие добавлено'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.citrusOrange),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
