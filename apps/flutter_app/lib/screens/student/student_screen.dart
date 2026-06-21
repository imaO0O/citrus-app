import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/services/storage_service.dart';
import '../../services/notification_service.dart';

/// Студенческий уголок: Pomodoro, отсчёт до экзаменов, экспресс-чек выгорания.
class StudentScreen extends StatefulWidget {
  StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  // Pomodoro
  static const _workMin = 25;
  static const _breakMin = 5;
  bool _isWork = true;
  bool _running = false;
  int _remaining = _workMin * 60;
  int _cycles = 0;
  Timer? _timer;

  // Экзамены
  static const _examsKey = 'student_exams';
  List<Map<String, String>> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────── Pomodoro ───────────────────

  int get _phaseTotal => (_isWork ? _workMin : _breakMin) * 60;

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        _switchPhase();
      }
    });
  }

  void _switchPhase() {
    HapticFeedback.mediumImpact();
    final wasWork = _isWork;
    setState(() {
      if (wasWork) _cycles++;
      _isWork = !wasWork;
      _remaining = _phaseTotal;
    });
    final title = wasWork ? '⏱️ Время перерыва' : '📚 Снова за работу';
    final body = wasWork ? 'Отдохни $_breakMin минут — встань, потянись, попей воды.' : 'Перерыв окончен. Сфокусируйся на задаче.';
    try {
      NotificationService().showInstantNotification(title: title, body: body, channelId: 'pomodoro');
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(title),
        backgroundColor: wasWork ? AppColors.citrusGreen : AppColors.citrusOrange,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _isWork = true;
      _remaining = _workMin * 60;
    });
  }

  void _skipPhase() {
    setState(() => _remaining = 0);
    if (!_running) _switchPhase();
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ─────────────────── Экзамены ───────────────────

  Future<void> _loadExams() async {
    final raw = await StorageService().getString(_examsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => Map<String, String>.from(e as Map)).toList();
      list.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
      if (mounted) setState(() => _exams = list);
    } catch (_) {}
  }

  Future<void> _saveExams() async {
    await StorageService().setString(_examsKey, jsonEncode(_exams));
  }

  Future<void> _addExam() async {
    final nameCtrl = TextEditingController();
    DateTime? date;
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.surface1,
          shape: RoundedRectangleBorder(borderRadius: AppSize.radius(16)),
          title: Text('Новый экзамен', style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: AppColors.foreground),
              decoration: InputDecoration(
                hintText: 'Предмет / название',
                hintStyle: TextStyle(color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: AppSize.radius(12), borderSide: BorderSide.none),
              ),
              autofocus: true,
            ),
            AppSize.gapH(12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event, color: AppColors.citrusOrange),
              title: Text(
                date == null ? 'Выбрать дату' : '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}',
                style: TextStyle(color: AppColors.foreground),
              ),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(context: ctx, initialDate: now, firstDate: now, lastDate: DateTime(now.year + 2));
                if (picked != null) setD(() => date = picked);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || date == null) return;
                Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusOrange),
              child: Text('Добавить'),
            ),
          ],
        ),
      ),
    );
    if (added == true && date != null) {
      setState(() {
        _exams.add({'name': nameCtrl.text.trim(), 'date': date!.toIso8601String()});
        _exams.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
      });
      await _saveExams();
    }
  }

  Future<void> _deleteExam(int index) async {
    setState(() => _exams.removeAt(index));
    await _saveExams();
  }

  int _daysLeft(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return 0;
    final today = DateTime.now();
    return DateTime(d.year, d.month, d.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  // ─────────────────── Build ───────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Студенту', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(19), fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: AppSize.padding(20),
        children: [
          _buildPomodoro(),
          AppSize.gapH(24),
          _buildExams(),
          AppSize.gapH(24),
          _buildBurnoutCard(),
        ],
      ),
    );
  }

  Widget _buildPomodoro() {
    final color = _isWork ? AppColors.citrusOrange : AppColors.citrusGreen;
    final progress = 1 - (_remaining / _phaseTotal);
    return Container(
      padding: AppSize.padding(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSize.radius(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_isWork ? '🍅' : '☕', style: TextStyle(fontSize: AppSize.s(16))),
          AppSize.gapW(6),
          Text(_isWork ? 'Фокус' : 'Перерыв', style: TextStyle(color: color, fontSize: AppSize.s(14), fontWeight: FontWeight.w700)),
        ]),
        AppSize.gapH(16),
        SizedBox(
          width: AppSize.s(180),
          height: AppSize.s(180),
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: AppSize.s(180),
              height: AppSize.s(180),
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 10,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_fmt(_remaining), style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(40), fontWeight: FontWeight.w800)),
              Text('🍅 ×$_cycles', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
            ]),
          ]),
        ),
        AppSize.gapH(20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: _resetTimer, icon: Icon(Icons.refresh, color: AppColors.mutedForeground, size: AppSize.s(26))),
          AppSize.gapW(16),
          GestureDetector(
            onTap: _toggleTimer,
            child: Container(
              width: AppSize.s(72),
              height: AppSize.s(72),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Icon(_running ? Icons.pause : Icons.play_arrow, color: Colors.white, size: AppSize.s(38)),
            ),
          ),
          AppSize.gapW(16),
          IconButton(onPressed: _skipPhase, icon: Icon(Icons.skip_next, color: AppColors.mutedForeground, size: AppSize.s(26))),
        ]),
        AppSize.gapH(4),
        Text('$_workMin мин работы · $_breakMin мин перерыв', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(11))),
      ]),
    );
  }

  Widget _buildExams() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Обратный отсчёт', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700)),
        const Spacer(),
        GestureDetector(
          onTap: _addExam,
          child: Container(
            padding: AppSize.paddingH(12, 6),
            decoration: BoxDecoration(color: AppColors.citrusOrange.withValues(alpha: 0.15), borderRadius: AppSize.radius(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, size: AppSize.s(15), color: AppColors.citrusOrange),
              AppSize.gapW(4),
              Text('Экзамен', style: TextStyle(color: AppColors.citrusOrange, fontSize: AppSize.s(12), fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
      AppSize.gapH(12),
      if (_exams.isEmpty)
        Container(
          width: double.infinity,
          padding: AppSize.padding(20),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: AppSize.radius(16), border: Border.all(color: AppColors.border, width: 0.5)),
          child: Column(children: [
            Icon(Icons.event_note, size: AppSize.s(36), color: AppColors.dimForeground),
            AppSize.gapH(8),
            Text('Добавь экзамен или дедлайн', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
          ]),
        )
      else
        ..._exams.asMap().entries.map((e) {
          final left = _daysLeft(e.value['date'] ?? '');
          final urgent = left <= 7;
          final color = left < 0 ? AppColors.dimForeground : (urgent ? AppColors.destructive : AppColors.citrusOrange);
          return Padding(
            padding: AppSize.paddingOnly(bottom: 8),
            child: Container(
              padding: AppSize.padding(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: AppSize.radius(14), border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(children: [
                Container(
                  width: AppSize.s(48),
                  height: AppSize.s(48),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSize.radius(12)),
                  child: Center(
                    child: Text(left < 0 ? '—' : '$left', style: TextStyle(color: color, fontSize: AppSize.s(18), fontWeight: FontWeight.w800)),
                  ),
                ),
                AppSize.gapW(12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.value['name'] ?? '', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    AppSize.gapH(2),
                    Text(
                      left < 0 ? 'позади' : (left == 0 ? 'сегодня!' : '$left ${_dayWord(left)}'),
                      style: TextStyle(color: color, fontSize: AppSize.s(12), fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
                GestureDetector(
                  onTap: () => _deleteExam(e.key),
                  child: Icon(Icons.close, size: AppSize.s(18), color: AppColors.dimForeground),
                ),
              ]),
            ),
          );
        }),
    ]);
  }

  String _dayWord(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'дня';
    return 'дней';
  }

  Widget _buildBurnoutCard() {
    return GestureDetector(
      onTap: _openBurnoutCheck,
      child: Container(
        padding: AppSize.padding(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.citrusPurple.withValues(alpha: 0.15), AppColors.citrusPurple.withValues(alpha: 0.05)],
          ),
          borderRadius: AppSize.radius(18),
          border: Border.all(color: AppColors.citrusPurple.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: AppSize.s(46),
            height: AppSize.s(46),
            decoration: BoxDecoration(color: AppColors.citrusPurple.withValues(alpha: 0.18), borderRadius: AppSize.radius(13)),
            child: Icon(Icons.battery_alert, color: AppColors.citrusPurple, size: AppSize.s(24)),
          ),
          AppSize.gapW(14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Экспресс-чек выгорания', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w700)),
              AppSize.gapH(2),
              Text('6 вопросов · 1 минута', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12))),
            ]),
          ),
          Icon(Icons.chevron_right, color: AppColors.dimForeground, size: AppSize.s(22)),
        ]),
      ),
    );
  }

  void _openBurnoutCheck() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.s(22)))),
      builder: (_) => const _BurnoutSheet(),
    );
  }
}

// ─────────────────── Чек выгорания ───────────────────

class _BurnoutSheet extends StatefulWidget {
  const _BurnoutSheet();

  @override
  State<_BurnoutSheet> createState() => _BurnoutSheetState();
}

class _BurnoutSheetState extends State<_BurnoutSheet> {
  static const _questions = [
    'Чувствую себя эмоционально опустошённым(ой)',
    'Тяжело заставить себя заниматься учёбой',
    'Стал(а) хуже справляться с задачами',
    'Просыпаюсь уставшим(ей), даже выспавшись',
    'Потерял(а) интерес к тому, что раньше радовало',
    'Раздражаюсь по мелочам чаще обычного',
  ];
  static const _scale = ['Никогда', 'Редко', 'Иногда', 'Часто', 'Постоянно'];

  final Map<int, int> _answers = {};
  bool _showResult = false;

  int get _score => _answers.values.fold(0, (a, b) => a + b);
  int get _maxScore => _questions.length * 4;

  ({String label, Color color, String advice}) get _result {
    final pct = _score / _maxScore;
    if (pct < 0.34) {
      return (label: 'Низкий риск выгорания', color: AppColors.citrusGreen, advice: 'Состояние стабильное. Продолжай заботиться о себе — сон, паузы, что радует.');
    } else if (pct < 0.67) {
      return (label: 'Средний риск выгорания', color: AppColors.citrusAmber, advice: 'Есть признаки усталости. Добавь перерывы (Pomodoro), сон и время на отдых. Не перегружай себя.');
    } else {
      return (label: 'Высокий риск выгорания', color: AppColors.destructive, advice: 'Похоже, ты сильно истощён(а). Снизь нагрузку, попроси поддержки у близких; при необходимости обратись к специалисту.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: AppSize.padding(20),
        child: _showResult ? _buildResult() : _buildQuestions(),
      ),
    );
  }

  Widget _buildQuestions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: AppSize.s(40), height: AppSize.s(4), decoration: BoxDecoration(color: AppColors.subtleBorder, borderRadius: AppSize.radius(2)))),
      AppSize.gapH(16),
      Text('Экспресс-чек выгорания', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w700)),
      AppSize.gapH(4),
      Text('Как часто за последние 2 недели у тебя было такое?', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
      AppSize.gapH(16),
      ..._questions.asMap().entries.map((q) {
        return Padding(
          padding: AppSize.paddingOnly(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${q.key + 1}. ${q.value}', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w500, height: 1.4)),
            AppSize.gapH(8),
            Row(children: List.generate(5, (i) {
              final active = _answers[q.key] == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _answers[q.key] = i),
                  child: Container(
                    margin: AppSize.paddingH(2, 0),
                    padding: AppSize.paddingH(0, 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.citrusPurple.withValues(alpha: 0.2) : AppColors.surface2,
                      borderRadius: AppSize.radius(8),
                      border: Border.all(color: active ? AppColors.citrusPurple : Colors.transparent),
                    ),
                    child: Center(
                      child: Text('$i', style: TextStyle(color: active ? AppColors.citrusPurple : AppColors.mutedForeground, fontSize: AppSize.s(13), fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              );
            })),
            AppSize.gapH(4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_scale.first, style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(10))),
              Text(_scale.last, style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(10))),
            ]),
          ]),
        );
      }),
      AppSize.gapH(8),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _answers.length == _questions.length ? () => setState(() => _showResult = true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.citrusPurple,
            foregroundColor: Colors.white,
            padding: AppSize.paddingH(0, 14),
            shape: RoundedRectangleBorder(borderRadius: AppSize.radius(14)),
          ),
          child: Text(_answers.length == _questions.length ? 'Узнать результат' : 'Ответь на все вопросы (${_answers.length}/${_questions.length})'),
        ),
      ),
      AppSize.gapH(8),
    ]);
  }

  Widget _buildResult() {
    final r = _result;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: AppSize.s(40), height: AppSize.s(4), decoration: BoxDecoration(color: AppColors.subtleBorder, borderRadius: AppSize.radius(2)))),
      AppSize.gapH(20),
      Center(child: Text('$_score / $_maxScore', style: TextStyle(color: r.color, fontSize: AppSize.s(40), fontWeight: FontWeight.w800))),
      AppSize.gapH(8),
      Center(child: Container(
        padding: AppSize.paddingH(14, 7),
        decoration: BoxDecoration(color: r.color.withValues(alpha: 0.15), borderRadius: AppSize.radius(999)),
        child: Text(r.label, style: TextStyle(color: r.color, fontSize: AppSize.s(14), fontWeight: FontWeight.w700)),
      )),
      AppSize.gapH(20),
      Container(
        padding: AppSize.padding(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppSize.radius(14), border: Border.all(color: AppColors.border, width: 0.5)),
        child: Text(r.advice, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), height: 1.5)),
      ),
      AppSize.gapH(16),
      Text('Это не диагноз, а ориентир. Если тяжело — обратись за поддержкой.', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(11))),
      AppSize.gapH(16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.citrusPurple,
            foregroundColor: Colors.white,
            padding: AppSize.paddingH(0, 14),
            shape: RoundedRectangleBorder(borderRadius: AppSize.radius(14)),
          ),
          child: Text('Понятно'),
        ),
      ),
      AppSize.gapH(8),
    ]);
  }
}
