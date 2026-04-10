import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class TestModel {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final bool completed;
  final int questionCount;
  final String duration;
  final List<String> questions;
  final List<String> options;

  const TestModel({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    this.completed = false,
    required this.questionCount,
    required this.duration,
    required this.questions,
    required this.options,
  });
}

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  final List<TestModel> tests = [
    TestModel(
      id: '1',
      emoji: '\u{1F9E0}',
      title: '\u0422\u0435\u0441\u0442 \u043D\u0430 \u0442\u0440\u0435\u0432\u043E\u0436\u043D\u043E\u0441\u0442\u044C',
      description: '\u041E\u0446\u0435\u043D\u0438\u0442\u0435 \u0443\u0440\u043E\u0432\u0435\u043D\u044C \u0442\u0440\u0435\u0432\u043E\u0433\u0438 \u043F\u043E \u0448\u043A\u0430\u043B\u0435 GAD-7',
      color: AppColors.citrusPurple,
      completed: true,
      questionCount: 7,
      duration: '3 \u043C\u0438\u043D',
      questions: [
        '\u0427\u0443\u0432\u0441\u0442\u0432\u043E\u0432\u0430\u043B\u0438 \u043B\u0438 \u0432\u044B \u043D\u0435\u0440\u0432\u043E\u0437\u043D\u043E\u0441\u0442\u044C \u0438\u043B\u0438 \u0442\u0440\u0435\u0432\u043E\u0433\u0443?',
        '\u041D\u0435 \u043C\u043E\u0433\u043B\u0438 \u0432\u044B \u043F\u0435\u0440\u0435\u0441\u0442\u0430\u0442\u044C \u0431\u0435\u0441\u043F\u043E\u043A\u043E\u0438\u0442\u044C\u0441\u044F?',
        '\u0411\u044B\u043B\u043E \u043B\u0438 \u0442\u0440\u0443\u0434\u043D\u043E \u0440\u0430\u0441\u0441\u043B\u0430\u0431\u0438\u0442\u044C\u0441\u044F?',
      ],
      options: ['\u041D\u0438\u043A\u043E\u0433\u0434\u0430', '\u0418\u043D\u043E\u0433\u0434\u0430', '\u0427\u0430\u0441\u0442\u043E', '\u041F\u043E\u0441\u0442\u043E\u044F\u043D\u043D\u043E'],
    ),
    TestModel(
      id: '2',
      emoji: '\u{1F4AD}',
      title: '\u0422\u0438\u043F \u043C\u044B\u0448\u043B\u0435\u043D\u0438\u044F',
      description: '\u041E\u043F\u0440\u0435\u0434\u0435\u043B\u0438\u0442\u0435 \u0432\u0430\u0448 \u0434\u043E\u043C\u0438\u043D\u0438\u0440\u0443\u044E\u0449\u0438\u0439 \u0442\u0438\u043F \u043C\u044B\u0448\u043B\u0435\u043D\u0438\u044F',
      color: AppColors.citrusPurple,
      completed: false,
      questionCount: 10,
      duration: '5 \u043C\u0438\u043D',
      questions: [
        '\u041A\u0430\u043A \u0432\u044B \u0447\u0430\u0449\u0435 \u0432\u0441\u0435\u0433\u043E \u0440\u0435\u0448\u0430\u0435\u0442\u0435 \u043F\u0440\u043E\u0431\u043B\u0435\u043C\u044B?',
        '\u0427\u0442\u043E \u0432\u0430\u043C \u0431\u043B\u0438\u0436\u0435: \u043B\u043E\u0433\u0438\u043A\u0430 \u0438\u043B\u0438 \u0438\u043D\u0442\u0443\u0438\u0446\u0438\u044F?',
      ],
      options: ['\u041B\u043E\u0433\u0438\u0447\u0435\u0441\u043A\u0438', '\u0418\u043D\u0442\u0443\u0438\u0442\u0438\u0432\u043D\u043E', '\u0422\u0432\u043E\u0440\u0447\u0435\u0441\u043A\u0438', '\u0410\u043D\u0430\u043B\u0438\u0442\u0438\u0447\u0435\u0441\u043A\u0438'],
    ),
    TestModel(
      id: '3',
      emoji: '\u{1F3AF}',
      title: '\u0412\u043D\u0438\u043C\u0430\u0442\u0435\u043B\u044C\u043D\u043E\u0441\u0442\u044C',
      description: '\u041F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u0441\u0432\u043E\u044E \u0441\u043F\u043E\u0441\u043E\u0431\u043D\u043E\u0441\u0442\u044C \u043A\u043E\u043D\u0446\u0435\u043D\u0442\u0440\u0438\u0440\u043E\u0432\u0430\u0442\u044C\u0441\u044F',
      color: const Color(0xFF4ECDC4),
      completed: false,
      questionCount: 8,
      duration: '4 \u043C\u0438\u043D',
      questions: [
        '\u0421\u043A\u043E\u043B\u044C\u043A\u043E \u0442\u0440\u0435\u0443\u0433\u043E\u043B\u044C\u043D\u0438\u043A\u043E\u0432 \u043D\u0430 \u043A\u0430\u0440\u0442\u0438\u043D\u043A\u0435?',
        '\u041D\u0430\u0439\u0434\u0438\u0442\u0435 \u043E\u0442\u043B\u0438\u0447\u0438\u0435 \u0432 \u0434\u0432\u0443\u0445 \u0438\u0437\u043E\u0431\u0440\u0430\u0436\u0435\u043D\u0438\u044F\u0445',
      ],
      options: ['3', '4', '5', '6'],
    ),
    TestModel(
      id: '4',
      emoji: '\u{1F9E9}',
      title: '\u041F\u0430\u043C\u044F\u0442\u044C',
      description: '\u0422\u0435\u0441\u0442 \u043D\u0430 \u043A\u0440\u0430\u0442\u043A\u043E\u0432\u0440\u0435\u043C\u0435\u043D\u043D\u0443\u044E \u043F\u0430\u043C\u044F\u0442\u044C',
      color: const Color(0xFFFF6B8A),
      completed: true,
      questionCount: 5,
      duration: '3 \u043C\u0438\u043D',
      questions: [
        '\u0417\u0430\u043F\u043E\u043C\u043D\u0438\u0442\u0435 5 \u0441\u043B\u043E\u0432 \u0438 \u0432\u043E\u0441\u043F\u0440\u043E\u0438\u0437\u0432\u0435\u0434\u0438\u0442\u0435 \u0438\u0445',
        '\u041A\u0430\u043A\u043E\u0435 \u0441\u043B\u043E\u0432\u043E \u0431\u044B\u043B\u043E \u0442\u0440\u0435\u0442\u044C\u0438\u043C?',
      ],
      options: ['\u041A\u043E\u0448\u043A\u0430', '\u0414\u043E\u043C', '\u0421\u0442\u043E\u043B', '\u0414\u0435\u0440\u0435\u0432\u043E'],
    ),
  ];

  int get completedTests => tests.where((t) => t.completed).length;
  int get totalTests => tests.length;

  void _openTestModal(TestModel test) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(opacity: animation, child: TestModal(test: test));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\u041F\u0441\u0438\u0445\u043E\u043B\u043E\u0433\u0438\u0447\u0435\u0441\u043A\u0438\u0435 \u0442\u0435\u0441\u0442\u044B',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  ...tests.map((test) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTestCard(test),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.citrusOrange.withOpacity(0.12), AppColors.citrusAmber.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.citrusOrange.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(
              painter: ProgressRingPainter(
                progress: completedTests / totalTests,
                color: AppColors.citrusOrange,
                strokeWidth: 4,
              ),
              child: Center(
                child: Text(
                  '$completedTests/$totalTests',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.citrusOrange),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u041F\u0440\u043E\u0433\u0440\u0435\u0441\u0441 \u0442\u0435\u0441\u0442\u043E\u0432',
                  style: TextStyle(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  '\u041F\u0440\u043E\u0434\u043E\u043B\u0436\u0430\u0439\u0442\u0435 \u043F\u0440\u043E\u0445\u043E\u0434\u0438\u0442\u044C \u0442\u0435\u0441\u0442\u044B!',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(TestModel test) {
    return GestureDetector(
      onTap: () => _openTestModal(test),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: test.completed ? test.color.withOpacity(0.25) : AppColors.subtleBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(test.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: const TextStyle(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    test.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${test.questionCount} \u0432\u043E\u043F\u0440\u043E\u0441\u043E\u0432',
                        style: const TextStyle(color: AppColors.dimForeground, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        test.duration,
                        style: const TextStyle(color: AppColors.dimForeground, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (test.completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: test.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '\u041F\u0440\u043E\u0439\u0434\u0435\u043D',
                  style: TextStyle(color: test.color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '\u041D\u0430\u0447\u0430\u0442\u044C',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class TestModal extends StatefulWidget {
  final TestModel test;
  const TestModal({super.key, required this.test});

  @override
  State<TestModal> createState() => _TestModalState();
}

class _TestModalState extends State<TestModal> {
  int currentQuestion = 0;
  String? selectedAnswer;
  bool isFinished = false;

  double get progress => isFinished ? 1.0 : (currentQuestion + 1) / widget.test.questions.length;

  void _nextQuestion() {
    if (currentQuestion < widget.test.questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
      });
    } else {
      setState(() => isFinished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.withOpacity(0.95),
      body: SafeArea(
        child: isFinished ? _buildCompletionScreen() : _buildQuizContent(),
      ),
    );
  }

  Widget _buildQuizContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.foreground),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.test.title,
                          style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '\u0412\u043E\u043F\u0440\u043E\u0441 ${currentQuestion + 1} \u0438\u0437 ${widget.test.questions.length}',
                          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.test.color, widget.test.color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.test.questions[currentQuestion],
                  style: const TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                ...widget.test.options.map((option) {
                  final isSelected = selectedAnswer == option;
                  return GestureDetector(
                    onTap: () => setState(() => selectedAnswer = option),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? widget.test.color : Colors.white.withOpacity(0.08),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? widget.test.color : Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                              color: isSelected ? widget.test.color : Colors.transparent,
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: isSelected ? widget.test.color : AppColors.foreground,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (selectedAnswer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.test.color, widget.test.color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.test.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    currentQuestion < widget.test.questions.length - 1 ? '\u0414\u0430\u043B\u0435\u0435' : '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044C',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u{1F389}', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              '\u0422\u0435\u0441\u0442 \u0437\u0430\u0432\u0435\u0440\u0448\u0451\u043D!',
              style: TextStyle(color: widget.test.color, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '\u0412\u044B \u0443\u0441\u043F\u0435\u0448\u043D\u043E \u043F\u0440\u043E\u0448\u043B\u0438 \u0442\u0435\u0441\u0442',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.test.color.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.test.title,
                    style: TextStyle(color: widget.test.color, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\u041E\u0442\u0432\u0435\u0447\u0435\u043D\u043E: ${widget.test.questions.length}/${widget.test.questions.length}',
                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface1,
                  foregroundColor: AppColors.foreground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: widget.test.color.withOpacity(0.25)),
                  ),
                ),
                child: const Text(
                  '\u0412\u0435\u0440\u043D\u0443\u0442\u044C\u0441\u044F \u043A \u0442\u0435\u0441\u0442\u0430\u043C',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
