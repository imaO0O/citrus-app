import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/services/casino_coins_service.dart';

class ToyScreen extends StatefulWidget {
  const ToyScreen({super.key});

  @override
  State<ToyScreen> createState() => _ToyScreenState();
}

class _ToyScreenState extends State<ToyScreen> {
  int _activeTab = 0;

  void _onTabChanged(int index) {
    setState(() => _activeTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Text(
                  'Антистресс',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
                ),
                SizedBox(height: 20),
                Expanded(
                child: IndexedStack(
                    index: _activeTab,
                    children: [
                      SqueezeCitrusToy(),
                      BubbleWrapToy(),
                      SandboxToy(),
                      RainToy(),
                      OrbsToy(),
                      CasinoToy(),
                    ],
                  ),
                ),
                _buildBottomTabs(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTabs() {
    const emojis = ['🍊', '🫧', '🏖️', '🌧️', '🔮', '🎰'];
    const labels = ['Цитрус', 'Пузыри', 'Песок', 'Дождь', 'Шарики', 'Казино'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(6, (i) {
            final isActive = _activeTab == i;
            return GestureDetector(
              onTap: () => _onTabChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
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
                    SizedBox(height: 4),
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
      ),
    );
  }
}

// ============================================================
// 1. Squish Citrus — с haptic, эффектом сока и стаканами
// ============================================================
class SqueezeCitrusToy extends StatefulWidget {
  const SqueezeCitrusToy({super.key});

  @override
  State<SqueezeCitrusToy> createState() => _SqueezeCitrusToyState();
}

class _SqueezeCitrusToyState extends State<SqueezeCitrusToy>
    with SingleTickerProviderStateMixin {
  int _squeezeCount = 0;
  int _glassesFilled = 0;
  static const int _squeezesPerGlass = 8;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final List<_JuiceDrop> _drops = [];
  bool _showSplash = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSqueeze() {
    HapticFeedback.mediumImpact();
    setState(() {
      _squeezeCount++;
      _showSplash = true;

      if (_squeezeCount % _squeezesPerGlass == 0) {
        _glassesFilled++;
        HapticFeedback.heavyImpact();
      }

      final random = Random();
      for (int i = 0; i < 3; i++) {
        _drops.add(_JuiceDrop(
          dx: -0.3 + random.nextDouble() * 0.6,
          dy: -0.3 + random.nextDouble() * 0.2,
          size: 4 + random.nextDouble() * 8,
          opacity: 0.6 + random.nextDouble() * 0.4,
        ));
      }
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showSplash = false);
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _drops.isNotEmpty) {
        setState(() {
          _drops.removeRange(0, _drops.length > 3 ? 3 : _drops.length);
        });
      }
    });

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward(from: 0);
  }

  double get _glassProgress => (_squeezeCount % _squeezesPerGlass) / _squeezesPerGlass;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Бейдж стаканов
          if (_glassesFilled > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.citrusAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🧃', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '$_glassesFilled ${_glassesFilled == 1 ? 'стакан' : _glassesFilled < 5 ? 'стакана' : 'стаканов'}',
                    style: TextStyle(
                      color: AppColors.citrusAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          Text(
            'Нажми на апельсин!',
            style: TextStyle(fontSize: 14, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20),

          // Апельсин с каплями сока
          GestureDetector(
            onTap: _onSqueeze,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
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
                          child: Center(
                            child: Text('🍊', style: TextStyle(fontSize: 72)),
                          ),
                        ),
                        // Капли сока
                        ..._drops.map((drop) => Positioned(
                          left: 90 + drop.dx * 80,
                          top: 60 + drop.dy * 80,
                          child: AnimatedOpacity(
                            opacity: drop.opacity,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: drop.size,
                              height: drop.size,
                              decoration: BoxDecoration(
                                color: AppColors.citrusYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )),
                        // Всплеск при нажатии
                        if (_showSplash)
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.citrusYellow.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20),

          // Стакан с прогрессом
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.mutedForeground.withOpacity(0.3), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: 68 * _glassProgress,
                  width: double.infinity,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.citrusYellow.withOpacity(0.6),
                        AppColors.citrusOrange.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
          Text(
            '$_squeezeCount',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'раз сжато',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _JuiceDrop {
  final double dx;
  final double dy;
  final double size;
  final double opacity;
  _JuiceDrop({required this.dx, required this.dy, required this.size, required this.opacity});
}

// ============================================================
// 2. Bubble Wrap — сетка 6×6, haptic, таймер, прогресс
// ============================================================
class BubbleWrapToy extends StatefulWidget {
  const BubbleWrapToy({super.key});

  @override
  State<BubbleWrapToy> createState() => _BubbleWrapToyState();
}

class _BubbleWrapToyState extends State<BubbleWrapToy> {
  final Map<int, bool> _popped = {};
  int _poppedCount = 0;
  static const int gridSize = 6;
  Stopwatch? _stopwatch;
  String _timeDisplay = '';
  Timer? _displayTimer;

  int get _totalBubbles => gridSize * gridSize;
  bool get _allPopped => _poppedCount == _totalBubbles;

  void _popBubble(int index) {
    if (_popped[index] == true) return;
    HapticFeedback.lightImpact();

    if (_poppedCount == 0) {
      _stopwatch = Stopwatch()..start();
      _startDisplayTimer();
    }

    setState(() {
      _popped[index] = true;
      _poppedCount++;
    });

    if (_poppedCount == _totalBubbles) {
      _stopwatch?.stop();
      _displayTimer?.cancel();
      _updateTime();
      HapticFeedback.heavyImpact();
    }
  }

  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    if (_stopwatch != null) {
      final e = _stopwatch!.elapsed;
      setState(() {
        _timeDisplay = '${e.inSeconds}.${(e.inMilliseconds % 1000) ~/ 100}';
      });
    }
  }

  void _reset() {
    _displayTimer?.cancel();
    setState(() {
      _popped.clear();
      _poppedCount = 0;
      _timeDisplay = '';
      _stopwatch?.stop();
      _stopwatch = null;
    });
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Лопнуто: ', style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
                Text('$_poppedCount/$_totalBubbles',
                    style: TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            Row(
              children: [
                if (_timeDisplay.isNotEmpty) ...[
                  Icon(Icons.timer, size: 16, color: AppColors.citrusAmber),
                  SizedBox(width: 4),
                  Text('${_timeDisplay}с',
                      style: TextStyle(color: AppColors.citrusAmber, fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(width: 12),
                ],
                if (_poppedCount > 0)
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.citrusOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 14, color: AppColors.citrusOrange),
                          SizedBox(width: 4),
                          Text('Заново',
                              style: TextStyle(color: AppColors.citrusOrange, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Прогресс-бар
        if (_poppedCount > 0 && !_allPopped) ...[
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _poppedCount / _totalBubbles,
              minHeight: 4,
              backgroundColor: AppColors.citrusOrange.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
            ),
          ),
        ],

        // Результат
        if (_allPopped) ...[
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.citrusGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎉', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Все лопнуто за ${_timeDisplay}с!',
                    style: TextStyle(color: AppColors.citrusGreen, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],

        SizedBox(height: 12),

        // Сетка
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _totalBubbles,
            itemBuilder: (context, index) {
              final isPopped = _popped[index] == true;
              return GestureDetector(
                onTap: () => _popBubble(index),
                child: AnimatedScale(
                  scale: isPopped ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isPopped ? null : const LinearGradient(
                        begin: Alignment(-0.3, -0.4),
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.4),
                          Color.fromRGBO(255, 140, 66, 0.6),
                          Color.fromRGBO(255, 90, 0, 0.8),
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
                        ? Center(child: Text('✓',
                            style: TextStyle(color: AppColors.mutedForeground.withOpacity(0.4), fontSize: 12)))
                        : null,
                  ),
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
// 3. Sandbox — рисование пальцем по песку
// ============================================================
class SandboxToy extends StatefulWidget {
  const SandboxToy({super.key});

  @override
  State<SandboxToy> createState() => _SandboxToyState();
}

class _SandboxToyState extends State<SandboxToy> {
  final List<_SandStroke> _strokes = [];
  _SandStroke? _currentStroke;
  double _brushSize = 12;
  Color _sandColor = const Color(0xFFD4A76A);
  static const _colorPalette = [
    Color(0xFFD4A76A), // Песок
    Color(0xFF8BC34A), // Трава
    Color(0xFF7C83D1), // Лаванда
    Color(0xFFFF8C42), // Апельсин
    Color(0xFFFFD93D), // Солнце
    Color(0xFFE63946), // Коралл
  ];

  void _onPanStart(DragStartDetails details) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentStroke = _SandStroke(
        points: [details.localPosition],
        color: _sandColor,
        size: _brushSize,
      );
      _strokes.add(_currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    setState(() => _currentStroke!.points.add(details.localPosition));
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  void _clearCanvas() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _strokes.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок и кнопки
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Рисуй пальцем по песку',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
            if (_strokes.isNotEmpty)
              Row(
                children: [
                  GestureDetector(
                    onTap: _undo,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.citrusOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.undo, size: 18, color: AppColors.citrusOrange),
                    ),
                  ),
                  SizedBox(width: 6),
                  GestureDetector(
                    onTap: _clearCanvas,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                    ),
                  ),
                ],
              ),
          ],
        ),

        SizedBox(height: 12),

        // Палитра цветов
        Row(
          children: [
            Text('Цвет: ', style: TextStyle(color: AppColors.dimForeground, fontSize: 11)),
            ..._colorPalette.map((c) {
              final sel = _sandColor == c;
              return GestureDetector(
                onTap: () => setState(() => _sandColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: sel ? 28 : 24,
                  height: sel ? 28 : 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? AppColors.foreground : Colors.transparent,
                      width: sel ? 2.5 : 0,
                    ),
                    boxShadow: sel
                        ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                ),
              );
            }),
          ],
        ),

        // Размер кисти
        SizedBox(height: 10),
        Row(
          children: [
            Text('Размер: ', style: TextStyle(color: AppColors.dimForeground, fontSize: 11)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.citrusOrange,
                  inactiveTrackColor: AppColors.citrusOrange.withOpacity(0.2),
                  thumbColor: AppColors.citrusOrange,
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _brushSize,
                  min: 4,
                  max: 30,
                  onChanged: (v) => setState(() => _brushSize = v),
                ),
              ),
            ),
            Container(
              width: _brushSize + 4,
              height: _brushSize + 4,
              decoration: BoxDecoration(
                color: _sandColor.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: _sandColor, width: 1.5),
              ),
            ),
          ],
        ),

        SizedBox(height: 10),

        // Холст
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SandCanvasPainter(
                  strokes: _strokes,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SandStroke {
  final List<Offset> points;
  final Color color;
  final double size;

  _SandStroke({
    required this.points,
    required this.color,
    required this.size,
  });
}

class _SandCanvasPainter extends CustomPainter {
  final List<_SandStroke> strokes;

  _SandCanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Фон — тёмный песок
    final bgPaint = Paint()..color = const Color(0xFF2A2218);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Текстура песчинок
    final rng = Random(42);
    final dotPaint = Paint()..color = const Color(0xFF3D3020);
    for (int i = 0; i < 300; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.5 + rng.nextDouble() * 1.5,
        dotPaint,
      );
    }

    // Рисуем штрихи
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final prev = stroke.points[i - 1];
        final curr = stroke.points[i];
        final midX = (prev.dx + curr.dx) / 2;
        final midY = (prev.dy + curr.dy) / 2;
        path.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
      }

      canvas.drawPath(path, paint);

      // Частицы песка вокруг штриха
      final particlePaint = Paint()..color = stroke.color.withOpacity(0.4);
      final pRng = Random(stroke.points.length);
      for (final pt in stroke.points) {
        if (pRng.nextDouble() < 0.3) {
          canvas.drawCircle(
            Offset(
              pt.dx + (pRng.nextDouble() - 0.5) * stroke.size * 1.5,
              pt.dy + (pRng.nextDouble() - 0.5) * stroke.size * 1.5,
            ),
            pRng.nextDouble() * 2 + 0.5,
            particlePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SandCanvasPainter oldDelegate) => true;
}

// ============================================================
// 4. Rain — медитативный дождь с кругами на воде
// ============================================================
class RainToy extends StatefulWidget {
  const RainToy({super.key});

  @override
  State<RainToy> createState() => _RainToyState();
}

class _RainToyState extends State<RainToy> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_RainDrop> _drops = [];
  final List<_Ripple> _ripples = [];
  Timer? _spawnTimer;
  Timer? _cleanupTimer;
  bool _isRaining = true;
  double _intensity = 0.5; // 0.0 — тихо, 1.0 — ливень
  int _dropCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _startRain();
    _startCleanup();
  }

  void _startRain() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: (400 * (1 - _intensity * 0.8)).round()),
      (_) {
        if (!_isRaining || !mounted) return;
        final rng = Random();
        setState(() {
          _drops.add(_RainDrop(
            x: rng.nextDouble(),
            speed: 2 + rng.nextDouble() * 3 + _intensity * 2,
            length: 12 + rng.nextDouble() * 20,
            opacity: 0.3 + rng.nextDouble() * 0.4,
          ));
          _dropCount++;
        });
      },
    );
  }

  void _startCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        // Удаляем капли за экраном, создаём круги
        _drops.removeWhere((d) {
          if (d.y > 1.0) {
            _ripples.add(_Ripple(x: d.x, radius: 0, maxRadius: 20 + Random().nextDouble() * 30, opacity: 0.6));
            return true;
          }
          return false;
        });
        // Анимируем круги
        for (final r in _ripples) {
          r.radius += 1.5;
          r.opacity -= 0.025;
        }
        _ripples.removeWhere((r) => r.opacity <= 0);
      });
    });
  }

  void _toggleRain() {
    setState(() => _isRaining = !_isRaining);
    if (_isRaining) {
      _startRain();
      HapticFeedback.lightImpact();
    } else {
      _spawnTimer?.cancel();
      HapticFeedback.mediumImpact();
    }
  }

  void _addManualDrop(double x, double y) {
    HapticFeedback.selectionClick();
    setState(() {
      _ripples.add(_Ripple(x: x, maxRadius: 30 + Random().nextDouble() * 25, opacity: 0.8));
      _dropCount++;
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _cleanupTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Управление
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleRain,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isRaining ? AppColors.citrusPurple : AppColors.citrusAmber).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRaining ? Icons.pause : Icons.play_arrow,
                          size: 18,
                          color: _isRaining ? AppColors.citrusPurple : AppColors.citrusAmber,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _isRaining ? 'Пауза' : 'Играть',
                          style: TextStyle(
                            color: _isRaining ? AppColors.citrusPurple : AppColors.citrusAmber,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text('💧 $_dropCount',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
              ],
            ),
          ],
        ),

        // Интенсивность
        SizedBox(height: 10),
        Row(
          children: [
            Text('🌧️ ', style: TextStyle(fontSize: 14)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.citrusPurple,
                  inactiveTrackColor: AppColors.citrusPurple.withOpacity(0.2),
                  thumbColor: AppColors.citrusPurple,
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _intensity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() => _intensity = v);
                    _startRain(); // Пересоздаём таймер с новой частотой
                  },
                ),
              ),
            ),
            Text('⛈️', style: TextStyle(fontSize: 14)),
          ],
        ),

        SizedBox(height: 6),
        Text('Нажми на воду, чтобы создать круги',
            style: TextStyle(color: AppColors.dimForeground, fontSize: 11)),
        SizedBox(height: 10),

        // Холст дождя
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTapDown: (details) {
                final size = (context.findRenderObject() as RenderBox).size;
                _addManualDrop(
                  details.localPosition.dx / size.width,
                  details.localPosition.dy / size.height,
                );
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _RainCanvasPainter(
                  drops: _drops,
                  ripples: _ripples,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RainDrop {
  double x;
  double y;
  final double speed;
  final double length;
  final double opacity;

  _RainDrop({
    required this.x,
    required this.speed,
    required this.length,
    required this.opacity,
  }) : y = -0.1;

  void fall() => y += speed * 0.01;
}

class _Ripple {
  final double x;
  double radius;
  final double maxRadius;
  double opacity;

  _Ripple({required this.x, required this.maxRadius, required this.opacity, this.radius = 0});
}

class _RainCanvasPainter extends CustomPainter {
  final List<_RainDrop> drops;
  final List<_Ripple> ripples;

  _RainCanvasPainter({required this.drops, required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    // Фон — тёмная вода
    final bgPaint = Paint()..color = const Color(0xFF0E1525);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Тонкая полоса «поверхности воды»
    final surfaceY = size.height * 0.85;
    final surfacePaint = Paint()
      ..color = const Color(0xFF1A2A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, surfaceY), Offset(size.width, surfaceY), surfacePaint);

    // Отражение — градиент под поверхностью
    final reflectPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A2A45),
          const Color(0xFF0E1525),
        ],
      ).createShader(Rect.fromLTWH(0, surfaceY, size.width, size.height - surfaceY));
    canvas.drawRect(Rect.fromLTWH(0, surfaceY, size.width, size.height - surfaceY), reflectPaint);

    // Капли дождя
    final dropPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final drop in drops) {
      drop.fall();
      final dx = drop.x * size.width;
      final dy = drop.y * surfaceY;
      dropPaint.color = Color.fromRGBO(160, 200, 255, drop.opacity);
      dropPaint.strokeWidth = 1.5;
      canvas.drawLine(
        Offset(dx, dy),
        Offset(dx, dy + drop.length),
        dropPaint,
      );
    }

    // Круги на воде
    for (final ripple in ripples) {
      final cx = ripple.x * size.width;
      final cy = surfaceY;
      final ripplePaint = Paint()
        ..color = Color.fromRGBO(140, 180, 255, ripple.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: ripple.radius * 2,
          height: ripple.radius * 0.6,
        ),
        ripplePaint,
      );
      // Второй круг (внутренний, легче)
      if (ripple.radius > 8) {
        final innerPaint = Paint()
          ..color = Color.fromRGBO(140, 180, 255, ripple.opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: ripple.radius * 1.2,
            height: ripple.radius * 0.36,
          ),
          innerPaint,
        );
      }
    }

    // Случайные отражения капель в воде
    final rng = Random(7);
    final reflPaint = Paint()..color = const Color.fromRGBO(140, 180, 255, 0.05);
    for (int i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, surfaceY + rng.nextDouble() * (size.height - surfaceY)),
        1 + rng.nextDouble() * 2,
        reflPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainCanvasPainter oldDelegate) => true;
}

// ============================================================
// 5. Orbs — плавающие шарики, которые лопаются
// ============================================================
class OrbsToy extends StatefulWidget {
  const OrbsToy({super.key});

  @override
  State<OrbsToy> createState() => _OrbsToyState();
}

class _OrbsToyState extends State<OrbsToy> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_Orb> _orbs = [];
  Timer? _spawnTimer;
  int _poppedCount = 0;
  int _missedCount = 0;
  bool _isPlaying = true;

  static const _orbColors = [
    Color(0xFFFF8C42),
    Color(0xFFFFD93D),
    Color(0xFF8BC34A),
    Color(0xFF7C83D1),
    Color(0xFFE63946),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _startSpawning();
    _startPhysics();
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_isPlaying || !mounted) return;
      final rng = Random();
      setState(() {
        if (_orbs.length < 15) {
          _orbs.add(_Orb(
            x: 0.1 + rng.nextDouble() * 0.8,
            y: 1.1,
            vx: (rng.nextDouble() - 0.5) * 0.002,
            vy: -(0.002 + rng.nextDouble() * 0.004),
            radius: 18 + rng.nextDouble() * 22,
            color: _orbColors[rng.nextInt(_orbColors.length)],
            wobblePhase: rng.nextDouble() * pi * 2,
            wobbleSpeed: 0.02 + rng.nextDouble() * 0.03,
          ));
        }
      });
    });
  }

  void _startPhysics() {
    Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() {
        final toRemove = <_Orb>[];
        for (final orb in _orbs) {
          orb.x += orb.vx + sin(orb.wobblePhase) * 0.001;
          orb.y += orb.vy;
          orb.wobblePhase += orb.wobbleSpeed;

          // Ушёл за верхний край
          if (orb.y < -0.15) {
            toRemove.add(orb);
            _missedCount++;
          }
        }
        _orbs.removeWhere((o) => toRemove.contains(o));
      });
    });
  }

  void _popOrb(_Orb orb) {
    HapticFeedback.mediumImpact();
    setState(() {
      _orbs.remove(orb);
      _poppedCount++;
    });
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _orbs.clear();
      _poppedCount = 0;
      _missedCount = 0;
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Счётчики
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.citrusGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💥', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('$_poppedCount',
                          style: TextStyle(color: AppColors.citrusGreen, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.citrusAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💨', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('$_missedCount',
                          style: TextStyle(color: AppColors.citrusAmber, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            if (_poppedCount > 0 || _missedCount > 0)
              GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.citrusOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.refresh, size: 18, color: AppColors.citrusOrange),
                ),
              ),
          ],
        ),

        SizedBox(height: 6),
        Text('Лопай шарики, пока не улетели!',
            style: TextStyle(color: AppColors.dimForeground, fontSize: 11)),
        SizedBox(height: 10),

        // Игровое поле
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return GestureDetector(
                  onTapUp: (details) {
                    // Проверяем попадание по шарику
                    for (final orb in _orbs) {
                      final ox = orb.x * w;
                      final oy = orb.y * h;
                      final dx = details.localPosition.dx - ox;
                      final dy = details.localPosition.dy - oy;
                      if (dx * dx + dy * dy <= orb.radius * orb.radius) {
                        _popOrb(orb);
                        return;
                      }
                    }
                  },
                  child: CustomPaint(
                    size: Size(w, h),
                    painter: _OrbsPainter(orbs: _orbs),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Orb {
  double x;
  double y;
  final double vx;
  double vy;
  final double radius;
  final Color color;
  double wobblePhase;
  final double wobbleSpeed;

  _Orb({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.wobblePhase,
    required this.wobbleSpeed,
  });
}

class _OrbsPainter extends CustomPainter {
  final List<_Orb> orbs;

  _OrbsPainter({required this.orbs});

  @override
  void paint(Canvas canvas, Size size) {
    // Фон — ночное небо
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0A0E1A), const Color(0xFF151025)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Звёзды
    final starRng = Random(42);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 60; i++) {
      final sx = starRng.nextDouble() * size.width;
      final sy = starRng.nextDouble() * size.height;
      final sr = 0.5 + starRng.nextDouble() * 1.5;
      starPaint.color = Colors.white.withOpacity(0.15 + starRng.nextDouble() * 0.25);
      canvas.drawCircle(Offset(sx, sy), sr, starPaint);
    }

    // Шарики
    for (final orb in orbs) {
      final cx = orb.x * size.width;
      final cy = orb.y * size.height;
      final r = orb.radius;

      // Свечение
      final glowPaint = Paint()
        ..color = orb.color.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(cx, cy), r * 1.4, glowPaint);

      // Основной шарик с градиентом
      final orbPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Colors.white.withOpacity(0.5),
            orb.color.withOpacity(0.8),
            orb.color,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, orbPaint);

      // Блик
      final highlightPaint = Paint()..color = Colors.white.withOpacity(0.45);
      final hlRect = Rect.fromCenter(
        center: Offset(cx - r * 0.3, cy - r * 0.35),
        width: r * 0.4,
        height: r * 0.25,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(hlRect, Radius.circular(r * 0.15)),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbsPainter oldDelegate) => true;
}

// ============================================================
// 6. Casino — игровой автомат (слоты) с ежедневными заданиями
// ============================================================
class CasinoToy extends StatefulWidget {
  const CasinoToy({super.key});

  @override
  State<CasinoToy> createState() => _CasinoToyState();
}

class _CasinoToyState extends State<CasinoToy> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _symbols = ['🍒', '🍋', '🍊', '🍇', '💎', '7️⃣', '🔔', '⭐'];
  static const _symbolPay = {
    '🍒': 2,
    '🍋': 3,
    '🍊': 4,
    '🍇': 5,
    '💎': 10,
    '7️⃣': 15,
    '🔔': 8,
    '⭐': 7,
  };

  late List<String> _reelResults;
  late List<AnimationController> _reelControllers;
  late List<Animation<double>> _reelAnimations;
  late List<CurvedAnimation> _reelCurves;

  bool _isSpinning = false;
  int _coins = 0;
  int _bet = 10;
  String _resultMessage = '';
  Color _resultColor = AppColors.mutedForeground;
  int _totalWins = 0;
  int _totalSpins = 0;
  int _biggestWin = 0;
  Set<String> _questsDone = {};
  bool _isLoading = true;

  final _coinsService = CasinoCoinsService();
  StreamSubscription? _statusSubscription;

  // Для анимации «вращения» каждого барабана
  late List<List<String>> _reelStrips;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reelResults = List.generate(3, (_) => _symbols[Random().nextInt(_symbols.length)]);
    _reelControllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500 + i * 200),
      );
      c.addListener(() => setState(() {}));
      return c;
    });
    _reelCurves = _reelControllers.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic)).toList();
    _reelAnimations = _reelCurves.map((c) => c.drive(Tween<double>(begin: 0, end: 1))).toList();
    _reelStrips = List.generate(3, (_) => _generateStrip());
    _loadState();
  }

  Future<void> _loadState() async {
    await _coinsService.initialize();
    await _refreshFromServer();
    _statusSubscription = _coinsService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _coins = status.coins;
          _questsDone = status.questsDone.toSet();
        });
      }
    });
    setState(() {
      _coins = _coinsService.currentCoins;
      _questsDone = _coinsService.questsDone;
      _isLoading = false;
    });
  }

  Future<void> _refreshFromServer() async {
    try {
      await _coinsService.refreshStatus();
      if (mounted) {
        setState(() {
          _coins = _coinsService.currentCoins;
          _questsDone = _coinsService.questsDone;
        });
      }
    } catch (e) {
      debugPrint('Failed to refresh casino status: $e');
    }
  }

  Future<void> _refreshCoins() async {
    if (mounted) {
      setState(() {
        _coins = _coinsService.currentCoins;
        _questsDone = _coinsService.questsDone;
      });
    }
  }

  List<String> _generateStrip() {
    final rng = Random();
    return List.generate(20, (_) => _symbols[rng.nextInt(_symbols.length)]);
  }

  void _spin() async {
    if (_isSpinning) return;
    if (_coins < _bet) {
      setState(() {
        _resultMessage = 'Недостаточно монет! Выполни задания ниже.';
        _resultColor = AppColors.destructive;
      });
      return;
    }

    HapticFeedback.mediumImpact();

    _reelResults = List.generate(3, (_) => _symbols[Random().nextInt(_symbols.length)]);

    setState(() {
      _isSpinning = true;
      _resultMessage = '';
      for (int i = 0; i < 3; i++) {
        _reelStrips[i] = _generateStrip();
      }
    });

    for (int i = 0; i < 3; i++) {
      _reelControllers[i].reset();
      _reelControllers[i].forward();
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    final r = _reelResults;
    int displayWin = 0;
    String msg = '';

    if (r[0] == r[1] && r[1] == r[2]) {
      final pay = _symbolPay[r[0]]!;
      displayWin = _bet * pay;
      msg = '🎉 ДЖЕКПОТ! ${r[0]}${r[1]}${r[2]} — ×$pay! +$displayWin';
      HapticFeedback.heavyImpact();
    } else if (r[0] == r[1] || r[1] == r[2] || r[0] == r[2]) {
      displayWin = (_bet * 1.5).round();
      msg = '✨ Два совпадения! +$displayWin монет';
      HapticFeedback.lightImpact();
    } else {
      msg = '😔 Не повезло... Крути ещё!';
    }

    final spinResult = await _coinsService.spin(_bet, _reelResults, displayWin);
    if (spinResult == null) {
      setState(() {
        _isSpinning = false;
        _resultMessage = 'Ошибка! Попробуй ещё.';
        _resultColor = AppColors.destructive;
      });
      return;
    }

    final newBalance = spinResult.newBalance;
    _totalSpins++;
    
    setState(() {
      _isSpinning = false;
      _coins = newBalance;
      _resultMessage = msg;
      _resultColor = displayWin > 0 ? AppColors.citrusGreen : AppColors.mutedForeground;
      if (displayWin > 0) _totalWins++;
      if (displayWin > _biggestWin) _biggestWin = displayWin;
    });
  }

  void _changeBet(int delta) {
    setState(() {
      _bet = (_bet + delta).clamp(5, 50);
    });
  }

  @override
  void dispose() {
    for (final c in _reelControllers) {
      c.dispose();
    }
    _statusSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCoins();
    }
  }

  int get _questCoinsEarned => _questsDone.length * CasinoCoinsService.questReward;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.citrusAmber));
    }

    return SingleChildScrollView(
      child: Column(
      children: [
        // Верхняя панель: монеты и статистика
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.citrusAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🪙', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('$_coins',
                      style: TextStyle(color: AppColors.citrusAmber, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.citrusGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('🏆 $_totalWins/$_totalSpins',
                      style: TextStyle(color: AppColors.citrusGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                SizedBox(width: 6),
                if (_biggestWin > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.citrusPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('💰 Макс: $_biggestWin',
                        style: TextStyle(color: AppColors.citrusPurple, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        ),

        SizedBox(height: 12),

        // Корпус автомата
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1428), Color(0xFF0E0A18)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.citrusAmber.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.citrusAmber.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Заголовок автомата
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.citrusAmber.withOpacity(0.2), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('★ ', style: TextStyle(color: AppColors.citrusAmber, fontSize: 14)),
                    Text('LUCKY SLOTS',
                        style: TextStyle(
                          color: AppColors.citrusAmber,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        )),
                    Text(' ★', style: TextStyle(color: AppColors.citrusAmber, fontSize: 14)),
                  ],
                ),
              ),

              // Барабаны
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return _buildReel(i);
                  }),
                ),
              ),

              // Линия выигрыша
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.citrusAmber.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Результат
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                constraints: const BoxConstraints(minHeight: 40),
                child: _resultMessage.isEmpty
                    ? Text('Крути барабаны!',
                        style: TextStyle(color: AppColors.dimForeground, fontSize: 13))
                    : Text(_resultMessage,
                        style: TextStyle(color: _resultColor, fontSize: 13, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // Управление ставкой
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ставка: ', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
            GestureDetector(
              onTap: _isSpinning ? null : () => _changeBet(-5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.citrusOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('−', style: TextStyle(color: AppColors.citrusOrange, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text('$_bet 🪙',
                  style: TextStyle(color: AppColors.citrusAmber, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: _isSpinning ? null : () => _changeBet(5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.citrusOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+', style: TextStyle(color: AppColors.citrusOrange, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Кнопка SPIN
        GestureDetector(
          onTap: _spin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            decoration: BoxDecoration(
              gradient: _isSpinning
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.citrusOrange, Color(0xFFFF6020)],
                    ),
              color: _isSpinning ? AppColors.mutedForeground.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isSpinning
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.citrusOrange.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSpinning ? '⏳' : '🎰',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(width: 8),
                Text(
                  _isSpinning ? 'Крутится...' : 'КРУТИТЬ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // ─── Панель ежедневных заданий ───
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('📋', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('Ежедневные задания',
                      style: TextStyle(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.w700)),
                  Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.citrusAmber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('+${CasinoCoinsService.dailyFreeLimit}/день',
                        style: TextStyle(color: AppColors.citrusAmber, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text('Ежедневно ${CasinoCoinsService.dailyFreeLimit} монет + задания по ${CasinoCoinsService.questReward} 🪙',
                  style: TextStyle(color: AppColors.dimForeground, fontSize: 10)),
              SizedBox(height: 10),

              // Список заданий
              ...CasinoCoinsService.quests.map((quest) {
                final done = _questsDone.contains(quest.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.citrusGreen.withOpacity(0.08)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: done
                          ? AppColors.citrusGreen.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(quest.emoji, style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quest.title,
                                style: TextStyle(
                                  color: done ? AppColors.citrusGreen : AppColors.foreground,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                )),
                            SizedBox(height: 2),
                            Text(quest.description,
                                style: TextStyle(color: AppColors.dimForeground, fontSize: 10)),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      if (done)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.citrusGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('✓ +${quest.reward}',
                              style: TextStyle(color: AppColors.citrusGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.citrusAmber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+${quest.reward} 🪙',
                              style: TextStyle(color: AppColors.citrusAmber, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                );
              }),

              // Прогресс заданий
              SizedBox(height: 4),
              Row(
                children: [
                  Text('${_questsDone.length}/${CasinoCoinsService.quests.length} заданий',
                      style: TextStyle(color: AppColors.dimForeground, fontSize: 10)),
                  SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _questsDone.length / CasinoCoinsService.quests.length,
                        minHeight: 4,
                        backgroundColor: AppColors.citrusGreen.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusGreen),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('+$_questCoinsEarned 🪙',
                      style: TextStyle(color: AppColors.citrusAmber, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // Таблица выплат
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Text('Таблица выплат', style: TextStyle(color: AppColors.dimForeground, fontSize: 10, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: _symbolPay.entries.map((e) {
                  return Text('${e.key} ×${e.value}',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 10));
                }).toList(),
              ),
              SizedBox(height: 2),
              Text('Два совпадения — ×1.5 к ставке',
                  style: TextStyle(color: AppColors.dimForeground, fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildReel(int index) {
    return Container(
      width: 80,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0618),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.citrusAmber.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _reelControllers[index],
        builder: (context, child) {
          String displaySymbol;
          if (_isSpinning && !_reelControllers[index].isAnimating) {
            displaySymbol = _reelResults[index];
          } else if (_isSpinning && _reelControllers[index].isAnimating) {
            final progress = _reelAnimations[index].value;
            final stripPos = (progress * _reelStrips[index].length).floor();
            final strip = _reelStrips[index];
            displaySymbol = stripPos < strip.length ? strip[stripPos] : _reelResults[index];
          } else {
            displaySymbol = _reelResults[index];
          }

          final isLanded = _isSpinning && !_reelControllers[index].isAnimating;

          return Center(
            child: AnimatedScale(
              scale: isLanded ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              child: Text(
                displaySymbol,
                style: TextStyle(
                  fontSize: isLanded ? 44 : 38,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
