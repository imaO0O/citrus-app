import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ExerciseItem {
  final String id;
  final String icon;
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final String type;
  final String category;
  final List<String> steps;
  final Color color;
  final int durationSeconds;

  const ExerciseItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.type,
    required this.category,
    required this.steps,
    this.color = AppColors.citrusOrange,
    required this.durationSeconds,
  });
}

const _categories = ['\u0412\u0441\u0435', '\u0414\u044B\u0445\u0430\u043D\u0438\u0435', '\u0420\u0430\u0441\u0441\u043B\u0430\u0431\u043B\u0435\u043D\u0438\u0435', '\u0424\u043E\u043A\u0443\u0441', '\u042D\u043D\u0435\u0440\u0433\u0438\u044F'];

const _exercises = [
  ExerciseItem(
    id: 'box_breathing',
    icon: '\u{1F32C}\u{FE0F}',
    title: '\u041A\u0432\u0430\u0434\u0440\u0430\u0442\u043D\u043E\u0435 \u0434\u044B\u0445\u0430\u043D\u0438\u0435',
    description: '\u0422\u0435\u0445\u043D\u0438\u043A\u0430 4-4-4-4 \u0434\u043B\u044F \u0441\u043D\u044F\u0442\u0438\u044F \u0441\u0442\u0440\u0435\u0441\u0441\u0430 \u0438 \u0443\u043B\u0443\u0447\u0448\u0435\u043D\u0438\u044F \u043A\u043E\u043D\u0446\u0435\u043D\u0442\u0440\u0430\u0446\u0438\u0438',
    duration: '5 \u043C\u0438\u043D',
    difficulty: '\u041B\u0435\u0433\u043A\u043E',
    type: '\u0414\u044B\u0445\u0430\u043D\u0438\u0435',
    category: '\u0414\u044B\u0445\u0430\u043D\u0438\u0435',
    color: AppColors.citrusGreen,
    steps: [
      '\u0412\u0434\u043E\u0445\u043D\u0438\u0442\u0435 \u0447\u0435\u0440\u0435\u0437 \u043D\u043E\u0441 \u043D\u0430 4 \u0441\u0447\u0451\u0442\u0430',
      '\u0417\u0430\u0434\u0435\u0440\u0436\u0438\u0442\u0435 \u0434\u044B\u0445\u0430\u043D\u0438\u0435 \u043D\u0430 4 \u0441\u0447\u0451\u0442\u0430',
      '\u0412\u044B\u0434\u043E\u0445\u043D\u0438\u0442\u0435 \u0447\u0435\u0440\u0435\u0437 \u0440\u043E\u0442 \u043D\u0430 4 \u0441\u0447\u0451\u0442\u0430',
      '\u0417\u0430\u0434\u0435\u0440\u0436\u0438\u0442\u0435 \u0434\u044B\u0445\u0430\u043D\u0438\u0435 \u043D\u0430 4 \u0441\u0447\u0451\u0442\u0430',
      '\u041F\u043E\u0432\u0442\u043E\u0440\u044F\u0439\u0442\u0435 \u0446\u0438\u043A\u043B 5 \u043C\u0438\u043D\u0443\u0442',
    ],
    durationSeconds: 300,
  ),
  ExerciseItem(
    id: 'progressive_relaxation',
    icon: '\u{1F9D8}',
    title: '\u041F\u0440\u043E\u0433\u0440\u0435\u0441\u0441\u0438\u0432\u043D\u0430\u044F \u0440\u0435\u043B\u0430\u043A\u0441\u0430\u0446\u0438\u044F',
    description: '\u041F\u043E\u0441\u043B\u0435\u0434\u043E\u0432\u0430\u0442\u0435\u043B\u044C\u043D\u043E\u0435 \u043D\u0430\u043F\u0440\u044F\u0436\u0435\u043D\u0438\u0435 \u0438 \u0440\u0430\u0441\u0441\u043B\u0430\u0431\u043B\u0435\u043D\u0438\u0435 \u043C\u044B\u0448\u0446 \u0442\u0435\u043B\u0430',
    duration: '10 \u043C\u0438\u043D',
    difficulty: '\u0421\u0440\u0435\u0434\u043D\u0435',
    type: '\u0420\u0430\u0441\u0441\u043B\u0430\u0431\u043B\u0435\u043D\u0438\u0435',
    category: '\u0420\u0430\u0441\u0441\u043B\u0430\u0431\u043B\u0435\u043D\u0438\u0435',
    color: Color(0xFF9C88FF),
    steps: [
      '\u041D\u0430\u043F\u0440\u044F\u0433\u0438\u0442\u0435 \u043C\u044B\u0448\u0446\u044B \u043D\u043E\u0433 \u043D\u0430 5 \u0441\u0435\u043A\u0443\u043D\u0434, \u0437\u0430\u0442\u0435\u043C \u0440\u0430\u0441\u0441\u043B\u0430\u0431\u044C\u0442\u0435',
      '\u041F\u0435\u0440\u0435\u0439\u0434\u0438\u0442\u0435 \u043A \u0438\u043A\u0440\u0430\u043C, \u0431\u0451\u0434\u0440\u0430\u043C, \u0436\u0438\u0432\u043E\u0442\u0443',
      '\u041D\u0430\u043F\u0440\u044F\u0433\u0438\u0442\u0435 \u0440\u0443\u043A\u0438 \u0438 \u043F\u043B\u0435\u0447\u0438',
      '\u0421\u043E\u0436\u043C\u0438\u0442\u0435 \u0438 \u0440\u0430\u0441\u0441\u043B\u0430\u0431\u044C\u0442\u0435 \u043C\u044B\u0448\u0446\u044B \u043B\u0438\u0446\u0430',
      '\u041F\u043E\u0447\u0443\u0432\u0441\u0442\u0432\u0443\u0439\u0442\u0435 \u0440\u0430\u0437\u043D\u0438\u0446\u0443 \u043C\u0435\u0436\u0434\u0443 \u043D\u0430\u043F\u0440\u044F\u0436\u0435\u043D\u0438\u0435\u043C \u0438 \u0440\u0430\u0441\u0441\u043B\u0430\u0431\u043B\u0435\u043D\u0438\u0435\u043C',
    ],
    durationSeconds: 600,
  ),
  ExerciseItem(
    id: 'visualization',
    icon: '\u{1F30A}',
    title: '\u0412\u0438\u0437\u0443\u0430\u043B\u0438\u0437\u0430\u0446\u0438\u044F',
    description: '\u041F\u043E\u0433\u0440\u0443\u0437\u0438\u0442\u0435\u0441\u044C \u0432 \u0441\u043F\u043E\u043A\u043E\u0439\u043D\u043E\u0435 \u043C\u044B\u0441\u043B\u0435\u043D\u043D\u043E\u0435 \u043F\u0443\u0442\u0435\u0448\u0435\u0441\u0442\u0432\u0438\u0435',
    duration: '8 \u043C\u0438\u043D',
    difficulty: '\u041B\u0435\u0433\u043A\u043E',
    type: '\u0420\u0430\u0441\u0441\u043B\u0430\u0431\u043B\u0435\u043D\u0438\u0435',
    category: '\u0420\u0430\u0441\u0441\u043B\u0430\u0431\u043B\u0435\u043D\u0438\u0435',
    color: Color(0xFF74B9FF),
    steps: [
      '\u0417\u0430\u043A\u0440\u043E\u0439\u0442\u0435 \u0433\u043B\u0430\u0437\u0430 \u0438 \u0441\u0434\u0435\u043B\u0430\u0439\u0442\u0435 \u0433\u043B\u0443\u0431\u043E\u043A\u0438\u0439 \u0432\u0434\u043E\u0445',
      '\u041F\u0440\u0435\u0434\u0441\u0442\u0430\u0432\u044C\u0442\u0435 \u0441\u043F\u043E\u043A\u043E\u0439\u043D\u043E\u0435 \u043C\u0435\u0441\u0442\u043E \u2014 \u043F\u043B\u044F\u0436, \u043B\u0435\u0441 \u0438\u043B\u0438 \u0433\u043E\u0440\u044B',
      '\u041E\u0449\u0443\u0442\u0438\u0442\u0435 \u0437\u0432\u0443\u043A\u0438, \u0437\u0430\u043F\u0430\u0445\u0438 \u0438 \u043E\u0449\u0443\u0449\u0435\u043D\u0438\u044F \u044D\u0442\u043E\u0433\u043E \u043C\u0435\u0441\u0442\u0430',
      '\u041F\u043E\u0437\u0432\u043E\u043B\u044C\u0442\u0435 \u0441\u0435\u0431\u0435 \u043F\u043E\u043B\u043D\u043E\u0441\u0442\u044C\u044E \u043F\u043E\u0433\u0440\u0443\u0437\u0438\u0442\u044C\u0441\u044F',
      '\u041C\u0435\u0434\u043B\u0435\u043D\u043D\u043E \u0432\u0435\u0440\u043D\u0438\u0442\u0435\u0441\u044C \u0432 \u043D\u0430\u0441\u0442\u043E\u044F\u0449\u0435\u0435',
    ],
    durationSeconds: 480,
  ),
  ExerciseItem(
    id: 'morning_meditation',
    icon: '\u{1F305}',
    title: '\u0423\u0442\u0440\u0435\u043D\u043D\u044F\u044F \u043C\u0435\u0434\u0438\u0442\u0430\u0446\u0438\u044F',
    description: '\u041D\u0430\u0447\u043D\u0438\u0442\u0435 \u0434\u0435\u043D\u044C \u0441 \u043E\u0441\u043E\u0437\u043D\u0430\u043D\u043D\u043E\u0441\u0442\u0438 \u0438 \u0441\u043F\u043E\u043A\u043E\u0439\u0441\u0442\u0432\u0438\u044F',
    duration: '7 \u043C\u0438\u043D',
    difficulty: '\u041B\u0435\u0433\u043A\u043E',
    type: '\u0424\u043E\u043A\u0443\u0441',
    category: '\u0424\u043E\u043A\u0443\u0441',
    color: Color(0xFFFFEAA7),
    steps: [
      '\u0421\u044F\u0434\u044C\u0442\u0435 \u0443\u0434\u043E\u0431\u043D\u043E \u0441 \u043F\u0440\u044F\u043C\u043E\u0439 \u0441\u043F\u0438\u043D\u043E\u0439',
      '\u0421\u043E\u0441\u0440\u0435\u0434\u043E\u0442\u043E\u0447\u044C\u0442\u0435\u0441\u044C \u043D\u0430 \u0434\u044B\u0445\u0430\u043D\u0438\u0438',
      '\u041D\u0430\u0431\u043B\u044E\u0434\u0430\u0439\u0442\u0435 \u0437\u0430 \u043C\u044B\u0441\u043B\u044F\u043C\u0438 \u0431\u0435\u0437 \u043E\u0446\u0435\u043D\u043A\u0438',
      '\u041C\u044F\u0433\u043A\u043E \u0432\u043E\u0437\u0432\u0440\u0430\u0449\u0430\u0439\u0442\u0435 \u0432\u043D\u0438\u043C\u0430\u043D\u0438\u0435 \u043A \u0434\u044B\u0445\u0430\u043D\u0438\u044E',
      '\u041D\u0430\u0447\u043D\u0438\u0442\u0435 \u0434\u0435\u043D\u044C \u0441 \u044F\u0441\u043D\u044B\u043C \u0443\u043C\u043E\u043C',
    ],
    durationSeconds: 420,
  ),
  ExerciseItem(
    id: 'yoga_beginners',
    icon: '\u{1F9D8}',
    title: '\u0419\u043E\u0433\u0430 \u0434\u043B\u044F \u043D\u0430\u0447\u0438\u043D\u0430\u044E\u0449\u0438\u0445',
    description: '\u041F\u0440\u043E\u0441\u0442\u044B\u0435 \u043F\u043E\u0437\u044B \u0434\u043B\u044F \u0433\u0438\u0431\u043A\u043E\u0441\u0442\u0438 \u0438 \u0440\u0430\u0432\u043D\u043E\u0432\u0435\u0441\u0438\u044F',
    duration: '15 \u043C\u0438\u043D',
    difficulty: '\u0421\u0440\u0435\u0434\u043D\u0435',
    type: '\u042D\u043D\u0435\u0440\u0433\u0438\u044F',
    category: '\u042D\u043D\u0435\u0440\u0433\u0438\u044F',
    color: Color(0xFFFD79A8),
    steps: [
      '\u0412\u0441\u0442\u0430\u043D\u044C\u0442\u0435 \u043F\u0440\u044F\u043C\u043E, \u043D\u043E\u0433\u0438 \u043D\u0430 \u0448\u0438\u0440\u0438\u043D\u0435 \u043F\u043B\u0435\u0447',
      '\u041C\u0435\u0434\u043B\u0435\u043D\u043D\u043E \u043F\u043E\u0434\u043D\u0438\u043C\u0438\u0442\u0435 \u0440\u0443\u043A\u0438 \u0432\u0432\u0435\u0440\u0445',
      '\u041D\u0430\u043A\u043B\u043E\u043D\u0438\u0442\u0435\u0441\u044C \u0432\u043F\u0435\u0440\u0451\u0434, \u043F\u043E\u0447\u0443\u0432\u0441\u0442\u0432\u0443\u0439\u0442\u0435 \u0440\u0430\u0441\u0442\u044F\u0436\u0435\u043D\u0438\u0435',
      '\u0412\u044B\u043F\u043E\u043B\u043D\u0438\u0442\u0435 \u043F\u043E\u0437\u0443 \u043A\u043E\u0448\u043A\u0438 \u0438 \u043A\u043E\u0440\u043E\u0432\u044B',
      '\u0414\u0432\u0438\u0433\u0430\u0439\u0442\u0435\u0441\u044C \u043F\u043B\u0430\u0432\u043D\u043E, \u0434\u044B\u0448\u0438\u0442\u0435 \u0433\u043B\u0443\u0431\u043E\u043A\u043E',
    ],
    durationSeconds: 900,
  ),
  ExerciseItem(
    id: 'technique_54321',
    icon: '\u26A1',
    title: '\u0422\u0435\u0445\u043D\u0438\u043A\u0430 5-4-3-2-1',
    description: '\u0417\u0430\u0437\u0435\u043C\u043B\u0435\u043D\u0438\u0435 \u0447\u0435\u0440\u0435\u0437 \u043E\u0440\u0433\u0430\u043D\u044B \u0447\u0443\u0432\u0441\u0442\u0432 \u0434\u043B\u044F \u0441\u043D\u044F\u0442\u0438\u044F \u0442\u0440\u0435\u0432\u043E\u0433\u0438',
    duration: '3 \u043C\u0438\u043D',
    difficulty: '\u041B\u0435\u0433\u043A\u043E',
    type: '\u0424\u043E\u043A\u0443\u0441',
    category: '\u0424\u043E\u043A\u0443\u0441',
    color: Color(0xFF00CEC9),
    steps: [
      '\u041D\u0430\u0439\u0434\u0438\u0442\u0435 5 \u0432\u0435\u0449\u0435\u0439, \u043A\u043E\u0442\u043E\u0440\u044B\u0435 \u0432\u044B \u0432\u0438\u0434\u0438\u0442\u0435',
      '\u041D\u0430\u0439\u0434\u0438\u0442\u0435 4 \u0432\u0435\u0449\u0438, \u043A\u043E\u0442\u043E\u0440\u044B\u0435 \u043C\u043E\u0436\u043D\u043E \u043F\u043E\u0442\u0440\u043E\u0433\u0430\u0442\u044C',
      '\u041E\u0431\u0440\u0430\u0442\u0438\u0442\u0435 \u0432\u043D\u0438\u043C\u0430\u043D\u0438\u0435 \u043D\u0430 3 \u0432\u0435\u0449\u0438, \u043A\u043E\u0442\u043E\u0440\u044B\u0435 \u0432\u044B \u0441\u043B\u044B\u0448\u0438\u0442\u0435',
      '\u041D\u0430\u0439\u0434\u0438\u0442\u0435 2 \u0432\u0435\u0449\u0438, \u043A\u043E\u0442\u043E\u0440\u044B\u0435 \u043C\u043E\u0436\u043D\u043E \u043F\u043E\u043D\u044E\u0445\u0430\u0442\u044C',
      '\u041D\u0430\u0439\u0434\u0438\u0442\u0435 1 \u0432\u0435\u0449\u044C, \u043A\u043E\u0442\u043E\u0440\u0443\u044E \u043C\u043E\u0436\u043D\u043E \u043F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u043D\u0430 \u0432\u043A\u0443\u0441',
    ],
    durationSeconds: 180,
  ),
];

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _selectedCategory = '\u0412\u0441\u0435';

  List<ExerciseItem> get _filteredExercises {
    if (_selectedCategory == '\u0412\u0441\u0435') return _exercises;
    return _exercises.where((e) => e.category == _selectedCategory).toList();
  }

  void _showExerciseDetail(ExerciseItem exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    '\u0423\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                ),
                _buildQuickStartCard(),
                const SizedBox(height: 16),
                _buildCategoryChips(),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildExerciseCard(_filteredExercises[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.citrusPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.citrusPurple.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u041D\u0443\u0436\u043D\u0430 \u043F\u043E\u043C\u043E\u0449\u044C \u043F\u0440\u044F\u043C\u043E \u0441\u0435\u0439\u0447\u0430\u0441?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
                SizedBox(height: 4),
                Text(
                  '\u041D\u0430\u0447\u043D\u0438\u0442\u0435 \u0441 \u0434\u044B\u0445\u0430\u0442\u0435\u043B\u044C\u043D\u043E\u0433\u043E \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_filteredExercises.isNotEmpty) _showExerciseDetail(_filteredExercises.first);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.citrusPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.citrusPurple.withOpacity(0.3)),
              ),
              child: const Text(
                '\u041D\u0430\u0447\u0430\u0442\u044C',
                style: TextStyle(color: AppColors.citrusPurple, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.citrusOrange.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseItem exercise) {
    return GestureDetector(
      onTap: () => _showExerciseDetail(exercise),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(exercise.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: const TextStyle(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(exercise.duration, style: const TextStyle(color: AppColors.dimForeground, fontSize: 11)),
                const SizedBox(width: 10),
                Text(exercise.difficulty, style: const TextStyle(color: AppColors.dimForeground, fontSize: 11)),
                const SizedBox(width: 10),
                Text(exercise.type, style: const TextStyle(color: AppColors.dimForeground, fontSize: 11)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showExerciseDetail(exercise),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: exercise.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\u041E\u0442\u043A\u0440\u044B\u0442\u044C',
                      style: TextStyle(color: exercise.color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseDetailSheet extends StatefulWidget {
  final ExerciseItem exercise;
  const ExerciseDetailSheet({super.key, required this.exercise});

  @override
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _currentCycle = 0;
  String _phaseText = '';
  bool _isRunning = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exercise.durationSeconds;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.exercise.id == 'box_breathing') {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _phaseText = '\u0412\u0434\u043E\u0445...';
    });

    if (widget.exercise.id == 'box_breathing') {
      _startBreathingCycle();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          if (widget.exercise.id == 'box_breathing') {
            final cyclePos = _currentCycle % 4;
            _phaseText = cyclePos == 0 ? '\u0412\u0434\u043E\u0445...'
                : cyclePos == 1 ? '\u0417\u0430\u0434\u0435\u0440\u0436\u043A\u0430...'
                : cyclePos == 2 ? '\u0412\u044B\u0434\u043E\u0445...'
                : '\u0417\u0430\u0434\u0435\u0440\u0436\u043A\u0430...';
          }
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
          _phaseText = '\u0423\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u0435 \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043D\u043E!';
        });
        _animationController.stop();
      }
    });
  }

  void _startBreathingCycle() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isRunning || _isFinished) {
        timer.cancel();
        return;
      }
      setState(() => _currentCycle++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = widget.exercise.durationSeconds;
      _currentCycle = 0;
      _phaseText = '';
      _isFinished = false;
    });
    if (widget.exercise.id == 'box_breathing') {
      _animationController.reset();
      _animationController.repeat(reverse: true);
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isBreathingExercise = widget.exercise.id == 'box_breathing';
    final color = widget.exercise.color;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF2A2830), width: 1)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dimForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Text(widget.exercise.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.exercise.title,
                            style: const TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isBreathingExercise)
                      Center(
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.citrusGreen.withOpacity(0.4),
                                      AppColors.citrusGreen.withOpacity(0.1),
                                      AppColors.citrusGreen.withOpacity(0.05),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.citrusGreen.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _isRunning ? _phaseText : '\u{1F32C}\u{FE0F}',
                                    style: TextStyle(
                                      color: AppColors.citrusGreen,
                                      fontSize: _isRunning ? 16 : 48,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(widget.exercise.icon, style: const TextStyle(fontSize: 56)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _isRunning || _isFinished ? _formatTime(_remainingSeconds) : widget.exercise.duration,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_phaseText.isNotEmpty && _isRunning) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _phaseText,
                          style: TextStyle(color: AppColors.citrusGreen, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      '\u0428\u0430\u0433\u0438 \u0432\u044B\u043F\u043E\u043B\u043D\u0435\u043D\u0438\u044F',
                      style: TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...widget.exercise.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.citrusOrange.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: AppColors.citrusOrange, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_isFinished) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.citrusGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.citrusGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '\u041E\u0442\u043B\u0438\u0447\u043D\u0430\u044F \u0440\u0430\u0431\u043E\u0442\u0430!',
                              style: TextStyle(color: AppColors.citrusGreen, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isRunning ? _stopTimer : _startTimer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _isRunning
                                    ? null
                                    : const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                                color: _isRunning ? AppColors.surface2 : null,
                                borderRadius: BorderRadius.circular(12),
                                border: _isRunning ? Border.all(color: AppColors.citrusOrange.withOpacity(0.3)) : null,
                                boxShadow: _isRunning
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: AppColors.citrusOrange.withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Text(
                                _isRunning ? '\u0421\u0442\u043E\u043F' : '\u0421\u0442\u0430\u0440\u0442',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isRunning ? AppColors.citrusOrange : AppColors.background,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
