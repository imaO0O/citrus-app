import 'dart:convert';
import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Сервис для отслеживания выполненных упражнений
class ExerciseTrackerService {
  static const String _storageKey = 'exercise_completions';

  /// Сохранить выполненное упражнение
  Future<void> recordExercise(String exerciseId) async {
    try {
      final storage = StorageService();
      final now = DateTime.now().toIso8601String();

      // Получаем существующие записи
      final existingJson = await storage.getString(_storageKey);
      final List<Map<String, dynamic>> completions = [];

      if (existingJson != null && existingJson.isNotEmpty) {
        final decoded = jsonDecode(existingJson) as List;
        completions.addAll(decoded.cast<Map<String, dynamic>>());
      }

      // Добавляем новую запись
      completions.add({
        'exerciseId': exerciseId,
        'completedAt': now,
      });

      // Сохраняем обратно
      await storage.setString(_storageKey, jsonEncode(completions));
      debugPrint('Exercise recorded: $exerciseId at $now');
    } catch (e) {
      debugPrint('Error recording exercise: $e');
    }
  }

  /// Получить количество выполненных упражнений
  Future<int> getExercisesCount() async {
    try {
      final storage = StorageService();
      final json = await storage.getString(_storageKey);
      if (json == null || json.isEmpty) return 0;

      final decoded = jsonDecode(json) as List;
      return decoded.length;
    } catch (e) {
      debugPrint('Error getting exercises count: $e');
      return 0;
    }
  }

  /// Очистить историю упражнений
  Future<void> clearHistory() async {
    try {
      final storage = StorageService();
      await storage.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing exercise history: $e');
    }
  }
}
