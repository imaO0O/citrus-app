import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/app_size.dart';
import '../../core/widgets/citrus_card.dart';

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
          Text('Отметки за сегодня', style: AppText.sectionTitle),
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
      child: CitrusCard(
        radius: 16,
        padding: AppSize.paddingH(16, 12),
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
