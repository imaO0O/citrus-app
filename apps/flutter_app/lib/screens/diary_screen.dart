import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/services/casino_coins_service.dart';
import '../features/diary/bloc/diary_bloc.dart';
import '../core/repository/diary_repository.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

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
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
    final yesterday = today.subtract(const Duration(days: 1));
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
            constraints: const BoxConstraints(maxWidth: 480),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.citrusOrange, const Color(0xFFFF7020)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('📔', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Дневник', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          Text('Ваши мысли и эмоции', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
        ])),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: AppColors.foreground, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Поиск в дневнике...',
            hintStyle: TextStyle(color: AppColors.dimForeground, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.citrusOrange, size: 22),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            _searchDebounce = Timer(const Duration(milliseconds: 400), () { if (mounted) _loadEntries(); });
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<DiaryBloc, DiaryState>(builder: (ctx, state) {
      if (state is DiaryLoading) return const Center(child: CircularProgressIndicator(color: AppColors.citrusOrange, strokeWidth: 3));
      if (state is DiaryError) return _buildError(state.message);
      if (state is DiaryLoaded) return state.entries.isEmpty ? _buildEmpty() : _buildList(state.entries);
      return const SizedBox.shrink();
    });
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.citrusOrange.withAlpha(38), AppColors.citrusAmber.withAlpha(25)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('📔', style: TextStyle(fontSize: 64))),
          ),
          const SizedBox(height: 28),
          Text('Начните свой дневник', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
          const SizedBox(height: 10),
          Text('Записывайте мысли, эмоции и события.\nЭто поможет лучше понять себя.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.mutedForeground, height: 1.6)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: Icon(Icons.add_rounded),
            label: Text('Создать первую запись'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.citrusOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.destructive.withAlpha(25), shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.error_outline_rounded, size: 40, color: AppColors.destructive))),
          const SizedBox(height: 24),
          Text('Что-то пошло не так', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground)),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEntries,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Повторить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.citrusOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildList(List<DiaryEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: entries.length,
      itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildCard(entries[i])),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: e.moodValue != null ? color.withAlpha(64) : AppColors.subtleBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (e.moodValue != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12)
                    ],
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(_formatDate(e.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.citrusOrange, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(_formatTime(e.createdAt), style: TextStyle(fontSize: 11, color: AppColors.dimForeground))
                      ]),
                    ])),
                    GestureDetector(
                      onTap: () => _showOptions(e),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.more_vert_rounded, size: 18, color: AppColors.dimForeground),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    e.content.length > 100 ? '${e.content.substring(0, 100)}...' : e.content,
                    style: TextStyle(fontSize: 13, color: e.moodValue != null ? AppColors.foreground : AppColors.mutedForeground, height: 1.5),
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
        decoration: BoxDecoration(color: AppColors.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.citrusOrange.withAlpha(38), borderRadius: BorderRadius.circular(12)),
            ),
            title: Text('Редактировать', style: TextStyle(color: AppColors.foreground)),
            onTap: () { Navigator.pop(ctx); _showEditDialog(e); },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.destructive.withAlpha(38), borderRadius: BorderRadius.circular(12)),
            ),
            title: Text('Удалить', style: TextStyle(color: AppColors.destructive)),
            onTap: () { Navigator.pop(ctx); _confirmDelete(e); },
          ),
          const SizedBox(height: 16),
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
          decoration: BoxDecoration(color: AppColors.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.citrusOrange, const Color(0xFFFF7020)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('✍️', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Text('Новая запись', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                ]),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) s(() => date = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded, color: AppColors.citrusOrange, size: 20),
                        const SizedBox(width: 12),
                        Text('${date.day} ${_monthName(date.month)} ${date.year}', style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down_rounded, color: AppColors.dimForeground),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Как вы себя чувствуете?', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      final sel = mood == i;
                      return GestureDetector(
                        onTap: () => s(() => mood = sel ? null : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: sel ? 52 : 46,
                          height: sel ? 52 : 46,
                          decoration: BoxDecoration(
                            color: sel ? _getMoodColor(i).withAlpha(51) : AppColors.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: sel ? _getMoodColor(i) : Colors.transparent, width: 2),
                          ),
                          child: Center(child: Text(_getMoodEmoji(i), style: TextStyle(fontSize: sel ? 26 : 22))),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.subtleBorder)),
                    child: TextField(
                      controller: ctrl,
                      style: TextStyle(color: AppColors.foreground, fontSize: 15, height: 1.6),
                      decoration: InputDecoration(
                        hintText: 'О чём хотите написать?',
                        hintStyle: TextStyle(color: AppColors.dimForeground),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 8,
                      autofocus: true,
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    final now = DateTime.now();
                    final entryWithTime = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
                    print('Creating entry with date: $entryWithTime');
                    context.read<DiaryBloc>().add(CreateDiaryEntry(content: ctrl.text.trim(), moodValue: mood, entryDate: entryWithTime));
                    CasinoCoinsService().completeQuest('diary').then((_) {
                      CasinoCoinsService().refreshStatus();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.citrusOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          decoration: BoxDecoration(color: AppColors.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.citrusPurple.withAlpha(51), borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('✏️', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Text('Редактировать', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                ]),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Как вы себя чувствуете?', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      final sel = mood == i;
                      return GestureDetector(
                        onTap: () => s(() => mood = sel ? null : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: sel ? 52 : 46,
                          height: sel ? 52 : 46,
                          decoration: BoxDecoration(
                            color: sel ? _getMoodColor(i).withAlpha(51) : AppColors.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: sel ? _getMoodColor(i) : Colors.transparent, width: 2),
                          ),
                          child: Center(child: Text(_getMoodEmoji(i), style: TextStyle(fontSize: sel ? 26 : 22))),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.subtleBorder)),
                    child: TextField(
                      controller: ctrl,
                      style: TextStyle(color: AppColors.foreground, fontSize: 15, height: 1.6),
                      decoration: InputDecoration(
                        hintText: 'О чём хотите написать?',
                        hintStyle: TextStyle(color: AppColors.dimForeground),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 8,
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, top: 16),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
        decoration: BoxDecoration(color: AppColors.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(children: [
                if (e.moodValue != null) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: _getMoodColor(e.moodValue).withAlpha(51), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(_getMoodEmoji(e.moodValue), style: const TextStyle(fontSize: 32))),
                  ),
                  const SizedBox(width: 16)
                ],
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_formatDate(e.createdAt), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                  Text(_formatTime(e.createdAt), style: TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
                ])),
              ]),
            ]),
          ),
          Divider(color: AppColors.subtleBorder),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
            child: Text(e.content, style: TextStyle(color: AppColors.foreground, fontSize: 15, height: 1.8)))),
        ]),
      ),
    );
  }

  void _confirmDelete(DiaryEntry e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.destructive.withAlpha(77))),
        title: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.destructive.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 24),
          ),
          const SizedBox(width: 12),
          Text('Удалить запись?', style: TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.w600)),
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