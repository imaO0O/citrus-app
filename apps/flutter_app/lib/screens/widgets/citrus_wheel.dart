import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood.dart';

class CitrusWheel extends StatefulWidget {
  final int? selectedMoodId;
  final ValueChanged<int> onMoodSelected;

  const CitrusWheel({
    super.key,
    required this.selectedMoodId,
    required this.onMoodSelected,
  });

  @override
  State<CitrusWheel> createState() => _CitrusWheelState();
}

class _CitrusWheelState extends State<CitrusWheel>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = -1;

  static const double _cx = 140;
  static const double _cy = 140;
  static const double _rSeg = 118;
  static const double _rInner = 42;
  static const double _gapDeg = 3.5;

  double _toRad(double deg) => deg * math.pi / 180;

  Path _segPath(int i) {
    final gap = _toRad(_gapDeg / 2);
    final a1 = _toRad(-90 + i * 60) + gap;
    final a2 = _toRad(-90 + (i + 1) * 60) - gap;

    final ix1 = _cx + _rInner * math.cos(a1);
    final iy1 = _cy + _rInner * math.sin(a1);
    final ox1 = _cx + _rSeg * math.cos(a1);
    final oy1 = _cy + _rSeg * math.sin(a1);
    final ox2 = _cx + _rSeg * math.cos(a2);
    final oy2 = _cy + _rSeg * math.sin(a2);
    final ix2 = _cx + _rInner * math.cos(a2);
    final iy2 = _cy + _rInner * math.sin(a2);

    final path = Path()..moveTo(ix1, iy1);
    path.lineTo(ox1, oy1);
    path.arcToPoint(
      Offset(ox2, oy2),
      radius: Radius.circular(_rSeg),
      clockwise: true,
    );
    path.lineTo(ix2, iy2);
    path.arcToPoint(
      Offset(ix1, iy1),
      radius: Radius.circular(_rInner),
      clockwise: false,
    );
    path.close();
    return path;
  }

  List<Map<String, double>> _membraneLines(int i) {
    final gap = _toRad(_gapDeg / 2);
    final a1 = _toRad(-90 + i * 60) + gap;
    final a2 = _toRad(-90 + (i + 1) * 60) - gap;
    final lines = <Map<String, double>>[];

    for (int j = 1; j <= 2; j++) {
      final a = a1 + (a2 - a1) * (j / 3);
      lines.add({
        'x1': _cx + (_rInner + 6) * math.cos(a),
        'y1': _cy + (_rInner + 6) * math.sin(a),
        'x2': _cx + (_rSeg - 14) * math.cos(a),
        'y2': _cy + (_rSeg - 14) * math.sin(a),
      });
    }
    return lines;
  }

  Offset _labelPos(int i) {
    final gap = _toRad(_gapDeg / 2);
    final a1 = _toRad(-90 + i * 60) + gap;
    final a2 = _toRad(-90 + (i + 1) * 60) - gap;
    final mid = (a1 + a2) / 2;
    final r = (_rInner + _rSeg) / 2;
    return Offset(_cx + r * math.cos(mid), _cy + r * math.sin(mid));
  }

  void _handleTapOnSegment(int index) {
    setState(() => _selectedIndex = index);
    widget.onMoodSelected(Mood.all[index].id);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _selectedIndex = -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedMood = widget.selectedMoodId != null
        ? Mood.all.firstWhere((m) => m.id == widget.selectedMoodId)
        : null;

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(280, 280),
            painter: _CitrusPainter(
              moods: Mood.all,
              selectedIndex: _selectedIndex,
              selectedId: widget.selectedMoodId,
              segPath: _segPath,
              membraneLines: _membraneLines,
            ),
          ),
          // Emoji labels
          ...Mood.all.asMap().entries.map((entry) {
            final i = entry.key;
            final mood = entry.value;
            final pos = _labelPos(i);
            final isSelected = _selectedIndex == i;

            return Positioned(
              left: pos.dx - 14,
              top: pos.dy - 14,
              child: GestureDetector(
                onTap: () => _handleTapOnSegment(i),
                child: AnimatedScale(
                  scale: isSelected ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            );
          }),
          // Feedback popup
          if (selectedMood != null && _selectedIndex >= 0)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selectedMood.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: selectedMood.glow,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${selectedMood.emoji} ${selectedMood.label}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0C0C14),
                    ),
                  ),
                ),
              ),
            ),
          // Center circle
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0C0C14),
                border: Border.all(
                  color: const Color.fromRGBO(255, 140, 66, 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(255, 140, 66, 0.08),
                  ),
                  child: Center(
                    child: Text(
                      selectedMood?.emoji ?? '🍊',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitrusPainter extends CustomPainter {
  final List<Mood> moods;
  final int selectedIndex;
  final int? selectedId;
  final Path Function(int) segPath;
  final List<Map<String, double>> Function(int) membraneLines;

  _CitrusPainter({
    required this.moods,
    required this.selectedIndex,
    required this.selectedId,
    required this.segPath,
    required this.membraneLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = 140.0;
    final cy = 140.0;

    // Outer rind ring
    canvas.drawCircle(
      Offset(cx, cy),
      132,
      Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (int i = 0; i < moods.length; i++) {
      final mood = moods[i];
      final isSelected = selectedIndex == i;
      final path = segPath(i);

      final gap = _toRad(3.5 / 2);
      final a1 = _toRad(-90 + i * 60) + gap;
      final a2 = _toRad(-90 + (i + 1) * 60) - gap;

      final peelPath = Path()
        ..moveTo(cx + 126 * math.cos(a1), cy + 126 * math.sin(a1))
        ..lineTo(cx + 132 * math.cos(a1), cy + 132 * math.sin(a1))
        ..arcToPoint(
          Offset(cx + 132 * math.cos(a2), cy + 132 * math.sin(a2)),
          radius: const Radius.circular(132),
          clockwise: true,
        )
        ..lineTo(cx + 126 * math.cos(a2), cy + 126 * math.sin(a2))
        ..arcToPoint(
          Offset(cx + 126 * math.cos(a1), cy + 126 * math.sin(a1)),
          radius: const Radius.circular(126),
          clockwise: false,
        )
        ..close();

      canvas.drawPath(
        peelPath,
        Paint()..color = mood.color.withOpacity(0.25),
      );

      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: 118);
      final shader = RadialGradient(
        colors: [mood.color.withOpacity(0.95), mood.color.withOpacity(0.7)],
      ).createShader(rect);
      canvas.drawPath(path, Paint()..shader = shader);

      if (isSelected) {
        canvas.drawPath(
          path,
          Paint()
            ..color = mood.color.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = isSelected ? mood.color : Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.5 : 0.5,
      );

      for (final line in membraneLines(i)) {
        canvas.drawLine(
          Offset(line['x1']!, line['y1']!),
          Offset(line['x2']!, line['y2']!),
          Paint()
            ..color = const Color.fromRGBO(255, 255, 255, 0.18)
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  double _toRad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(covariant _CitrusPainter oldDelegate) =>
      selectedIndex != oldDelegate.selectedIndex;
}
