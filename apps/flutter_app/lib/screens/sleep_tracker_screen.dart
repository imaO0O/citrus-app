import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_colors.dart';
import '../features/sleep/bloc/sleep_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../models/sleep_record.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  final List<String> _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  final List<String> _sleepTips = [
    'Ложитесь и вставайте в одно и то же время каждый день.',
    'Откажитесь от экранов за 30 минут до сна.',
    'Оптимальная температура в спальне 18-20°C.',
    'Избегайте кофе и энергетиков после 14:00.',
    'Создайте ритуал перед сном: чтение, медитация.',
    'Не ешьте тяжёлую пищу за 2-3 часа до сна.',
  ];

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  void _loadSleepData() {
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, 1, 1);
    final endDate = DateTime(now.year + 1, 12, 31);
    context.read<SleepBloc>().add(LoadSleepRecords(startDate: startDate, endDate: endDate));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Перезагружаем при изменении AuthState
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _loadSleepData();
    }
  }

  String _getQualityLabel(int? quality) {
    return switch (quality) {
      5 => 'Отлично',
      4 => 'Хорошо',
      3 => 'Нормально',
      2 => 'Плохо',
      1 => 'Очень плохо',
      _ => '—',
    };
  }

  double _calculateSleepDuration(String? bedTime, String? wakeTime) {
    if (bedTime == null || wakeTime == null) return 0;
    final bed = _parseTime(bedTime);
    final wake = _parseTime(wakeTime);
    if (bed == null || wake == null) return 0;
    double hours = wake - bed;
    if (hours < 0) hours += 24;
    return hours;
  }

  double? _parseTime(String timeStr) {
    if (!timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour + minute / 60.0;
    } catch (e) {
      return null;
    }
  }

  String _formatSleepDuration(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}ч ${m}м';
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    return switch (diff) {
      0 => 'Сегодня',
      1 => 'Вчера',
      _ => '${diff} дн. назад',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<SleepBloc, SleepState>(
          builder: (context, state) {
            if (state is SleepLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.citrusOrange));
            }

            if (state is SleepError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: AppColors.mutedForeground)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSleepData,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is SleepLoaded) {
              final records = state.records;
              records.sort((a, b) => b.sleepDate.compareTo(a.sleepDate));
              return _buildContent(records, state);
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bedtime, size: 64, color: AppColors.dimForeground),
                  const SizedBox(height: 16),
                  const Text('Нет данных о сне', style: TextStyle(color: AppColors.mutedForeground, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSleepDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить запись'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<SleepBloc, SleepState>(
        builder: (context, state) {
          if (state is SleepLoaded) {
            return FloatingActionButton(
              onPressed: () => _showAddSleepDialog(context, state.records),
              backgroundColor: AppColors.citrusPurple,
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(List<SleepRecord> records, SleepLoaded state) {
    final last7Days = _getLast7Days(records);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSummaryCards(records, state),
              const SizedBox(height: 24),
              _buildSleepChart(last7Days),
              const SizedBox(height: 24),
              _buildLogSleepButton(),
              const SizedBox(height: 24),
              _buildSleepHistoryHeader(),
              const SizedBox(height: 12),
              _buildSleepHistoryList(records),
              const SizedBox(height: 24),
              _buildSleepTipsHeader(),
              const SizedBox(height: 12),
              _buildSleepTipsList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<SleepRecord> _getLast7Days(List<SleepRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7 = <SleepRecord>[];

    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final record = records.where((r) {
        final rd = DateTime(r.sleepDate.year, r.sleepDate.month, r.sleepDate.day);
        return rd.isAtSameMomentAs(day);
      }).firstOrNull;
      if (record != null) {
        last7.add(record);
      }
    }

    return last7.reversed.toList();
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Трекер сна',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
        ),
        SizedBox(height: 4),
        Text(
          'Отслеживайте качество сна',
          style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(List<SleepRecord> records, SleepLoaded state) {
    final avgDuration = state.averageSleepDuration;
    final avgQuality = state.averageQuality;
    final goodNights = records.where((r) => (r.quality ?? 0) >= 2).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            value: avgDuration != null ? _formatSleepDuration(avgDuration) : '—',
            label: 'Средний сон',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            value: avgQuality != null ? '${avgQuality.toStringAsFixed(1)} / 5' : '—',
            label: 'Качество',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            value: '$goodNights/${records.length}',
            label: 'Хорошие ночи',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.dimForeground)),
        ],
      ),
    );
  }

  Widget _buildSleepChart(List<SleepRecord> last7Days) {
    final maxHours = 10.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сон за неделю',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                if (index < last7Days.length) {
                  final record = last7Days[index];
                  final hours = _calculateSleepDuration(record.bedTime, record.wakeTime);
                  final barHeight = hours > 0 ? (hours / maxHours) * 120 : 0.0;
                  final dayOfWeek = (record.sleepDate.weekday - 1) % 7;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (hours > 0)
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: AppColors.citrusPurple,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _days[dayOfWeek],
                            style: const TextStyle(fontSize: 10, color: AppColors.dimForeground),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(height: 0),
                          const SizedBox(height: 8),
                          const Text('', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Фиолетовые столбцы — длительность сна',
            style: TextStyle(fontSize: 10, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildLogSleepButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.citrusPurple.withOpacity(0.12), AppColors.citrusOrange.withOpacity(0.08)],
        ),
        border: Border.all(color: AppColors.citrusPurple.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final state = context.read<SleepBloc>().state;
            final records = state is SleepLoaded ? state.records : <SleepRecord>[];
            _showAddSleepDialog(context, records);
          },
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nights_stay, color: AppColors.citrusPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Записать сон',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepHistoryHeader() {
    return const Text(
      'История сна',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground),
    );
  }

  Widget _buildSleepHistoryList(List<SleepRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.bedtime, size: 48, color: AppColors.dimForeground),
              const SizedBox(height: 8),
              const Text(
                'Нет записей о сне',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: records.take(10).map((record) {
        final hours = _calculateSleepDuration(record.bedTime, record.wakeTime);
        final quality = record.quality;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getDayLabel(record.sleepDate),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppColors.citrusOrange,
                    onPressed: () => _showEditSleepDialog(context, record),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: AppColors.destructive,
                    onPressed: () => _confirmDeleteSleep(context, record),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (record.bedTime != null && record.wakeTime != null)
                    Text(
                      '${record.bedTime!.substring(0, 5)} - ${record.wakeTime!.substring(0, 5)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                    ),
                  Text(
                    hours > 0 ? _formatSleepDuration(hours) : '—',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                ],
              ),
              if (quality != null) ...[
                const SizedBox(height: 4),
                Text(
                  _getQualityLabel(quality),
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSleepTipsHeader() {
    return const Text(
      'Советы для здорового сна',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
    );
  }

  Widget _buildSleepTipsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.citrusOrange.withOpacity(0.05),
        border: Border.all(color: AppColors.citrusOrange.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _sleepTips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $tip',
              style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, height: 1.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddSleepDialog(BuildContext context, List<SleepRecord>? records) {
    String bedtime = '23:00';
    String wakeup = '07:00';
    int quality = 3;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.citrusPurple.withOpacity(0.2)),
          ),
          title: const Text(
            'Добавить запись о сне',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.mutedForeground, size: 20),
                  title: const Text('Дата', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  subtitle: Text(
                    '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Отбой:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                        controller: TextEditingController(text: bedtime),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          isDense: true,
                        ),
                        onChanged: (v) => bedtime = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Подъём:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                        controller: TextEditingController(text: wakeup),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          isDense: true,
                        ),
                        onChanged: (v) => wakeup = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Качество:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 2, 3, 4, 5].map((q) {
                    final isSelected = quality == q;
                    return GestureDetector(
                      onTap: () => setModalState(() => quality = q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.citrusPurple.withValues(alpha: 0.2) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppColors.citrusPurple : Colors.transparent),
                        ),
                        child: Text(
                          _getQualityLabel(q),
                          style: TextStyle(
                            color: isSelected ? AppColors.citrusPurple : AppColors.mutedForeground,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                final btParts = bedtime.split(':');
                final wuParts = wakeup.split(':');
                final btH = int.tryParse(btParts[0]) ?? 0;
                final btM = int.tryParse(btParts[1]) ?? 0;
                final wuH = int.tryParse(wuParts[0]) ?? 0;
                final wuM = int.tryParse(wuParts[1]) ?? 0;

                final record = SleepRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: 'unknown',
                  sleepDate: selectedDate,
                  bedTime: '${btH.toString().padLeft(2, '0')}:${btM.toString().padLeft(2, '0')}:00',
                  wakeTime: '${wuH.toString().padLeft(2, '0')}:${wuM.toString().padLeft(2, '0')}:00',
                  quality: quality,
                );

                context.read<SleepBloc>().add(AddSleepRecord(record));
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Запись о сне добавлена'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusPurple),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSleepDialog(BuildContext context, SleepRecord record) {
    String bedtime = record.bedTime?.substring(0, 5) ?? '23:00';
    String wakeup = record.wakeTime?.substring(0, 5) ?? '07:00';
    int quality = record.quality ?? 3;
    DateTime selectedDate = record.sleepDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.citrusPurple.withOpacity(0.2)),
          ),
          title: const Text(
            'Редактировать запись',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.mutedForeground, size: 20),
                  title: const Text('Дата', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  subtitle: Text(
                    '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    style: const TextStyle(color: AppColors.foreground),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setModalState(() => selectedDate = date);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Отбой:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                        controller: TextEditingController(text: bedtime),
                        decoration: InputDecoration(
                          filled: true, fillColor: AppColors.surface2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), isDense: true,
                        ),
                        onChanged: (v) => bedtime = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Подъём:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                        controller: TextEditingController(text: wakeup),
                        decoration: InputDecoration(
                          filled: true, fillColor: AppColors.surface2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), isDense: true,
                        ),
                        onChanged: (v) => wakeup = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Качество:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 2, 3, 4, 5].map((q) {
                    final isSelected = quality == q;
                    return GestureDetector(
                      onTap: () => setModalState(() => quality = q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.citrusPurple.withValues(alpha: 0.2) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppColors.citrusPurple : Colors.transparent),
                        ),
                        child: Text(_getQualityLabel(q), style: TextStyle(
                          color: isSelected ? AppColors.citrusPurple : AppColors.mutedForeground, fontSize: 11)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
            FilledButton(
              onPressed: () {
                final btParts = bedtime.split(':');
                final wuParts = wakeup.split(':');
                final btH = int.tryParse(btParts[0]) ?? 0;
                final btM = int.tryParse(btParts[1]) ?? 0;
                final wuH = int.tryParse(wuParts[0]) ?? 0;
                final wuM = int.tryParse(wuParts[1]) ?? 0;

                final updatedRecord = SleepRecord(
                  id: record.id,
                  userId: record.userId,
                  sleepDate: selectedDate,
                  bedTime: '${btH.toString().padLeft(2, '0')}:${btM.toString().padLeft(2, '0')}:00',
                  wakeTime: '${wuH.toString().padLeft(2, '0')}:${wuM.toString().padLeft(2, '0')}:00',
                  quality: quality,
                );

                context.read<SleepBloc>().add(UpdateSleepRecord(updatedRecord));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись обновлена'), backgroundColor: Colors.green));
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusPurple),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSleep(BuildContext context, SleepRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.destructive.withOpacity(0.3))),
        title: const Text('Удалить запись?', style: TextStyle(color: AppColors.foreground)),
        content: const Text('Запись о сне будет удалена навсегда.', style: TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
          FilledButton(
            onPressed: () {
              context.read<SleepBloc>().add(DeleteSleepRecord(record.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись удалена'), backgroundColor: Colors.orange));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
