import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../core/api/diary_api_service.dart';

class DiaryEntry {
  final String id;
  final String userId;
  final String content;
  final int? moodValue;
  final DateTime entryDate;
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.content,
    this.moodValue,
    required this.entryDate,
    required this.createdAt,
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

  List<String> get tags {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(content).map((m) => m.group(1)!).toList();
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
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      moodValue: json['mood_value'] as int?,
      entryDate: entryDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'mood_value': moodValue,
      'entry_date': entryDate.toIso8601String().split('T').first,
    };
  }
}

class DiaryRepository {
  DiaryApiService _apiService;
  String _userId;
  String? _token;

  DiaryRepository({
    required String userId,
    String? token,
    DiaryApiService? apiService,
  })  : _userId = userId,
        _token = token,
        _apiService = apiService ?? DiaryApiService(token: token);

  void setUserId(String userId, {String? token}) {
    _userId = userId;
    if (token != null && token.isNotEmpty) {
      _token = token;
      _apiService = DiaryApiService(token: token);
    }
  }

  String get userId => _userId;

  Future<List<DiaryEntry>> getEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final data = await _apiService.getEntries(
      startDate: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : null,
      endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      search: search,
    );
    return data.map((e) => DiaryEntry.fromJson(e)).toList();
  }

  Future<DiaryEntry> createEntry({
    required String content,
    int? moodValue,
    DateTime? entryDate,
  }) async {
    final data = await _apiService.createEntry(
      content: content,
      moodValue: moodValue,
      entryDate: entryDate?.toIso8601String(),
    );
    return DiaryEntry.fromJson(data);
  }

  Future<DiaryEntry> updateEntry({
    required String id,
    required String content,
    int? moodValue,
  }) async {
    final data = await _apiService.updateEntry(
      id: id,
      content: content,
      moodValue: moodValue,
    );
    return DiaryEntry.fromJson(data);
  }

  Future<void> deleteEntry(String id) async {
    await _apiService.deleteEntry(id);
  }
}
