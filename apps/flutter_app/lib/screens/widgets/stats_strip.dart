import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/widgets/citrus_card.dart';

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
    return CitrusCard(
      accent: iconColor,
      radius: 16,
      padding: AppSize.padding(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSize.s(30),
            height: AppSize.s(30),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: AppSize.radius(9),
            ),
            child: Icon(icon, size: AppSize.s(17), color: iconColor),
          ),
          AppSize.gapH(8),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSize.s(19),
              fontWeight: FontWeight.w800,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
