import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0;
  final List<String> _periods = ['\u041D\u0435\u0434\u0435\u043B\u044F', '\u041C\u0435\u0441\u044F\u0446', '3 \u043C\u0435\u0441', '\u0413\u043E\u0434'];

  Color _getMoodBarColor(double value) {
    if (value >= 5) return AppColors.moodExcellent;
    if (value >= 4) return AppColors.moodGood;
    if (value >= 3) return AppColors.citrusOrange;
    if (value >= 2) return AppColors.moodAnxious;
    return AppColors.moodVeryBad;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildPeriodSelector(),
                        const SizedBox(height: 20),
                        _buildOverviewCards(),
                        const SizedBox(height: 20),
                        _buildMoodChart(),
                        const SizedBox(height: 20),
                        _buildMoodDistribution(),
                        const SizedBox(height: 20),
                        _buildInsights(),
                        const SizedBox(height: 20),
                        _buildActivitySection(),
                        const SizedBox(height: 20),
                        _buildExportButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u0410\u043D\u0430\u043B\u0438\u0442\u0438\u043A\u0430',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
            ),
            SizedBox(height: 4),
            Text(
              '\u041E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0439\u0442\u0435 \u0441\u0432\u043E\u0439 \u043F\u0440\u043E\u0433\u0440\u0435\u0441\u0441',
              style: TextStyle(fontSize: 13, color: AppColors.dimForeground),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.download_outlined, color: AppColors.citrusOrange, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = index == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.citrusOrange.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _periods[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final cards = [
      {'value': '30', 'label': '\u0414\u043D\u0435\u0439'},
      {'value': '71%', 'label': '\u0425\u043E\u0440\u043E\u0448\u0438\u0445 \u0434\u043D\u0435\u0439'},
      {'value': '+15%', 'label': '\u0423\u043B\u0443\u0447\u0448\u0435\u043D\u0438\u0435'},
      {'value': '7', 'label': '\u0421\u0435\u0440\u0438\u044F \u0434\u043D\u0435\u0439'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                card['value'] as String,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
              const SizedBox(height: 4),
              Text(
                card['label'] as String,
                style: const TextStyle(fontSize: 10, color: AppColors.dimForeground),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodChart() {
    const days = ['\u041F\u043D', '\u0412\u0442', '\u0421\u0440', '\u0427\u0442', '\u041F\u0442', '\u0421\u0431', '\u0412\u0441'];
    const values = [4.2, 4.8, 3.5, 4.0, 5.0, 2.8, 4.5];

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
            '\u0413\u0440\u0430\u0444\u0438\u043A \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F \u0437\u0430 \u043D\u0435\u0434\u0435\u043B\u044E',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(days.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 110 * (values[index] / 5),
                          decoration: BoxDecoration(
                            color: _getMoodBarColor(values[index]),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, color: AppColors.dimForeground),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution() {
    const distributions = [
      _DistributionData(emoji: '\u{1F604}', label: '\u041E\u0442\u043B\u0438\u0447\u043D\u043E', count: 9, percent: 30, color: AppColors.moodExcellent),
      _DistributionData(emoji: '\u{1F642}', label: '\u0425\u043E\u0440\u043E\u0448\u043E', count: 12, percent: 40, color: AppColors.moodGood),
      _DistributionData(emoji: '\u{1F610}', label: '\u041D\u043E\u0440\u043C\u0430\u043B\u044C\u043D\u043E', count: 6, percent: 20, color: AppColors.citrusOrange),
      _DistributionData(emoji: '\u{1F61F}', label: '\u0422\u0440\u0435\u0432\u043E\u0436\u043D\u043E', count: 3, percent: 10, color: AppColors.moodVeryBad),
    ];

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
            '\u0420\u0430\u0441\u043F\u0440\u0435\u0434\u0435\u043B\u0435\u043D\u0438\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          const SizedBox(height: 16),
          ...distributions.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(d.label, style: const TextStyle(fontSize: 12, color: AppColors.foreground, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('${d.count} (${d.percent}%)', style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: d.percent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: d.color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    const insights = [
      _InsightData(icon: '\u{1F31F}', text: '\u0412\u0430\u0448\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435 \u043B\u0443\u0447\u0448\u0435 \u0432\u0441\u0435\u0433\u043E \u0432 \u0441\u0435\u0440\u0435\u0434\u0438\u043D\u0435 \u043D\u0435\u0434\u0435\u043B\u0438. \u041F\u043B\u0430\u043D\u0438\u0440\u0443\u0439\u0442\u0435 \u0441\u043B\u043E\u0436\u043D\u044B\u0435 \u0437\u0430\u0434\u0430\u0447\u0438 \u043D\u0430 \u0432\u0442\u043E\u0440\u043D\u0438\u043A-\u0441\u0440\u0435\u0434\u0443.'),
      _InsightData(icon: '\u{1F4A4}', text: '\u0414\u043D\u0438 \u0441 \u0445\u043E\u0440\u043E\u0448\u0438\u043C \u0441\u043D\u043E\u043C \u043D\u0430 40% \u0447\u0430\u0449\u0435 \u0438\u043C\u0435\u044E\u0442 \u043F\u043E\u043B\u043E\u0436\u0438\u0442\u0435\u043B\u044C\u043D\u043E\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435.'),
      _InsightData(icon: '\u{1F3C3}', text: '\u041F\u043E\u0441\u043B\u0435 \u0434\u043D\u0435\u0439 \u0441 \u0444\u0438\u0437\u0438\u0447\u0435\u0441\u043A\u043E\u0439 \u0430\u043A\u0442\u0438\u0432\u043D\u043E\u0441\u0442\u044C\u044E \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435 \u0443\u043B\u0443\u0447\u0448\u0430\u0435\u0442\u0441\u044F \u043D\u0430 25%.'),
      _InsightData(icon: '\u{1F9D8}', text: '\u0420\u0435\u0433\u0443\u043B\u044F\u0440\u043D\u044B\u0435 \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F \u043D\u0430 \u0434\u044B\u0445\u0430\u043D\u0438\u0435 \u0441\u043D\u0438\u0436\u0430\u044E\u0442 \u0442\u0440\u0435\u0432\u043E\u0436\u043D\u043E\u0441\u0442\u044C \u043D\u0430 30%.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\u0418\u043D\u0441\u0430\u0439\u0442\u044B',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 140, 66, 0.08),
                Color.fromRGBO(255, 173, 31, 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.citrusOrange.withOpacity(0.1)),
          ),
          child: Column(
            children: insights.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      i.text,
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    final activities = [
      _ActivityData(label: '\u0417\u0430\u043F\u0438\u0441\u0438', value: 24, color: AppColors.citrusOrange),
      _ActivityData(label: '\u0421\u043E\u043E\u0431\u0449\u0435\u043D\u0438\u044F', value: 18, color: AppColors.citrusAmber),
      _ActivityData(label: '\u0423\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F', value: 12, color: AppColors.moodGood),
      _ActivityData(label: '\u0422\u0435\u0441\u0442\u044B', value: 5, color: AppColors.moodVeryBad),
    ];

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
            '\u0410\u043A\u0442\u0438\u0432\u043D\u043E\u0441\u0442\u044C',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          const SizedBox(height: 16),
          ...activities.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(a.label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(a.value.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (a.value / 30).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: a.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildExportButton(icon: Icons.picture_as_pdf, label: 'PDF'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildExportButton(icon: Icons.table_chart, label: 'CSV'),
        ),
      ],
    );
  }

  Widget _buildExportButton({required IconData icon, required String label}) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u042D\u043A\u0441\u043F\u043E\u0440\u0442 \u0437\u0430\u0432\u0435\u0440\u0448\u0451\u043D'),
            backgroundColor: AppColors.surface1,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.citrusOrange, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
          ],
        ),
      ),
    );
  }
}

class _DistributionData {
  final String emoji;
  final String label;
  final int count;
  final int percent;
  final Color color;

  const _DistributionData({required this.emoji, required this.label, required this.count, required this.percent, required this.color});
}

class _InsightData {
  final String icon;
  final String text;

  const _InsightData({required this.icon, required this.text});
}

class _ActivityData {
  final String label;
  final int value;
  final Color color;

  const _ActivityData({required this.label, required this.value, required this.color});
}
