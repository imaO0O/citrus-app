import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/services/storage_service.dart';

/// Модель аффирмации
class Affirmation {
  final String id;
  final String emoji;
  final String text;
  final String category;
  final Color color;
  final DateTime createdAt;

  const Affirmation({
    required this.id,
    required this.emoji,
    required this.text,
    required this.category,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'text': text,
    'category': category,
    'color': color.toARGB32(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Affirmation.fromJson(Map<String, dynamic> json) => Affirmation(
    id: json['id'] as String,
    emoji: json['emoji'] as String,
    text: json['text'] as String,
    category: json['category'] as String,
    color: Color(json['color'] as int),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Сервис для работы с аффирмациями
class AffirmationsService {
  static const _storageKey = 'cached_affirmations';
  static const _lastGenerationKey = 'last_affirmations_generation';
  
  // Базовые аффирмации на случай если GigaChat недоступен
  static const _defaultAffirmations = [
    {'emoji': '🌟', 'text': 'Я достоин любви и уважения', 'category': 'Любовь', 'color': 0xFFFFB347},
    {'emoji': '🌱', 'text': 'Каждый день я становлюсь лучше', 'category': 'Сила', 'color': 0xFF8BC34A},
    {'emoji': '💪', 'text': 'Я справлюсь с любыми трудностями', 'category': 'Сила', 'color': 0xFFFF8C42},
    {'emoji': '❤️', 'text': 'Мои чувства важны', 'category': 'Любовь', 'color': 0xFFFF5B5B},
    {'emoji': '🏆', 'text': 'Я горжусь своими достижениями', 'category': 'Уверенность', 'color': 0xFFFFD93D},
    {'emoji': '✨', 'text': 'У меня есть всё для успеха', 'category': 'Уверенность', 'color': 0xFFC084FC},
    {'emoji': '🦋', 'text': 'Я принимаю себя таким, какой я есть', 'category': 'Любовь', 'color': 0xFFA78BFA},
    {'emoji': '☀️', 'text': 'Сегодня я выбираю позитив', 'category': 'Спокойствие', 'color': 0xFFFFD93D},
    {'emoji': '🧠', 'text': 'Мой ум ясен и силён', 'category': 'Уверенность', 'color': 0xFFA78BFA},
    {'emoji': '🌸', 'text': 'Я заслуживаю отдыха и заботы', 'category': 'Спокойствие', 'color': 0xFF8BC34A},
    {'emoji': '🌊', 'text': 'Я спокоен как океан', 'category': 'Спокойствие', 'color': 0xFF64B5F6},
    {'emoji': '🔥', 'text': 'Во мне горит неугасимый огонь', 'category': 'Сила', 'color': 0xFFFF5722},
  ];

  final List<Color> _affirmationColors = const [
    Color(0xFFFFB347),
    Color(0xFF8BC34A),
    Color(0xFFFF8C42),
    Color(0xFFFF5B5B),
    Color(0xFFFFD93D),
    Color(0xFFC084FC),
    Color(0xFFA78BFA),
    Color(0xFF64B5F6),
    Color(0xFF4DD0E1),
    Color(0xFFFF7043),
  ];

  final List<String> _emojis = const [
    '🌟', '🌱', '💪', '❤️', '🏆', '✨', '🦋', '☀️', '🧠', '🌸',
    '🌊', '🔥', '🌈', '💎', '🦅', '🦁', '🌻', '🍀', '💫', '🎯',
  ];

  /// Получить сохранённые аффирмации
  Future<List<Affirmation>> getCachedAffirmations() async {
    try {
      final storage = StorageService();
      final jsonStr = await storage.getString(_storageKey);
      
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((e) => Affirmation.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached affirmations: $e');
    }
    
    // Возвращаем дефолтные если нет сохранённых
    return _getDefaultAffirmations();
  }

  /// Сохранить аффирмации
  Future<void> saveAffirmations(List<Affirmation> affirmations) async {
    try {
      final storage = StorageService();
      final jsonList = affirmations.map((a) => a.toJson()).toList();
      await storage.setString(_storageKey, jsonEncode(jsonList));
      await storage.setString(_lastGenerationKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving affirmations: $e');
    }
  }

  /// Сгенерировать новые аффирмации через GigaChat
  Future<List<Affirmation>> generateAffirmations({String category = 'Все'}) async {
    try {
      final storage = StorageService();
      final token = await storage.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('Не авторизован');
      }

      final prompt = _buildPrompt(category);
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': prompt,
          'temperature': 0.8,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['response'] as String;
        
        // Парсим ответ AI
        final affirmations = _parseAiResponse(aiResponse, category);
        
        if (affirmations.isNotEmpty) {
          // Сохраняем новые аффирмации
          await saveAffirmations(affirmations);
          return affirmations;
        }
      }
      
      throw Exception('Failed to generate affirmations');
    } catch (e) {
      debugPrint('Error generating affirmations: $e');
      // Возвращаем дефолтные при ошибке
      return _getDefaultAffirmations(category: category);
    }
  }

  /// Построить промпт для AI
  String _buildPrompt(String category) {
    final categoryText = category == 'Все' 
      ? 'разных категориях: уверенность, спокойствие, сила, любовь к себе' 
      : 'категории "$category"';
    
    return '''
Создай 10 аффирмаций (утверждений) для повышения ментального здоровья в $categoryText.

Требования:
1. Каждая аффирмация должна быть короткой (до 60 символов)
2. Начинаться с "Я"
3. Быть позитивной и мотивирующей
4. Подходить для ежедневного повторения

Формат ответа - строго JSON массив:
[
  {"text": "Я достоин любви и счастья", "category": "Любовь"},
  {"text": "Я справлюсь с любыми трудностями", "category": "Сила"}
]

Важно: отвечай только JSON массивом, без дополнительного текста.
'''.trim();
  }

  /// Парсить ответ от AI
  List<Affirmation> _parseAiResponse(String response, String defaultCategory) {
    try {
      // Ищем JSON в ответе
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) return [];
      
      final jsonStr = jsonMatch.group(0);
      if (jsonStr == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      
      return jsonList.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value as Map<String, dynamic>;
        
        return Affirmation(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_$index',
          emoji: _emojis[index % _emojis.length],
          text: data['text'] as String,
          category: data['category'] as String? ?? defaultCategory,
          color: _affirmationColors[index % _affirmationColors.length],
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      return [];
    }
  }

  /// Получить дефолтные аффирмации
  List<Affirmation> _getDefaultAffirmations({String category = 'Все'}) {
    var defaults = _defaultAffirmations.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return Affirmation(
        id: 'default_$index',
        emoji: data['emoji'] as String,
        text: data['text'] as String,
        category: data['category'] as String,
        color: Color(data['color'] as int),
        createdAt: DateTime.now(),
      );
    }).toList();
    
    if (category != 'Все') {
      defaults = defaults.where((a) => a.category == category).toList();
    }
    
    return defaults.isEmpty ? _getDefaultAffirmations(category: 'Все') : defaults;
  }

  /// Проверить, нужно ли обновить аффирмации (раз в день)
  Future<bool> shouldRefresh() async {
    try {
      final storage = StorageService();
      final lastGen = await storage.getString(_lastGenerationKey);
      
      if (lastGen == null) return true;
      
      final lastDate = DateTime.parse(lastGen);
      final now = DateTime.now();
      
      return now.difference(lastDate).inHours >= 24;
    } catch (e) {
      return true;
    }
  }
}
