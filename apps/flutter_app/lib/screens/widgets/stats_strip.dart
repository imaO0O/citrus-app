import 'package:flutter/material.dart';

class StatsStrip extends StatelessWidget {
  final int streakDays;
  final String goodDaysPercent;
  final String sleepHours;

  const StatsStrip({
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
        iconColor: const Color(0xFFFF8C42),
        value: '$streakDays',
        label: 'Дней подряд',
      ),
      _StatCard(
        icon: Icons.trending_up,
        iconColor: const Color(0xFF8BC34A),
        value: goodDaysPercent,
        label: 'Хороших дней',
      ),
      _StatCard(
        icon: Icons.nightlight_round,
        iconColor: const Color(0xFF7C83D1),
        value: sleepHours,
        label: 'Сон вчера',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: stats
            .map((s) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 140, 66, 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEDE8E0),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A8298),
            ),
          ),
        ],
      ),
    );
  }
}
