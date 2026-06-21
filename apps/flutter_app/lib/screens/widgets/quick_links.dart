import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';

class QuickLinks extends StatelessWidget {
  final VoidCallback? onExerciseTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onDiaryTap;
  final VoidCallback? onSleepTap;
  final VoidCallback? onTestsTap;

  QuickLinks({
    super.key,
    this.onExerciseTap,
    this.onChatTap,
    this.onDiaryTap,
    this.onSleepTap,
    this.onTestsTap,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      _QuickLinkItem(icon: '🌬️', label: 'Дыхание', color: AppColors.citrusGreen, onTap: onExerciseTap ?? () {}),
      _QuickLinkItem(icon: '🤖', label: 'ИИ Чат', color: AppColors.citrusPurple, onTap: onChatTap ?? () {}),
      _QuickLinkItem(icon: '📝', label: 'Дневник', color: AppColors.citrusOrange, onTap: onDiaryTap ?? () {}),
      _QuickLinkItem(icon: '🌙', label: 'Сон', color: const Color(0xFF5C6BC0), onTap: onSleepTap ?? () {}),
      _QuickLinkItem(icon: '🧪', label: 'Тесты', color: const Color(0xFF4A90D9), onTap: onTestsTap ?? () {}),
    ];

    return Padding(
      padding: AppSize.paddingH(20, 0),
      child: Row(
        children: links
            .map((link) => Expanded(
                  child: Padding(
                    padding: AppSize.paddingH(4, 0),
                    child: link,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _QuickLinkItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickLinkItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSize.paddingH(0, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSize.radius(16),
          border: Border.all(color: AppColors.foreground.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSize.s(40),
              height: AppSize.s(40),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: AppSize.radius(13),
              ),
              child: Center(child: Text(icon, style: TextStyle(fontSize: AppSize.s(20)))),
            ),
            AppSize.gapH(7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSize.s(10),
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
