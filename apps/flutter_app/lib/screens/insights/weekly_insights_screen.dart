import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/repository/mood_repository.dart';
import '../../core/repository/sleep_repository.dart';
import '../../core/repository/diary_repository.dart';
import '../../services/analytics_loader.dart';
import '../../services/diary_loader.dart';
import '../../services/chat_api_client.dart';

/// Еженедельная персональная ИИ-сводка по настроению/сну/дневнику.
class WeeklyInsightsScreen extends StatefulWidget {
  const WeeklyInsightsScreen({super.key});

  @override
  State<WeeklyInsightsScreen> createState() => _WeeklyInsightsScreenState();
}

class _WeeklyInsightsScreenState extends State<WeeklyInsightsScreen> {
  static const _textKey = 'weekly_insight_text';
  static const _atKey = 'weekly_insight_at';
  static const _insightPrompt =
      'Ты — Цитрус, заботливый помощник по ментальному здоровью для студентов. '
      'На основе данных пользователя за неделю (настроение, сон, записи дневника) сделай короткую тёплую сводку на «ты».\n\n'
      'Формат (markdown):\n'
      '### Что я заметил\n'
      '2–3 коротких наблюдения о динамике (без диагнозов и оценок).\n\n'
      '### Советы на неделю\n'
      'Ровно 2 конкретных небольших совета, которые реально выполнить.\n\n'
      'Пиши кратко и поддерживающе. Если данных мало — мягко предложи чаще отмечать настроение и вести дневник.';

  bool _loading = false;
  String? _insight;
  DateTime? _generatedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final text = await StorageService().getString(_textKey);
    final at = await StorageService().getString(_atKey);
    if (mounted && text != null && text.isNotEmpty) {
      setState(() {
        _insight = text;
        _generatedAt = DateTime.tryParse(at ?? '');
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final moodRepo = context.read<MoodRepository>();
      final sleepRepo = context.read<SleepRepository>();
      final diaryRepo = context.read<DiaryRepository>();
      final token = await StorageService().getString('auth_token') ?? '';
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final analytics = await AnalyticsLoaderService(moodRepo: moodRepo, sleepRepo: sleepRepo)
          .loadAndFormatAnalytics(token: token, userId: moodRepo.userId, startDate: weekAgo);

      String diaryText = '';
      try {
        final entries = await DiaryLoaderService(diaryRepo: diaryRepo).loadDiaryEntries(startDate: weekAgo);
        if (entries.isNotEmpty) {
          diaryText = DiaryLoaderService(diaryRepo: diaryRepo).formatSelectedEntries(entries);
        }
      } catch (_) {}

      final msg = StringBuffer()
        ..writeln('Данные пользователя за последнюю неделю:')
        ..writeln(analytics);
      if (diaryText.isNotEmpty) {
        msg
          ..writeln()
          ..writeln(diaryText);
      }

      final resp = await ChatApiClient(baseUrl: ApiConfig.baseUrl, token: token)
          .sendMessage(message: msg.toString(), systemPrompt: _insightPrompt);

      final now = DateTime.now();
      await StorageService().setString(_textKey, resp);
      await StorageService().setString(_atKey, now.toIso8601String());
      if (mounted) {
        setState(() {
          _insight = resp;
          _generatedAt = now;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось получить сводку. Попробуйте позже.';
          _loading = false;
        });
      }
    }
  }

  String _relative(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'сегодня';
    if (days == 1) return 'вчера';
    if (days < 7) return '$days дн. назад';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('ИИ-инсайты недели',
            style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(19), fontWeight: FontWeight.w700)),
        actions: [
          if (_insight != null && !_loading)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.foreground),
              tooltip: 'Обновить',
              onPressed: _generate,
            ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : (_insight == null ? _buildEmpty() : _buildResult()),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: AppColors.citrusPurple),
        AppSize.gapH(16),
        Text('Цитрус анализирует твою неделю…', style: TextStyle(color: AppColors.mutedForeground)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: AppSize.padding(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: AppSize.s(72),
            height: AppSize.s(72),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.citrusPurple, AppColors.citrusOrange]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(Icons.insights, color: Colors.white, size: AppSize.s(36))),
          ),
          AppSize.gapH(16),
          Text('Персональная сводка недели', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          AppSize.gapH(8),
          Text(
            'Цитрус посмотрит на твоё настроение, сон и записи за неделю и подскажет, что заметно и что можно улучшить.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14), height: 1.5),
          ),
          if (_error != null) ...[
            AppSize.gapH(12),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.destructive, fontSize: AppSize.s(13))),
          ],
          AppSize.gapH(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generate,
              icon: Icon(Icons.auto_awesome),
              label: Text('Сгенерировать сводку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.citrusPurple,
                foregroundColor: Colors.white,
                padding: AppSize.paddingH(0, 15),
                shape: RoundedRectangleBorder(borderRadius: AppSize.radius(14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildResult() {
    return ListView(
      padding: AppSize.padding(20),
      children: [
        Row(children: [
          Icon(Icons.auto_awesome, size: AppSize.s(16), color: AppColors.citrusPurple),
          AppSize.gapW(8),
          Text(
            _generatedAt != null ? 'Обновлено ${_relative(_generatedAt!)}' : 'Сводка готова',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12)),
          ),
        ]),
        AppSize.gapH(12),
        Container(
          padding: AppSize.padding(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.citrusPurple.withValues(alpha: 0.12), AppColors.citrusPurple.withValues(alpha: 0.04)],
            ),
            borderRadius: AppSize.radius(18),
            border: Border.all(color: AppColors.citrusPurple.withValues(alpha: 0.25)),
          ),
          child: MarkdownBody(
            data: _insight!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), height: 1.6),
              strong: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.bold),
              h3: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(16), fontWeight: FontWeight.w700),
              h2: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(18), fontWeight: FontWeight.w700),
              listBullet: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(15)),
            ),
          ),
        ),
        AppSize.gapH(16),
        OutlinedButton.icon(
          onPressed: _generate,
          icon: Icon(Icons.refresh, size: AppSize.s(18)),
          label: Text('Обновить сводку'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.citrusPurple,
            side: BorderSide(color: AppColors.citrusPurple.withValues(alpha: 0.5)),
            padding: AppSize.paddingH(0, 13),
            shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)),
          ),
        ),
        AppSize.gapH(12),
        Text(
          'Это информационная сводка, а не медицинская консультация.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(11)),
        ),
      ],
    );
  }
}
