import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/repository/auth_repository.dart';
import '../../../core/repository/sleep_repository.dart';
import '../../../models/sleep_record.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/sleep_bloc.dart';
import '../../../core/utils/app_size.dart';

class SleepPage extends StatefulWidget {
  SleepPage({Key? key}) : super(key: key);

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  @override
  void initState() {
    super.initState();
    _initSleep();
  }

  void _initSleep() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final sleepRepository = context.read<SleepRepository>();
      sleepRepository.setUserId(user.id, token: user.token);
      context.read<SleepBloc>().updateUserId(user.id, token: user.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _initSleep();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Трекер сна'),
        ),
        body: BlocBuilder<SleepBloc, SleepState>(
          builder: (context, state) {
            if (state is SleepLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (state is SleepError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    AppSize.gapH(16),
                    Text(state.message),
                  ],
                ),
              );
            }

            if (state is SleepLoaded) {
              return _buildContent(state);
            }

            return Center(child: Text('Нет данных'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'sleep_page_fab',
          onPressed: () => _showAddSleepDialog(context),
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildContent(SleepLoaded state) {
    final records = state.records;
    
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 64, color: Colors.grey[400]),
            AppSize.gapH(16),
            Text(
              'Нет записей о сне',
              style: TextStyle(fontSize: AppSize.s(16), color: Colors.grey[600]),
            ),
            AppSize.gapH(8),
            TextButton.icon(
              onPressed: () => _showAddSleepDialog(context),
              icon: Icon(Icons.add),
              label: Text('Добавить запись'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppSize.padding(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(state),
          AppSize.gapH(16),
          _buildRecordsList(records),
        ],
      ),
    );
  }

  Widget _buildStatsCard(SleepLoaded state) {
    final avgQuality = state.averageQuality;
    final avgDuration = state.averageSleepDuration;

    return Card(
      child: Padding(
        padding: AppSize.padding(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.blue[700]),
                AppSize.gapW(12),
                Text(
                  'Статистика',
                  style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppSize.gapH(16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Среднее качество',
                    avgQuality != null ? '${avgQuality.toStringAsFixed(1)} / 5' : 'Нет данных',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                AppSize.gapW(16),
                Expanded(
                  child: _buildStatItem(
                    'Средняя длительность',
                    avgDuration != null ? '${avgDuration.toStringAsFixed(1)} ч' : 'Нет данных',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: AppSize.padding(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSize.radius(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          AppSize.gapH(8),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSize.s(18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          AppSize.gapH(4),
          Text(
            label,
            style: TextStyle(fontSize: AppSize.s(12), color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<SleepRecord> records) {
    // Сортируем по дате (новые сверху)
    final sorted = List<SleepRecord>.from(records)
      ..sort((a, b) => b.sleepDate.compareTo(a.sleepDate));

    return Card(
      child: Padding(
        padding: AppSize.padding(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Colors.blue[700]),
                AppSize.gapW(12),
                Text(
                  'Записи',
                  style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppSize.gapH(16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                return _buildRecordItem(sorted[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(SleepRecord record) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _getQualityColor(record.quality)?.withOpacity(0.2),
        child: Icon(
          Icons.bedtime,
          color: _getQualityColor(record.quality),
        ),
      ),
      title: Text(
        DateFormat('dd MMMM yyyy', 'ru_RU').format(record.sleepDate),
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSize.gapH(4),
          if (record.bedTime != null && record.bedTime!.isNotEmpty && record.wakeTime != null && record.wakeTime!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                AppSize.gapW(4),
                Text('${_formatTime(record.bedTime!)} - ${_formatTime(record.wakeTime!)}'),
                AppSize.gapW(8),
                Container(
                  padding: AppSize.paddingH(6, 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: AppSize.radius(4),
                  ),
                  child: Text(
                    _calculateDuration(record.bedTime, record.wakeTime) ?? '',
                    style: TextStyle(
                      fontSize: AppSize.s(12),
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (record.quality != null) ...[
            AppSize.gapH(4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: _getQualityColor(record.quality)),
                AppSize.gapW(4),
                Text('Качество: ${record.quality} / 5'),
              ],
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () => _showEditSleepDialog(context, record),
      ),
    );
  }

  Color? _getQualityColor(int? quality) {
    if (quality == null) return Colors.grey;
    if (quality >= 4) return Colors.green;
    if (quality >= 3) return Colors.orange;
    return Colors.red;
  }

  /// Форматирует время из "HH:MM:SS" или "HH:MM" в "HH:MM"
  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '--:--';
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Рассчитывает продолжительность сна в часах
  String? _calculateDuration(String? bedTime, String? wakeTime) {
    if (bedTime == null || wakeTime == null || bedTime.isEmpty || wakeTime.isEmpty) {
      return null;
    }
    
    try {
      final bedParts = bedTime.split(':');
      final wakeParts = wakeTime.split(':');
      
      if (bedParts.length < 2 || wakeParts.length < 2) return null;
      
      var bedHour = int.parse(bedParts[0]);
      var bedMinute = int.parse(bedParts[1]);
      var wakeHour = int.parse(wakeParts[0]);
      var wakeMinute = int.parse(wakeParts[1]);
      
      // Переводим в минуты
      var bedMinutes = bedHour * 60 + bedMinute;
      var wakeMinutes = wakeHour * 60 + wakeMinute;
      
      // Если проснулись на следующий день
      if (wakeMinutes < bedMinutes) {
        wakeMinutes += 24 * 60;
      }
      
      final durationMinutes = wakeMinutes - bedMinutes;
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      
      if (minutes == 0) {
        return '$hours ч';
      }
      return '$hours ч ${minutes.toString().padLeft(2, '0')} мин';
    } catch (e) {
      return null;
    }
  }

  void _showAddSleepDialog(BuildContext context) {
    final dateController = TextEditingController();
    TimeOfDay? bedTime;
    TimeOfDay? wakeTime;
    int? quality = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: AppSize.w(16), top: AppSize.h(16), right: AppSize.w(16), bottom: MediaQuery.of(context).viewInsets.bottom + AppSize.h(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Новая запись сна',
                style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.bold),
              ),
              AppSize.gapH(16),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Дата',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setModalState(() {
                      dateController.text = DateFormat('dd.MM.yyyy').format(date);
                    });
                  }
                },
              ),
              AppSize.gapH(16),
              ListTile(
                leading: Icon(Icons.nights_stay),
                title: Text('Время отхода ко сну'),
                subtitle: Text(bedTime != null ? 'Выбрано: ${bedTime!.format(context)}' : 'Не выбрано'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: 23, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      final bedTime = time;
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.wb_sunny),
                title: Text('Время пробуждения'),
                subtitle: Text(wakeTime != null ? 'Выбрано: ${wakeTime!.format(context)}' : 'Не выбрано'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      final wakeTime = time;
                    });
                  }
                },
              ),
              AppSize.gapH(16),
              Text('Качество сна'),
              AppSize.gapH(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        final quality = value;
                      });
                    },
                    child: Icon(
                      value <= (quality ?? 0) ? Icons.star : Icons.star_border,
                      color: value <= (quality ?? 0) ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                  );
                }),
              ),
              AppSize.gapH(24),
              ElevatedButton(
                onPressed: () {
                  if (dateController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Выберите дату')),
                    );
                    return;
                  }

                  final date = DateFormat('dd.MM.yyyy').parse(dateController.text);
                  final authState = context.read<AuthBloc>().state;
                  final userId = authState is AuthAuthenticated ? authState.user.id : 'unknown';

                  final record = SleepRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: userId,
                    sleepDate: date,
                    bedTime: bedTime != null
                        ? '${bedTime!.hour.toString().padLeft(2, '0')}:${bedTime!.minute.toString().padLeft(2, '0')}:00'
                        : null,
                    wakeTime: wakeTime != null
                        ? '${wakeTime!.hour.toString().padLeft(2, '0')}:${wakeTime!.minute.toString().padLeft(2, '0')}:00'
                        : null,
                    quality: quality,
                  );

                  context.read<SleepBloc>().add(AddSleepRecord(record));
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Запись добавлена'),
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
                child: Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSleepDialog(BuildContext context, SleepRecord record) {
    print('_showEditSleepDialog: record.bedTime="${record.bedTime}", record.wakeTime="${record.wakeTime}"');
    
    final dateController = TextEditingController(
      text: DateFormat('dd.MM.yyyy').format(record.sleepDate),
    );
    TimeOfDay? bedTime;
    if (record.bedTime != null && record.bedTime!.isNotEmpty && record.bedTime!.contains(':')) {
      try {
        final parts = record.bedTime!.split(':');
        final bedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        print('_showEditSleepDialog: bedTime parsed: ${bedTime.hour}:${bedTime.minute}');
      } catch (e) {
        print('_showEditSleepDialog: ошибка парсинга bedTime: $e, value="${record.bedTime}"');
      }
    }
    
    TimeOfDay? wakeTime;
    if (record.wakeTime != null && record.wakeTime!.isNotEmpty && record.wakeTime!.contains(':')) {
      try {
        final parts = record.wakeTime!.split(':');
        final wakeTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        print('_showEditSleepDialog: wakeTime parsed: ${wakeTime.hour}:${wakeTime.minute}');
      } catch (e) {
        print('_showEditSleepDialog: ошибка парсинга wakeTime: $e, value="${record.wakeTime}"');
      }
    }
    
    int? quality = record.quality ?? 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: AppSize.w(16), top: AppSize.h(16), right: AppSize.w(16), bottom: MediaQuery.of(context).viewInsets.bottom + AppSize.h(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Редактировать запись сна',
                style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.bold),
              ),
              AppSize.gapH(16),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Дата',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: record.sleepDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setModalState(() {
                      dateController.text = DateFormat('dd.MM.yyyy').format(date);
                    });
                  }
                },
              ),
              AppSize.gapH(16),
              ListTile(
                leading: Icon(Icons.nights_stay),
                title: Text('Время отхода ко сну'),
                subtitle: Text(bedTime != null ? 'Выбрано: ${bedTime!.format(context)}' : 'Не выбрано'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: bedTime ?? TimeOfDay(hour: 23, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      final bedTime = time;
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.wb_sunny),
                title: Text('Время пробуждения'),
                subtitle: Text(wakeTime != null ? 'Выбрано: ${wakeTime!.format(context)}' : 'Не выбрано'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: wakeTime ?? TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      final wakeTime = time;
                    });
                  }
                },
              ),
              AppSize.gapH(16),
              Text('Качество сна'),
              AppSize.gapH(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        final quality = value;
                      });
                    },
                    child: Icon(
                      value <= (quality ?? 0) ? Icons.star : Icons.star_border,
                      color: value <= (quality ?? 0) ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                  );
                }),
              ),
              AppSize.gapH(24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: AppSize.paddingH(0, 16),
                      ),
                      child: Text('Отмена'),
                    ),
                  ),
                  AppSize.gapW(16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (dateController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Выберите дату')),
                          );
                          return;
                        }

                        final date = DateFormat('dd.MM.yyyy').parse(dateController.text);
                        final updatedRecord = SleepRecord(
                          id: record.id,
                          userId: record.userId,
                          sleepDate: date,
                          bedTime: bedTime != null
                              ? '${bedTime!.hour.toString().padLeft(2, '0')}:${bedTime!.minute.toString().padLeft(2, '0')}:00'
                              : null,
                          wakeTime: wakeTime != null
                              ? '${wakeTime!.hour.toString().padLeft(2, '0')}:${wakeTime!.minute.toString().padLeft(2, '0')}:00'
                              : null,
                          quality: quality,
                        );

                        context.read<SleepBloc>().add(UpdateSleepRecord(updatedRecord));
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Запись обновлена'),
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
                      child: Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
