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
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Пульсирующие внешние кольца
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOutCubic,
                      tween: Tween(begin: 0.9, end: _isBreathing ? 1.0 : 0.9),
                      builder: (context, pulse, _) {
                        return Container(
                          width: 180 * pulse,
                          height: 180 * pulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isBreathing
                                  ? _phaseColor.withOpacity(0.2 * pulse)
                                  : const Color.fromRGBO(255, 140, 66, 0.15),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Второе кольцо
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOutCubic,
                      tween: Tween(begin: 0.9, end: _isBreathing ? 1.0 : 0.9),
                      builder: (context, pulse, _) {
                        return Container(
                          width: 200 * pulse,
                          height: 200 * pulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isBreathing
                                  ? _phaseColor.withOpacity(0.1 * pulse)
                                  : const Color.fromRGBO(255, 140, 66, 0.08),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),

                    // Основной круг
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 160 * _circleScale,
                      height: 160 * _circleScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isBreathing
                            ? RadialGradient(
                                colors: [
                                  _phaseColor.withOpacity(0.35),
                                  _phaseColor.withOpacity(0.15),
                                  _phaseColor.withOpacity(0.05),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              )
                            : const RadialGradient(
                                colors: [
                                  Color.fromRGBO(255, 140, 66, 0.15),
                                  Color.fromRGBO(255, 140, 66, 0.05),
                                ],
                              ),
                        border: Border.all(
                          color: _isBreathing
                              ? _phaseColor
                              : const Color.fromRGBO(255, 140, 66, 0.3),
                          width: 3,
                        ),
                        boxShadow: _isBreathing
                            ? [
                                BoxShadow(
                                  color: _phaseColor.withOpacity(0.35),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: _phaseColor.withOpacity(0.2),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color.fromRGBO(255, 140, 66, 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                              style: TextStyle(
                                fontSize: _isBreathing ? 22 : 40,
                                fontWeight: FontWeight.w800,
                                color: _isBreathing
                                    ? _phaseColor
                                    : const Color(0xFFEDE8E0),
                                letterSpacing: _isBreathing ? 0.3 : 0,
                              ),
                              child: Text(
                                _isBreathing ? phases[_breathPhase] : '🌬️',
                              ),
                            ),
                            if (_isBreathing)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: 0.8,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _phaseColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${4 - (_controller.value * 4).floor()} сек',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _phaseColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                    horizontal: 36,
                    vertical: 18,
                  ),
                  backgroundColor: const Color(0xFFFF8C42),
                  foregroundColor: const Color(0xFF0C0C14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFFF8C42).withOpacity(0.5),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _stopBreathing,
                icon: const Icon(Icons.stop),
                label: Text('Цикл $_breathCount / 4'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 18,
                  ),
                  foregroundColor: const Color(0xFFFF8C42),
                  side: BorderSide(color: const Color(0xFFFF8C42).withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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
