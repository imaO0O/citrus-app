import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/app_size.dart';
import 'citrus_button.dart';

/// Брендовое пустое/вступительное состояние: маскот-долька в мягком радиальном
/// свечении + заголовок + подзаголовок + опциональная кнопка действия.
/// Единый узнаваемый вид на всех экранах (инсайты, дерево, студент, курсы).
class CitrusEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? accent;

  const CitrusEmptyState({
    super.key,
    this.emoji = '🍊',
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.citrusOrange;
    return Center(
      child: Padding(
        padding: AppSize.padding(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSize.s(104),
              height: AppSize.s(104),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.03)],
                ),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Center(child: Text(emoji, style: TextStyle(fontSize: AppSize.s(46)))),
            ),
            AppSize.gapH(22),
            Text(title, textAlign: TextAlign.center, style: AppText.sectionTitle),
            AppSize.gapH(8),
            Text(subtitle, textAlign: TextAlign.center, style: AppText.bodyMuted.copyWith(height: 1.45)),
            if (actionLabel != null && onAction != null) ...[
              AppSize.gapH(24),
              CitrusButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                expand: false,
                color: accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
