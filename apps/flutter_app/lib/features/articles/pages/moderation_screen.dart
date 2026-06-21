import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/api/article_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_size.dart';
import '../../../core/utils/article_visuals.dart';
import '../../../models/article.dart';

/// Кабинет модерации (только для админа): очередь статей сообщества,
/// ожидающих проверки, с действиями «Одобрить» / «Отклонить».
class ModerationScreen extends StatefulWidget {
  final String? token;

  ModerationScreen({super.key, this.token});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  late final ArticleApiService _api = ArticleApiService(token: widget.token);
  List<Article> _queue = [];
  bool _loading = true;
  String? _error;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = await _api.getModerationQueue();
      if (mounted) setState(() { _queue = q; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _moderate(Article a, String action) async {
    setState(() => _processing.add(a.id));
    try {
      await _api.moderateArticle(a.id, action);
      if (!mounted) return;
      setState(() {
        _queue.removeWhere((x) => x.id == a.id);
        _processing.remove(a.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'approve' ? 'Статья одобрена' : 'Статья отклонена'),
        backgroundColor: action == 'approve' ? AppColors.citrusGreen : AppColors.destructive,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing.remove(a.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка: $e'),
        backgroundColor: AppColors.destructive,
      ));
    }
  }

  void _readFull(Article a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.s(22)))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: AppSize.padding(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: AppSize.s(40), height: AppSize.s(4), decoration: BoxDecoration(color: AppColors.subtleBorder, borderRadius: AppSize.radius(2)))),
            AppSize.gapH(16),
            Text(a.title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(22), fontWeight: FontWeight.bold, height: 1.3)),
            AppSize.gapH(12),
            MarkdownBody(
              data: a.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(15), height: 1.7),
                h1: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(22), fontWeight: FontWeight.bold),
                h2: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(19), fontWeight: FontWeight.bold),
                h3: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(17), fontWeight: FontWeight.w600),
                strong: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.bold),
                listBullet: TextStyle(color: AppColors.citrusOrange, fontSize: AppSize.s(15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.foreground), onPressed: () => Navigator.pop(context)),
        title: Text('Модерация', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(20), fontWeight: FontWeight.w700)),
        actions: [
          if (!_loading)
            Padding(
              padding: AppSize.paddingH(8, 0),
              child: Center(
                child: Container(
                  padding: AppSize.paddingH(10, 4),
                  decoration: BoxDecoration(color: AppColors.citrusOrange.withValues(alpha: 0.15), borderRadius: AppSize.radius(999)),
                  child: Text('${_queue.length}', style: TextStyle(color: AppColors.citrusOrange, fontSize: AppSize.s(13), fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          IconButton(icon: Icon(Icons.refresh, color: AppColors.foreground), onPressed: _load),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.citrusOrange));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 56, color: AppColors.destructive),
          AppSize.gapH(12),
          Padding(padding: AppSize.padding(24), child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedForeground))),
          ElevatedButton(onPressed: _load, child: Text('Повторить')),
        ]),
      );
    }
    if (_queue.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.verified_outlined, size: 64, color: AppColors.citrusGreen),
          AppSize.gapH(16),
          Text('Очередь пуста', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w600)),
          AppSize.gapH(6),
          Text('Нет статей, ожидающих модерации', style: TextStyle(color: AppColors.mutedForeground)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.citrusOrange,
      child: ListView.builder(
        padding: AppSize.padding(16),
        itemCount: _queue.length,
        itemBuilder: (ctx, i) => _card(_queue[i]),
      ),
    );
  }

  Widget _card(Article a) {
    final color = ArticleVisuals.color(a.category);
    final busy = _processing.contains(a.id);
    final preview = a.content.length > 240 ? '${a.content.substring(0, 240)}…' : a.content;
    return Container(
      margin: AppSize.paddingOnly(bottom: 12),
      padding: AppSize.padding(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: AppSize.radius(16), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ArticleVisuals.icon(a.category), size: AppSize.s(15), color: color),
          AppSize.gapW(6),
          Text(ArticleVisuals.name(a.category), style: TextStyle(color: color, fontSize: AppSize.s(12), fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.person_outline, size: AppSize.s(13), color: AppColors.dimForeground),
          AppSize.gapW(4),
          Text(a.author ?? 'Аноним', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12))),
        ]),
        AppSize.gapH(10),
        Text(a.title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700, height: 1.3)),
        AppSize.gapH(8),
        Text(preview, style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), height: 1.5)),
        AppSize.gapH(6),
        GestureDetector(
          onTap: () => _readFull(a),
          child: Text('Читать полностью →', style: TextStyle(color: AppColors.citrusOrange, fontSize: AppSize.s(13), fontWeight: FontWeight.w600)),
        ),
        AppSize.gapH(14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => _moderate(a, 'reject'),
              icon: Icon(Icons.close, size: AppSize.s(18)),
              label: Text('Отклонить'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.destructive,
                side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.5)),
                padding: AppSize.paddingH(0, 12),
                shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)),
              ),
            ),
          ),
          AppSize.gapW(12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: busy ? null : () => _moderate(a, 'approve'),
              icon: busy
                  ? SizedBox(width: AppSize.s(16), height: AppSize.s(16), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.check, size: AppSize.s(18)),
              label: Text('Одобрить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.citrusGreen,
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
}
