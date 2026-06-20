import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/psychological_test.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/test_api_service.dart';
import '../../core/utils/app_size.dart';
import '../../features/articles/pages/articles_page.dart';
import '../exercises_screen.dart';
import '../help_screen.dart';
import 'test_taking_screen.dart';

class TestResultScreen extends StatefulWidget {
  final PsychologicalTest test;
  final Map<String, int> scores;
  final Map<String, ScoreInterpretation?> interpretations;
  final String? token;

  TestResultScreen({
    super.key,
    required this.test,
    required this.scores,
    required this.interpretations,
    this.token,
  });

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  Map<String, int>? _previousScores;
  List<_PastResult> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (widget.token == null || widget.token!.isEmpty) return;
    try {
      final api = TestApiService(token: widget.token);
      final results = await api.getTestResult(widget.test.id); // DESC по дате
      final parsed = <_PastResult>[];
      for (final r in results) {
        final date = DateTime.tryParse(r['completedAt']?.toString() ?? '');
        parsed.add(_PastResult(date: date, scores: _parseScores(r['scores'])));
      }
      // results[0] — текущее прохождение, [1] — предыдущее
      if (parsed.length > 1) {
        _previousScores = parsed[1].scores;
      }
      if (mounted) setState(() => _history = parsed);
    } catch (_) {
      // история не критична — молча пропускаем
    }
  }

  /// Баллы в БД хранятся как JSON с ключами вида `question_<шкала>`.
  Map<String, int> _parseScores(dynamic raw) {
    final out = <String, int>{};
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is Map) {
        decoded.forEach((k, v) {
          final key = k.toString().replaceFirst('question_', '');
          final val = v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
          if (val != null) out[key] = val;
        });
      }
    } catch (_) {}
    return out;
  }

  // ---- Тяжесть и рекомендации ----

  int _rank(String? level) {
    switch (level) {
      case 'moderately_severe':
      case 'high':
      case 'severe':
      case 'extremely_severe':
        return 3;
      case 'moderate':
        return 2;
      case 'mild':
      case 'medium':
        return 1;
      default:
        return 0;
    }
  }

  int get _maxRank =>
      widget.interpretations.values.map((i) => _rank(i?.level)).fold(0, (a, b) => a > b ? a : b);

  /// Категория статей по тесту (null = немедицинский тест, без рекомендаций).
  String? get _articleCategory {
    switch (widget.test.id) {
      case 'phq9':
        return 'depression';
      case 'gad7':
        return 'anxiety';
      case 'dass21':
        return 'stress';
      case 'rosenberg_self_esteem':
        return 'self-esteem';
      default:
        return null;
    }
  }

  /// Для симптомных шкал меньше = лучше; для самооценки больше = лучше.
  bool? get _lowerIsBetter {
    switch (widget.test.id) {
      case 'phq9':
      case 'gad7':
      case 'dass21':
        return true;
      case 'rosenberg_self_esteem':
        return false;
      default:
        return null;
    }
  }

  void _openExercises() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ExercisesScreen()));

  void _openHelp() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => HelpScreen()));

  void _openArticles(String category) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticlesPage(showBackButton: true, initialCategory: category)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Результаты',
          style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(20), fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSize.padding(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Center(
              child: Column(
                children: [
                  Text(widget.test.icon, style: TextStyle(fontSize: AppSize.s(64))),
                  AppSize.gapH(16),
                  Text(
                    widget.test.title,
                    style: TextStyle(fontSize: AppSize.s(24), fontWeight: FontWeight.w700, color: AppColors.foreground),
                    textAlign: TextAlign.center,
                  ),
                  AppSize.gapH(8),
                  Text(
                    'Завершено ${_formatDate(DateTime.now())}',
                    style: TextStyle(fontSize: AppSize.s(12), color: AppColors.dimForeground),
                  ),
                ],
              ),
            ),
            AppSize.gapH(32),

            // Рекомендации по результату
            if (_articleCategory != null) ...[
              _buildRecommendations(),
              AppSize.gapH(24),
            ],

            // Результаты по шкалам
            Text(
              'Ваши результаты',
              style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w600, color: AppColors.foreground),
            ),
            AppSize.gapH(16),
            ...widget.scores.entries.map((entry) {
              final scale = widget.test.scoringScales[entry.key];
              final interpretation = widget.interpretations[entry.key];
              if (scale == null) return const SizedBox.shrink();
              return Padding(
                padding: AppSize.paddingOnly(bottom: 16),
                child: _ScaleResultCard(
                  scale: scale,
                  score: entry.value,
                  interpretation: interpretation,
                  previousScore: _previousScores?[entry.key],
                  lowerIsBetter: _lowerIsBetter,
                ),
              );
            }),

            // История прохождений
            if (_history.length > 1) ...[
              AppSize.gapH(8),
              _buildHistory(),
            ],

            AppSize.gapH(24),

            // Дисклеймер
            Container(
              padding: AppSize.padding(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppSize.radius(12),
                border: Border.all(color: AppColors.citrusOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.citrusOrange, size: 24),
                  AppSize.gapW(12),
                  Expanded(
                    child: Text(
                      'Этот тест носит информационный характер. Для профессиональной консультации обратитесь к специалисту.',
                      style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ),
            AppSize.gapH(24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => TestTakingScreen(testId: widget.test.id, token: widget.token),
                        ),
                      );
                    },
                    icon: Icon(Icons.replay),
                    label: Text('Пройти снова'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.foreground,
                      side: BorderSide(color: AppColors.dimForeground),
                      padding: AppSize.paddingH(0, 16),
                      shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)),
                    ),
                  ),
                ),
                AppSize.gapW(12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.list),
                    label: Text('Все тесты'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.citrusOrange,
                      foregroundColor: AppColors.primaryForeground,
                      padding: AppSize.paddingH(0, 16),
                      shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final category = _articleCategory!;
    final high = _maxRank >= 2;
    final color = high ? AppColors.destructive : AppColors.citrusGreen;

    Widget item(IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: AppSize.radius(12),
          child: Padding(
            padding: AppSize.paddingH(0, 10),
            child: Row(children: [
              Container(
                width: AppSize.s(34),
                height: AppSize.s(34),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSize.radius(10)),
                child: Icon(icon, size: AppSize.s(18), color: color),
              ),
              AppSize.gapW(12),
              Expanded(child: Text(label, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right, size: AppSize.s(20), color: AppColors.dimForeground),
            ]),
          ),
        );

    return Container(
      padding: AppSize.paddingH(16, 6),
      decoration: BoxDecoration(
        color: high ? AppColors.destructive.withValues(alpha: 0.08) : AppColors.card,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppSize.gapH(12),
        Row(children: [
          Icon(high ? Icons.favorite : Icons.lightbulb_outline, size: AppSize.s(18), color: color),
          AppSize.gapW(8),
          Expanded(
            child: Text(
              high ? 'Возможно, стоит обратиться за поддержкой' : 'Что может помочь',
              style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        if (high) ...[
          AppSize.gapH(6),
          Text(
            'Результаты выше среднего — это не диагноз. Если состояние беспокоит, поговорите со специалистом или близким.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12), height: 1.5),
          ),
        ],
        AppSize.gapH(4),
        if (high) item(Icons.support_agent, 'Получить помощь', _openHelp),
        item(Icons.self_improvement, 'Дыхательное упражнение', _openExercises),
        item(Icons.menu_book, 'Статьи по теме', () => _openArticles(category)),
        AppSize.gapH(8),
      ]),
    );
  }

  Widget _buildHistory() {
    final past = _history.skip(1).take(5).toList(); // без текущего
    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.foreground.withValues(alpha: 0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.history, size: AppSize.s(16), color: AppColors.mutedForeground),
          AppSize.gapW(8),
          Text('История прохождений', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w700)),
        ]),
        AppSize.gapH(12),
        ...past.map((r) {
          final total = r.scores.values.fold<int>(0, (a, b) => a + b);
          return Padding(
            padding: AppSize.paddingOnly(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(r.date != null ? _formatDate(r.date!) : '—', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
              Text('сумма баллов: $total', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12))),
            ]),
          );
        }),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _PastResult {
  final DateTime? date;
  final Map<String, int> scores;
  _PastResult({required this.date, required this.scores});
}

class _ScaleResultCard extends StatelessWidget {
  final ScoringScale scale;
  final int score;
  final ScoreInterpretation? interpretation;
  final int? previousScore;
  final bool? lowerIsBetter;

  _ScaleResultCard({
    required this.scale,
    required this.score,
    required this.interpretation,
    this.previousScore,
    this.lowerIsBetter,
  });

  double get _progress {
    final range = scale.maxScore - scale.minScore;
    if (range == 0) return 0;
    return (score - scale.minScore) / range;
  }

  Color get _levelColor {
    switch (interpretation?.level) {
      case 'low':
      case 'normal':
      case 'minimal':
        return Color(0xFF8BC34A);
      case 'medium':
      case 'mild':
        return Color(0xFFFFD93D);
      case 'moderate':
        return AppColors.citrusOrange;
      case 'high':
      case 'severe':
      case 'moderately_severe':
      case 'extremely_severe':
        return AppColors.destructive;
      default:
        return AppColors.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.foreground.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  scale.label,
                  style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
              ),
              Text(
                '$score / ${scale.maxScore}',
                style: TextStyle(fontSize: AppSize.s(14), fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
              ),
            ],
          ),
          AppSize.gapH(12),
          ClipRRect(
            borderRadius: AppSize.radius(4),
            child: LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.muted,
              valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
              minHeight: 8,
            ),
          ),
          AppSize.gapH(12),
          Row(children: [
            if (interpretation != null)
              Container(
                padding: AppSize.paddingH(10, 4),
                decoration: BoxDecoration(color: _levelColor.withValues(alpha: 0.15), borderRadius: AppSize.radius(8)),
                child: Text(
                  interpretation!.label,
                  style: TextStyle(fontSize: AppSize.s(12), fontWeight: FontWeight.w600, color: _levelColor),
                ),
              ),
            if (previousScore != null) ...[
              AppSize.gapW(8),
              _buildDelta(),
            ],
          ]),
          if (interpretation != null) ...[
            AppSize.gapH(8),
            Text(
              interpretation!.description,
              style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDelta() {
    final delta = score - previousScore!;
    if (delta == 0) {
      return Container(
        padding: AppSize.paddingH(8, 4),
        decoration: BoxDecoration(color: AppColors.muted, borderRadius: AppSize.radius(8)),
        child: Text('без изменений', style: TextStyle(fontSize: AppSize.s(11), color: AppColors.mutedForeground)),
      );
    }
    final up = delta > 0;
    // Цвет по смыслу: для симптомных шкал рост = хуже.
    Color c;
    if (lowerIsBetter == null) {
      c = AppColors.mutedForeground;
    } else {
      final improved = lowerIsBetter! ? delta < 0 : delta > 0;
      c = improved ? AppColors.citrusGreen : AppColors.destructive;
    }
    return Container(
      padding: AppSize.paddingH(8, 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: AppSize.radius(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: AppSize.s(12), color: c),
        AppSize.gapW(3),
        Text('было $previousScore', style: TextStyle(fontSize: AppSize.s(11), color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
