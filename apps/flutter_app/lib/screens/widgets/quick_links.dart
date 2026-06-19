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
      _QuickLinkItem(
        icon: '🌬️',
        label: 'Дыхание',
        onTap: onExerciseTap ?? () {},
      ),
      _QuickLinkItem(
        icon: '🤖',
        label: 'ИИ Чат',
        onTap: onChatTap ?? () {},
      ),
      _QuickLinkItem(
        icon: '📝',
        label: 'Дневник',
        onTap: onDiaryTap ?? () {},
      ),
      _QuickLinkItem(
        icon: '🌙',
        label: 'Сон',
        onTap: onSleepTap ?? () {},
      ),
      _QuickLinkItem(
        icon: '🧪',
        label: 'Тесты',
        onTap: onTestsTap ?? () {},
      ),
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
  final VoidCallback onTap;

  _QuickLinkItem({
    required this.icon,
    required this.label,
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
          border: Border.all(
            color: AppColors.foreground.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: AppSize.s(22))),
            AppSize.gapH(6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSize.s(10),
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
