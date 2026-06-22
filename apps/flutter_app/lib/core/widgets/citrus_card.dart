import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/app_size.dart';

/// Единый компонент карточки: одинаковые радиус, мягкая тень, паддинг и рамка.
/// Цель — консистентный «премиальный» вид по всему приложению.
class CitrusCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Gradient? gradient;

  /// Акцентный цвет рамки (например, цвет категории). Если null — нейтральная рамка.
  final Color? accent;
  final VoidCallback? onTap;
  final double radius;

  /// Включить мягкую тень (по умолчанию да).
  final bool elevated;

  const CitrusCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.gradient,
    this.accent,
    this.onTap,
    this.radius = 18,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? AppSize.padding(16),
      decoration: BoxDecoration(
        color: gradient != null ? null : (color ?? AppColors.card),
        gradient: gradient,
        borderRadius: AppSize.radius(radius),
        border: Border.all(
          color: accent != null
              ? accent!.withValues(alpha: 0.3)
              : AppColors.foreground.withValues(alpha: 0.06),
        ),
        boxShadow: elevated
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}
