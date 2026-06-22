import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/app_size.dart';

/// Премиальный линейный график с градиентной заливкой под кривой —
/// как в финтех-дэшбордах (Copilot, Mercury). Сглаженная линия, мягкая
/// заливка, точка на последнем значении. null в values = пропуск (разрыв).
class CitrusLineChart extends StatelessWidget {
  final List<double?> values;
  final double minY;
  final double maxY;
  final Color color;
  final double height;
  final List<String>? labels;

  const CitrusLineChart({
    super.key,
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
    this.height = 150,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LineChartPainter(
              values: values,
              minY: minY,
              maxY: maxY,
              color: color,
              gridColor: AppColors.subtleBorder,
            ),
          ),
        ),
        if (labels != null && labels!.isNotEmpty) ...[
          AppSize.gapH(8),
          Row(
            children: labels!
                .map((l) => Expanded(
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: AppText.label,
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double?> values;
  final double minY;
  final double maxY;
  final Color color;
  final Color gridColor;

  _LineChartPainter({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final span = (maxY - minY).abs() < 1e-9 ? 1.0 : (maxY - minY);
    final n = values.length;
    final dx = n <= 1 ? 0.0 : w / (n - 1);

    // Базовая горизонтальная линия
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h - 1), Offset(w, h - 1), gridPaint);

    // Собираем экранные точки (пропуская null)
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) continue;
      final t = ((v - minY) / span).clamp(0.0, 1.0);
      final x = n == 1 ? w / 2 : i * dx;
      final y = h - t * (h - 6) - 3; // небольшие поля сверху/снизу
      pts.add(Offset(x, y));
    }
    if (pts.isEmpty) return;

    // Сглаженная линия (квадратичные кривые через середины сегментов)
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) {
      linePath.lineTo(pts.first.dx, pts.first.dy);
    } else {
      for (var i = 0; i < pts.length - 1; i++) {
        final p0 = pts[i];
        final p1 = pts[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        linePath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      linePath.lineTo(pts.last.dx, pts.last.dy);
    }

    // Градиентная заливка под кривой
    final fillPath = Path.from(linePath)
      ..lineTo(pts.last.dx, h)
      ..lineTo(pts.first.dx, h)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Линия
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Точка на последнем значении
    final last = pts.last;
    canvas.drawCircle(last, 5, Paint()..color = color);
    canvas.drawCircle(last, 5, Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values || old.color != color || old.minY != minY || old.maxY != maxY;
}
