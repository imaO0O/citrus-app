import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/citrus_card.dart';
import '../core/widgets/citrus_empty_state.dart';
import '../core/repository/sleep_repository.dart';
import '../core/services/casino_coins_service.dart';
import '../core/services/health_sync_service.dart';
import '../core/utils/network_error.dart';
import '../features/sleep/bloc/sleep_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../models/sleep_record.dart';
import '../core/utils/app_size.dart';

class SleepTrackerScreen extends StatefulWidget {
  SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  final List<String> _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  bool _isImporting = false;

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

  /// Проверка корректности времени (HH:MM)
  bool _isValidTime(String value) {
    if (!value.contains(':')) return false;
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  /// Автоформатирование и коррекция времени при вводе
  String _formatTimeInput(String value) {
    // Удаляем всё кроме цифр и двоеточий
    final cleaned = value.replaceAll(RegExp(r'[^\d:]'), '');
    
    // Если введено только число без двоеточия
    if (!cleaned.contains(':')) {
      if (cleaned.length == 1) return cleaned; // "2" -> "2"
      if (cleaned.length == 2) return cleaned; // "23" -> "23"
      if (cleaned.length == 3) return '${cleaned[0]}:${cleaned[1]}${cleaned[2]}'; // "230" -> "2:30"
      if (cleaned.length >= 4) return '${cleaned.substring(0, 2)}:${cleaned.substring(2, 4)}'; // "2300" -> "23:00"
    }
    
    // Если уже есть двоеточие, ограничиваем длину
    final parts = cleaned.split(':');
    if (parts.length >= 2) {
      String hour = parts[0].length > 2 ? parts[0].substring(0, 2) : parts[0];
      String minute = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];
      
      // Автоматическая коррекция некорректных значений
      final h = int.tryParse(hour) ?? 0;
      final m = int.tryParse(minute) ?? 0;
      if (h > 23) hour = '23';
      if (m > 59) minute = '59';
      
      return '$hour:$minute';
    }
    
    return cleaned.length > 5 ? cleaned.substring(0, 5) : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<SleepBloc, SleepState>(
          builder: (context, state) {
            if (state is SleepLoading) {
              return Center(child: CircularProgressIndicator(color: AppColors.citrusOrange));
            }

            if (state is SleepError) {
              return CitrusEmptyState(
                accent: AppColors.citrusPurple,
                title: 'Не удалось загрузить',
                subtitle: state.message,
                actionLabel: 'Повторить',
                actionIcon: Icons.refresh,
                onAction: _loadSleepData,
              );
            }

            if (state is SleepLoaded) {
              final records = state.records;
              records.sort((a, b) => b.sleepDate.compareTo(a.sleepDate));
              return _buildContent(records, state);
            }

            return CitrusEmptyState(
              emoji: '🌙',
              accent: AppColors.citrusPurple,
              title: 'Нет данных о сне',
              subtitle: 'Запиши, во сколько лёг и проснулся — и Цитрус покажет динамику сна.',
              actionLabel: 'Добавить запись',
              actionIcon: Icons.add,
              onAction: () => _showAddSleepDialog(context, null),
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<SleepBloc, SleepState>(
        builder: (context, state) {
          if (state is SleepLoaded) {
            return FloatingActionButton(
              heroTag: 'sleep_fab',
              onPressed: () => _showAddSleepDialog(context, state.records),
              backgroundColor: AppColors.citrusPurple,
              child: Icon(Icons.add),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(List<SleepRecord> records, SleepLoaded state) {
    final last7Days = _getLast7Days(records);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              AppSize.gapH(20),
              _buildSummaryCards(records, state),
              AppSize.gapH(24),
              _buildSleepChart(last7Days),
              AppSize.gapH(24),
              _buildLogSleepButton(),
              if (!kIsWeb) ...[
                AppSize.gapH(12),
                _buildImportFromWatchButton(),
              ],
              AppSize.gapH(24),
              _buildSleepHistoryHeader(),
              AppSize.gapH(12),
              _buildSleepHistoryList(records),
              AppSize.gapH(24),
              _buildSleepTipsHeader(),
              AppSize.gapH(12),
              _buildSleepTipsList(),
              AppSize.gapH(20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Трекер сна', style: AppText.displayTitle),
        AppSize.gapH(4),
        Text('Отслеживайте качество сна', style: AppText.caption),
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
        AppSize.gapW(10),
        Expanded(
          child: _buildSummaryCard(
            value: avgQuality != null ? '${avgQuality.toStringAsFixed(1)} / 5' : '—',
            label: 'Качество',
          ),
        ),
        AppSize.gapW(10),
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
    return CitrusCard(
      radius: 14,
      padding: AppSize.padding(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w700, color: AppColors.foreground),
          ),
          AppSize.gapH(4),
          Text(label, style: TextStyle(fontSize: AppSize.s(10), color: AppColors.dimForeground)),
        ],
      ),
    );
  }

  Widget _buildSleepChart(List<SleepRecord> last7Days) {
    final maxHours = 10.0;

    return CitrusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сон за неделю', style: AppText.sectionTitle),
          AppSize.gapH(20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                if (index < last7Days.length) {
                  final record = last7Days[index];
                  final hours = _calculateSleepDuration(record.bedTime, record.wakeTime);
                  final barHeight = hours > 0 ? ((hours / maxHours) * 120).clamp(0.0, 120.0) : 0.0;
                  final dayOfWeek = (record.sleepDate.weekday - 1) % 7;

                  return Expanded(
                    child: Padding(
                      padding: AppSize.paddingH(3, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (hours > 0)
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: AppColors.citrusPurple,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          AppSize.gapH(8),
                          Text(
                            _days[dayOfWeek],
                            style: TextStyle(fontSize: AppSize.s(10), color: AppColors.dimForeground),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Expanded(
                    child: Padding(
                      padding: AppSize.paddingH(3, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(height: 0),
                          AppSize.gapH(8),
                          Text('', style: TextStyle(fontSize: AppSize.s(10))),
                        ],
                      ),
                    ),
                  );
                }
              }),
            ),
          ),
          AppSize.gapH(16),
          Text(
            'Фиолетовые столбцы — длительность сна',
            style: TextStyle(fontSize: AppSize.s(10), color: AppColors.mutedForeground),
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
          colors: [AppColors.citrusPurple.withValues(alpha: 0.12), AppColors.citrusOrange.withValues(alpha: 0.08)],
        ),
        border: Border.all(color: AppColors.citrusPurple.withValues(alpha: 0.25)),
        borderRadius: AppSize.radius(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final state = context.read<SleepBloc>().state;
            final records = state is SleepLoaded ? state.records : <SleepRecord>[];
            _showAddSleepDialog(context, records);
          },
          borderRadius: AppSize.radius(14),
          child: Padding(
            padding: AppSize.paddingH(0, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nights_stay, color: AppColors.citrusPurple, size: 20),
                AppSize.gapW(8),
                Text(
                  'Записать сон',
                  style: TextStyle(fontSize: AppSize.s(14), fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Импорт сна с часов через Health Connect (Android) / HealthKit (iOS).
  /// Дедупликация по дате: ручные записи не перезаписываются.
  Future<void> _importFromWatch() async {
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<SleepBloc>();
    final repo = context.read<SleepRepository>();
    final blocState = bloc.state;
    final existing =
        blocState is SleepLoaded ? blocState.records : <SleepRecord>[];

    setState(() => _isImporting = true);
    try {
      final service = HealthSyncService();
      final granted = await service.requestPermission();
      if (!granted) {
        messenger.showSnackBar(SnackBar(
          content: Text(
              'Нет доступа к данным о сне. Установите Health Connect, подключите к нему приложение часов и разрешите чтение сна.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      final now = DateTime.now();
      final imported = await service.fetchSleepRecords(
        from: now.subtract(Duration(days: 14)),
        to: now,
      );
      if (imported.isEmpty) {
        messenger.showSnackBar(SnackBar(
          content: Text('Данных о сне за последние 14 дней не найдено'),
        ));
        return;
      }

      String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
      final existingDates = existing.map((r) => dateKey(r.sleepDate)).toSet();
      final newRecords = imported
          .where((r) => !existingDates.contains(dateKey(r.sleepDate)))
          .toList();

      if (newRecords.isEmpty) {
        messenger.showSnackBar(SnackBar(
          content: Text('Все записи с часов уже есть в дневнике сна'),
        ));
        return;
      }

      for (final record in newRecords) {
        await repo.createSleepRecord(record);
      }

      messenger.showSnackBar(SnackBar(
        content: Text('Импортировано записей с часов: ${newRecords.length} ⌚'),
        backgroundColor: Colors.green,
      ));
      _loadSleepData();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(friendlyError(e,
            fallback:
                'Не удалось получить данные с часов. Проверьте, что Health Connect установлен.')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Widget _buildImportFromWatchButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.citrusPurple.withValues(alpha: 0.35)),
        borderRadius: AppSize.radius(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isImporting ? null : _importFromWatch,
          borderRadius: AppSize.radius(14),
          child: Padding(
            padding: AppSize.paddingH(0, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isImporting)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.citrusPurple,
                    ),
                  )
                else
                  Icon(Icons.watch, color: AppColors.citrusPurple, size: 20),
                AppSize.gapW(8),
                Text(
                  _isImporting ? 'Импортируем...' : 'Импорт с часов',
                  style: TextStyle(
                    fontSize: AppSize.s(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepHistoryHeader() {
    return Text('История сна', style: AppText.sectionTitle);
  }

  Widget _buildSleepHistoryList(List<SleepRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSize.padding(32),
          child: Column(
            children: [
              Icon(Icons.bedtime, size: 48, color: AppColors.dimForeground),
              AppSize.gapH(8),
              Text(
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
          margin: AppSize.paddingOnly(bottom: 8),
          padding: AppSize.padding(14),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppSize.radius(14),
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
                      style: TextStyle(fontSize: AppSize.s(14), fontWeight: FontWeight.w600, color: AppColors.foreground),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 18),
                    color: AppColors.citrusOrange,
                    tooltip: 'Редактировать запись',
                    onPressed: () => _showEditSleepDialog(context, record),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 18),
                    color: AppColors.destructive,
                    tooltip: 'Удалить запись',
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
                      style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground),
                    ),
                  Text(
                    hours > 0 ? _formatSleepDuration(hours) : '—',
                    style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                ],
              ),
              if (quality != null) ...[
                AppSize.gapH(4),
                Text(
                  _getQualityLabel(quality),
                  style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSleepTipsHeader() {
    return Text('Советы для здорового сна', style: AppText.sectionTitle);
  }

  Widget _buildSleepTipsList() {
    return CitrusCard(
      accent: AppColors.citrusOrange,
      color: AppColors.citrusOrange.withValues(alpha: 0.06),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _sleepTips.map((tip) {
          return Padding(
            padding: AppSize.paddingOnly(bottom: 6),
            child: Text(
              '• $tip',
              style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground, height: 1.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddSleepDialog(BuildContext context, List<SleepRecord>? records) {
    // Проверяем есть ли запись на сегодня
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existingToday = records?.where((r) {
      final recordDate = DateTime(r.sleepDate.year, r.sleepDate.month, r.sleepDate.day);
      return recordDate.isAtSameMomentAs(today);
    }).firstOrNull;

    if (existingToday != null) {
      // Открываем редактирование существующей записи
      _showEditSleepDialog(context, existingToday);
      return;
    }

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
            borderRadius: AppSize.radius(16),
            side: BorderSide(color: AppColors.citrusPurple.withValues(alpha: 0.2)),
          ),
          title: Text(
            'Добавить запись о сне',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: AppColors.mutedForeground, size: 20),
                  title: Text('Дата', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                  subtitle: Text(
                    '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14)),
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
                AppSize.gapH(12),
                Row(
                  children: [
                    Text('Отбой:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                    AppSize.gapW(8),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(13)),
                        controller: TextEditingController(text: bedtime),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: AppSize.radius(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: AppSize.paddingH(10, 6),
                          isDense: true,
                        ),
                        onChanged: (v) => bedtime = _formatTimeInput(v),
                      ),
                    ),
                  ],
                ),
                AppSize.gapH(10),
                Row(
                  children: [
                    Text('Подъём:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                    AppSize.gapW(8),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(13)),
                        controller: TextEditingController(text: wakeup),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: AppSize.radius(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: AppSize.paddingH(10, 6),
                          isDense: true,
                        ),
                        onChanged: (v) => wakeup = _formatTimeInput(v),
                      ),
                    ),
                  ],
                ),
                AppSize.gapH(10),
                Text('Качество:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                AppSize.gapH(6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [1, 2, 3, 4, 5].map((q) {
                    final isSelected = quality == q;
                    return GestureDetector(
                      onTap: () => setModalState(() => quality = q),
                      child: Container(
                        padding: AppSize.paddingH(14, 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.citrusPurple.withValues(alpha: 0.2) : AppColors.surface2,
                          borderRadius: AppSize.radius(10),
                          border: Border.all(color: isSelected ? AppColors.citrusPurple : Colors.transparent),
                        ),
                        child: Text(
                          _getQualityLabel(q),
                          style: TextStyle(
                            color: isSelected ? AppColors.citrusPurple : AppColors.mutedForeground,
                            fontSize: AppSize.s(12),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
            ),
            FilledButton(
              onPressed: () {
                if (!_isValidTime(bedtime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Некорректное время отбоя (формат ЧЧ:ММ, часы 0-23, минуты 0-59)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!_isValidTime(wakeup)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Некорректное время подъёма (формат ЧЧ:ММ, часы 0-23, минуты 0-59)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

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
                CasinoCoinsService().completeQuest('sleep').then((_) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Запись о сне добавлена +25 🪙'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
              child: Text('Сохранить'),
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
            borderRadius: AppSize.radius(16),
            side: BorderSide(color: AppColors.citrusPurple.withValues(alpha: 0.2)),
          ),
          title: Text(
            'Редактировать запись',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: AppColors.mutedForeground, size: 20),
                  title: Text('Дата', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                  subtitle: Text(
                    '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    style: TextStyle(color: AppColors.foreground),
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
                AppSize.gapH(12),
                Row(
                  children: [
                    Text('Отбой:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                    AppSize.gapW(8),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(13)),
                        controller: TextEditingController(text: bedtime),
                        decoration: InputDecoration(
                          filled: true, fillColor: AppColors.surface2,
                          border: OutlineInputBorder(borderRadius: AppSize.radius(8), borderSide: BorderSide.none),
                          contentPadding: AppSize.paddingH(10, 6), isDense: true,
                        ),
                        onChanged: (v) => bedtime = _formatTimeInput(v),
                      ),
                    ),
                  ],
                ),
                AppSize.gapH(10),
                Row(
                  children: [
                    Text('Подъём:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                    AppSize.gapW(8),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(13)),
                        controller: TextEditingController(text: wakeup),
                        decoration: InputDecoration(
                          filled: true, fillColor: AppColors.surface2,
                          border: OutlineInputBorder(borderRadius: AppSize.radius(8), borderSide: BorderSide.none),
                          contentPadding: AppSize.paddingH(10, 6), isDense: true,
                        ),
                        onChanged: (v) => wakeup = _formatTimeInput(v),
                      ),
                    ),
                  ],
                ),
                AppSize.gapH(10),
                Text('Качество:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                AppSize.gapH(6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [1, 2, 3, 4, 5].map((q) {
                    final isSelected = quality == q;
                    return GestureDetector(
                      onTap: () => setModalState(() => quality = q),
                      child: Container(
                        padding: AppSize.paddingH(14, 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.citrusPurple.withValues(alpha: 0.2) : AppColors.surface2,
                          borderRadius: AppSize.radius(10),
                          border: Border.all(color: isSelected ? AppColors.citrusPurple : Colors.transparent),
                        ),
                        child: Text(
                          _getQualityLabel(q),
                          style: TextStyle(
                            color: isSelected ? AppColors.citrusPurple : AppColors.mutedForeground,
                            fontSize: AppSize.s(12),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
            FilledButton(
              onPressed: () {
                if (!_isValidTime(bedtime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Некорректное время отбоя (формат ЧЧ:ММ, часы 0-23, минуты 0-59)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!_isValidTime(wakeup)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Некорректное время подъёма (формат ЧЧ:ММ, часы 0-23, минуты 0-59)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Запись обновлена'), backgroundColor: Colors.green));
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusPurple),
              child: Text('Сохранить'),
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
        shape: RoundedRectangleBorder(borderRadius: AppSize.radius(16), side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.3))),
        title: Text('Удалить запись?', style: TextStyle(color: AppColors.foreground)),
        content: Text('Запись о сне будет удалена навсегда.', style: TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
          FilledButton(
            onPressed: () {
              context.read<SleepBloc>().add(DeleteSleepRecord(record.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Запись удалена'), backgroundColor: Colors.orange));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
