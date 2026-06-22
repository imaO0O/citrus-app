import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../utils/app_size.dart';

/// Премиальная карточка-действие: мягкий градиентный верх с заголовком и
/// сплошной цветной «подвал» с CTA (паттерн Yotta «Manage →» / «Get More →»).
class CitrusActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final Color color;
  final VoidCallback onTap;

  const CitrusActionCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppSize.radius(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppSize.radius(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Градиентный верх
            Container(
              padding: AppSize.padding(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
                ),
              ),
              child: Row(children: [
                Text(emoji, style: TextStyle(fontSize: AppSize.s(34))),
                AppSize.gapW(14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: AppText.cardTitle),
                    AppSize.gapH(3),
                    Text(subtitle, style: AppText.caption.copyWith(height: 1.3)),
                  ]),
                ),
              ]),
            ),
            // Сплошной цветной «подвал» с CTA
            Material(
              color: color,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: AppSize.paddingH(16, 12),
                  child: Row(children: [
                    Text(ctaLabel, style: TextStyle(color: Colors.white, fontSize: AppSize.s(13), fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: AppSize.s(18)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
