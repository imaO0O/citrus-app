import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';

class MoodLog extends StatelessWidget {
  final List<MoodLogEntry> entries;

  MoodLog({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: AppSize.paddingH(20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сегодня',
            style: TextStyle(
              fontSize: AppSize.s(16),
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          AppSize.gapH(8),
          ...entries.map(_buildEntry),
        ],
      ),
    );
  }

  Widget _buildEntry(MoodLogEntry entry) {
    final mood = Mood.all.firstWhere((m) => m.id == entry.moodId);

    return Padding(
      key: ValueKey(entry.entryKey),
      padding: AppSize.paddingOnly(bottom: 8),
      child: Container(
        padding: AppSize.paddingH(16, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSize.radius(16),
          border: Border.all(
            color: AppColors.foreground.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Text(mood.emoji, style: TextStyle(fontSize: AppSize.s(20))),
            AppSize.gapW(12),
            Expanded(
              child: Text(
                mood.label,
                style: TextStyle(
                  fontSize: AppSize.s(14),
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
            AppSize.gapW(8),
            Text(
              DateFormat('HH:mm').format(entry.timestamp),
              style: TextStyle(
                fontSize: AppSize.s(12),
                color: AppColors.dimForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
