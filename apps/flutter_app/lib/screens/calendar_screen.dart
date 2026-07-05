import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/citrus_card.dart';
import '../core/widgets/citrus_empty_state.dart';
import '../features/calendar/bloc/calendar_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../models/calendar_event.dart';
import '../screens/models/mood.dart';
import '../core/utils/app_size.dart';
import 'diary_screen.dart';

class CalendarScreen extends StatefulWidget {
  CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with WidgetsBindingObserver {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  bool _hasLoadedOnce = false;
  bool _weekView = false;

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

  List<DateTime> _weekDays(DateTime anchor) {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  List<DateTime> _visibleDays() {
    return _weekView ? _weekDays(_selectedDay ?? DateTime.now()) : _getDaysInMonth(_focusedMonth);
  }

  void _prev() {
    if (_weekView) {
      setState(() {
        _selectedDay = (_selectedDay ?? DateTime.now()).subtract(const Duration(days: 7));
        _focusedMonth = DateTime(_selectedDay!.year, _selectedDay!.month);
      });
      context.read<CalendarBloc>().add(LoadCalendar(month: _focusedMonth));
    } else {
      _prevMonth();
    }
  }

  void _next() {
    if (_weekView) {
      setState(() {
        _selectedDay = (_selectedDay ?? DateTime.now()).add(const Duration(days: 7));
        _focusedMonth = DateTime(_selectedDay!.year, _selectedDay!.month);
      });
      context.read<CalendarBloc>().add(LoadCalendar(month: _focusedMonth));
    } else {
      _nextMonth();
    }
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDay = now;
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
              return _buildSkeleton();
            }

            if (state is CalendarError) {
              return CitrusEmptyState(
                title: 'Не удалось загрузить',
                subtitle: state.message,
                actionLabel: 'Повторить',
                actionIcon: Icons.refresh,
                onAction: _loadCalendar,
              );
            }

            final days = _visibleDays();
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
                    AppSize.gapH(14),
                    _buildControls(),
                    AppSize.gapH(16),
                    _buildWeekdayHeaders(),
                    AppSize.gapH(8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      child: KeyedSubtree(
                        key: ValueKey('grid_${_weekView}_${_focusedMonth.year}_${_focusedMonth.month}_${_weekView ? (_selectedDay?.day ?? 0) : 0}'),
                        child: _buildCalendarGrid(days, today, eventsByDay, moodAverages),
                      ),
                    ),
                    AppSize.gapH(12),
                    _buildMoodLegend(),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _selectedDay != null
                          ? Padding(
                              padding: AppSize.paddingOnly(top: 16),
                              child: _buildSelectedDayPanel(eventsByDay),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    AppSize.gapH(24),
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

  String _navTitle() {
    if (!_weekView) return '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';
    final wd = _weekDays(_selectedDay ?? DateTime.now());
    final a = wd.first;
    final b = wd.last;
    if (a.month == b.month) return '${a.day}–${b.day} ${_monthNames[a.month - 1]}';
    return '${a.day} ${_monthNames[a.month - 1].substring(0, 3)} – ${b.day} ${_monthNames[b.month - 1].substring(0, 3)}';
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppSize.radius(12),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Icon(icon, color: AppColors.foreground, size: 18),
        ),
      );

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navArrow(Icons.chevron_left, _prev),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _navTitle(),
                key: ValueKey(_navTitle()),
                style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w600, letterSpacing: 1.0, color: AppColors.foreground),
              ),
            ),
          ),
        ),
        _navArrow(Icons.chevron_right, _next),
      ],
    );
  }

  Widget _buildControls() {
    Widget seg(String label, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: AppSize.paddingH(14, 7),
            decoration: BoxDecoration(
              color: active ? AppColors.citrusOrange.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: AppSize.radius(9),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSize.s(13),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.citrusOrange : AppColors.mutedForeground,
              ),
            ),
          ),
        );

    return Row(
      children: [
        Container(
          padding: AppSize.padding(3),
          decoration: BoxDecoration(color: AppColors.surface1, borderRadius: AppSize.radius(11)),
          child: Row(children: [
            seg('Месяц', !_weekView, () => setState(() => _weekView = false)),
            seg('Неделя', _weekView, () => setState(() => _weekView = true)),
          ]),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _goToday,
          child: Container(
            padding: AppSize.paddingH(14, 8),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: AppSize.radius(11),
              border: Border.all(color: AppColors.citrusOrange.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.today, size: AppSize.s(15), color: AppColors.citrusOrange),
              AppSize.gapW(6),
              Text('Сегодня', style: TextStyle(fontSize: AppSize.s(13), fontWeight: FontWeight.w600, color: AppColors.citrusOrange)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodLegend() {
    Widget chip(int id) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: AppSize.s(9), height: AppSize.s(9), decoration: BoxDecoration(color: Mood.all[id].color, shape: BoxShape.circle)),
          AppSize.gapW(4),
          Text(Mood.all[id].label, style: TextStyle(fontSize: AppSize.s(10), color: AppColors.mutedForeground)),
        ]);
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [chip(0), chip(2), chip(5)],
    );
  }

  Widget _panelAction(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: AppSize.paddingH(10, 6),
          decoration: BoxDecoration(
            color: AppColors.citrusOrange.withValues(alpha: 0.15),
            borderRadius: AppSize.radius(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: AppSize.s(14), color: AppColors.citrusOrange),
            AppSize.gapW(4),
            Text(label, style: TextStyle(fontSize: AppSize.s(12), fontWeight: FontWeight.w600, color: AppColors.citrusOrange)),
          ]),
        ),
      );

  void _openDiaryForDay(DateTime day) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DiaryScreen()));
  }

  static const Map<String, String> _recurrenceLabels = {
    'none': 'Не повторять',
    'daily': 'Каждый день',
    'weekly': 'Каждую неделю',
    'monthly': 'Каждый месяц',
  };

  Widget _recurrenceSelector(String selected, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _recurrenceLabels.entries.map((e) {
        final active = selected == e.key;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: Container(
            padding: AppSize.paddingH(12, 7),
            decoration: BoxDecoration(
              color: active ? AppColors.citrusOrange.withValues(alpha: 0.18) : AppColors.surface2,
              borderRadius: AppSize.radius(999),
              border: Border.all(color: active ? AppColors.citrusOrange : Colors.transparent),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: AppSize.s(12),
                color: active ? AppColors.citrusOrange : AppColors.mutedForeground,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkeleton() {
    Widget box({double? w, double h = 0, double r = 10}) => Container(
          width: w,
          height: h == 0 ? null : h,
          decoration: BoxDecoration(color: AppColors.surface1, borderRadius: AppSize.radius(r)),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              box(w: 36, h: 36, r: 12),
              box(w: 150, h: 22),
              box(w: 36, h: 36, r: 12),
            ]),
            AppSize.gapH(14),
            Row(children: [box(w: 160, h: 34, r: 11), const Spacer(), box(w: 100, h: 34, r: 11)]),
            AppSize.gapH(20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.85,
              children: List.generate(35, (_) => box(r: 10)),
            ),
          ],
        ),
      ),
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
        final isCurrentMonth = _weekView || day.month == _focusedMonth.month;
        final isToday = _isSameDay(day, today);
        final isSelected = _selectedDay != null && _isSameDay(day, _selectedDay!);
        final dayKey = DateTime(day.year, day.month, day.day);
        final dayEvents = eventsByDay[dayKey] ?? [];
        final hasEvents = dayEvents.isNotEmpty;
        final avgMood = moodAverages[dayKey];
        final hasMood = avgMood != null && isCurrentMonth;

        // Фон по среднему настроению, кольцо «сегодня» и заливка выбранного дня.
        Color bgColor = Colors.transparent;
        Color borderColor = Colors.transparent;

        if (hasMood) {
          final moodColor = Mood.all[avgMood!.round().clamp(0, Mood.all.length - 1)].color;
          bgColor = moodColor.withValues(alpha: 0.18);
          borderColor = moodColor.withValues(alpha: 0.35);
        }
        if (isSelected) {
          bgColor = AppColors.citrusOrange.withValues(alpha: 0.22);
          borderColor = AppColors.citrusOrange;
        } else if (isToday) {
          // Чёткое кольцо «сегодня» поверх любого фона
          borderColor = AppColors.citrusOrange;
        }

        return GestureDetector(
          onTap: isCurrentMonth ? () => setState(() => _selectedDay = day) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppSize.radius(10),
              border: Border.all(color: borderColor, width: (isToday || isSelected) ? 1.5 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCurrentMonth ? '${day.day}' : '',
                  style: TextStyle(
                    fontSize: AppSize.s(14),
                    fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrentMonth ? AppColors.foreground : AppColors.dimForeground,
                  ),
                ),
                if (isCurrentMonth && (hasMood || hasEvents)) ...[
                  AppSize.gapH(3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasMood)
                        Text(_getMoodEmoji(avgMood!), style: TextStyle(fontSize: AppSize.s(11))),
                      if (hasMood && hasEvents) AppSize.gapW(3),
                      if (hasEvents)
                        Container(
                          width: AppSize.s(5),
                          height: AppSize.s(5),
                          decoration: const BoxDecoration(color: AppColors.citrusOrange, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ],
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

    return CitrusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${selected.day} ${_monthNames[selected.month - 1]}',
                  style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600, color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _panelAction(Icons.menu_book_outlined, 'Дневник', () => _openDiaryForDay(selected)),
              AppSize.gapW(8),
              _panelAction(Icons.add, 'Добавить', () => _showAddEventDialog(context, selected)),
            ],
          ),
          if (dayEvents.isNotEmpty) ...[
            AppSize.gapH(12),
            ...dayEvents.map((event) => _buildEventCard(event)),
          ] else ...[
            AppSize.gapH(12),
            Row(children: [
              Icon(Icons.event_available, size: AppSize.s(16), color: AppColors.dimForeground),
              AppSize.gapW(8),
              Text('На этот день событий нет', style: TextStyle(fontSize: AppSize.s(13), color: AppColors.mutedForeground)),
            ]),
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
        color: AppColors.subtleBg,
        borderRadius: AppSize.radius(12),
        border: Border.all(color: AppColors.subtleBorder),
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
                if (event.recurrence != 'none')
                  Padding(
                    padding: AppSize.paddingOnly(top: 3),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.repeat, size: AppSize.s(11), color: AppColors.citrusOrange),
                      AppSize.gapW(4),
                      Text(
                        _recurrenceLabels[event.recurrence] ?? '',
                        style: TextStyle(fontSize: AppSize.s(10), color: AppColors.citrusOrange),
                      ),
                    ]),
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
      return CitrusEmptyState(
        emoji: '🗓️',
        title: 'Пока нет событий',
        subtitle: 'Добавь экзамен, дедлайн или встречу — кнопкой «+» внизу.',
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
    String recurrence = 'none';

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
              AppSize.gapH(8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Повтор', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
              ),
              AppSize.gapH(8),
              _recurrenceSelector(recurrence, (v) => setDialogState(() => recurrence = v)),
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
                recurrence: recurrence,
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
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    bool notificationEnabled = event.notificationEnabled;
    String recurrence = event.recurrence;

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
                AppSize.gapH(8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Повтор', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                ),
                AppSize.gapH(8),
                _recurrenceSelector(recurrence, (v) => setModalState(() => recurrence = v)),
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
                  recurrence: recurrence,
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
