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

class _DiaryScreenState extends State<DiaryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    final now = DateTime.now();
    context.read<DiaryBloc>().add(LoadDiaryEntries(
      startDate: DateTime(now.year - 1),
      endDate: DateTime(now.year + 1),
      search: _searchQuery.isEmpty ? null : _searchQuery,
    ));
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ru_RU').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: BlocBuilder<DiaryBloc, DiaryState>(
                    builder: (context, state) {
                      if (state is DiaryLoading) {
                        return Center(
                          child: CircularProgressIndicator(color: AppColors.citrusOrange),
                        );
                      }

                      if (state is DiaryError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                              SizedBox(height: 16),
                              Text(state.message, style: TextStyle(color: AppColors.mutedForeground)),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadEntries,
                                child: Text('Повторить'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is DiaryLoaded) {
                        if (state.entries.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book, size: 64, color: AppColors.dimForeground),
                                SizedBox(height: 16),
                                Text(
                                  'Нет записей в дневнике',
                                  style: TextStyle(color: AppColors.mutedForeground),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddEntryDialog(context),
                                  icon: Icon(Icons.add),
                                  label: Text('Добавить запись'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 80),
                          itemCount: state.entries.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildEntryCard(state.entries[index]),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'diary_fab',
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: AppColors.citrusOrange,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дневник',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
          ),
          SizedBox(height: 4),
          Text(
            'Записывайте мысли и наблюдения',
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppColors.foreground),
        decoration: InputDecoration(
          hintText: 'Поиск записей...',
          hintStyle: TextStyle(color: AppColors.mutedForeground),
          prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
          filled: true,
          fillColor: AppColors.surface1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadEntries();
                  },
                )
              : null,
        ),
        onSubmitted: (value) {
          setState(() => _searchQuery = value.trim());
          _loadEntries();
        },
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    return GestureDetector(
      onTap: () => _showEntryDetails(entry),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.moodValue != null)
              Container(
                width: 3,
                height: 60,
                decoration: BoxDecoration(
                  color: entry.moodColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (entry.moodValue != null) SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (entry.moodValue != null)
                        Text(entry.mood, style: TextStyle(fontSize: 24)),
                      if (entry.moodValue != null) SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    entry.content.length > 100
                        ? '${entry.content.substring(0, 100)}...'
                        : entry.content,
                    style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(entry.entryDate),
                        style: TextStyle(fontSize: 10, color: AppColors.dimForeground),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 18),
                            color: AppColors.citrusOrange,
                            onPressed: () => _showEditEntryDialog(context, entry),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete, size: 18),
                            color: AppColors.destructive,
                            onPressed: () => _confirmDeleteEntry(context, entry),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final contentController = TextEditingController();
    int? selectedMood;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.citrusOrange.withOpacity(0.2)),
          ),
          title: Text(
            'Новая запись',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: AppColors.mutedForeground, size: 20),
                  title: Text('Дата', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  subtitle: Text(
                    '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    style: TextStyle(color: AppColors.foreground),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setModalState(() => selectedDate = date);
                  },
                ),
                SizedBox(height: 12),
                Text('Настроение:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [0, 1, 2, 3, 4, 5].map((moodId) {
                    final isSelected = selectedMood == moodId;
                    final emoji = switch (moodId) {
                      0 => '😄', 1 => '🙂', 2 => '😐', 3 => '😟', 4 => '😢', _ => '😞',
                    };
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedMood = isSelected ? null : moodId),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.citrusOrange.withOpacity(0.2) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.citrusOrange : Colors.transparent),
                        ),
                        child: Text(emoji, style: TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  style: TextStyle(color: AppColors.foreground),
                  decoration: InputDecoration(
                    hintText: 'О чём думаете?',
                    hintStyle: TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 5,
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
            ),
            FilledButton(
              onPressed: () {
                if (contentController.text.trim().isEmpty) return;
                context.read<DiaryBloc>().add(CreateDiaryEntry(
                  content: contentController.text.trim(),
                  moodValue: selectedMood,
                  entryDate: selectedDate,
                ));
                Navigator.pop(context);
                CasinoCoinsService().completeQuest('diary');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Запись добавлена +25 🪙'), backgroundColor: Colors.green),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusOrange),
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEntryDialog(BuildContext context, DiaryEntry entry) {
    final contentController = TextEditingController(text: entry.content);
    int? selectedMood = entry.moodValue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.citrusOrange.withOpacity(0.2)),
          ),
          title: Text(
            'Редактировать запись',
            style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Настроение:', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [0, 1, 2, 3, 4, 5].map((moodId) {
                    final isSelected = selectedMood == moodId;
                    final emoji = switch (moodId) {
                      0 => '😄', 1 => '🙂', 2 => '😐', 3 => '😟', 4 => '😢', _ => '😞',
                    };
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedMood = isSelected ? null : moodId),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.citrusOrange.withOpacity(0.2) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.citrusOrange : Colors.transparent),
                        ),
                        child: Text(emoji, style: TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  style: TextStyle(color: AppColors.foreground),
                  decoration: InputDecoration(
                    hintText: 'О чём думаете?',
                    hintStyle: TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
            FilledButton(
              onPressed: () {
                if (contentController.text.trim().isEmpty) return;
                context.read<DiaryBloc>().add(UpdateDiaryEntry(
                  id: entry.id,
                  content: contentController.text.trim(),
                  moodValue: selectedMood,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Запись обновлена'), backgroundColor: Colors.green),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.citrusOrange),
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (entry.moodValue != null) Text(entry.mood, style: TextStyle(fontSize: 24)),
            if (entry.moodValue != null) SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDate(entry.entryDate),
                style: TextStyle(color: AppColors.foreground, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            entry.content,
            style: TextStyle(color: Color(0xFFD4D0D8), fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Закрыть', style: TextStyle(color: AppColors.citrusOrange))),
        ],
      ),
    );
  }

  void _confirmDeleteEntry(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.destructive.withOpacity(0.3))),
        title: Text('Удалить запись?', style: TextStyle(color: AppColors.foreground)),
        content: Text('Запись будет удалена навсегда.', style: TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground))),
          FilledButton(
            onPressed: () {
              context.read<DiaryBloc>().add(DeleteDiaryEntry(entry.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись удалена'), backgroundColor: Colors.orange));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
