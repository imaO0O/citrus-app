import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../config/api_config.dart';

/// Сервис для отслеживания выполненных упражнений
class ExerciseTrackerService {
  static const String _storageKey = 'exercise_completions';

  /// Сохранить выполненное упражнение (локально + на сервере)
  Future<void> recordExercise(
    String exerciseId, {
    String? exerciseType,
    String? title,
    int? durationMinutes,
    int? difficultyLevel,
    String? userNotes,
    int? moodBefore,
    int? moodAfter,
  }) async {
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
      debugPrint('Exercise recorded locally: $exerciseId at $now');

      // Отправляем на сервер
      await _sendToServer(
        exerciseId: exerciseId,
        exerciseType: exerciseType,
        title: title,
        durationMinutes: durationMinutes,
        difficultyLevel: difficultyLevel,
        userNotes: userNotes,
        moodBefore: moodBefore,
        moodAfter: moodAfter,
      );
    } catch (e) {
      debugPrint('Error recording exercise: $e');
    }
  }

  /// Отправить данные о выполнении упражнения на сервер
  Future<void> _sendToServer({
    required String exerciseId,
    String? exerciseType,
    String? title,
    int? durationMinutes,
    int? difficultyLevel,
    String? userNotes,
    int? moodBefore,
    int? moodAfter,
  }) async {
    try {
      final storage = StorageService();
      final token = await storage.getString('auth_token');

      if (token == null || token.isEmpty) {
        debugPrint('No auth token, skipping server sync for exercise');
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/exercises/complete');
      final body = jsonEncode({
        'exercise_id': exerciseId,
        'exercise_type': exerciseType ?? 'breathing',
        if (title != null) 'title': title,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
        if (userNotes != null) 'user_notes': userNotes,
        if (moodBefore != null) 'mood_before': moodBefore,
        if (moodAfter != null) 'mood_after': moodAfter,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        debugPrint('Exercise synced to server: $exerciseId');
      } else {
        debugPrint('Failed to sync exercise to server: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error syncing exercise to server: $e');
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
