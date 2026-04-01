import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/repository/auth_repository.dart';
import '../../../core/repository/sleep_repository.dart';
import '../../../models/sleep_record.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/sleep_bloc.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({Key? key}) : super(key: key);

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
          title: const Text('Трекер сна'),
        ),
        body: BlocBuilder<SleepBloc, SleepState>(
          builder: (context, state) {
            if (state is SleepLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SleepError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                  ],
                ),
              );
            }

            if (state is SleepLoaded) {
              return _buildContent(state);
            }

            return const Center(child: Text('Нет данных'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSleepDialog(context),
          child: const Icon(Icons.add),
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
            const SizedBox(height: 16),
            Text(
              'Нет записей о сне',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddSleepDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить запись'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(state),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Text(
                  'Статистика',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                const SizedBox(width: 16),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Text(
                  'Записи',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const Divider(),
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
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (record.bedTime != null && record.bedTime!.isNotEmpty && record.wakeTime != null && record.wakeTime!.isNotEmpty)
            Text('Сон: ${record.bedTime!.substring(0, 5)} - ${record.wakeTime!.substring(0, 5)}'),
          if (record.quality != null)
            Row(
              children: [
                Icon(Icons.star, size: 16, color: _getQualityColor(record.quality)),
                const SizedBox(width: 4),
                Text('Качество: ${record.quality} / 5'),
              ],
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
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
              const Text(
                'Новая запись сна',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
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
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.nights_stay),
                title: const Text('Время отхода ко сну'),
                subtitle: Text(bedTime != null ? 'Выбрано: ${bedTime!.format(context)}' : 'Не выбрано'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: 23, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      bedTime = time;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('Время пробуждения'),
                subtitle: Text(wakeTime != null ? 'Выбрано: ${wakeTime!.format(context)}' : 'Не выбрано'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      wakeTime = time;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Качество сна'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        quality = value;
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (dateController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Выберите дату')),
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
                    const SnackBar(
                      content: Text('Запись добавлена'),
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
                child: const Text('Сохранить'),
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
        bedTime = TimeOfDay(
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
        wakeTime = TimeOfDay(
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
              const Text(
                'Редактировать запись сна',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
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
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.nights_stay),
                title: const Text('Время отхода ко сну'),
                subtitle: Text(bedTime != null ? 'Выбрано: ${bedTime!.format(context)}' : 'Не выбрано'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: bedTime ?? TimeOfDay(hour: 23, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      bedTime = time;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('Время пробуждения'),
                subtitle: Text(wakeTime != null ? 'Выбрано: ${wakeTime!.format(context)}' : 'Не выбрано'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: wakeTime ?? TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    setModalState(() {
                      wakeTime = time;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Качество сна'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        quality = value;
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (dateController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Выберите дату')),
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
                          const SnackBar(
                            content: Text('Запись обновлена'),
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
                      child: const Text('Сохранить'),
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
