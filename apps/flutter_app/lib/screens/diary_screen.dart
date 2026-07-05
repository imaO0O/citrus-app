import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/citrus_button.dart';
import '../core/widgets/citrus_empty_state.dart';
import '../core/services/casino_coins_service.dart';
import '../features/diary/bloc/diary_bloc.dart';
import '../core/repository/diary_repository.dart';
import '../core/utils/app_size.dart';
import 'models/mood.dart';

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

  int? _moodFilter;
  DateTimeRange? _dateRange;
  String? _tagFilter;

  // Вопросы-подсказки для записи (ротация снижает барьер «не знаю, что писать»).
  static const _prompts = [
    'За что ты благодарен сегодня?',
    'Что тебя сейчас тревожит?',
    'Что хорошего случилось за день?',
    'Чем ты сегодня гордишься?',
    'Какие три вещи порадовали тебя?',
    'Что бы ты хотел(а) отпустить?',
    'Что бы ты сказал(а) себе вчерашнему?',
    'Какое чувство сейчас сильнее всего — и почему?',
    'Что помогло тебе справиться сегодня?',
  ];

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

  // ===== Хелперы дат/настроения (палитра Mood — как у долек на главной) =====

  String _getMoodEmoji(int? v) => v == null ? '' : Mood.all[v.clamp(0, 5)].emoji;
  Color _getMoodColor(int? v) => v == null ? AppColors.dimForeground : Mood.all[v.clamp(0, 5)].color;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Сегодня';
    if (d == yesterday) return 'Вчера';
    return DateFormat('d MMMM yyyy', 'ru_RU').format(date);
  }

  String _formatTime(DateTime date) => DateFormat('HH:mm', 'ru_RU').format(date);

  String _monthName(int m) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return months[m - 1];
  }

  DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  // ===== Вычисления из записей (всё на клиенте, без бэкенда) =====

  /// Серия: сколько дней подряд (вкл. сегодня или вчера) есть записи.
  int _calcStreak(List<DiaryEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = entries.map((e) => _dayOf(e.entryDate)).toSet();
    var cursor = _dayOf(DateTime.now());
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(Duration(days: 1));
    }
    return streak;
  }

  /// «В этот день»: запись примерно год или месяц назад (±1 день).
  DiaryEntry? _onThisDay(List<DiaryEntry> entries) {
    final now = DateTime.now();
    final targets = [
      DateTime(now.year - 1, now.month, now.day),
      DateTime(now.year, now.month - 1, now.day),
    ];
    for (final target in targets) {
      for (final e in entries) {
        if (_dayOf(e.entryDate).difference(target).inDays.abs() <= 1) return e;
      }
    }
    return null;
  }

  List<DiaryEntry> _applyFilters(List<DiaryEntry> entries) {
    final list = entries.where((e) {
      if (_moodFilter != null && e.moodValue != _moodFilter) return false;
      if (_tagFilter != null && !e.tags.contains(_tagFilter)) return false;
      if (_dateRange != null) {
        final d = _dayOf(e.entryDate);
        if (d.isBefore(_dayOf(_dateRange!.start)) || d.isAfter(_dayOf(_dateRange!.end))) return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return list;
  }

  bool get _hasActiveFilter => _moodFilter != null || _dateRange != null || _tagFilter != null;

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
              _buildActiveFilters(),
              Expanded(child: _buildContent()),
            ]),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          heroTag: 'diary_fab',
          onPressed: () => _showWritingSheet(),
          backgroundColor: AppColors.citrusOrange,
          icon: Icon(Icons.edit_note, color: Colors.white),
          label: Text('Запись', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.citrusOrange, Color(0xFFFF7020)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppSize.radius(16),
          ),
          child: Center(child: Text('📔', style: TextStyle(fontSize: AppSize.s(24)))),
        ),
        AppSize.gapW(14),
        Expanded(child: Text('Дневник', style: AppText.displayTitle)),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(children: [
        Expanded(
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
                contentPadding: AppSize.paddingH(16, 14),
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
        ),
        AppSize.gapW(10),
        GestureDetector(
          onTap: _showFiltersSheet,
          child: Container(
            padding: AppSize.padding(13),
            decoration: BoxDecoration(
              color: _hasActiveFilter ? AppColors.citrusOrange.withValues(alpha: 0.15) : AppColors.surface1,
              borderRadius: AppSize.radius(16),
              border: Border.all(color: _hasActiveFilter ? AppColors.citrusOrange : Colors.transparent, width: 1.5),
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              Icon(Icons.tune_rounded, size: AppSize.s(22), color: _hasActiveFilter ? AppColors.citrusOrange : AppColors.mutedForeground),
              if (_hasActiveFilter)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: AppSize.s(8),
                    height: AppSize.s(8),
                    decoration: BoxDecoration(color: AppColors.citrusOrange, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 1.5)),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  String _rangeLabel(DateTimeRange r) =>
      '${r.start.day}.${r.start.month}–${r.end.day}.${r.end.month}';

  Widget _buildActiveFilters() {
    if (!_hasActiveFilter) return const SizedBox.shrink();

    Widget chip(String label, VoidCallback onRemove) => GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: AppSize.paddingH(11, 6),
            decoration: BoxDecoration(
              color: AppColors.citrusOrange.withValues(alpha: 0.12),
              borderRadius: AppSize.radius(999),
              border: Border.all(color: AppColors.citrusOrange.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: TextStyle(fontSize: AppSize.s(12), color: AppColors.citrusOrange, fontWeight: FontWeight.w600)),
              AppSize.gapW(5),
              Icon(Icons.close_rounded, size: AppSize.s(13), color: AppColors.citrusOrange),
            ]),
          ),
        );

    final chips = <Widget>[];
    if (_moodFilter != null) {
      chips.add(chip('${Mood.all[_moodFilter!].emoji} ${Mood.all[_moodFilter!].label}', () => setState(() => _moodFilter = null)));
    }
    if (_tagFilter != null) {
      chips.add(chip('#$_tagFilter', () => setState(() => _tagFilter = null)));
    }
    if (_dateRange != null) {
      chips.add(chip(_rangeLabel(_dateRange!), () => setState(() => _dateRange = null)));
    }
    chips.add(GestureDetector(
      onTap: () => setState(() { _moodFilter = null; _tagFilter = null; _dateRange = null; }),
      child: Padding(
        padding: AppSize.paddingH(4, 6),
        child: Text('Сбросить всё', style: TextStyle(fontSize: AppSize.s(12), color: AppColors.dimForeground, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
      ),
    ));

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: chips),
    );
  }

  void _showFiltersSheet() {
    final state = context.read<DiaryBloc>().state;
    final allTags = <String>{};
    if (state is DiaryLoaded) {
      for (final e in state.entries) {
        allTags.addAll(e.tags);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          void refresh() {
            setSheet(() {});
            setState(() {});
          }

          Widget sectionTitle(String t) => Text(t, style: TextStyle(fontSize: AppSize.s(13), color: AppColors.mutedForeground, fontWeight: FontWeight.w600));

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.s(24))),
            ),
            padding: EdgeInsets.fromLTRB(AppSize.s(20), AppSize.s(12), AppSize.s(20), AppSize.s(20) + MediaQuery.of(sheetCtx).padding.bottom),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Center(child: Container(width: AppSize.s(40), height: AppSize.s(4), decoration: BoxDecoration(color: AppColors.subtleBorder, borderRadius: AppSize.radius(2)))),
                AppSize.gapH(16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Фильтры', style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w700, color: AppColors.foreground)),
                  if (_hasActiveFilter)
                    GestureDetector(
                      onTap: () { _moodFilter = null; _tagFilter = null; _dateRange = null; refresh(); },
                      child: Text('Сбросить', style: TextStyle(fontSize: AppSize.s(13), color: AppColors.citrusOrange, fontWeight: FontWeight.w600)),
                    ),
                ]),
                AppSize.gapH(20),
                sectionTitle('Настроение'),
                AppSize.gapH(12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (i) {
                  final active = _moodFilter == i;
                  final c = Mood.all[i].color;
                  return GestureDetector(
                    onTap: () { _moodFilter = active ? null : i; refresh(); },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 160),
                      width: AppSize.s(46),
                      height: AppSize.s(46),
                      decoration: BoxDecoration(
                        color: active ? c.withValues(alpha: 0.22) : AppColors.surface2,
                        shape: BoxShape.circle,
                        border: Border.all(color: active ? c : Colors.transparent, width: 2),
                      ),
                      child: Center(child: Text(Mood.all[i].emoji, style: TextStyle(fontSize: AppSize.s(22)))),
                    ),
                  );
                })),
                AppSize.gapH(22),
                sectionTitle('Период'),
                AppSize.gapH(12),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final range = await showDateRangePicker(
                      context: sheetCtx,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      initialDateRange: _dateRange ?? DateTimeRange(start: now.subtract(Duration(days: 7)), end: now),
                    );
                    if (range != null) { _dateRange = range; refresh(); }
                  },
                  child: Container(
                    padding: AppSize.paddingH(14, 13),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(14)),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, size: AppSize.s(18), color: AppColors.citrusOrange),
                      AppSize.gapW(12),
                      Expanded(
                        child: Text(
                          _dateRange == null
                              ? 'Любой период'
                              : '${_dateRange!.start.day}.${_dateRange!.start.month}.${_dateRange!.start.year} – ${_dateRange!.end.day}.${_dateRange!.end.month}.${_dateRange!.end.year}',
                          style: TextStyle(color: _dateRange == null ? AppColors.mutedForeground : AppColors.foreground, fontSize: AppSize.s(13), fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (_dateRange != null)
                        GestureDetector(onTap: () { _dateRange = null; refresh(); }, child: Icon(Icons.close_rounded, size: AppSize.s(16), color: AppColors.dimForeground)),
                    ]),
                  ),
                ),
                if (allTags.isNotEmpty) ...[
                  AppSize.gapH(22),
                  sectionTitle('Теги'),
                  AppSize.gapH(12),
                  Wrap(spacing: 8, runSpacing: 8, children: allTags.map((tag) {
                    final active = _tagFilter == tag;
                    return GestureDetector(
                      onTap: () { _tagFilter = active ? null : tag; refresh(); },
                      child: Container(
                        padding: AppSize.paddingH(13, 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.citrusPurple.withValues(alpha: 0.18) : AppColors.surface2,
                          borderRadius: AppSize.radius(999),
                          border: Border.all(color: active ? AppColors.citrusPurple : Colors.transparent),
                        ),
                        child: Text('#$tag', style: TextStyle(fontSize: AppSize.s(12), color: active ? AppColors.citrusPurple : AppColors.mutedForeground, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList()),
                ],
                AppSize.gapH(24),
                CitrusButton(
                  label: 'Показать записи',
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<DiaryBloc, DiaryState>(builder: (ctx, state) {
      if (state is DiaryLoading) return Center(child: CircularProgressIndicator(color: AppColors.citrusOrange, strokeWidth: 3));
      if (state is DiaryError) return _buildError(state.message);
      if (state is DiaryLoaded) return state.entries.isEmpty ? _buildEmpty() : _buildBody(state.entries);
      return SizedBox.shrink();
    });
  }

  Widget _buildBody(List<DiaryEntry> allEntries) {
    final filtered = _applyFilters(allEntries);
    final streak = _calcStreak(allEntries);
    final onThisDay = (_hasActiveFilter || _searchQuery.isNotEmpty) ? null : _onThisDay(allEntries);

    final children = <Widget>[];

    if (streak >= 2) {
      children.add(Padding(
        padding: AppSize.paddingOnly(bottom: 12),
        child: Row(children: [
          Container(
            padding: AppSize.paddingH(12, 6),
            decoration: BoxDecoration(color: AppColors.citrusAmber.withValues(alpha: 0.15), borderRadius: AppSize.radius(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🔥', style: TextStyle(fontSize: AppSize.s(14))),
              AppSize.gapW(6),
              Text('$streak ${_dayWord(streak)} подряд', style: TextStyle(fontSize: AppSize.s(12), color: AppColors.citrusAmber, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ));
    }

    if (allEntries.length >= 2) {
      children.add(Padding(padding: AppSize.paddingOnly(bottom: 16), child: _buildHeatmap(allEntries)));
    }

    if (onThisDay != null) {
      children.add(Padding(padding: AppSize.paddingOnly(bottom: 16), child: _buildOnThisDay(onThisDay)));
    }

    if (filtered.isEmpty) {
      children.add(Padding(
        padding: AppSize.padding(32),
        child: Center(child: Text('По выбранным фильтрам записей нет', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14)))),
      ));
    } else {
      String? lastHeader;
      for (final e in filtered) {
        final header = _formatDate(e.entryDate);
        if (header != lastHeader) {
          lastHeader = header;
          children.add(Padding(
            padding: AppSize.paddingOnly(top: 6, bottom: 8),
            child: Text(header, style: TextStyle(fontSize: AppSize.s(13), fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
          ));
        }
        children.add(Padding(padding: AppSize.paddingOnly(bottom: 10), child: _buildCard(e)));
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: children,
    );
  }

  String _dayWord(int n) {
    final n100 = n % 100;
    final n10 = n % 10;
    if (n100 >= 11 && n100 <= 14) return 'дней';
    if (n10 == 1) return 'день';
    if (n10 >= 2 && n10 <= 4) return 'дня';
    return 'дней';
  }

  Widget _buildHeatmap(List<DiaryEntry> entries) {
    final byDay = <String, List<int>>{};
    for (final e in entries) {
      if (e.moodValue == null) continue;
      final d = _dayOf(e.entryDate);
      byDay.putIfAbsent('${d.year}-${d.month}-${d.day}', () => []).add(e.moodValue!);
    }
    final today = _dayOf(DateTime.now());
    final cells = <Widget>[];
    for (int i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final list = byDay['${d.year}-${d.month}-${d.day}'];
      final hasData = list != null && list.isNotEmpty;
      final color = hasData
          ? Mood.all[(list.reduce((a, b) => a + b) / list.length).round().clamp(0, 5)].color
          : AppColors.surface2;
      cells.add(Expanded(
        child: Padding(
          padding: AppSize.paddingH(2, 0),
          child: Container(
            height: AppSize.s(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppSize.radius(3),
              border: hasData ? null : Border.all(color: AppColors.subtleBorder),
            ),
          ),
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('настроение за 2 недели', style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground)),
      AppSize.gapH(6),
      Row(children: cells),
    ]);
  }

  Widget _buildOnThisDay(DiaryEntry e) {
    return GestureDetector(
      onTap: () => _showDetails(e),
      child: Container(
        padding: AppSize.padding(14),
        decoration: BoxDecoration(
          color: AppColors.citrusPurple.withValues(alpha: 0.10),
          borderRadius: AppSize.radius(16),
          border: Border.all(color: AppColors.citrusPurple.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.history_rounded, size: AppSize.s(16), color: AppColors.citrusPurple),
            AppSize.gapW(6),
            Text('В этот день · ${e.entryDate.day} ${_monthName(e.entryDate.month)} ${e.entryDate.year}',
                style: TextStyle(fontSize: AppSize.s(12), fontWeight: FontWeight.w600, color: AppColors.citrusPurple)),
          ]),
          AppSize.gapH(8),
          Text(
            e.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: AppSize.s(13), color: AppColors.foreground, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    final prompt = _prompts[DateTime.now().day % _prompts.length];
    return Center(
      child: SingleChildScrollView(
        padding: AppSize.padding(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.citrusOrange.withAlpha(38), AppColors.citrusAmber.withAlpha(25)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('📔', style: TextStyle(fontSize: AppSize.s(48)))),
          ),
          AppSize.gapH(20),
          Text('Начните свой дневник', style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.w700, color: AppColors.foreground)),
          AppSize.gapH(16),
          Container(
            padding: AppSize.padding(16),
            decoration: BoxDecoration(color: AppColors.surface1, borderRadius: AppSize.radius(16), border: Border.all(color: AppColors.subtleBorder)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('💭', style: TextStyle(fontSize: AppSize.s(16))),
                AppSize.gapW(8),
                Flexible(child: Text(prompt, textAlign: TextAlign.center, style: TextStyle(fontSize: AppSize.s(14), color: AppColors.foreground, fontWeight: FontWeight.w500))),
              ]),
            ]),
          ),
          AppSize.gapH(20),
          CitrusButton(
            label: 'Написать',
            icon: Icons.add_rounded,
            expand: false,
            onPressed: () => _showWritingSheet(),
          ),
        ]),
      ),
    );
  }

  Widget _buildError(String msg) {
    return CitrusEmptyState(
      title: 'Что-то пошло не так',
      subtitle: msg,
      actionLabel: 'Повторить',
      actionIcon: Icons.refresh_rounded,
      onAction: _loadEntries,
    );
  }

  Widget _buildCard(DiaryEntry e) {
    final color = _getMoodColor(e.moodValue);
    final preview = e.content.length > 140 ? '${e.content.substring(0, 140)}…' : e.content;
    return GestureDetector(
      onTap: () => _showDetails(e),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: AppSize.radius(16),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: ClipRRect(
          borderRadius: AppSize.radius(16),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 4, color: e.moodValue != null ? color : AppColors.subtleBorder),
              Expanded(
                child: Padding(
                  padding: AppSize.padding(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (e.moodValue != null) ...[
                        Text(_getMoodEmoji(e.moodValue), style: TextStyle(fontSize: AppSize.s(16))),
                        AppSize.gapW(8),
                      ],
                      Text(_formatTime(e.createdAt), style: TextStyle(fontSize: AppSize.s(12), color: AppColors.dimForeground)),
                      Spacer(),
                      GestureDetector(
                        onTap: () => _showOptions(e),
                        child: Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.dimForeground),
                      ),
                    ]),
                    AppSize.gapH(8),
                    Text(
                      preview,
                      style: TextStyle(fontSize: AppSize.s(13), color: AppColors.foreground, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (e.tags.isNotEmpty) ...[
                      AppSize.gapH(8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: e.tags.take(4).map((t) => Container(
                          padding: AppSize.paddingH(8, 3),
                          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(999)),
                          child: Text('#$t', style: TextStyle(fontSize: AppSize.s(11), color: AppColors.mutedForeground)),
                        )).toList(),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _mdStyle() => MarkdownStyleSheet(
        p: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), height: 1.8),
        h1: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(20), fontWeight: FontWeight.w700),
        h2: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w600),
        h3: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w600),
        strong: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w700),
        em: TextStyle(color: AppColors.foreground, fontStyle: FontStyle.italic),
        listBullet: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15)),
        blockquote: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(15)),
      );

  void _showOptions(DiaryEntry e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: AppSize.padding(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: AppSize.radius(2))),
          AppSize.gapH(20),
          ListTile(
            leading: Icon(Icons.edit_rounded, color: AppColors.citrusOrange),
            title: Text('Редактировать', style: TextStyle(color: AppColors.foreground)),
            onTap: () { Navigator.pop(ctx); _showWritingSheet(entry: e); },
          ),
          ListTile(
            leading: Icon(Icons.delete_rounded, color: AppColors.destructive),
            title: Text('Удалить', style: TextStyle(color: AppColors.destructive)),
            onTap: () { Navigator.pop(ctx); _confirmDelete(e); },
          ),
          AppSize.gapH(8),
        ]),
      ),
    );
  }

  /// Единый экран письма для новой записи и редактирования.
  void _showWritingSheet({DiaryEntry? entry}) {
    final isEdit = entry != null;
    final ctrl = TextEditingController(text: entry?.content ?? '');
    final tagCtrl = TextEditingController();
    final tags = <String>[...?entry?.tags];
    final speech = stt.SpeechToText();
    bool isListening = false;
    bool speechReady = false;
    String baseText = '';
    int? mood = entry?.moodValue;
    DateTime date = entry?.entryDate ?? DateTime.now();
    var prompt = _prompts[DateTime.now().millisecondsSinceEpoch % _prompts.length];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, s) {
        Future<void> toggleMic() async {
          if (isListening) {
            await speech.stop();
            s(() => isListening = false);
            return;
          }
          if (!speechReady) {
            speechReady = await speech.initialize(
              debugLogging: true,
              onStatus: (st) {
                debugPrint('STT status: $st');
                if ((st == 'done' || st == 'notListening') && isListening) s(() => isListening = false);
              },
              onError: (e) {
                debugPrint('STT error: ${e.errorMsg} permanent=${e.permanent}');
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Речь: ${e.errorMsg}')));
                if (isListening) s(() => isListening = false);
              },
            );
          }
          if (!speechReady) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Распознавание речи недоступно на этом устройстве')));
            }
            return;
          }
          baseText = ctrl.text;
          s(() => isListening = true);
          await speech.listen(
            listenOptions: stt.SpeechListenOptions(
              partialResults: true,
              cancelOnError: true,
              localeId: 'ru_RU',
              listenFor: const Duration(seconds: 60),
              pauseFor: const Duration(seconds: 4),
            ),
            onResult: (r) {
              debugPrint('STT result: "${r.recognizedWords}" final=${r.finalResult}');
              final sep = (baseText.isEmpty || baseText.endsWith(' ') || baseText.endsWith('\n')) ? '' : ' ';
              final text = baseText + sep + r.recognizedWords;
              ctrl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
            },
          );
        }
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(
              padding: AppSize.padding(20),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: AppSize.radius(2))),
                AppSize.gapH(16),
                Row(children: [
                  Text(isEdit ? '✏️' : '✍️', style: TextStyle(fontSize: AppSize.s(22))),
                  AppSize.gapW(12),
                  Text(isEdit ? 'Редактировать' : 'Новая запись', style: TextStyle(fontSize: AppSize.s(20), fontWeight: FontWeight.w700, color: AppColors.foreground)),
                ]),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSize.paddingH(20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Дата
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) s(() => date = d);
                    },
                    child: Container(
                      padding: AppSize.paddingH(14, 12),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(12)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded, color: AppColors.citrusOrange, size: 18),
                        AppSize.gapW(12),
                        Text('${date.day} ${_monthName(date.month)} ${date.year}', style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w500)),
                        Spacer(),
                        Icon(Icons.arrow_drop_down_rounded, color: AppColors.dimForeground),
                      ]),
                    ),
                  ),
                  AppSize.gapH(14),
                  // Промпт-подсказка (только для новой записи)
                  if (!isEdit) ...[
                    Container(
                      padding: AppSize.padding(14),
                      decoration: BoxDecoration(
                        color: AppColors.citrusPurple.withValues(alpha: 0.10),
                        borderRadius: AppSize.radius(12),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('💭', style: TextStyle(fontSize: AppSize.s(16))),
                          AppSize.gapW(8),
                          Expanded(child: Text(prompt, style: TextStyle(fontSize: AppSize.s(14), color: AppColors.foreground, fontWeight: FontWeight.w500, height: 1.4))),
                        ]),
                        AppSize.gapH(8),
                        GestureDetector(
                          onTap: () => s(() => prompt = (_prompts.toList()..shuffle()).firstWhere((p) => p != prompt, orElse: () => prompt)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.refresh_rounded, size: AppSize.s(14), color: AppColors.citrusPurple),
                            AppSize.gapW(4),
                            Text('другой вопрос', style: TextStyle(fontSize: AppSize.s(12), color: AppColors.citrusPurple)),
                          ]),
                        ),
                      ]),
                    ),
                    AppSize.gapH(14),
                  ],
                  // Настроение
                  Text('Как вы себя чувствуете?', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), fontWeight: FontWeight.w500)),
                  AppSize.gapH(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      final sel = mood == i;
                      return GestureDetector(
                        onTap: () => s(() => mood = sel ? null : i),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: sel ? 50 : 44,
                          height: sel ? 50 : 44,
                          decoration: BoxDecoration(
                            color: sel ? _getMoodColor(i).withAlpha(51) : AppColors.surface2,
                            borderRadius: AppSize.radius(14),
                            border: Border.all(color: sel ? _getMoodColor(i) : Colors.transparent, width: 2),
                          ),
                          child: Center(child: Text(Mood.all[i].emoji, style: TextStyle(fontSize: sel ? 25 : 21))),
                        ),
                      );
                    }),
                  ),
                  AppSize.gapH(16),
                  // Теги (отдельное поле, не из текста)
                  Text('Теги', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), fontWeight: FontWeight.w500)),
                  AppSize.gapH(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...tags.map((t) => GestureDetector(
                        onTap: () => s(() => tags.remove(t)),
                        child: Container(
                          padding: AppSize.paddingH(10, 6),
                          decoration: BoxDecoration(color: AppColors.citrusPurple.withValues(alpha: 0.15), borderRadius: AppSize.radius(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('#$t', style: TextStyle(fontSize: AppSize.s(12), color: AppColors.citrusPurple, fontWeight: FontWeight.w500)),
                            AppSize.gapW(4),
                            Icon(Icons.close, size: AppSize.s(13), color: AppColors.citrusPurple),
                          ]),
                        ),
                      )),
                      SizedBox(
                        width: AppSize.s(120),
                        child: TextField(
                          controller: tagCtrl,
                          style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(13)),
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '+ тег',
                            hintStyle: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(13)),
                            filled: true,
                            fillColor: AppColors.surface2,
                            contentPadding: AppSize.paddingH(12, 8),
                            border: OutlineInputBorder(borderRadius: AppSize.radius(999), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (v) {
                            final raw = v.trim().replaceAll('#', '');
                            if (raw.isNotEmpty && !tags.contains(raw)) tags.add(raw);
                            tagCtrl.clear();
                            s(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSize.gapH(16),
                  // Текст
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(14), border: Border.all(color: AppColors.subtleBorder)),
                    child: TextField(
                      controller: ctrl,
                      style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), height: 1.6),
                      decoration: InputDecoration(
                        hintText: 'Пиши свободно, никто кроме тебя это не увидит…',
                        hintStyle: TextStyle(color: AppColors.dimForeground),
                        border: InputBorder.none,
                        contentPadding: AppSize.padding(14),
                      ),
                      maxLines: 8,
                      autofocus: !isEdit,
                    ),
                  ),
                  AppSize.gapH(10),
                  Row(children: [
                    GestureDetector(
                      onTap: toggleMic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: AppSize.paddingH(14, 9),
                        decoration: BoxDecoration(
                          color: isListening ? AppColors.citrusOrange : AppColors.surface2,
                          borderRadius: AppSize.radius(999),
                          border: Border.all(color: isListening ? AppColors.citrusOrange : AppColors.subtleBorder),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded, size: AppSize.s(17), color: isListening ? Colors.white : AppColors.citrusOrange),
                          AppSize.gapW(7),
                          Text(isListening ? 'Слушаю… нажмите, чтобы остановить' : 'Надиктовать голосом',
                              style: TextStyle(fontSize: AppSize.s(12), color: isListening ? Colors.white : AppColors.foreground, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                  AppSize.gapH(8),
                  Text('Разметка: **жирный**, *курсив*, списки', style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground)),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: AppSize.w(20), right: AppSize.w(20), bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSize.h(20), top: AppSize.h(12)),
              child: CitrusButton(
                label: 'Сохранить',
                onPressed: () {
                  if (isListening) speech.stop();
                  if (ctrl.text.trim().isEmpty) return;
                  if (isEdit) {
                    context.read<DiaryBloc>().add(UpdateDiaryEntry(id: entry.id, content: ctrl.text.trim(), moodValue: mood, tags: tags));
                  } else {
                    final now = DateTime.now();
                    final entryWithTime = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
                    context.read<DiaryBloc>().add(CreateDiaryEntry(content: ctrl.text.trim(), moodValue: mood, entryDate: entryWithTime, tags: tags));
                    CasinoCoinsService().completeQuest('diary').then((_) => CasinoCoinsService().refreshStatus());
                  }
                  Navigator.pop(ctx);
                },
              ),
            ),
          ]),
        );
      },
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
            padding: AppSize.padding(20),
            child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.dimForeground, borderRadius: AppSize.radius(2))),
              AppSize.gapH(18),
              Row(children: [
                if (e.moodValue != null) ...[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: _getMoodColor(e.moodValue).withAlpha(51), borderRadius: AppSize.radius(16)),
                    child: Center(child: Text(_getMoodEmoji(e.moodValue), style: TextStyle(fontSize: AppSize.s(30)))),
                  ),
                  AppSize.gapW(14),
                ],
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_formatDate(e.entryDate), style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w700, color: AppColors.foreground)),
                  Text(_formatTime(e.createdAt), style: TextStyle(fontSize: AppSize.s(14), color: AppColors.mutedForeground)),
                ])),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: AppColors.citrusOrange),
                  tooltip: 'Редактировать',
                  onPressed: () { Navigator.pop(ctx); _showWritingSheet(entry: e); },
                ),
              ]),
            ]),
          ),
          Divider(color: AppColors.subtleBorder, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSize.padding(20),
              child: MarkdownBody(data: e.content, styleSheet: _mdStyle()),
            ),
          ),
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
        title: Text('Удалить запись?', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(18), fontWeight: FontWeight.w600)),
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
