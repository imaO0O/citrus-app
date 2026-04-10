import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class _MoodOption {
  final String emoji;
  final String label;
  final Color color;

  const _MoodOption({required this.emoji, required this.label, required this.color});
}

const _moodOptions = [
  _MoodOption(emoji: '\u{1F604}', label: '\u041E\u0442\u043B\u0438\u0447\u043D\u043E', color: AppColors.moodExcellent),
  _MoodOption(emoji: '\u{1F642}', label: '\u0425\u043E\u0440\u043E\u0448\u043E', color: AppColors.moodGood),
  _MoodOption(emoji: '\u{1F610}', label: '\u041D\u043E\u0440\u043C\u0430\u043B\u044C\u043D\u043E', color: AppColors.moodOkay),
  _MoodOption(emoji: '\u{1F61F}', label: '\u041F\u043B\u043E\u0445\u043E', color: AppColors.moodAnxious),
  _MoodOption(emoji: '\u{1F622}', label: '\u0423\u0436\u0430\u0441\u043D\u043E', color: AppColors.moodBad),
  _MoodOption(emoji: '\u{1F620}', label: '\u0417\u043B\u044E\u0441\u044C', color: AppColors.moodVeryBad),
];

class _DiaryEntry {
  final String id;
  final String mood;
  final Color moodColor;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime date;

  const _DiaryEntry({
    required this.id,
    required this.mood,
    required this.moodColor,
    required this.title,
    required this.content,
    required this.tags,
    required this.date,
  });
}

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_DiaryEntry> _entries = [
    _DiaryEntry(
      id: '1',
      mood: '\u{1F604}',
      moodColor: AppColors.moodExcellent,
      title: '\u041E\u0442\u043B\u0438\u0447\u043D\u044B\u0439 \u0434\u0435\u043D\u044C!',
      content: '\u0421\u0435\u0433\u043E\u0434\u043D\u044F \u0441\u0434\u0430\u043B \u043F\u0440\u043E\u0435\u043A\u0442, \u0447\u0443\u0432\u0441\u0442\u0432\u0443\u044E \u043E\u0431\u043B\u0435\u0433\u0447\u0435\u043D\u0438\u0435. \u041A\u043E\u043C\u0430\u043D\u0434\u0430 \u043F\u043E\u0440\u0430\u0434\u043E\u0432\u0430\u043B\u0430\u0441\u044C, \u043D\u0430\u0447\u0430\u043B\u044C\u043D\u0438\u043A \u043F\u043E\u0445\u0432\u0430\u043B\u0438\u043B. \u0412\u0435\u0447\u0435\u0440\u043E\u043C \u043F\u043B\u0430\u043D\u0438\u0440\u0443\u044E \u043E\u0442\u043C\u0435\u0442\u0438\u0442\u044C \u0441 \u0434\u0440\u0443\u0437\u044C\u044F\u043C\u0438.',
      tags: ['\u0440\u0430\u0431\u043E\u0442\u0430', '\u0443\u0441\u043F\u0435\u0445'],
      date: DateTime(2026, 4, 10, 18, 45),
    ),
    _DiaryEntry(
      id: '2',
      mood: '\u{1F642}',
      moodColor: AppColors.moodGood,
      title: '\u0425\u043E\u0440\u043E\u0448\u0435\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435',
      content: '\u0413\u0443\u043B\u044F\u043B \u0441 \u0434\u0440\u0443\u0437\u044C\u044F\u043C\u0438, \u0431\u044B\u043B\u043E \u0432\u0435\u0441\u0435\u043B\u043E. \u041F\u043E\u0441\u0435\u0442\u0438\u043B\u0438 \u043D\u043E\u0432\u044B\u0439 \u043F\u0430\u0440\u043A, \u043E\u0442\u043B\u0438\u0447\u043D\u043E \u043F\u0440\u043E\u0432\u0435\u043B\u0438 \u0432\u0440\u0435\u043C\u044F \u043D\u0430 \u0441\u0432\u0435\u0436\u0435\u043C \u0432\u043E\u0437\u0434\u0443\u0445\u0435.',
      tags: ['\u0434\u0440\u0443\u0437\u044C\u044F', '\u043F\u0440\u043E\u0433\u0443\u043B\u043A\u0430'],
      date: DateTime(2026, 4, 9, 12, 30),
    ),
    _DiaryEntry(
      id: '3',
      mood: '\u{1F610}',
      moodColor: AppColors.moodOkay,
      title: '\u041E\u0431\u044B\u0447\u043D\u044B\u0439 \u0434\u0435\u043D\u044C',
      content: '\u041D\u0438\u0447\u0435\u0433\u043E \u043E\u0441\u043E\u0431\u0435\u043D\u043D\u043E\u0433\u043E \u043D\u0435 \u043F\u0440\u043E\u0438\u0437\u043E\u0448\u043B\u043E. \u0420\u0430\u0431\u043E\u0442\u0430\u043B \u0438\u0437 \u0434\u043E\u043C\u0430, \u0433\u043E\u0442\u043E\u0432\u0438\u043B \u0443\u0436\u0438\u043D, \u0441\u043C\u043E\u0442\u0440\u0435\u043B \u0441\u0435\u0440\u0438\u0430\u043B.',
      tags: ['\u0440\u0443\u0442\u0438\u043D\u0430', '\u0434\u043E\u043C'],
      date: DateTime(2026, 4, 8, 9, 0),
    ),
    _DiaryEntry(
      id: '4',
      mood: '\u{1F61F}',
      moodColor: AppColors.moodAnxious,
      title: '\u0422\u0440\u0435\u0432\u043E\u0436\u043D\u044B\u0439 \u0432\u0435\u0447\u0435\u0440',
      content: '\u0411\u0435\u0441\u043F\u043E\u043A\u043E\u044E\u0441\u044C \u043E \u043F\u0440\u0435\u0434\u0441\u0442\u043E\u044F\u0449\u0435\u0439 \u043F\u0440\u0435\u0437\u0435\u043D\u0442\u0430\u0446\u0438\u0438. \u041D\u0435 \u043C\u043E\u0433\u0443 \u0441\u043E\u0441\u0440\u0435\u0434\u043E\u0442\u043E\u0447\u0438\u0442\u044C\u0441\u044F, \u043C\u044B\u0441\u043B\u0438 \u043F\u043E\u0441\u0442\u043E\u044F\u043D\u043D\u043E \u0432\u043E\u0437\u0432\u0440\u0430\u0449\u0430\u044E\u0442\u0441\u044F \u043A \u044D\u0442\u043E\u043C\u0443.',
      tags: ['\u0442\u0440\u0435\u0432\u043E\u0433\u0430', '\u043F\u0440\u0435\u0437\u0435\u043D\u0442\u0430\u0446\u0438\u044F'],
      date: DateTime(2026, 4, 7, 21, 15),
    ),
  ];

  List<_DiaryEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final query = _searchQuery.toLowerCase();
    return _entries.where((e) {
      return e.title.toLowerCase().contains(query) ||
          e.content.toLowerCase().contains(query) ||
          e.tags.any((t) => t.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              children: [
                _buildHeader(),
                _buildSearch(),
                _buildWeeklyAnalysis(),
                Expanded(
                  child: _buildEntriesList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.citrusOrange, AppColors.citrusAmber],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.citrusOrange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddEntry,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.background,
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            '\u0417\u0430\u043F\u0438\u0441\u044C',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\u0414\u041D\u0415\u0412\u041D\u0418\u041A',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_entries.length} \u0437\u0430\u043F\u0438\u0441\u0435\u0439',
                style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.foreground),
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: '\u041F\u043E\u0438\u0441\u043A...',
            hintStyle: const TextStyle(color: AppColors.mutedForeground),
            prefixIcon: const Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyAnalysis() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(255, 140, 66, 0.12),
              Color.fromRGBO(255, 173, 31, 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.citrusOrange.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_up, color: AppColors.citrusGreen, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u041D\u0435\u0434\u0435\u043B\u044C\u043D\u0430\u044F \u0441\u0432\u043E\u0434\u043A\u0430',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '\u0421\u0440\u0435\u0434\u043D\u0435\u0435: \u0425\u043E\u0440\u043E\u0448\u043E \u00B7 \u041B\u0443\u0447\u0448\u0438\u0439 \u0434\u0435\u043D\u044C: \u041F\u043D \u00B7 \u0422\u0440\u0438\u0433\u0433\u0435\u0440: \u0414\u0435\u0434\u043B\u0430\u0439\u043D\u044B',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (_filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 48, color: AppColors.dimForeground),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? '\u041D\u0435\u0442 \u0437\u0430\u043F\u0438\u0441\u0435\u0439' : '\u041D\u0438\u0447\u0435\u0433\u043E \u043D\u0435 \u043D\u0430\u0439\u0434\u0435\u043D\u043E',
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 80),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) => _buildEntryCard(_filteredEntries[index]),
    );
  }

  Widget _buildEntryCard(_DiaryEntry entry) {
    return GestureDetector(
      onTap: () => _showEntryDetails(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 60,
              decoration: BoxDecoration(
                color: entry.moodColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.mood, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.content,
                    style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: entry.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: entry.moodColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(fontSize: 10, color: entry.moodColor, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(entry.date),
                    style: const TextStyle(fontSize: 10, color: AppColors.dimForeground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(_DiaryEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A2830))),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.dimForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(entry.mood, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              entry.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: entry.moodColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 10, color: entry.moodColor)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              entry.content,
              style: const TextStyle(fontSize: 14, color: Color(0xFFD4D0D8), height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('\u0420\u0435\u0434\u0430\u043A\u0442\u0438\u0440\u043E\u0432\u0430\u0442\u044C'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.subtleBg,
                      foregroundColor: AppColors.foreground,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('\u0417\u0430\u043A\u0440\u044B\u0442\u044C', style: TextStyle(color: AppColors.mutedForeground)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEntry() {
    final moodController = ValueNotifier<int>(-1);
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFF2A2830))),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.dimForeground,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  '\u041D\u043E\u0432\u0430\u044F \u0437\u0430\u043F\u0438\u0441\u044C',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _moodOptions.length,
                  itemBuilder: (context, index) {
                    final mood = _moodOptions[index];
                    final isSelected = moodController.value == index;
                    return GestureDetector(
                      onTap: () => setModalState(() => moodController.value = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.citrusOrange.withOpacity(0.15) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? mood.color : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              mood.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? mood.color : AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: InputDecoration(
                    hintText: '\u0417\u0430\u0433\u043E\u043B\u043E\u0432\u043E\u043A',
                    hintStyle: const TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: AppColors.foreground),
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: '\u041A\u0430\u043A \u0432\u044B \u0441\u0435\u0431\u044F \u0447\u0443\u0432\u0441\u0442\u0432\u0443\u0435\u0442\u0435?',
                    hintStyle: const TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (moodController.value == -1) return;
                        if (titleController.text.trim().isEmpty) return;
                        if (contentController.text.trim().isEmpty) return;

                        final mood = _moodOptions[moodController.value];
                        setState(() {
                          _entries.insert(0, _DiaryEntry(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            mood: mood.emoji,
                            moodColor: mood.color,
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            tags: [],
                            date: DateTime.now(),
                          ));
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        '\u0421\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u044C',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '\u044F\u043D\u0432', '\u0444\u0435\u0432', '\u043C\u0430\u0440', '\u0430\u043F\u0440',
      '\u043C\u0430\u0439', '\u0438\u044E\u043D', '\u0438\u044E\u043B', '\u0430\u0432\u0433',
      '\u0441\u0435\u043D', '\u043E\u043A\u0442', '\u043D\u043E\u044F', '\u0434\u0435\u043A',
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month, $hour:$minute';
  }
}
