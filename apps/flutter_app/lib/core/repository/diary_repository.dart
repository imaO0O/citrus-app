import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../core/api/diary_api_service.dart';
import '../services/offline_queue_service.dart';

class DiaryEntry {
  final String id;
  final String userId;
  final String content;
  final int? moodValue;
  final DateTime entryDate;
  final DateTime createdAt;
  final List<String> tags;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.content,
    this.moodValue,
    required this.entryDate,
    required this.createdAt,
    this.tags = const [],
  });

  Color get moodColor {
    if (moodValue == null) return Colors.grey;
    return switch (moodValue) {
      0 => const Color(0xFF8BC34A),
      1 => const Color(0xFFFFD93D),
      2 => const Color(0xFFFF8C42),
      3 => const Color(0xFFFFA726),
      4 => const Color(0xFFFF5B5B),
      5 => const Color(0xFFE63946),
      _ => Colors.grey,
    };
  }

  String get mood {
    if (moodValue == null) return '';
    return switch (moodValue) {
      0 => '😄',
      1 => '🙂',
      2 => '😐',
      3 => '😟',
      4 => '😢',
      5 => '😞',
      _ => '',
    };
  }

  String get title {
    final lines = content.split('\n');
    return lines.first.length > 50 ? '${lines.first.substring(0, 50)}...' : lines.first;
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final entryDateStr = json['entry_date'] as String?;
    final createdAtStr = json['created_at'] as String?;

    DateTime entryDate;
    if (entryDateStr != null) {
      try {
        entryDate = DateTime.parse(entryDateStr);
      } catch (_) {
        entryDate = DateTime.now();
      }
    } else {
      entryDate = DateTime.now();
    }

    DateTime createdAt;
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr);
      } catch (_) {
        createdAt = entryDate;
      }
    } else {
      createdAt = entryDate;
    }

    return DiaryEntry(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      moodValue: json['mood_value'] as int?,
      entryDate: entryDate,
      createdAt: createdAt,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'mood_value': moodValue,
      'entry_date': entryDate.toIso8601String().split('T').first,
      'tags': tags,
    };
  }
}

class DiaryRepository {
  DiaryApiService _apiService;
  String _userId;

  DiaryRepository({
    required String userId,
    String? token,
    DiaryApiService? apiService,
  })  : _userId = userId,
        _apiService = apiService ?? DiaryApiService(token: token);

  void setUserId(String userId, {String? token}) {
    _userId = userId;
    if (token != null && token.isNotEmpty) {
      _apiService = DiaryApiService(token: token);
    }
  }

  String get userId => _userId;

  Future<List<DiaryEntry>> getEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final query = (search != null && search.trim().isNotEmpty) ? search.trim() : null;
    final data = await _apiService.getEntries(
      startDate: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : null,
      endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      search: query,
    );
    return data.map((e) => DiaryEntry.fromJson(e)).toList();
  }

  Future<DiaryEntry> createEntry({
    required String content,
    int? moodValue,
    DateTime? entryDate,
    List<String>? tags,
  }) async {
    try {
      final data = await _apiService.createEntry(
        content: content,
        moodValue: moodValue,
        entryDate: entryDate?.toIso8601String(),
        tags: tags,
      );
      return DiaryEntry.fromJson(data);
    } catch (e) {
      // Нет сети — сохраняем запись в офлайн-очередь и возвращаем оптимистичную.
      if (OfflineQueueService.isNetworkError(e)) {
        await OfflineQueueService.instance.enqueue('diary', {
          'content': content,
          'moodValue': moodValue,
          'entryDate': entryDate?.toIso8601String(),
          'tags': tags,
        });
        final now = DateTime.now();
        return DiaryEntry(
          id: 'local_${now.microsecondsSinceEpoch}',
          userId: _userId,
          content: content,
          moodValue: moodValue,
          entryDate: entryDate ?? now,
          createdAt: now,
          tags: tags ?? const [],
        );
      }
      rethrow;
    }
  }

  /// Повторная отправка из офлайн-очереди.
  Future<void> replayCreate(Map<String, dynamic> d) async {
    await _apiService.createEntry(
      content: d['content'] as String,
      moodValue: d['moodValue'] as int?,
      entryDate: d['entryDate'] as String?,
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Future<DiaryEntry> updateEntry({
    required String id,
    required String content,
    int? moodValue,
    List<String>? tags,
  }) async {
    final data = await _apiService.updateEntry(
      id: id,
      content: content,
      moodValue: moodValue,
      tags: tags,
    );
    return DiaryEntry.fromJson(data);
  }

  Future<void> deleteEntry(String id) async {
    await _apiService.deleteEntry(id);
  }
}
