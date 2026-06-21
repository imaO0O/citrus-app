import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/app_size.dart';

enum CitrusButtonVariant { primary, secondary }

/// Единая кнопка приложения: одинаковые высота, радиус, шрифт и состояния.
class CitrusButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CitrusButtonVariant variant;

  /// Акцентный цвет. Если null и primary — фирменный градиент.
  final Color? color;
  final bool expand;
  final bool loading;

  const CitrusButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = CitrusButtonVariant.primary,
    this.color,
    this.expand = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.citrusOrange;
    final primary = variant == CitrusButtonVariant.primary;
    final useGradient = primary && color == null;
    final fg = primary ? Colors.white : c;

    final content = loading
        ? SizedBox(
            width: AppSize.s(20),
            height: AppSize.s(20),
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(fg)),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: AppSize.s(18), color: fg), AppSize.gapW(8)],
              Text(label, style: TextStyle(fontSize: AppSize.s(15), fontWeight: FontWeight.w700, color: fg)),
            ],
          );

    final box = Container(
      height: AppSize.s(52),
      width: expand ? double.infinity : null,
      alignment: Alignment.center,
      padding: expand ? null : AppSize.paddingH(22, 0),
      decoration: BoxDecoration(
        color: useGradient ? null : (primary ? c : Colors.transparent),
        gradient: useGradient
            ? LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.citrusOrange, AppColors.citrusAmber])
            : null,
        borderRadius: AppSize.radius(14),
        border: primary ? null : Border.all(color: c.withValues(alpha: 0.5), width: 1.5),
        boxShadow: primary ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))] : null,
      ),
      child: content,
    );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: (onPressed == null || loading) ? null : onPressed,
        behavior: HitTestBehavior.opaque,
        child: box,
      ),
    );
  }
}
