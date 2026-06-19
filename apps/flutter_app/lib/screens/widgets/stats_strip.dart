import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';

class StatsStrip extends StatelessWidget {
  final int streakDays;
  final String goodDaysPercent;
  final String sleepHours;

  StatsStrip({
    super.key,
    this.streakDays = 7,
    this.goodDaysPercent = '85%',
    this.sleepHours = '7.2ч',
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatCard(
        icon: Icons.local_fire_department,
        iconColor: Color(0xFFFF8C42),
        value: '$streakDays',
        label: 'Дней подряд',
      ),
      _StatCard(
        icon: Icons.trending_up,
        iconColor: Color(0xFF8BC34A),
        value: goodDaysPercent,
        label: 'Хороших дней',
      ),
      _StatCard(
        icon: Icons.nightlight_round,
        iconColor: Color(0xFF7C83D1),
        value: sleepHours,
        label: 'Сон вчера',
      ),
    ];

    return Padding(
      padding: AppSize.paddingH(20, 0),
      child: Row(
        children: stats
            .map((s) => Expanded(
                  child: Padding(
                    padding: AppSize.paddingH(4, 0),
                    child: s,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.padding(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSize.radius(16),
        border: Border.all(
          color: AppColors.citrusOrange.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          AppSize.gapH(4),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSize.s(18),
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          AppSize.gapH(2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSize.s(10),
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
