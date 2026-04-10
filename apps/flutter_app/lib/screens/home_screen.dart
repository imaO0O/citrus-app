import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

// ─── Mood Data ────────────────────────────────────────────────────────────────────
class _MoodData {
  final int id;
  final String label;
  final Color color;
  final Color glow;
  final String emoji;

  const _MoodData({
    required this.id,
    required this.label,
    required this.color,
    required this.glow,
    required this.emoji,
  });
}

const moods = [
  _MoodData(id: 0, label: 'Отлично',     color: AppColors.moodExcellent, glow: Color(0x738BC34A),  emoji: '\u{1F604}'),
  _MoodData(id: 1, label: 'Хорошо',      color: AppColors.moodGood,      glow: Color(0x73FFD93D),  emoji: '\u{1F642}'),
  _MoodData(id: 2, label: 'Нормально',   color: AppColors.moodOkay,      glow: Color(0x73FF8C42),  emoji: '\u{1F610}'),
  _MoodData(id: 3, label: 'Тревожно',    color: AppColors.moodAnxious,   glow: Color(0x73FFA726),  emoji: '\u{1F61F}'),
  _MoodData(id: 4, label: 'Плохо',       color: AppColors.moodBad,       glow: Color(0x73FF5B5B),  emoji: '\u{1F622}'),
  _MoodData(id: 5, label: 'Очень плохо', color: AppColors.moodVeryBad,   glow: Color(0x73E63946),  emoji: '\u{1F61E}'),
];

// ─── Citrus Wheel geometry ───────────────────────────────────────────────────────
const double _cx = 140, _cy = 140;
const double _rOuter = 118;   // outer radius of colored segments
const double _rInner = 42;    // inner radius (center hole)
const double _rRindOuter = 132; // outer decorative ring
const double _gapDeg = 7.0;   // gap between segments in degrees

double _toRad(double d) => d * math.pi / 180;

/// Build a wedge path for segment `i` (0..5), going from angle -90°+i*60 to -90°+(i+1)*60
Path _segmentPath(int i) {
  final halfGap = _toRad(_gapDeg / 2);
  final startAngle = _toRad(-90 + i * 60) + halfGap;
  final endAngle = _toRad(-90 + (i + 1) * 60) - halfGap;
  final path = Path();
  // Start at inner radius, start angle
  path.moveTo(_cx + _rInner * math.cos(startAngle), _cy + _rInner * math.sin(startAngle));
  // Line to outer radius, start angle
  path.lineTo(_cx + _rOuter * math.cos(startAngle), _cy + _rOuter * math.sin(startAngle));
  // Arc along outer radius
  path.arcTo(
    Rect.fromCircle(center: Offset(_cx, _cy), radius: _rOuter),
    startAngle,
    endAngle - startAngle,
    false,
  );
  // Line back to inner radius, end angle
  path.lineTo(_cx + _rInner * math.cos(endAngle), _cy + _rInner * math.sin(endAngle));
  // Arc along inner radius (backwards)
  path.arcTo(
    Rect.fromCircle(center: Offset(_cx, _cy), radius: _rInner),
    endAngle,
    -(endAngle - startAngle),
    false,
  );
  path.close();
  return path;
}

/// Build outer ring (peel) segment for segment `i`
Path _rindPath(int i) {
  final halfGap = _toRad(_gapDeg / 2);
  final startAngle = _toRad(-90 + i * 60) + halfGap;
  final endAngle = _toRad(-90 + (i + 1) * 60) - halfGap;
  final path = Path();
  path.moveTo(_cx + _rOuter * math.cos(startAngle), _cy + _rOuter * math.sin(startAngle));
  path.lineTo(_cx + _rRindOuter * math.cos(startAngle), _cy + _rRindOuter * math.sin(startAngle));
  path.arcTo(
    Rect.fromCircle(center: Offset(_cx, _cy), radius: _rRindOuter),
    startAngle,
    endAngle - startAngle,
    false,
  );
  path.lineTo(_cx + _rOuter * math.cos(endAngle), _cy + _rOuter * math.sin(endAngle));
  path.arcTo(
    Rect.fromCircle(center: Offset(_cx, _cy), radius: _rOuter),
    endAngle,
    -(endAngle - startAngle),
    false,
  );
  path.close();
  return path;
}

/// Middle angle of segment i (for emoji placement)
double _midAngle(int i) {
  final halfGap = _toRad(_gapDeg / 2);
  final a1 = _toRad(-90 + i * 60) + halfGap;
  final a2 = _toRad(-90 + (i + 1) * 60) - halfGap;
  return (a1 + a2) / 2;
}

/// Membrane lines inside segment i
List<(double, double, double, double)> _membraneLines(int i) {
  final halfGap = _toRad(_gapDeg / 2);
  final a1 = _toRad(-90 + i * 60) + halfGap;
  final a2 = _toRad(-90 + (i + 1) * 60) - halfGap;
  final lines = <(double, double, double, double)>[];
  for (int j = 1; j <= 2; j++) {
    final a = a1 + (a2 - a1) * (j / 3);
    lines.add((
      _cx + (_rInner + 10) * math.cos(a),
      _cy + (_rInner + 10) * math.sin(a),
      _cx + (_rOuter - 18) * math.cos(a),
      _cy + (_rOuter - 18) * math.sin(a),
    ));
  }
  return lines;
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToExercises;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToDiary;
  final VoidCallback? onNavigateToSleep;

  const HomeScreen({
    super.key,
    this.onNavigateToExercises,
    this.onNavigateToChat,
    this.onNavigateToDiary,
    this.onNavigateToSleep,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int? _selected;
  final List<Map<String, dynamic>> _todayLog = [];
  bool _showFeedback = false;
  final int streak = 7;
  late final AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleSelect(int id) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _selected = id;
      _todayLog.add({'time': time, 'id': id});
      _showFeedback = true;
    });
    _feedbackController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _feedbackController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _showFeedback = false);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _selected = null);
        });
      });
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 8),
              _buildCitrusWheel(),
              const SizedBox(height: 12),
              _buildSelectedLabel(),
              const SizedBox(height: 8),
              _buildStatsStrip(),
              const SizedBox(height: 16),
              _buildQuickLinks(),
              if (_todayLog.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildTodaysMoodLog(),
              ],
              const SizedBox(height: 16),
              _buildDailyQuote(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getFormattedDate(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Как твоё состояние?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Нажми на дольку цитруса, чтобы отметить настроение',
            style: TextStyle(fontSize: 12, color: AppColors.dimForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildCitrusWheel() {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_showFeedback && _selected != null)
            Positioned(
              top: 0,
              child: AnimatedBuilder(
                animation: _feedbackController,
                builder: (context, child) {
                  final t = _feedbackController.value;
                  return Transform.translate(
                    offset: Offset(0, 10 * (1 - t)),
                    child: Opacity(
                      opacity: t,
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * t,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _buildFeedbackBadge(),
              ),
            ),
          GestureDetector(
            onTapUp: (details) {
              final pos = details.localPosition;
              final segment = _hitTestSegment(pos);
              if (segment != null) {
                _handleSelect(segment);
              }
            },
            child: CustomPaint(
              size: const Size(280, 280),
              painter: CitrusWheelPainter(selectedId: _selected),
            ),
          ),
        ],
      ),
    );
  }

  int? _hitTestSegment(Offset position) {
    final dx = position.dx - _cx;
    final dy = position.dy - _cy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist < _rInner || dist > _rRindOuter) return null;

    double angle = math.atan2(dy, dx) * 180 / math.pi + 90;
    if (angle < 0) angle += 360;

    final segIndex = (angle / 60).floor() % 6;
    final segStart = segIndex * 60 + _gapDeg / 2;
    final segEnd = (segIndex + 1) * 60 - _gapDeg / 2;

    if (angle >= segStart && angle < segEnd) return segIndex;
    return null;
  }

  Widget _buildFeedbackBadge() {
    final mood = moods.firstWhere((m) => m.id == _selected);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: mood.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mood.glow,
            blurRadius: 32,
          ),
        ],
      ),
      child: Text(
        '${mood.emoji} ${mood.label}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0C0C14),
        ),
      ),
    );
  }

  Widget _buildSelectedLabel() {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _selected != null
            ? Container(
                key: ValueKey('hs_selected'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${moods.firstWhere((m) => m.id == _selected).emoji} ${moods.firstWhere((m) => m.id == _selected).label} — записано',
                  style: TextStyle(
                    fontSize: 11,
                    color: moods.firstWhere((m) => m.id == _selected).color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Container(
                key: const ValueKey('hs_hint'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: const Text(
                  '6 уровней настроения · нажми на дольку',
                  style: TextStyle(fontSize: 11, color: AppColors.dimForeground),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsStrip() {
    final stats = [
      {'icon': '🔥', 'value': '$streak', 'label': 'Дней подряд'},
      {'icon': '📈', 'value': '85%', 'label': 'Хороших дней'},
      {'icon': '🌙', 'value': '7.2ч', 'label': 'Сон вчера'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: stats.map((s) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.citrusOrange.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['icon'] as String, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  s['value'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['label'] as String,
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickLinks() {
    final quickLinks = [
      {'label': 'Дыхание', 'icon': '🌬️', 'onTap': widget.onNavigateToExercises},
      {'label': 'ИИ Чат', 'icon': '🤖', 'onTap': widget.onNavigateToChat},
      {'label': 'Дневник', 'icon': '📝', 'onTap': widget.onNavigateToDiary},
      {'label': 'Сон', 'icon': '🌙', 'onTap': widget.onNavigateToSleep},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.75,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: quickLinks.map((link) {
          return GestureDetector(
            onTap: link['onTap'] as VoidCallback?,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(link['icon'] as String, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    link['label'] as String,
                    style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTodaysMoodLog() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сегодня',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          ..._todayLog.reversed.take(4).map((entry) {
            final mood = moods.firstWhere((m) => m.id == entry['id']);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mood.label,
                      style: const TextStyle(
                        fontSize: 14,
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
                        BoxShadow(color: mood.glow, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry['time'] as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.dimForeground),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDailyQuote() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(255, 140, 66, 0.12),
            Color.fromRGBO(255, 173, 31, 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.citrusOrange.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '«Каждый день — это новая возможность стать лучше. Ты справишься!»',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.warmText,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Аффирмация дня',
                  style: TextStyle(fontSize: 11, color: AppColors.dimForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Painter: Citrus Wheel ────────────────────────────────────────────────
class CitrusWheelPainter extends CustomPainter {
  final int? selectedId;

  CitrusWheelPainter({required this.selectedId});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(_cx, _cy);

    // 1. Draw outer decorative ring (segmented, each piece colored)
    for (int i = 0; i < 6; i++) {
      final mood = moods[i];
      canvas.drawPath(_rindPath(i), Paint()
        ..color = mood.color.withOpacity(0.2)
        ..style = PaintingStyle.fill);
    }

    // 2. Draw main segments
    for (int i = 0; i < 6; i++) {
      final mood = moods[i];
      final isSelected = selectedId == mood.id;

      // Selected glow (behind segment)
      if (isSelected) {
        canvas.drawPath(_segmentPath(i), Paint()
          ..color = mood.color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..style = PaintingStyle.fill);
      }

      // Segment fill with radial gradient
      final gradPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.8,
          colors: [
            mood.color.withOpacity(0.95),
            mood.color.withOpacity(0.65),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: _rOuter))
        ..style = PaintingStyle.fill;
      canvas.drawPath(_segmentPath(i), gradPaint);

      // Subtle border on segment edges
      canvas.drawPath(_segmentPath(i), Paint()
        ..color = isSelected ? mood.color : Colors.black.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2 : 0.8);

      // Membrane lines (veins)
      final veins = _membraneLines(i);
      for (final (x1, y1, x2, y2) in veins) {
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          Paint()
            ..color = Colors.white.withOpacity(0.15)
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round,
        );
      }

      // Emoji label — draw dark outline faces
      final mid = _midAngle(i);
      final emojiR = (_rInner + _rOuter) / 2;
      final ex = _cx + emojiR * math.cos(mid);
      final ey = _cy + emojiR * math.sin(mid);
      _drawFace(canvas, Offset(ex, ey), i);
    }

    // 3. Center circle
    // Outer dark ring
    canvas.drawCircle(
      center,
      _rInner + 2,
      Paint()..color = const Color(0xFF1A1A2A)..style = PaintingStyle.fill,
    );
    // Inner background
    canvas.drawCircle(
      center,
      _rInner - 1,
      Paint()..color = AppColors.background..style = PaintingStyle.fill,
    );
    // Subtle ring border
    canvas.drawCircle(
      center,
      _rInner - 1,
      Paint()
        ..color = AppColors.citrusOrange.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Inner glow
    canvas.drawCircle(
      center,
      _rInner - 10,
      Paint()
        ..color = AppColors.citrusOrange.withOpacity(0.06)
        ..style = PaintingStyle.fill,
    );

    // Center emoji (🍊 or selected mood emoji)
    final centerEmoji = selectedId != null
        ? moods.firstWhere((m) => m.id == selectedId).emoji
        : '🍊';
    final centerText = TextPainter(
      text: TextSpan(text: centerEmoji, style: const TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    );
    centerText.layout();
    centerText.paint(
      canvas,
      Offset(_cx - centerText.width / 2, _cy - centerText.height / 2),
    );
  }

  /// Draw a simple face icon at [pos] for mood index [i].
  /// Uses dark outline faces matching the reference design.
  void _drawFace(Canvas canvas, Offset pos, int moodIndex) {
    const radius = 10.0;
    const lineW = 1.5;
    final color = const Color(0xFF1A1A2A); // dark color for faces

    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineW
      ..strokeCap = StrokeCap.round;

    // Face circle
    canvas.drawCircle(pos, radius, basePaint);

    switch (moodIndex) {
      case 0: // 😄 Excellent — big smile, happy eyes
        _eyes(canvas, pos, radius, happy: true);
        _mouth(canvas, pos, radius, type: 0); // big smile
        break;
      case 1: // 🙂 Good — slight smile
        _eyes(canvas, pos, radius, happy: false);
        _mouth(canvas, pos, radius, type: 1); // slight smile
        break;
      case 2: // 😐 Neutral — straight mouth
        _eyes(canvas, pos, radius, happy: false);
        _mouth(canvas, pos, radius, type: 2); // straight
        break;
      case 3: // 😟 Anxious — worried eyebrows, slight frown
        _eyebrows(canvas, pos, radius, worried: true);
        _eyes(canvas, pos, radius, happy: false);
        _mouth(canvas, pos, radius, type: 3); // slight frown
        break;
      case 4: // 😢 Bad — frown, sad eyes
        _eyebrows(canvas, pos, radius, worried: true);
        _eyes(canvas, pos, radius, happy: false);
        _mouth(canvas, pos, radius, type: 4); // frown
        break;
      case 5: // 😞 Very bad — big frown
        _eyebrows(canvas, pos, radius, worried: true);
        _eyes(canvas, pos, radius, happy: false);
        _mouth(canvas, pos, radius, type: 5); // big frown
        break;
    }
  }

  void _eyes(Canvas canvas, Offset pos, double r, {required bool happy}) {
    const eyeY = -2.5;
    const eyeSpread = 4.0;
    if (happy) {
      // Happy curved eyes (∩ ∩)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(pos.dx - eyeSpread, pos.dy + eyeY), radius: 2.5),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF1A1A2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(pos.dx + eyeSpread, pos.dy + eyeY), radius: 2.5),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF1A1A2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Dot eyes
      canvas.drawCircle(Offset(pos.dx - eyeSpread, pos.dy + eyeY), 1.2,
          Paint()..color = const Color(0xFF1A1A2A)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(pos.dx + eyeSpread, pos.dy + eyeY), 1.2,
          Paint()..color = const Color(0xFF1A1A2A)..style = PaintingStyle.fill);
    }
  }

  void _eyebrows(Canvas canvas, Offset pos, double r, {required bool worried}) {
    if (!worried) return;
    const browY = -6.5;
    const browSpread = 4.0;
    final paint = Paint()
      ..color = const Color(0xFF1A1A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    // Left eyebrow angled up on outside
    canvas.drawLine(
      Offset(pos.dx - browSpread - 2, pos.dy + browY - 1),
      Offset(pos.dx - browSpread + 2, pos.dy + browY + 1),
      paint,
    );
    // Right eyebrow angled up on outside
    canvas.drawLine(
      Offset(pos.dx + browSpread - 2, pos.dy + browY + 1),
      Offset(pos.dx + browSpread + 2, pos.dy + browY - 1),
      paint,
    );
  }

  void _mouth(Canvas canvas, Offset pos, double r, {required int type}) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const mouthY = 3.5;
    switch (type) {
      case 0: // Big smile
        canvas.drawArc(
          Rect.fromLTRB(pos.dx - 5, pos.dy + mouthY - 5, pos.dx + 5, pos.dy + mouthY + 3),
          0.1,
          math.pi - 0.2,
          false,
          paint,
        );
        break;
      case 1: // Slight smile
        canvas.drawArc(
          Rect.fromLTRB(pos.dx - 4, pos.dy + mouthY - 3, pos.dx + 4, pos.dy + mouthY + 2),
          0.2,
          math.pi - 0.4,
          false,
          paint,
        );
        break;
      case 2: // Straight
        canvas.drawLine(
          Offset(pos.dx - 4, pos.dy + mouthY),
          Offset(pos.dx + 4, pos.dy + mouthY),
          paint,
        );
        break;
      case 3: // Slight frown
        canvas.drawArc(
          Rect.fromLTRB(pos.dx - 4, pos.dy + mouthY - 1, pos.dx + 4, pos.dy + mouthY + 4),
          math.pi + 0.2,
          math.pi - 0.4,
          false,
          paint,
        );
        break;
      case 4: // Frown
        canvas.drawArc(
          Rect.fromLTRB(pos.dx - 4, pos.dy + mouthY, pos.dx + 4, pos.dy + mouthY + 5),
          math.pi + 0.1,
          math.pi - 0.2,
          false,
          paint,
        );
        break;
      case 5: // Big frown
        canvas.drawArc(
          Rect.fromLTRB(pos.dx - 5, pos.dy + mouthY + 1, pos.dx + 5, pos.dy + mouthY + 6),
          math.pi + 0.05,
          math.pi - 0.1,
          false,
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CitrusWheelPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId;
  }
}
