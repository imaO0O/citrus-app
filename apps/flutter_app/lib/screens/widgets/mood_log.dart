import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../../core/theme/app_colors.dart';

class MoodLog extends StatelessWidget {
  final List<MoodLogEntry> entries;

  const MoodLog({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сегодня',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map(_buildEntry),
        ],
      ),
    );
  }

  Widget _buildEntry(MoodLogEntry entry) {
    final mood = Mood.all.firstWhere((m) => m.id == entry.moodId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.foreground.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mood.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: mood.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: mood.glow,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('HH:mm').format(entry.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.dimForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
