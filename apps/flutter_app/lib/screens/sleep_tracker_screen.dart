import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  final List<String> _days = ['\u041F\u043D', '\u0412\u0442', '\u0421\u0440', '\u0427\u0442', '\u041F\u0442', '\u0421\u0431', '\u0412\u0441'];
  final List<double> _sleepHours = [7.0, 8.5, 6.0, 7.5, 8.0, 9.0, 7.5];
  final List<int> _sleepQuality = [2, 3, 1, 2, 3, 3, 2];

  final List<Map<String, dynamic>> _sleepHistory = [
    {'date': '\u0421\u0435\u0433\u043E\u0434\u043D\u044F', 'bedtime': '23:15', 'wakeup': '06:45', 'hours': 7.5, 'quality': 2},
    {'date': '\u0412\u0447\u0435\u0440\u0430', 'bedtime': '22:30', 'wakeup': '07:00', 'hours': 8.5, 'quality': 3},
    {'date': '2 \u0434\u043D\u044F \u043D\u0430\u0437\u0430\u0434', 'bedtime': '00:30', 'wakeup': '06:30', 'hours': 6.0, 'quality': 1},
    {'date': '3 \u0434\u043D\u044F \u043D\u0430\u0437\u0430\u0434', 'bedtime': '23:00', 'wakeup': '06:30', 'hours': 7.5, 'quality': 2},
    {'date': '4 \u0434\u043D\u044F \u043D\u0430\u0437\u0430\u0434', 'bedtime': '22:00', 'wakeup': '06:00', 'hours': 8.0, 'quality': 3},
    {'date': '5 \u0434\u043D\u0435\u0439 \u043D\u0430\u0437\u0430\u0434', 'bedtime': '23:45', 'wakeup': '08:45', 'hours': 9.0, 'quality': 3},
  ];

  final List<String> _sleepTips = [
    '\u041B\u043E\u0436\u0438\u0442\u0435\u0441\u044C \u0438 \u0432\u0441\u0442\u0430\u0432\u0430\u0439\u0442\u0435 \u0432 \u043E\u0434\u043D\u043E \u0438 \u0442\u043E \u0436\u0435 \u0432\u0440\u0435\u043C\u044F \u043A\u0430\u0436\u0434\u044B\u0439 \u0434\u0435\u043D\u044C.',
    '\u041E\u0442\u043A\u0430\u0436\u0438\u0442\u0435\u0441\u044C \u043E\u0442 \u044D\u043A\u0440\u0430\u043D\u043E\u0432 \u0437\u0430 30 \u043C\u0438\u043D\u0443\u0442 \u0434\u043E \u0441\u043D\u0430.',
    '\u041E\u043F\u0442\u0438\u043C\u0430\u043B\u044C\u043D\u0430\u044F \u0442\u0435\u043C\u043F\u0435\u0440\u0430\u0442\u0443\u0440\u0430 \u0432 \u0441\u043F\u0430\u043B\u044C\u043D\u0435 18-20\u00B0C.',
    '\u0418\u0437\u0431\u0435\u0433\u0430\u0439\u0442\u0435 \u043A\u043E\u0444\u0435 \u0438 \u044D\u043D\u0435\u0440\u0433\u0435\u0442\u0438\u043A\u043E\u0432 \u043F\u043E\u0441\u043B\u0435 14:00.',
    '\u0421\u043E\u0437\u0434\u0430\u0439\u0442\u0435 \u0440\u0438\u0442\u0443\u0430\u043B \u043F\u0435\u0440\u0435\u0434 \u0441\u043D\u043E\u043C: \u0447\u0442\u0435\u043D\u0438\u0435, \u043C\u0435\u0434\u0438\u0442\u0430\u0446\u0438\u044F.',
    '\u041D\u0435 \u0435\u0448\u044C\u0442\u0435 \u0442\u044F\u0436\u0451\u043B\u0443\u044E \u043F\u0438\u0449\u0443 \u0437\u0430 2-3 \u0447\u0430\u0441\u0430 \u0434\u043E \u0441\u043D\u0430.',
  ];

  Color _getQualityColor(int quality) {
    return switch (quality) {
      3 => AppColors.moodExcellent,
      2 => AppColors.moodGood,
      1 => AppColors.moodAnxious,
      _ => AppColors.moodVeryBad,
    };
  }

  String _getQualityLabel(int quality) {
    return switch (quality) {
      3 => '\u041E\u0442\u043B\u0438\u0447\u043D\u043E',
      2 => '\u0425\u043E\u0440\u043E\u0448\u043E',
      1 => '\u0421\u0440\u0435\u0434\u043D\u0435',
      _ => '\u041F\u043B\u043E\u0445\u043E',
    };
  }

  int _getGoodNightsCount() => _sleepQuality.where((q) => q >= 2).length;
  double _getAverageSleep() => _sleepHours.reduce((a, b) => a + b) / _sleepHours.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildSleepChart(),
              const SizedBox(height: 24),
              _buildLogSleepButton(),
              const SizedBox(height: 24),
              _buildSleepHistoryHeader(),
              const SizedBox(height: 12),
              _buildSleepHistoryList(),
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

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\u0422\u0440\u0435\u043A\u0435\u0440 \u0441\u043D\u0430',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
        ),
        SizedBox(height: 4),
        Text(
          '\u041E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0439\u0442\u0435 \u043A\u0430\u0447\u0435\u0441\u0442\u0432\u043E \u0441\u043D\u0430',
          style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final avgSleep = _getAverageSleep();
    final goodNights = _getGoodNightsCount();

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(value: '${avgSleep.toStringAsFixed(1)}\u0447', label: '\u0421\u0440\u0435\u0434\u043D\u0438\u0439 \u0441\u043E\u043D'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(value: '23:30', label: '\u0421\u0440\u0435\u0434\u043D\u0438\u0439 \u043E\u0442\u0431\u043E\u0439'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(value: '$goodNights/7', label: '\u0425\u043E\u0440\u043E\u0448\u0438\u0435 \u043D\u043E\u0447\u0438'),
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

  Widget _buildSleepChart() {
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
            '\u0421\u043E\u043D \u0437\u0430 \u043D\u0435\u0434\u0435\u043B\u044E',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_sleepHours.length, (index) {
                final hours = _sleepHours[index];
                final quality = _sleepQuality[index];
                final barHeight = (hours / maxHours) * 120;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: _getQualityColor(quality),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _days[index],
                          style: const TextStyle(fontSize: 10, color: AppColors.dimForeground),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _qualityLegend(3, '\u041E\u0442\u043B\u0438\u0447\u043D\u043E'),
              const SizedBox(width: 12),
              _qualityLegend(2, '\u0425\u043E\u0440\u043E\u0448\u043E'),
              const SizedBox(width: 12),
              _qualityLegend(1, '\u0421\u0440\u0435\u0434\u043D\u0435'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qualityLegend(int level, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getQualityColor(level),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
      ],
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
          onTap: _showAddSleepDialog,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nights_stay, color: AppColors.citrusPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  '\u0417\u0430\u043F\u0438\u0441\u0430\u0442\u044C \u0441\u043E\u043D',
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
      '\u0418\u0441\u0442\u043E\u0440\u0438\u044F \u0441\u043D\u0430',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground),
    );
  }

  Widget _buildSleepHistoryList() {
    return Column(
      children: _sleepHistory.map((entry) {
        final quality = entry['quality'] as int;
        final qColor = _getQualityColor(quality);
        final hours = entry['hours'] as double;
        final maxH = 10.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: qColor, width: 3),
              top: BorderSide(color: AppColors.subtleBorder),
              right: BorderSide(color: AppColors.subtleBorder),
              bottom: BorderSide(color: AppColors.subtleBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry['date'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground),
                  ),
                  Text(
                    '${hours}\u0447',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: qColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${entry['bedtime']} - ${entry['wakeup']}',
                style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (hours / maxH).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: qColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSleepTipsHeader() {
    return const Text(
      '\u0421\u043E\u0432\u0435\u0442\u044B \u0434\u043B\u044F \u0437\u0434\u043E\u0440\u043E\u0432\u043E\u0433\u043E \u0441\u043D\u0430',
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
              '\u2022 $tip',
              style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, height: 1.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddSleepDialog() {
    String bedtime = '23:00';
    String wakeup = '07:00';
    int quality = 2;

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
            '\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u0437\u0430\u043F\u0438\u0441\u044C \u043E \u0441\u043D\u0435',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('\u041E\u0442\u0431\u043E\u0439:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                      controller: TextEditingController(text: bedtime),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                  const Text('\u041F\u043E\u0434\u044A\u0451\u043C:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                      controller: TextEditingController(text: wakeup),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        isDense: true,
                      ),
                      onChanged: (v) => wakeup = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('\u041A\u0430\u0447\u0435\u0441\u0442\u0432\u043E:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3].map((q) {
                  final isSelected = quality == q;
                  return GestureDetector(
                    onTap: () => setModalState(() => quality = q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _getQualityColor(q).withOpacity(0.2) : AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? _getQualityColor(q) : Colors.transparent),
                      ),
                      child: Text(
                        _getQualityLabel(q),
                        style: TextStyle(color: isSelected ? _getQualityColor(q) : AppColors.mutedForeground, fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('\u041E\u0442\u043C\u0435\u043D\u0430', style: TextStyle(color: AppColors.mutedForeground)),
            ),
            FilledButton(
              onPressed: () {
                final btParts = bedtime.split(':');
                final wuParts = wakeup.split(':');
                final btH = int.tryParse(btParts[0]) ?? 0;
                final btM = int.tryParse(btParts[1]) ?? 0;
                final wuH = int.tryParse(wuParts[0]) ?? 0;
                final wuM = int.tryParse(wuParts[1]) ?? 0;
                double hours = (wuH + wuM / 60 - btH - btM / 60);
                if (hours < 0) hours += 24;

                setState(() {
                  _sleepHistory.insert(0, {'date': '\u0421\u0435\u0433\u043E\u0434\u043D\u044F', 'bedtime': bedtime, 'wakeup': wakeup, 'hours': double.parse(hours.toStringAsFixed(1)), 'quality': quality});
                });
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusPurple),
              child: const Text('\u0421\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u044C'),
            ),
          ],
        ),
      ),
    );
  }
}
