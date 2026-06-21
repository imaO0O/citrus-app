import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/repository/mood_repository.dart';
import '../../core/repository/diary_repository.dart';
import '../../core/services/course_prefs_service.dart';
import '../../data/courses/courses.dart';

class _Stage {
  final String emoji;
  final String name;
  final int min;
  const _Stage(this.emoji, this.name, this.min);
}

/// Геймификация: цитрусовое дерево растёт от заботы о себе.
class CitrusTreeScreen extends StatefulWidget {
  CitrusTreeScreen({super.key});

  @override
  State<CitrusTreeScreen> createState() => _CitrusTreeScreenState();
}

class _CitrusTreeScreenState extends State<CitrusTreeScreen> with SingleTickerProviderStateMixin {
  static const _stages = [
    _Stage('🌱', 'Семечко', 0),
    _Stage('🌿', 'Росток', 12),
    _Stage('🪴', 'Саженец', 30),
    _Stage('🌳', 'Деревце', 55),
    _Stage('🌳', 'Крепкое дерево', 90),
    _Stage('🍊', 'Плодоносит!', 140),
  ];

  bool _loading = true;
  int _moodDays = 0;
  int _diaryCount = 0;
  int _courseDays = 0;
  late final AnimationController _pulse;

  int get _points => _moodDays * 1 + _diaryCount * 2 + _courseDays * 3;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    // Читаем репозитории синхронно, до await.
    final moodRepo = context.read<MoodRepository>();
    final diaryRepo = context.read<DiaryRepository>();
    int moodDays = 0, diaryCount = 0, courseDays = 0;
    try {
      final moodMap = await moodRepo.getAverageMoodByDay(startDate: from, endDate: now);
      moodDays = moodMap.length;
    } catch (_) {}
    try {
      final entries = await diaryRepo.getEntries(startDate: from, endDate: now);
      diaryCount = entries.length;
    } catch (_) {}
    try {
      final prefs = CoursePrefsService();
      for (final c in kCourses) {
        courseDays += (await prefs.getProgress(c.id)).doneDays.length;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _moodDays = moodDays;
        _diaryCount = diaryCount;
        _courseDays = courseDays;
        _loading = false;
      });
    }
  }

  int get _stageIndex {
    int idx = 0;
    for (int i = 0; i < _stages.length; i++) {
      if (_points >= _stages[i].min) idx = i;
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_stageIndex];
    final isMax = _stageIndex == _stages.length - 1;
    final next = isMax ? null : _stages[_stageIndex + 1];
    final progress = isMax
        ? 1.0
        : ((_points - stage.min) / (next!.min - stage.min)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Моё цитрусовое дерево',
            style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(19), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: AppColors.foreground), onPressed: _load),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.citrusGreen))
          : ListView(
              padding: AppSize.padding(20),
              children: [
                AppSize.gapH(8),
                // Дерево
                Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final scale = 1.0 + 0.04 * _pulse.value;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: AppSize.s(200),
                      height: AppSize.s(200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.citrusGreen.withValues(alpha: 0.25),
                          AppColors.citrusGreen.withValues(alpha: 0.05),
                        ]),
                        boxShadow: [BoxShadow(color: AppColors.citrusGreen.withValues(alpha: 0.3), blurRadius: 50, spreadRadius: 6)],
                      ),
                      child: Center(child: Text(stage.emoji, style: TextStyle(fontSize: AppSize.s(96)))),
                    ),
                  ),
                ),
                AppSize.gapH(20),
                Center(
                  child: Text(stage.name, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(22), fontWeight: FontWeight.w800)),
                ),
                AppSize.gapH(6),
                Center(
                  child: Text('$_points очков заботы', style: TextStyle(color: AppColors.citrusGreen, fontSize: AppSize.s(14), fontWeight: FontWeight.w600)),
                ),
                AppSize.gapH(20),
                // Прогресс к следующей стадии
                if (!isMax) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('До «${next!.name}»', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12))),
                    Text('${_points - stage.min}/${next.min - stage.min}', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12))),
                  ]),
                  AppSize.gapH(8),
                  ClipRRect(
                    borderRadius: AppSize.radius(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.surface2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusGreen),
                    ),
                  ),
                ] else
                  Center(
                    child: Text('Твоё дерево расцвело! Так держать 🍊', style: TextStyle(color: AppColors.citrusGreen, fontSize: AppSize.s(13), fontWeight: FontWeight.w600)),
                  ),
                AppSize.gapH(24),
                // Из чего растёт
                Text('Из чего растёт дерево', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w700)),
                AppSize.gapH(4),
                Text('За последние 30 дней', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12))),
                AppSize.gapH(12),
                _contribRow('😊', 'Отметки настроения', _moodDays, '×1'),
                _contribRow('📔', 'Записи в дневник', _diaryCount, '×2'),
                _contribRow('🎓', 'Дни курсов', _courseDays, '×3'),
                AppSize.gapH(20),
                Container(
                  padding: AppSize.padding(14),
                  decoration: BoxDecoration(
                    color: AppColors.citrusGreen.withValues(alpha: 0.1),
                    borderRadius: AppSize.radius(14),
                    border: Border.all(color: AppColors.citrusGreen.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Text('🌱', style: TextStyle(fontSize: AppSize.s(20))),
                    AppSize.gapW(10),
                    Expanded(
                      child: Text(
                        'Отмечай настроение, веди дневник и проходи курсы — и дерево будет расти вместе с тобой.',
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(13), height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _contribRow(String emoji, String label, int count, String mult) {
    return Padding(
      padding: AppSize.paddingOnly(bottom: 10),
      child: Container(
        padding: AppSize.padding(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSize.radius(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Text(emoji, style: TextStyle(fontSize: AppSize.s(22))),
          AppSize.gapW(12),
          Expanded(child: Text(label, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w600))),
          Text('$count', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700)),
          AppSize.gapW(6),
          Container(
            padding: AppSize.paddingH(7, 3),
            decoration: BoxDecoration(color: AppColors.citrusGreen.withValues(alpha: 0.15), borderRadius: AppSize.radius(8)),
            child: Text(mult, style: TextStyle(color: AppColors.citrusGreen, fontSize: AppSize.s(11), fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
