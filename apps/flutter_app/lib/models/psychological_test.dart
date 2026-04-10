/// Модель психологического теста

class PsychologicalTest {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category; // 'personality', 'clinical', 'behavioral'
  final int durationMinutes;
  final List<TestQuestion> questions;
  final Map<String, ScoringScale> scoringScales;

  const PsychologicalTest({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.durationMinutes,
    required this.questions,
    required this.scoringScales,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'category': category,
        'durationMinutes': durationMinutes,
        'questions': questions.map((q) => q.toJson()).toList(),
        'scoringScales':
            scoringScales.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory PsychologicalTest.fromJson(Map<String, dynamic> json) =>
      PsychologicalTest(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        category: json['category'] as String,
        durationMinutes: json['durationMinutes'] as int,
        questions: (json['questions'] as List)
            .map((q) => TestQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        scoringScales: (json['scoringScales'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, ScoringScale.fromJson(v as Map<String, dynamic>)),
        ),
      );
}

class TestQuestion {
  final int id;
  final String text;
  final List<String> options; // Варианты ответов
  final Map<String, int> scoring; // {scale_name: score}

  const TestQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.scoring,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'scoring': scoring,
      };

  factory TestQuestion.fromJson(Map<String, dynamic> json) => TestQuestion(
        id: json['id'] as int,
        text: json['text'] as String,
        options: (json['options'] as List).map((e) => e as String).toList(),
        scoring: (json['scoring'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
      );
}

class ScoringScale {
  final String name;
  final String label;
  final String description;
  final int minScore;
  final int maxScore;
  final List<ScoreInterpretation> interpretations;

  const ScoringScale({
    required this.name,
    required this.label,
    required this.description,
    required this.minScore,
    required this.maxScore,
    required this.interpretations,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'description': description,
        'minScore': minScore,
        'maxScore': maxScore,
        'interpretations': interpretations.map((i) => i.toJson()).toList(),
      };

  factory ScoringScale.fromJson(Map<String, dynamic> json) => ScoringScale(
        name: json['name'] as String,
        label: json['label'] as String,
        description: json['description'] as String,
        minScore: json['minScore'] as int,
        maxScore: json['maxScore'] as int,
        interpretations: (json['interpretations'] as List)
            .map((i) =>
                ScoreInterpretation.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class ScoreInterpretation {
  final String level;
  final String label;
  final String description;
  final int minScore;
  final int maxScore;

  const ScoreInterpretation({
    required this.level,
    required this.label,
    required this.description,
    required this.minScore,
    required this.maxScore,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'label': label,
        'description': description,
        'minScore': minScore,
        'maxScore': maxScore,
      };

  factory ScoreInterpretation.fromJson(Map<String, dynamic> json) =>
      ScoreInterpretation(
        level: json['level'] as String,
        label: json['label'] as String,
        description: json['description'] as String,
        minScore: json['minScore'] as int,
        maxScore: json['maxScore'] as int,
      );
}

class TestResult {
  final String testId;
  final Map<String, int> scores;
  final Map<String, String> interpretations;
  final DateTime completedAt;

  const TestResult({
    required this.testId,
    required this.scores,
    required this.interpretations,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'scores': scores,
        'interpretations': interpretations,
        'completedAt': completedAt.toIso8601String(),
      };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        testId: json['testId'] as String,
        scores: (json['scores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
        interpretations: (json['interpretations'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}
