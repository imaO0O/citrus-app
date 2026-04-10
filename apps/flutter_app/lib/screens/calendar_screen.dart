import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(2026, 4);
  DateTime? _selectedDay;

  final List<String> _monthNames = [
    '\u042F\u043D\u0432\u0430\u0440\u044C', '\u0424\u0435\u0432\u0440\u0430\u043B\u044C', '\u041C\u0430\u0440\u0442', '\u0410\u043F\u0440\u0435\u043B\u044C', '\u041C\u0430\u0439', '\u0418\u044E\u043D\u044C',
    '\u0418\u044E\u043B\u044C', '\u0410\u0432\u0433\u0443\u0441\u0442', '\u0421\u0435\u043D\u0442\u044F\u0431\u0440\u044C', '\u041E\u043A\u0442\u044F\u0431\u0440\u044C', '\u041D\u043E\u044F\u0431\u0440\u044C', '\u0414\u0435\u043A\u0430\u0431\u0440\u044C',
  ];

  final Map<DateTime, String> _moods = {};
  final Map<DateTime, List<Map<String, String>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _generateSampleData();
  }

  void _generateSampleData() {
    final now = DateTime.now();
    final sampleMoods = ['\u{1F60A}', '\u{1F610}', '\u{1F614}', '\u{1F604}', '\u{1F970}', '\u{1F624}', '\u{1F914}'];
    for (int i = 1; i <= 30; i++) {
      final day = DateTime(now.year, now.month, i);
      _moods[day] = sampleMoods[i % sampleMoods.length];
      if (i % 5 == 0) {
        _events[day] = [
          {'emoji': '\u{1F4DD}', 'title': '\u0417\u0430\u043F\u0438\u0441\u044C \u0432 \u0434\u043D\u0435\u0432\u043D\u0438\u043A\u0435'},
          {'emoji': '\u{1F9D8}', 'title': '\u041C\u0435\u0434\u0438\u0442\u0430\u0446\u0438\u044F'},
        ];
      }
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
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
    final days = _getDaysInMonth(_focusedMonth);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
                _buildCalendarGrid(days, today),
                if (_selectedDay != null) ...[
                  const SizedBox(height: 16),
                  _buildSelectedDayPanel(),
                ],
                if (_selectedDay != null) const SizedBox(height: 24),
                _buildUpcomingEvents(),
              ],
            ),
          ),
        ),
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
    const weekdays = ['\u041F\u043D', '\u0412\u0442', '\u0421\u0440', '\u0427\u0442', '\u041F\u0442', '\u0421\u0431', '\u0412\u0441'];
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

  Widget _buildCalendarGrid(List<DateTime> days, DateTime today) {
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
        final hasEvents = _events[day] != null && _events[day]!.isNotEmpty;
        final mood = _moods[day];

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
                if (mood != null && isCurrentMonth)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(mood, style: const TextStyle(fontSize: 12)),
                  ),
                if (hasEvents && isCurrentMonth)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
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

  Widget _buildSelectedDayPanel() {
    final selected = _selectedDay!;
    final dayEvents = _events[selected] ?? [];

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
                onTap: _showAddEventModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.citrusOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C',
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
            ...dayEvents.map((event) => _buildEventCard(event['emoji']!, event['title']!)),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(String emoji, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppColors.foreground),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    final today = DateTime.now();
    final upcoming = <Map<String, String>>[];

    for (int i = 1; i <= 30; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      if (_events[day] != null) {
        for (final event in _events[day]!) {
          final shortMonth = _monthNames[day.month - 1].substring(0, 3).toLowerCase();
          upcoming.add({
            'date': '${day.day} $shortMonth',
            'emoji': event['emoji']!,
            'title': event['title']!,
          });
        }
      }
      if (upcoming.length >= 3) break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\u041F\u0420\u0415\u0414\u0421\u0422\u041E\u042F\u0429\u0418\u0415 \u0421\u041E\u0411\u042B\u0422\u0418\u042F',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        ...upcoming.map((event) => _buildUpcomingEventCard(
              event['date']!,
              event['emoji']!,
              event['title']!,
            )),
      ],
    );
  }

  Widget _buildUpcomingEventCard(String date, String emoji, String title) {
    final dayNum = date.split(' ')[0];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.citrusOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                dayNum,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.citrusOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventModal() {
    final titleController = TextEditingController();
    final emojiController = TextEditingController();
    String? selectedEmoji;
    final emojis = ['\u{1F4DD}', '\u{1F9D8}', '\u{1F3CB}', '\u{1F4D6}', '\u{1F3A8}', '\u{1F3B5}', '\u{1F3AF}', '\u{1F3C6}'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF2A2830))),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dimForeground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '\u041D\u043E\u0432\u043E\u0435 \u0441\u043E\u0431\u044B\u0442\u0438\u0435',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u0438\u043A\u043E\u043D\u043A\u0443',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.2,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  final isSelected = selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedEmoji = emoji),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.surface2 : AppColors.surface1,
                        border: Border.all(
                          color: isSelected ? AppColors.citrusOrange.withOpacity(0.5) : Colors.white.withOpacity(0.06),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.foreground),
                decoration: InputDecoration(
                  hintText: '\u041D\u0430\u0437\u0432\u0430\u043D\u0438\u0435 \u0441\u043E\u0431\u044B\u0442\u0438\u044F',
                  hintStyle: const TextStyle(color: AppColors.mutedForeground),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedEmoji != null && titleController.text.trim().isNotEmpty) {
                        setState(() {
                          _events[_selectedDay!] = [
                            ...(_events[_selectedDay!] ?? []),
                            {'emoji': selectedEmoji!, 'title': titleController.text.trim()},
                          ];
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      '\u0421\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u044C',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
