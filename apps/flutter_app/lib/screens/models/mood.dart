import 'package:flutter/material.dart';

class Mood {
  final int id;
  final String label;
  final Color color;
  final Color glow;
  final String emoji;

  const Mood({
    required this.id,
    required this.label,
    required this.color,
    required this.glow,
    required this.emoji,
  });

  static const List<Mood> all = [
    Mood(
      id: 0,
      label: 'Отлично',
      color: Color(0xFF8BC34A),
      glow: Color.fromRGBO(139, 195, 74, 0.45),
      emoji: '😄',
    ),
    Mood(
      id: 1,
      label: 'Хорошо',
      color: Color(0xFFFFD93D),
      glow: Color.fromRGBO(255, 217, 61, 0.45),
      emoji: '🙂',
    ),
    Mood(
      id: 2,
      label: 'Нормально',
      color: Color(0xFFFF8C42),
      glow: Color.fromRGBO(255, 140, 66, 0.45),
      emoji: '😐',
    ),
    Mood(
      id: 3,
      label: 'Тревожно',
      color: Color(0xFFFFA726),
      glow: Color.fromRGBO(255, 167, 38, 0.45),
      emoji: '😟',
    ),
    Mood(
      id: 4,
      label: 'Плохо',
      color: Color(0xFFFF5B5B),
      glow: Color.fromRGBO(255, 91, 91, 0.45),
      emoji: '😢',
    ),
    Mood(
      id: 5,
      label: 'Очень плохо',
      color: Color(0xFFE63946),
      glow: Color.fromRGBO(230, 57, 70, 0.45),
      emoji: '😞',
    ),
  ];
}

class MoodLogEntry {
  final DateTime timestamp;
  final int moodId;

  const MoodLogEntry({
    required this.timestamp,
    required this.moodId,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'moodId': moodId,
  };

  factory MoodLogEntry.fromJson(Map<String, dynamic> json) => MoodLogEntry(
    timestamp: DateTime.parse(json['timestamp'] as String),
    moodId: json['moodId'] as int,
  );
}
