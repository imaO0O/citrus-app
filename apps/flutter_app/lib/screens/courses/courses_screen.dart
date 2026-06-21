import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/services/course_prefs_service.dart';
import '../../data/courses/courses.dart';

// ─────────────────────────── Список курсов ───────────────────────────

class CoursesListScreen extends StatefulWidget {
  CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final CoursePrefsService _prefs = CoursePrefsService();
  final Map<String, int> _doneCount = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    for (final c in kCourses) {
      final p = await _prefs.getProgress(c.id);
      _doneCount[c.id] = p.doneDays.length;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Программы самопомощи',
            style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(20), fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: AppSize.padding(16),
        children: [
          Text(
            'Короткие курсы по 5 дней: теория, упражнение и рефлексия. Открывается по одному дню в день — так привычка закрепляется.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), height: 1.5),
          ),
          AppSize.gapH(16),
          ...kCourses.map((c) {
            final done = _doneCount[c.id] ?? 0;
            final total = c.days.length;
            final progress = total == 0 ? 0.0 : done / total;
            final started = done > 0;
            final finished = done >= total;
            return Padding(
              padding: AppSize.paddingOnly(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CourseDetailScreen(course: c)),
                  );
                  _loadProgress();
                },
                child: Container(
                  padding: AppSize.padding(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppSize.radius(18),
                    border: Border.all(color: c.color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: AppSize.s(48),
                          height: AppSize.s(48),
                          decoration: BoxDecoration(color: c.color.withValues(alpha: 0.15), borderRadius: AppSize.radius(14)),
                          child: Center(child: Text(c.emoji, style: TextStyle(fontSize: AppSize.s(24)))),
                        ),
                        AppSize.gapW(14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700)),
                            AppSize.gapH(3),
                            Text(c.subtitle, style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12), height: 1.3)),
                          ]),
                        ),
                      ]),
                      AppSize.gapH(14),
                      ClipRRect(
                        borderRadius: AppSize.radius(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surface2,
                          valueColor: AlwaysStoppedAnimation<Color>(c.color),
                        ),
                      ),
                      AppSize.gapH(8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('$done из $total дней', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12))),
                        Text(
                          finished ? 'Завершён ✓' : (started ? 'Продолжить →' : 'Начать →'),
                          style: TextStyle(color: c.color, fontSize: AppSize.s(13), fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────── Дни курса ───────────────────────────

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CoursePrefsService _prefs = CoursePrefsService();
  CourseProgress _progress = CourseProgress(<int, DateTime>{}, <int, String>{});
  bool _loading = true;

  Course get course => widget.course;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _prefs.getProgress(course.id);
    if (mounted) setState(() { _progress = p; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final total = course.days.length;
    final done = _progress.doneDays.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.foreground), onPressed: () => Navigator.pop(context)),
        title: Text(course.title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: course.color))
          : ListView(
              padding: AppSize.padding(16),
              children: [
                Container(
                  padding: AppSize.padding(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [course.color.withValues(alpha: 0.3), course.color.withValues(alpha: 0.1)],
                    ),
                    borderRadius: AppSize.radius(18),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(course.emoji, style: TextStyle(fontSize: AppSize.s(32))),
                      AppSize.gapW(12),
                      Expanded(child: Text(course.subtitle, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w600, height: 1.3))),
                    ]),
                    AppSize.gapH(14),
                    ClipRRect(
                      borderRadius: AppSize.radius(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        minHeight: 6,
                        backgroundColor: Colors.black.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(course.color),
                      ),
                    ),
                    AppSize.gapH(8),
                    Text('Пройдено $done из $total дней', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(12))),
                  ]),
                ),
                AppSize.gapH(20),
                if (done >= total && total > 0) ...[
                  _buildCompletedBanner(),
                  AppSize.gapH(20),
                ],
                ...List.generate(course.days.length, (i) => _buildDayTile(i)),
              ],
            ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      padding: AppSize.padding(18),
      decoration: BoxDecoration(
        color: AppColors.citrusGreen.withValues(alpha: 0.12),
        borderRadius: AppSize.radius(18),
        border: Border.all(color: AppColors.citrusGreen.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Text('🎉', style: TextStyle(fontSize: AppSize.s(40))),
        AppSize.gapH(8),
        Text('Курс пройден!', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w800)),
        AppSize.gapH(6),
        Text(
          'Ты прошёл(а) все дни 🌟 Возвращайся к материалам когда угодно или начни курс заново.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), height: 1.4),
        ),
        AppSize.gapH(14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _confirmRestart,
              icon: Icon(Icons.replay, size: AppSize.s(18)),
              label: Text('Заново'),
              style: OutlinedButton.styleFrom(
                foregroundColor: course.color,
                side: BorderSide(color: course.color.withValues(alpha: 0.5)),
                padding: AppSize.paddingH(0, 12),
                shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)),
              ),
            ),
          ),
          AppSize.gapW(10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.grid_view, size: AppSize.s(18)),
              label: Text('К курсам'),
              style: ElevatedButton.styleFrom(
                backgroundColor: course.color,
                foregroundColor: Colors.white,
                padding: AppSize.paddingH(0, 12),
                shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  void _confirmRestart() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        title: Text('Начать заново?', style: TextStyle(color: AppColors.foreground)),
        content: Text('Прогресс по курсу будет сброшен.', style: TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _prefs.resetCourse(course.id);
              _load();
            },
            style: FilledButton.styleFrom(backgroundColor: course.color),
            child: Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTile(int i) {
    final day = course.days[i];
    final isDone = _progress.isDone(i);
    final unlocked = _progress.isUnlocked(i);
    final unlockDate = _progress.unlockDate(i);
    final lockNote = unlocked
        ? null
        : (unlockDate != null ? 'Откроется завтра' : 'Сначала пройди предыдущий день');

    final Color leadColor = isDone ? AppColors.citrusGreen : (unlocked ? course.color : AppColors.dimForeground);
    final IconData leadIcon = isDone
        ? Icons.check_circle
        : (unlocked ? Icons.play_circle_fill : (unlockDate != null ? Icons.lock_clock : Icons.lock));

    return Padding(
      padding: AppSize.paddingOnly(bottom: 10),
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: GestureDetector(
          onTap: unlocked
              ? () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => CourseDayScreen(course: course, dayIndex: i)),
                  );
                  if (changed == true) _load();
                }
              : null,
          child: Container(
            padding: AppSize.padding(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppSize.radius(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(children: [
              Icon(leadIcon, color: leadColor, size: AppSize.s(26)),
              AppSize.gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('День ${i + 1}', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(11), fontWeight: FontWeight.w600)),
                  AppSize.gapH(2),
                  Text(day.title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w600)),
                  if (lockNote != null) ...[
                    AppSize.gapH(2),
                    Text(lockNote, style: TextStyle(color: unlockDate != null ? AppColors.citrusAmber : AppColors.dimForeground, fontSize: AppSize.s(11))),
                  ],
                ]),
              ),
              if (unlocked) Icon(Icons.chevron_right, color: AppColors.dimForeground, size: AppSize.s(20)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Экран дня ───────────────────────────

class CourseDayScreen extends StatefulWidget {
  final Course course;
  final int dayIndex;
  const CourseDayScreen({super.key, required this.course, required this.dayIndex});

  @override
  State<CourseDayScreen> createState() => _CourseDayScreenState();
}

class _CourseDayScreenState extends State<CourseDayScreen> {
  final CoursePrefsService _prefs = CoursePrefsService();
  final TextEditingController _reflection = TextEditingController();
  bool _saving = false;
  bool _alreadyDone = false;

  Course get course => widget.course;
  CourseDay get day => course.days[widget.dayIndex];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final p = await _prefs.getProgress(course.id);
    if (mounted) {
      setState(() {
        _alreadyDone = p.isDone(widget.dayIndex);
        _reflection.text = p.reflections[widget.dayIndex] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _reflection.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    await _prefs.completeDay(course.id, widget.dayIndex, _reflection.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_alreadyDone ? 'Сохранено' : 'День завершён!'), backgroundColor: AppColors.citrusGreen),
    );
    Navigator.pop(context, true);
  }

  MarkdownStyleSheet _md() => MarkdownStyleSheet(
        p: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(15), height: 1.6),
        strong: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.bold),
        listBullet: TextStyle(color: course.color, fontSize: AppSize.s(15)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.foreground), onPressed: () => Navigator.pop(context)),
        title: Text('День ${widget.dayIndex + 1}', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: AppSize.padding(20),
        children: [
          Text(day.title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(22), fontWeight: FontWeight.bold, height: 1.3)),
          AppSize.gapH(16),
          MarkdownBody(data: day.theory, styleSheet: _md()),
          AppSize.gapH(20),
          // Упражнение
          Container(
            padding: AppSize.padding(16),
            decoration: BoxDecoration(
              color: course.color.withValues(alpha: 0.1),
              borderRadius: AppSize.radius(16),
              border: Border.all(color: course.color.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.fitness_center, size: AppSize.s(16), color: course.color),
                AppSize.gapW(8),
                Text('Упражнение', style: TextStyle(color: course.color, fontSize: AppSize.s(13), fontWeight: FontWeight.w700)),
              ]),
              AppSize.gapH(10),
              MarkdownBody(data: day.exercise, styleSheet: _md()),
            ]),
          ),
          AppSize.gapH(20),
          // Рефлексия
          Text('Рефлексия', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700)),
          AppSize.gapH(6),
          Text(day.reflectionPrompt, style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), height: 1.4)),
          AppSize.gapH(10),
          TextField(
            controller: _reflection,
            style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14)),
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Запиши пару мыслей…',
              hintStyle: TextStyle(color: AppColors.dimForeground),
              filled: true,
              fillColor: AppColors.surface1,
              border: OutlineInputBorder(borderRadius: AppSize.radius(14), borderSide: BorderSide.none),
            ),
          ),
          AppSize.gapH(20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _complete,
              icon: _saving
                  ? SizedBox(width: AppSize.s(18), height: AppSize.s(18), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_alreadyDone ? Icons.save : Icons.check),
              label: Text(_alreadyDone ? 'Сохранить' : 'Завершить день'),
              style: ElevatedButton.styleFrom(
                backgroundColor: course.color,
                foregroundColor: Colors.white,
                padding: AppSize.paddingH(0, 15),
                shape: RoundedRectangleBorder(borderRadius: AppSize.radius(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
