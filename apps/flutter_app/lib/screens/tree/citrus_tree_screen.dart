import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/app_size.dart';
import '../../core/widgets/citrus_card.dart';
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
    final green = AppColors.citrusGreen;
    final stage = _stages[_stageIndex];
    final isMax = _stageIndex == _stages.length - 1;
    final next = isMax ? null : _stages[_stageIndex + 1];
    final progress = isMax
        ? 1.0
        : ((_points - stage.min) / (next!.min - stage.min)).clamp(0.0, 1.0);
    final remain = isMax ? 0 : (next!.min - _points);

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
          ? Center(child: CircularProgressIndicator(color: green))
          : ListView(
              padding: AppSize.padding(20),
              children: [
                AppSize.gapH(8),
                // Дерево в кольце прогресса
                Center(child: _buildRing(stage, progress, green)),
                AppSize.gapH(22),
                Center(
                  child: Text(stage.name, style: AppText.displayTitle),
                ),
                AppSize.gapH(8),
                // Пилюля статуса
                Center(
                  child: Container(
                    padding: AppSize.paddingH(14, 7),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.14),
                      borderRadius: AppSize.radius(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('🌿', style: TextStyle(fontSize: AppSize.s(13))),
                      AppSize.gapW(6),
                      Text(
                        isMax ? '$_points очков · максимум!' : '$_points очков · ещё $remain до «${next!.name}»',
                        style: TextStyle(color: green, fontSize: AppSize.s(12.5), fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                ),
                AppSize.gapH(24),
                // Путь стадий
                _buildJourney(green),
                AppSize.gapH(26),
                // Из чего растёт
                Text('Из чего растёт дерево', style: AppText.sectionTitle),
                AppSize.gapH(3),
                Text('За последние 30 дней', style: AppText.caption),
                AppSize.gapH(12),
                _contribRow('🍊', 'Отметки настроения', _moodDays, '×1', AppColors.citrusOrange),
                _contribRow('📔', 'Записи в дневник', _diaryCount, '×2', AppColors.citrusPurple),
                _contribRow('🎓', 'Дни курсов', _courseDays, '×3', green),
                AppSize.gapH(18),
                CitrusCard(
                  color: green.withValues(alpha: 0.1),
                  accent: green,
                  padding: AppSize.padding(14),
                  child: Row(children: [
                    Text('🌱', style: TextStyle(fontSize: AppSize.s(20))),
                    AppSize.gapW(10),
                    Expanded(
                      child: Text(
                        'Отмечай настроение, веди дневник и проходи курсы — и дерево будет расти вместе с тобой.',
                        style: AppText.bodyMuted,
                      ),
                    ),
                  ]),
                ),
                AppSize.gapH(26),
                _buildAchievements(green),
              ],
            ),
    );
  }

  /// Достижения — бейджи по вехам заботы о себе (за последние 30 дней + очки).
  Widget _buildAchievements(Color green) {
    final items = <(String, String, int, int)>[
      ('🌱', 'Первый шаг', _moodDays, 1),
      ('📅', 'Неделя заботы', _moodDays, 7),
      ('📔', 'Писатель', _diaryCount, 5),
      ('🎓', 'Ученик', _courseDays, 5),
      ('✨', 'Усердие', _points, 50),
      ('🍊', 'Полный расцвет', _points, 140),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Достижения', style: AppText.sectionTitle),
      AppSize.gapH(3),
      Text('Открываются по мере заботы о себе', style: AppText.caption),
      AppSize.gapH(12),
      ...items.map((it) {
        final cur = it.$3;
        final target = it.$4;
        final unlocked = cur >= target;
        final progress = (cur / target).clamp(0.0, 1.0).toDouble();
        final c = unlocked ? green : AppColors.dimForeground;
        return Padding(
          padding: AppSize.paddingOnly(bottom: 10),
          child: CitrusCard(
            accent: unlocked ? green : null,
            padding: AppSize.padding(14),
            child: Row(children: [
              Opacity(
                opacity: unlocked ? 1 : 0.45,
                child: Container(
                  width: AppSize.s(44),
                  height: AppSize.s(44),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: Center(child: Text(it.$1, style: TextStyle(fontSize: AppSize.s(22)))),
                ),
              ),
              AppSize.gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.$2, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  AppSize.gapH(6),
                  ClipRRect(
                    borderRadius: AppSize.radius(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surface2,
                      valueColor: AlwaysStoppedAnimation<Color>(unlocked ? green : AppColors.citrusOrange),
                    ),
                  ),
                ]),
              ),
              AppSize.gapW(10),
              unlocked
                  ? Icon(Icons.verified_rounded, color: green, size: AppSize.s(22))
                  : Text('$cur/$target', style: AppText.caption),
            ]),
          ),
        );
      }),
    ]);
  }

  /// Дерево в анимированном кольце прогресса к следующей стадии.
  Widget _buildRing(_Stage stage, double progress, Color green) {
    final size = AppSize.s(210);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Кольцо прогресса
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: AppSize.s(8),
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(green),
            ),
          ),
          // Свечение + маскот (с лёгким пульсом)
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Transform.scale(scale: 1.0 + 0.04 * _pulse.value, child: child),
            child: Container(
              width: AppSize.s(168),
              height: AppSize.s(168),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  green.withValues(alpha: 0.25),
                  green.withValues(alpha: 0.04),
                ]),
                boxShadow: [BoxShadow(color: green.withValues(alpha: 0.3), blurRadius: 44, spreadRadius: 4)],
              ),
              child: Center(child: Text(stage.emoji, style: TextStyle(fontSize: AppSize.s(86)))),
            ),
          ),
        ],
      ),
    );
  }

  /// Горизонтальный «путь» из шести стадий: пройденные — зелёные, текущая —
  /// выделена свечением, будущие — приглушены.
  Widget _buildJourney(Color green) {
    final current = _stageIndex;
    final nodes = <Widget>[];
    for (int i = 0; i < _stages.length; i++) {
      final reached = i <= current;
      final isCurrent = i == current;
      nodes.add(Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: AppSize.s(36),
          height: AppSize.s(36),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? green.withValues(alpha: 0.16) : AppColors.surface1,
            border: Border.all(
              color: isCurrent ? green : (reached ? green.withValues(alpha: 0.4) : AppColors.subtleBorder),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent ? [BoxShadow(color: green.withValues(alpha: 0.35), blurRadius: 12)] : null,
          ),
          child: Center(
            child: Opacity(
              opacity: reached ? 1 : 0.4,
              child: Text(_stages[i].emoji, style: TextStyle(fontSize: AppSize.s(17))),
            ),
          ),
        ),
      ]));
      if (i < _stages.length - 1) {
        nodes.add(Expanded(
          child: Container(
            height: AppSize.s(2),
            margin: AppSize.paddingH(2, 0),
            color: i < current ? green.withValues(alpha: 0.5) : AppColors.subtleBorder,
          ),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Путь роста', style: AppText.sectionTitle),
      AppSize.gapH(12),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: nodes),
    ]);
  }

  Widget _contribRow(String emoji, String label, int count, String mult, Color color) {
    return Padding(
      padding: AppSize.paddingOnly(bottom: 10),
      child: CitrusCard(
        padding: AppSize.padding(14),
        child: Row(children: [
          Container(
            width: AppSize.s(40),
            height: AppSize.s(40),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: AppSize.radius(12)),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: AppSize.s(20)))),
          ),
          AppSize.gapW(12),
          Expanded(child: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
          Text('$count', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700)),
          AppSize.gapW(6),
          Container(
            padding: AppSize.paddingH(7, 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSize.radius(8)),
            child: Text(mult, style: TextStyle(color: color, fontSize: AppSize.s(11), fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
