import 'dart:convert';
import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Сервис для отслеживания пройденных тестов (локальное хранилище)
class TestTrackingService {
  static const String _storageKey = 'test_completions';

  /// Сохранить пройденный тест
  Future<void> recordTest(String testId) async {
    try {
      final storage = StorageService();
      final now = DateTime.now().toIso8601String();

      final existingJson = await storage.getString(_storageKey);
      final List<Map<String, dynamic>> completions = [];

      if (existingJson != null && existingJson.isNotEmpty) {
        final decoded = jsonDecode(existingJson) as List;
        completions.addAll(decoded.cast<Map<String, dynamic>>());
      }

      completions.add({
        'testId': testId,
        'completedAt': now,
      });

      await storage.setString(_storageKey, jsonEncode(completions));
      debugPrint('Test recorded: $testId at $now');
    } catch (e) {
      debugPrint('Error recording test: $e');
    }
  }

  /// Получить количество пройденных тестов
  Future<int> getTestsCount() async {
    try {
      final storage = StorageService();
      final json = await storage.getString(_storageKey);
      if (json == null || json.isEmpty) return 0;

      final decoded = jsonDecode(json) as List;
      return decoded.length;
    } catch (e) {
      debugPrint('Error getting tests count: $e');
      return 0;
    }
  }

  /// Очистить историю тестов
  Future<void> clearHistory() async {
    try {
      final storage = StorageService();
      await storage.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing test history: $e');
    }
  }
}
