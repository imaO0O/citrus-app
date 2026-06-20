import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_size.dart';
import '../../../core/utils/article_visuals.dart';
import '../../../core/services/article_prefs_service.dart';
import '../../../models/article.dart';
import '../bloc/article_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../screens/tests/test_taking_screen.dart';
import '../../../screens/exercises_screen.dart';

class ArticleDetailPage extends StatefulWidget {
  final Article article;
  final bool showBackButton;

  ArticleDetailPage({
    super.key,
    required this.article,
    this.showBackButton = true,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final ScrollController _scroll = ScrollController();
  final ArticlePrefsService _prefs = ArticlePrefsService();
  double _progress = 0;
  double _fontScale = 1.0;

  Article get article => widget.article;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFont();
  }

  Future<void> _loadFont() async {
    final fs = await _prefs.getFontScale();
    if (mounted) setState(() => _fontScale = fs);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.004) setState(() => _progress = p);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _fs(double base) => AppSize.s(base) * _fontScale;

  void _share() {
    SharePlus.instance.share(
      ShareParams(text: '${article.title}\n\n${article.content}\n\n— из приложения «Цитрус»'),
    );
  }

  void _openFontSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.s(22)))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: AppSize.padding(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: AppSize.s(40), height: AppSize.s(4), decoration: BoxDecoration(color: AppColors.subtleBorder, borderRadius: AppSize.radius(2)))),
              AppSize.gapH(16),
              Text('Размер шрифта', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700)),
              AppSize.gapH(8),
              Row(children: [
                Text('А', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
                Expanded(
                  child: Slider(
                    min: 0.85,
                    max: 1.6,
                    divisions: 6,
                    value: _fontScale,
                    activeColor: AppColors.citrusOrange,
                    label: '${(_fontScale * 100).round()}%',
                    onChanged: (v) {
                      setSheet(() {});
                      setState(() => _fontScale = v);
                    },
                    onChangeEnd: (v) => _prefs.setFontScale(v),
                  ),
                ),
                Text('А', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(22), fontWeight: FontWeight.w700)),
              ]),
              Text(
                'Пример: так будет выглядеть текст статьи.',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: _fs(15), height: 1.6),
              ),
              AppSize.gapH(8),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = ArticleVisuals.color(article.category);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.foreground),
                onPressed: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              )
            : null,
        title: Text(
          article.title,
          style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.format_size, color: AppColors.foreground),
            tooltip: 'Размер шрифта',
            onPressed: _openFontSheet,
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: AppColors.foreground),
            tooltip: 'Поделиться',
            onPressed: _share,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 3,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        padding: AppSize.padding(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Категория (в цвете)
            Container(
              padding: AppSize.paddingH(12, 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: AppSize.radius(20),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ArticleVisuals.icon(article.category), color: color, size: 16),
                AppSize.gapW(6),
                Text(ArticleVisuals.name(article.category), style: TextStyle(color: color, fontSize: AppSize.s(13), fontWeight: FontWeight.w600)),
              ]),
            ),
            AppSize.gapH(16),

            // Заголовок
            Text(
              article.title,
              style: TextStyle(color: AppColors.foreground, fontSize: _fs(26), fontWeight: FontWeight.bold, height: 1.3),
            ),
            AppSize.gapH(10),

            // Время чтения + дата
            Row(children: [
              Icon(Icons.schedule, size: AppSize.s(14), color: AppColors.dimForeground),
              AppSize.gapW(5),
              Text('${ArticleVisuals.readingMinutes(article.content)} мин чтения', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(13))),
              AppSize.gapW(12),
              Text('· ${_formatDate(article.createdAt)}', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(13))),
            ]),

            Divider(color: AppColors.border, height: 32),

            // Контент
            MarkdownBody(
              data: article.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: AppColors.mutedForeground, fontSize: _fs(16), height: 1.7),
                h1: TextStyle(color: AppColors.foreground, fontSize: _fs(24), fontWeight: FontWeight.bold, height: 1.4),
                h2: TextStyle(color: AppColors.foreground, fontSize: _fs(20), fontWeight: FontWeight.bold, height: 1.4),
                h3: TextStyle(color: AppColors.foreground, fontSize: _fs(18), fontWeight: FontWeight.w600, height: 1.4),
                h4: TextStyle(color: AppColors.foreground, fontSize: _fs(16), fontWeight: FontWeight.w600, height: 1.4),
                strong: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.bold),
                em: TextStyle(color: AppColors.mutedForeground, fontStyle: FontStyle.italic),
                blockquote: TextStyle(color: AppColors.citrusAmber, fontSize: _fs(16), fontStyle: FontStyle.italic, height: 1.6),
                blockquotePadding: AppSize.paddingOnly(left: 16),
                listBullet: TextStyle(color: AppColors.citrusOrange, fontSize: _fs(16)),
                code: TextStyle(color: AppColors.citrusGreen, backgroundColor: AppColors.surface2, fontSize: _fs(14)),
                codeblockDecoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(8)),
                a: TextStyle(color: AppColors.citrusOrange, decoration: TextDecoration.underline),
              ),
              onTapLink: (text, href, title) {
                if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
              },
            ),

            AppSize.gapH(24),
            _buildResourcesCta(context, color),
            _buildSimilar(context),
            AppSize.gapH(16),
          ],
        ),
      ),
    );
  }

  // ---- Связки контента: тест и упражнение по теме ----

  String? _testIdForCategory(String c) {
    switch (c.toLowerCase()) {
      case 'anxiety':
        return 'gad7';
      case 'depression':
        return 'phq9';
      case 'stress':
        return 'dass21';
      case 'self-esteem':
        return 'rosenberg_self_esteem';
      default:
        return null;
    }
  }

  String _testLabel(String testId) {
    switch (testId) {
      case 'gad7':
        return 'Тест на тревожность (GAD-7)';
      case 'phq9':
        return 'Тест на депрессию (PHQ-9)';
      case 'dass21':
        return 'Тест DASS-21';
      case 'rosenberg_self_esteem':
        return 'Тест самооценки';
      default:
        return 'Пройти тест';
    }
  }

  void _openTest(String testId) {
    final st = context.read<AuthBloc>().state;
    final token = st is AuthAuthenticated ? st.user.token : null;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TestTakingScreen(testId: testId, token: token)),
    );
  }

  void _openExercises() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExercisesScreen()));
  }

  Widget _buildResourcesCta(BuildContext context, Color color) {
    final testId = _testIdForCategory(article.category);
    Widget row(IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: AppSize.radius(12),
          child: Padding(
            padding: AppSize.paddingH(0, 12),
            child: Row(children: [
              Container(
                width: AppSize.s(36),
                height: AppSize.s(36),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSize.radius(10)),
                child: Icon(icon, size: AppSize.s(19), color: color),
              ),
              AppSize.gapW(12),
              Expanded(child: Text(label, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right, size: AppSize.s(20), color: AppColors.dimForeground),
            ]),
          ),
        );

    return Container(
      padding: AppSize.paddingH(16, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppSize.gapH(12),
        Text('Полезное по теме', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w700)),
        AppSize.gapH(4),
        if (testId != null) row(Icons.fact_check_outlined, _testLabel(testId), () => _openTest(testId)),
        row(Icons.self_improvement, 'Дыхательное упражнение', _openExercises),
        AppSize.gapH(8),
      ]),
    );
  }

  Widget _buildSimilar(BuildContext context) {
    final state = context.read<ArticleBloc>().state;
    if (state is! ArticlesLoaded) return const SizedBox.shrink();
    final similar = state.articles
        .where((a) => a.category == article.category && a.id != article.id)
        .take(4)
        .toList();
    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSize.gapH(28),
        Text('Похожие статьи', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(17), fontWeight: FontWeight.w700)),
        AppSize.gapH(12),
        ...similar.map((a) {
          final c = ArticleVisuals.color(a.category);
          return Padding(
            padding: AppSize.paddingOnly(bottom: 8),
            child: InkWell(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => ArticleDetailPage(article: a)),
              ),
              borderRadius: AppSize.radius(12),
              child: Container(
                padding: AppSize.padding(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppSize.radius(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(children: [
                  Container(
                    width: AppSize.s(38),
                    height: AppSize.s(38),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: AppSize.radius(10)),
                    child: Icon(ArticleVisuals.icon(a.category), size: AppSize.s(20), color: c),
                  ),
                  AppSize.gapW(12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      AppSize.gapH(3),
                      Text('${ArticleVisuals.readingMinutes(a.content)} мин', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12))),
                    ]),
                  ),
                  Icon(Icons.chevron_right, size: AppSize.s(20), color: AppColors.dimForeground),
                ]),
              ),
            ),
          );
        }),
      ],
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
