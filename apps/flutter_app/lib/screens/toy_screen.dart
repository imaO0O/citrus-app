import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ToyScreen extends StatefulWidget {
  const ToyScreen({super.key});

  @override
  State<ToyScreen> createState() => _ToyScreenState();
}

class _ToyScreenState extends State<ToyScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                '\u0410\u043D\u0442\u0438\u0441\u0442\u0440\u0435\u0441\u0441',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: IndexedStack(
                  index: _activeTab,
                  children: const [
                    SqueezeCitrusToy(),
                    BubbleWrapToy(),
                    BreathingExerciseToy(),
                  ],
                ),
              ),
              _buildBottomTabs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTabs() {
    const emojis = ['\u{1F34A}', '\u{1FAE7}', '\u{1F32C}\u{FE0F}'];
    const labels = ['\u0426\u0438\u0442\u0440\u0443\u0441', '\u041F\u0443\u0437\u044B\u0440\u0438', '\u0414\u044B\u0445\u0430\u043D\u0438\u0435'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          final isActive = _activeTab == i;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.citrusOrange.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emojis[i],
                    style: TextStyle(fontSize: 24, color: isActive ? AppColors.citrusOrange : AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? AppColors.citrusOrange : AppColors.dimForeground,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================
// 1. Squish Citrus
// ============================================================
class SqueezeCitrusToy extends StatefulWidget {
  const SqueezeCitrusToy({super.key});

  @override
  State<SqueezeCitrusToy> createState() => _SqueezeCitrusToyState();
}

class _SqueezeCitrusToyState extends State<SqueezeCitrusToy>
    with SingleTickerProviderStateMixin {
  int _squeezeCount = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSqueeze() {
    setState(() => _squeezeCount++);
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '\u041D\u0430\u0436\u043C\u0438 \u043D\u0430 \u0430\u043F\u0435\u043B\u044C\u0441\u0438\u043D!',
            style: TextStyle(fontSize: 14, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _onSqueeze,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.citrusOrange, Color(0xFFFF7020)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.citrusOrange.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('\u{1F34A}', style: TextStyle(fontSize: 72)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$_squeezeCount',
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            '\u0440\u0430\u0437 \u0441\u043E\u0436\u0430\u0442\u043E',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 2. Bubble Wrap
// ============================================================
class BubbleWrapToy extends StatefulWidget {
  const BubbleWrapToy({super.key});

  @override
  State<BubbleWrapToy> createState() => _BubbleWrapToyState();
}

class _BubbleWrapToyState extends State<BubbleWrapToy> {
  final Map<int, bool> _popped = {};
  int _poppedCount = 0;
  static const int gridSize = 5;

  void _popBubble(int index) {
    if (_popped[index] == true) return;
    setState(() {
      _popped[index] = true;
      _poppedCount++;
    });
  }

  void _reset() {
    setState(() {
      _popped.clear();
      _poppedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\u041B\u043E\u043F\u043D\u0443\u0442\u043E: $_poppedCount',
              style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_poppedCount > 0)
              GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.citrusOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '\u0421\u0431\u0440\u043E\u0441\u0438\u0442\u044C',
                    style: TextStyle(color: AppColors.citrusOrange, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              final isPopped = _popped[index] == true;
              return GestureDetector(
                onTap: () => _popBubble(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    gradient: isPopped ? null : const LinearGradient(
                      begin: Alignment(-0.3, -0.4),
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromRGBO(255, 255, 255, 0.35),
                        Color.fromRGBO(255, 140, 66, 0.55),
                        Color.fromRGBO(255, 90, 0, 0.75),
                      ],
                    ),
                    color: isPopped ? Colors.white.withOpacity(0.03) : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPopped ? Colors.white.withOpacity(0.04) : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isPopped
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.citrusOrange.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: isPopped
                      ? const Center(child: Text('\u2713', style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)))
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 3. Breathing Exercise
// ============================================================
class BreathingExerciseToy extends StatefulWidget {
  const BreathingExerciseToy({super.key});

  @override
  State<BreathingExerciseToy> createState() => _BreathingExerciseToyState();
}

enum _Phase { ready, inhale, hold, exhale }

class _BreathingExerciseToyState extends State<BreathingExerciseToy>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  _Phase _phase = _Phase.ready;
  Timer? _phaseTimer;
  int _cycleCount = 0;
  bool _isRunning = false;

  static const phaseDurations = {
    _Phase.inhale: Duration(seconds: 4),
    _Phase.hold: Duration(seconds: 2),
    _Phase.exhale: Duration(seconds: 6),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isRunning = true;
      _phase = _Phase.inhale;
    });
    _runPhase(_Phase.inhale);
  }

  void _stopBreathing() {
    _phaseTimer?.cancel();
    setState(() {
      _isRunning = false;
      _phase = _Phase.ready;
      _cycleCount = 0;
    });
    _scaleAnimation = Tween<double>(begin: _scaleAnimation.value, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.duration = const Duration(milliseconds: 300);
    _controller.forward(from: 0);
  }

  void _runPhase(_Phase phase) {
    if (!mounted || !_isRunning) return;

    final duration = phaseDurations[phase]!;
    _controller.duration = duration;

    double endScale;
    switch (phase) {
      case _Phase.inhale:
        endScale = 1.45;
        break;
      case _Phase.hold:
        endScale = 1.45;
        break;
      case _Phase.exhale:
        endScale = 1.0;
        break;
      case _Phase.ready:
        endScale = 1.0;
    }

    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: endScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward(from: 0);

    _phaseTimer?.cancel();
    _phaseTimer = Timer(duration, () {
      if (!mounted || !_isRunning) return;

      _Phase nextPhase;
      switch (phase) {
        case _Phase.inhale:
          nextPhase = _Phase.hold;
          break;
        case _Phase.hold:
          nextPhase = _Phase.exhale;
          break;
        case _Phase.exhale:
          nextPhase = _Phase.inhale;
          setState(() => _cycleCount++);
          break;
        case _Phase.ready:
          nextPhase = _Phase.inhale;
      }
      setState(() => _phase = nextPhase);
      _runPhase(nextPhase);
    });
  }

  String _getPhaseText() {
    return switch (_phase) {
      _Phase.ready => '\u0413\u043E\u0442\u043E\u0432?',
      _Phase.inhale => '\u0412\u0434\u043E\u0445 4\u0441',
      _Phase.hold => '\u0417\u0430\u0434\u0435\u0440\u0436\u0438 2\u0441',
      _Phase.exhale => '\u0412\u044B\u0434\u043E\u0445 6\u0441',
    };
  }

  Color _getPhaseColor() {
    return switch (_phase) {
      _Phase.ready => AppColors.citrusPurple,
      _Phase.inhale => AppColors.citrusGreen,
      _Phase.hold => AppColors.citrusAmber,
      _Phase.exhale => AppColors.citrusOrange,
    };
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = _getPhaseColor();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SizedBox(
                width: 192,
                height: 192,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 192,
                      height: 192,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: phaseColor, width: 4),
                      ),
                    ),
                    // Progress ring
                    CustomPaint(
                      size: const Size(192, 192),
                      painter: _ProgressRingPainter(
                        progress: _controller.value,
                        color: phaseColor,
                      ),
                    ),
                    // Inner circle
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              phaseColor.withOpacity(0.6),
                              phaseColor.withOpacity(0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: phaseColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getPhaseText(),
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_isRunning)
                          Text(
                            '\u0426\u0438\u043A\u043B\u043E\u0432: $_cycleCount',
                            style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isRunning ? _stopBreathing : _startBreathing,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: _isRunning
                    ? null
                    : const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                color: _isRunning ? AppColors.surface2 : null,
                borderRadius: BorderRadius.circular(14),
                border: _isRunning ? Border.all(color: AppColors.citrusOrange.withOpacity(0.3)) : null,
                boxShadow: _isRunning
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.citrusOrange.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                _isRunning ? '\u0421\u0442\u043E\u043F' : '\u0421\u0442\u0430\u0440\u0442',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _isRunning ? AppColors.citrusOrange : AppColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
