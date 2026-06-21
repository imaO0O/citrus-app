import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/widgets/citrus_button.dart';

class _Slide {
  final String emoji;
  final String title;
  final String text;
  final Color color;
  const _Slide(this.emoji, this.title, this.text, this.color);
}

/// Короткий тур при первом запуске.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide('🍊', 'Привет! Я Цитрус', 'Тёплый помощник для твоего ментального здоровья. Каждый день — маленький шаг к себе.', AppColors.citrusOrange),
    _Slide('😊', 'Отмечай настроение', 'Колесо настроения, дневник и аналитика помогут замечать, как ты на самом деле.', Color(0xFF66BB6A)),
    _Slide('🧘', 'Заботься о себе', 'Дыхательные упражнения, мини-курсы и ИИ-чат — поддержка всегда под рукой.', Color(0xFF9C6ADE)),
    _Slide('✨', 'Расти каждый день', 'Серии, цитрусовое дерево и инсайты недели делают заботу о себе приятной привычкой.', Color(0xFF4A90D9)),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _slides.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: AppSize.padding(12),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Пропустить', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14))),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: AppSize.padding(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: AppSize.s(160),
                          height: AppSize.s(160),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [s.color.withValues(alpha: 0.3), s.color.withValues(alpha: 0.08)]),
                            boxShadow: [BoxShadow(color: s.color.withValues(alpha: 0.3), blurRadius: 50, spreadRadius: 6)],
                          ),
                          child: Center(child: Text(s.emoji, style: TextStyle(fontSize: AppSize.s(80)))),
                        ),
                        AppSize.gapH(40),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(26), fontWeight: FontWeight.w800),
                        ),
                        AppSize.gapH(14),
                        Text(
                          s.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(15), height: 1.6),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: AppSize.paddingH(4, 0),
                  width: active ? AppSize.s(22) : AppSize.s(8),
                  height: AppSize.s(8),
                  decoration: BoxDecoration(
                    color: active ? _slides[_page].color : AppColors.subtleBorder,
                    borderRadius: AppSize.radius(4),
                  ),
                );
              }),
            ),
            AppSize.gapH(24),
            Padding(
              padding: AppSize.padding(24),
              child: CitrusButton(
                label: _isLast ? 'Начать' : 'Далее',
                color: _slides[_page].color,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
