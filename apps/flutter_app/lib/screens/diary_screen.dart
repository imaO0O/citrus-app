import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/services/casino_coins_service.dart';
import '../features/diary/bloc/diary_bloc.dart';
import '../core/repository/diary_repository.dart';
import '../core/utils/app_size.dart';

class DiaryScreen extends StatefulWidget {
  DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack);
    _fabController.forward();
    _loadEntries();
  }

  void _loadEntries() {
    final search = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();
    context.read<DiaryBloc>().add(LoadDiaryEntries(search: search));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);
    if (entryDate == today) return 'Сегодня';
    if (entryDate == yesterday) return 'Вчера';
    return DateFormat('d MMMM yyyy', 'ru_RU').format(date);
  }

  String _formatTime(DateTime date) => DateFormat('HH:mm', 'ru_RU').format(date);

  String _getMoodEmoji(int? v) {
    if (v == null) return '';
    const emojis = ['😄', '🙂', '😐', '😟', '😢', '😞'];
    return emojis[v.clamp(0, 5)];
  }

  Color _getMoodColor(int? v) {
    if (v == 0) return AppColors.citrusGreen;
    if (v == 1) return AppColors.citrusAmber;
    if (v == 2) return AppColors.dimForeground;
    if (v == 3) return AppColors.citrusOrange;
    if (v == 4) return AppColors.citrusPurple;
    if (v == 5) return AppColors.destructive;
    return AppColors.dimForeground;
  }

  String _monthName(int m) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: Column(children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildContent())
            ]),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          heroTag: 'diary_fab',
          onPressed: () => _showAddDialog(),
          backgroundColor: AppColors.citrusOrange,
          icon: Icon(Icons.edit_note, color: Colors.white),
          label: Text('Запись', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.citrusOrange, Color(0xFFFF7020)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppSize.radius(16),
          ),
          child: Center(child: Text('📔', style: TextStyle(fontSize: AppSize.s(26)))),
        ),
        AppSize.gapW(14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Дневник', style: TextStyle(fontSize: AppSize.s(26), fontWeight: FontWeight.w800, color: AppColors.foreground)),
          Text('Ваши мысли и эмоции', style: TextStyle(fontSize: AppSize.s(13), color: AppColors.mutedForeground)),
        ])),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface1, borderRadius: AppSize.radius(16)),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15)),
          decoration: InputDecoration(
            hintText: 'Поиск в дневнике...',
            hintStyle: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(14)),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.citrusOrange, size: 22),
            prefixIconConstraints: BoxConstraints(minWidth: 40),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(borderRadius: AppSize.radius(16), borderSide: BorderSide.none),
            contentPadding: AppSize.paddingH(16, 16),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: AppColors.dimForeground),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); _loadEntries(); },
                  )
                : null,
          ),
          onChanged: (v) {
            setState(() => _searchQuery = v.trim());
            _searchDebounce?.cancel();
            _searchDebounce = Timer(Duration(milliseconds: 400), () { if (mounted) _loadEntries(); });
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<DiaryBloc, DiaryState>(builder: (ctx, state) {
      if (state is DiaryLoading) return Center(child: CircularProgressIndicator(color: AppColors.citrusOrange, strokeWidth: 3));
      if (state is DiaryError) return _buildError(state.message);
      if (state is DiaryLoaded) return state.entries.isEmpty ? _buildEmpty() : _buildList(state.entries);
      return SizedBox.shrink();
    });
  }

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        padding: AppSize.padding(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.citrusOrange.withAlpha(38), AppColors.citrusAmber.withAlpha(25)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('📔', style: TextStyle(fontSize: AppSize.s(52)))),
          ),
          AppSize.gapH(20),
          Text('Начните свой дневник', style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.w700, color: AppColors.foreground)),
          AppSize.gapH(8),
          Text('Записывайте мысли, эмоции и события.\nЭто поможет лучше понять себя.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppSize.s(14), color: AppColors.mutedForeground, height: 1.5)),
          AppSize.gapH(24),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: Icon(Icons.add_rounded),
            label: Text('Создать первую запись'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.citrusOrange,
              foregroundColor: Colors.white,
              padding: AppSize.paddingH(24, 14),
              shape: RoundedRectangleBorder(borderRadius: AppSize.radius(14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSize.padding(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.destructive.withAlpha(25), shape: BoxShape.circle),
            child: Center(child: Icon(Icons.error_outline_rounded, size: 40, color: AppColors.destructive))),
          AppSize.gapH(24),
          Text('Что-то пошло не так', style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w600, color: AppColors.foreground)),
          AppSize.gapH(8),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: AppSize.s(13), color: AppColors.mutedForeground)),
          AppSize.gapH(24),
          ElevatedButton.icon(
            onPressed: _loadEntries,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Повторить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.citrusOrange,
              foregroundColor: Colors.white,
              padding: AppSize.paddingH(24, 14),
              shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildList(List<DiaryEntry> entries) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: entries.length,
      itemBuilder: (ctx, i) => Padding(padding: AppSize.paddingOnly(bottom: 14), child: _buildCard(entries[i])),
    );
  }

  Widget _buildCard(DiaryEntry e) {
    final color = _getMoodColor(e.moodValue);
    final emoji = _getMoodEmoji(e.moodValue);
    return GestureDetector(
      onTap: () => _showDetails(e),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: AppSize.radius(20),
          border: Border.all(color: e.moodValue != null ? color.withAlpha(64) : AppColors.subtleBorder),
        ),
        child: ClipRRect(
          borderRadius: AppSize.radius(20),
          child: Row(children: [
            if (e.moodValue != null)
              Container(
                width: 5,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withAlpha(128)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
              ),
            Expanded(
              child: Padding(
                padding: AppSize.padding(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (e.moodValue != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: AppSize.radius(12)),
                        child: Center(child: Text(emoji, style: TextStyle(fontSize: AppSize.s(22)))),
                      ),
                      AppSize.gapW(12)
                    ],
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(_formatDate(e.createdAt), style: TextStyle(fontSize: AppSize.s(12), color: AppColors.citrusOrange, fontWeight: FontWeight.w600)),
                        AppSize.gapW(8),
                        Text(_formatTime(e.createdAt), style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground))
                      ]),
                    ])),
                    GestureDetector(
                      onTap: () => _showOptions(e),
                      child: Container(
                        padding: AppSize.padding(8),
                        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(10)),
                        child: Icon(Icons.more_vert_rounded, size: 18, color: AppColors.dimForeground),
                      ),
                    ),
                  ]),
                  AppSize.gapH(10),
                  Text(
                    e.content.length > 100 ? '${e.content.substring(0, 100)}...' : e.content,
                    style: TextStyle(fontSize: AppSize.s(13), color: e.moodValue != null ? AppColors.foreground : AppColors.mutedForeground, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showOptions(DiaryEntry e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: AppSize.padding(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: AppSize.radius(2))),
          AppSize.gapH(24),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.citrusOrange.withAlpha(38), borderRadius: AppSize.radius(12)),
            ),
            title: Text('Редактировать', style: TextStyle(color: AppColors.foreground)),
            onTap: () { Navigator.pop(ctx); _showEditDialog(e); },
          ),
          AppSize.gapH(8),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.destructive.withAlpha(38), borderRadius: AppSize.radius(12)),
            ),
            title: Text('Удалить', style: TextStyle(color: AppColors.destructive)),
            onTap: () { Navigator.pop(ctx); _confirmDelete(e); },
          ),
          AppSize.gapH(16),
        ]),
      ),
    );
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    int? mood;
    DateTime date = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, s) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(
              padding: AppSize.padding(24),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: AppSize.radius(2))),
                AppSize.gapH(20),
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.citrusOrange, Color(0xFFFF7020)]),
                      borderRadius: AppSize.radius(14),
                    ),
                    child: Center(child: Text('✍️', style: TextStyle(fontSize: AppSize.s(24)))),
                  ),
                  AppSize.gapW(14),
                  Text('Новая запись', style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.w700, color: AppColors.foreground)),
                ]),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSize.paddingH(24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) s(() => date = d);
                    },
                    child: Container(
                      padding: AppSize.paddingH(16, 14),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(14)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded, color: AppColors.citrusOrange, size: 20),
                        AppSize.gapW(12),
                        Text('${date.day} ${_monthName(date.month)} ${date.year}', style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w500)),
                        Spacer(),
                        Icon(Icons.arrow_drop_down_rounded, color: AppColors.dimForeground),
                      ]),
                    ),
                  ),
                  AppSize.gapH(20),
                  Text('Как вы себя чувствуете?', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), fontWeight: FontWeight.w500)),
                  AppSize.gapH(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      final sel = mood == i;
                      return GestureDetector(
                        onTap: () => s(() => mood = sel ? null : i),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: sel ? 52 : 46,
                          height: sel ? 52 : 46,
                          decoration: BoxDecoration(
                            color: sel ? _getMoodColor(i).withAlpha(51) : AppColors.surface2,
                            borderRadius: AppSize.radius(14),
                            border: Border.all(color: sel ? _getMoodColor(i) : Colors.transparent, width: 2),
                          ),
                          child: Center(child: Text(_getMoodEmoji(i), style: TextStyle(fontSize: sel ? 26 : 22))),
                        ),
                      );
                    }),
                  ),
                  AppSize.gapH(20),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(16), border: Border.all(color: AppColors.subtleBorder)),
                    child: TextField(
                      controller: ctrl,
                      style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), height: 1.6),
                      decoration: InputDecoration(
                        hintText: 'О чём хотите написать?',
                        hintStyle: TextStyle(color: AppColors.dimForeground),
                        border: InputBorder.none,
                        contentPadding: AppSize.padding(16),
                      ),
                      maxLines: 8,
                      autofocus: true,
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: AppSize.w(24), right: AppSize.w(24), bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSize.h(24), top: AppSize.h(16)),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    final now = DateTime.now();
                    final entryWithTime = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
                    debugPrint('Creating entry with date: $entryWithTime');
                    context.read<DiaryBloc>().add(CreateDiaryEntry(content: ctrl.text.trim(), moodValue: mood, entryDate: entryWithTime));
                    CasinoCoinsService().completeQuest('diary').then((_) {
                      CasinoCoinsService().refreshStatus();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.citrusOrange,
                    foregroundColor: Colors.white,
                    padding: AppSize.paddingH(0, 16),
                    shape: RoundedRectangleBorder(borderRadius: AppSize.radius(14)),
                  ),
                  child: Text('Сохранить', style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showEditDialog(DiaryEntry e) {
    final ctrl = TextEditingController(text: e.content);
    int? mood = e.moodValue;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, s) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(
              padding: AppSize.padding(24),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: AppSize.radius(2))),
                AppSize.gapH(20),
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.citrusPurple.withAlpha(51), borderRadius: AppSize.radius(14)),
                    child: Center(child: Text('✏️', style: TextStyle(fontSize: AppSize.s(24)))),
                  ),
                  AppSize.gapW(14),
                  Text('Редактировать', style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.w700, color: AppColors.foreground)),
                ]),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSize.paddingH(24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Как вы себя чувствуете?', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), fontWeight: FontWeight.w500)),
                  AppSize.gapH(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      final sel = mood == i;
                      return GestureDetector(
                        onTap: () => s(() => mood = sel ? null : i),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: sel ? 52 : 46,
                          height: sel ? 52 : 46,
                          decoration: BoxDecoration(
                            color: sel ? _getMoodColor(i).withAlpha(51) : AppColors.surface2,
                            borderRadius: AppSize.radius(14),
                            border: Border.all(color: sel ? _getMoodColor(i) : Colors.transparent, width: 2),
                          ),
                          child: Center(child: Text(_getMoodEmoji(i), style: TextStyle(fontSize: sel ? 26 : 22))),
                        ),
                      );
                    }),
                  ),
                  AppSize.gapH(20),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(16), border: Border.all(color: AppColors.subtleBorder)),
                    child: TextField(
                      controller: ctrl,
                      style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), height: 1.6),
                      decoration: InputDecoration(
                        hintText: 'О чём хотите написать?',
                        hintStyle: TextStyle(color: AppColors.dimForeground),
                        border: InputBorder.none,
                        contentPadding: AppSize.padding(16),
                      ),
                      maxLines: 8,
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: AppSize.w(24), right: AppSize.w(24), bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSize.h(24), top: AppSize.h(16)),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    context.read<DiaryBloc>().add(UpdateDiaryEntry(id: e.id, content: ctrl.text.trim(), moodValue: mood));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.citrusOrange,
                    foregroundColor: Colors.white,
                    padding: AppSize.paddingH(0, 16),
                    shape: RoundedRectangleBorder(borderRadius: AppSize.radius(14)),
                  ),
                  child: Text('Сохранить', style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDetails(DiaryEntry e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Padding(
            padding: AppSize.padding(24),
            child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: AppSize.radius(2))),
              AppSize.gapH(20),
              Row(children: [
                if (e.moodValue != null) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: _getMoodColor(e.moodValue).withAlpha(51), borderRadius: AppSize.radius(16)),
                    child: Center(child: Text(_getMoodEmoji(e.moodValue), style: TextStyle(fontSize: AppSize.s(32)))),
                  ),
                  AppSize.gapW(16)
                ],
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_formatDate(e.createdAt), style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w700, color: AppColors.foreground)),
                  Text(_formatTime(e.createdAt), style: TextStyle(fontSize: AppSize.s(14), color: AppColors.mutedForeground)),
                ])),
              ]),
            ]),
          ),
          Divider(color: AppColors.subtleBorder),
          Expanded(child: SingleChildScrollView(padding: AppSize.padding(24),
            child: Text(e.content, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), height: 1.8)))),
        ]),
      ),
    );
  }

  void _confirmDelete(DiaryEntry e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: AppSize.radius(20), side: BorderSide(color: AppColors.destructive.withAlpha(77))),
        title: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.destructive.withAlpha(25), borderRadius: AppSize.radius(12)),
            child: Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 24),
          ),
          AppSize.gapW(12),
          Text('Удалить запись?', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w600)),
        ]),
        content: Text('Эта запись будет удалена навсегда.', style: TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
          ElevatedButton(
            onPressed: () { context.read<DiaryBloc>().add(DeleteDiaryEntry(e.id)); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _fabController.dispose();
    super.dispose();
  }
}