import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Единые визуалы категорий статей (цвет, название, иконка) + оценка времени
/// чтения. Используется в списке и детальной статье, чтобы не дублировать.
class ArticleVisuals {
  static const _names = {
    'anxiety': 'Тревожность',
    'depression': 'Депрессия',
    'sleep': 'Сон',
    'stress': 'Стресс',
    'self-esteem': 'Самооценка',
    'relationships': 'Отношения',
    'mindfulness': 'Осознанность',
    'custom': 'Пользовательские',
  };

  static const _icons = {
    'anxiety': Icons.psychology,
    'depression': Icons.cloud,
    'sleep': Icons.nightlight,
    'stress': Icons.self_improvement,
    'self-esteem': Icons.favorite,
    'relationships': Icons.people,
    'mindfulness': Icons.auto_awesome,
  };

  static Color color(String category) {
    switch (category.toLowerCase()) {
      case 'anxiety':
        return const Color(0xFF9C6ADE); // фиолетовый
      case 'depression':
        return const Color(0xFF4A90D9); // синий
      case 'sleep':
        return const Color(0xFF5C6BC0); // индиго
      case 'stress':
        return const Color(0xFF66BB6A); // зелёный
      case 'self-esteem':
        return const Color(0xFFEC6A8C); // розовый
      case 'relationships':
        return const Color(0xFF26A69A); // бирюзовый
      case 'mindfulness':
        return const Color(0xFFFFB74D); // янтарный
      default:
        return AppColors.citrusOrange;
    }
  }

  static String name(String category) =>
      _names[category.toLowerCase()] ?? category;

  static IconData icon(String category) =>
      _icons[category.toLowerCase()] ?? Icons.article;

  /// Примерное время чтения в минутах (≈180 слов/мин).
  static int readingMinutes(String content) {
    final words = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final m = (words / 180).ceil();
    return m < 1 ? 1 : m;
  }
}
