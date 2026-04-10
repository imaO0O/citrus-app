import 'package:flutter/material.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isBreathing = false;
  int _breathPhase = 0;
  int _breathCount = 0;

  final phases = ['Вдох', 'Задержка', 'Выдох'];
  final phaseDurations = [4, 4, 4];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isBreathing = true;
      _breathPhase = 0;
      _breathCount = 0;
    });

    _controller.forward(from: 0);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _breathPhase = (_breathPhase + 1) % 3;
          if (_breathPhase == 0) _breathCount++;
        });
        _controller.forward(from: 0);

        if (_breathCount >= 4) {
          _stopBreathing();
        }
      }
    });
  }

  void _stopBreathing() {
    _controller.reset();
    setState(() => _isBreathing = false);
  }

  double get _circleScale {
    if (!_isBreathing) return 1.0;
    final value = _controller.value;
    if (_breathPhase == 0) {
      return 1.0 + 0.5 * value;
    } else if (_breathPhase == 1) {
      return 1.5;
    } else {
      return 1.5 - 0.5 * value;
    }
  }

  Color get _phaseColor {
    switch (_breathPhase) {
      case 0: return const Color(0xFF8BC34A);
      case 1: return const Color(0xFFFFD93D);
      case 2: return const Color(0xFFFF8C42);
      default: return const Color(0xFF8BC34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дыхательные упражнения')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Техника дыхания 4-4-4',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEDE8E0),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Вдох 4 сек → Задержка 4 сек → Выдох 4 сек',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A8298),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 160 * _circleScale,
                  height: 160 * _circleScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isBreathing
                        ? _phaseColor.withOpacity(0.3)
                        : const Color.fromRGBO(255, 140, 66, 0.1),
                    border: Border.all(
                      color: _isBreathing
                          ? _phaseColor
                          : const Color.fromRGBO(255, 140, 66, 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isBreathing ? phases[_breathPhase] : '🌬️',
                          style: TextStyle(
                            fontSize: _isBreathing ? 20 : 40,
                            fontWeight: FontWeight.w600,
                            color: _isBreathing
                                ? _phaseColor
                                : const Color(0xFFEDE8E0),
                          ),
                        ),
                        if (_isBreathing)
                          Text(
                            '${4 - (_controller.value * 4).floor()} сек',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8A8298),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            if (!_isBreathing)
              ElevatedButton.icon(
                onPressed: _startBreathing,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Начать (4 цикла)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFFFF8C42),
                  foregroundColor: const Color(0xFF0C0C14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _stopBreathing,
                icon: const Icon(Icons.stop),
                label: Text('Цикл $_breathCount / 4'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  foregroundColor: const Color(0xFFFF8C42),
                  side: const BorderSide(color: Color(0xFFFF8C42)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

            const SizedBox(height: 48),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Другие упражнения',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEDE8E0),
                    ),
                  ),
                  SizedBox(height: 12),
                  _ExerciseCard(
                    icon: Icons.slow_motion_video,
                    title: 'Квадратное дыхание',
                    subtitle: '4-4-4-4 (вдох-задержка-выдох-задержка)',
                  ),
                  SizedBox(height: 8),
                  _ExerciseCard(
                    icon: Icons.air,
                    title: '4-7-8 техника',
                    subtitle: 'Вдох 4 — Задержка 7 — Выдох 8',
                  ),
                  SizedBox(height: 8),
                  _ExerciseCard(
                    icon: Icons.self_improvement,
                    title: 'Прогрессивная релаксация',
                    subtitle: 'Поочерёдное напряжение и расслабление мышц',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ExerciseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C42), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEDE8E0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8298),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF5A5468)),
        ],
      ),
    );
  }
}
