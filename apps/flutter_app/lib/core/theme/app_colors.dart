import 'package:flutter/material.dart';
import '../utils/theme_service.dart';

/// Адаптивные цвета — автоматически переключаются между тёмной и светлой темой
///
/// Все поля — геттеры, которые читают текущую тему из ThemeService.
/// При смене темы ThemeService вызывает notifyListeners(),
/// и ListenableBuilder в main.dart перестраивает дерево виджетов.
class AppColors {
  static bool get _isDark {
    try {
      final service = ThemeService();
      final isDark = service.isDarkMode;
      return isDark;
    } catch (e) {
      print('AppColors: ОШИБКА чтения темы: $e, fallback на dark');
      return true;
    }
  }

  // === Background & surfaces ===
  static Color get background => _isDark ? const Color(0xFF0C0C14) : const Color(0xFFF9FAFB);
  static Color get foreground => _isDark ? const Color(0xFFEDE8E0) : const Color(0xFF111827);
  static Color get card => _isDark ? const Color(0xFF131320) : const Color(0xFFFFFFFF);
  static Color get cardForeground => _isDark ? const Color(0xFFEDE8E0) : const Color(0xFF111827);
  static Color get popover => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFFFFFFF);
  static Color get popoverForeground => _isDark ? const Color(0xFFEDE8E0) : const Color(0xFF111827);
  static Color get surface1 => _isDark ? const Color(0xFF131320) : const Color(0xFFF3F4F6);
  static Color get surface2 => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFE5E7EB);
  static Color get surface3 => _isDark ? const Color(0xFF222235) : const Color(0xFFD1D5DB);

  // === Primary ===
  static const Color primary = Color(0xFFFF8C42);
  static Color get primaryForeground => _isDark ? const Color(0xFF0C0C14) : const Color(0xFFFFFFFF);

  // === Secondary ===
  static Color get secondary => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFE5E7EB);
  static Color get secondaryForeground => _isDark ? const Color(0xFFEDE8E0) : const Color(0xFF111827);

  // === Muted ===
  static Color get muted => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFE5E7EB);
  static Color get mutedForeground => _isDark ? const Color(0xFF8A8298) : const Color(0xFF6B7280);

  // === Accent ===
  static const Color accent = Color(0xFFFFAD1F);
  static Color get accentForeground => _isDark ? const Color(0xFF0C0C14) : const Color(0xFF111827);

  // === Destructive ===
  static const Color destructive = Color(0xFFE63946);
  static Color get destructiveForeground => _isDark ? const Color(0xFFEDE8E0) : const Color(0xFFFFFFFF);

  // === Borders & inputs ===
  static Color get border => _isDark
      ? const Color.fromRGBO(255, 140, 66, 0.14)
      : const Color.fromRGBO(0, 0, 0, 0.1);
  static Color get input => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFE5E7EB);
  static Color get inputBackground => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFF3F4F6);
  static const Color ring = Color(0xFFFF8C42);
  static Color get switchBackground => _isDark ? const Color(0xFF2A2A3A) : const Color(0xFFD1D5DB);

  // === Citrus accent colors (не меняются) ===
  static const Color citrusOrange = Color(0xFFFF8C42);
  static const Color citrusAmber = Color(0xFFFFAD1F);
  static const Color citrusYellow = Color(0xFFFFD93D);
  static const Color citrusGreen = Color(0xFF8BC34A);
  static Color get citrusLight => _isDark ? const Color(0xFF131320) : const Color(0xFFF3F4F6);
  static const Color citrusLightOrange = Color(0xFFFF7020);
  static Color get citrusPale => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFE5E7EB);
  static const Color citrusRed = Color(0xFFE63946);
  static const Color citrusPurple = Color(0xFF7C83D1);

  // === Glow effects ===
  static const Color glowOrange = Color.fromRGBO(255, 140, 66, 0.25);
  static const Color glowAmber = Color.fromRGBO(255, 173, 31, 0.2);

  // === Chart colors ===
  static const List<Color> chartColors = [
    Color(0xFFFF8C42),
    Color(0xFFFFAD1F),
    Color(0xFFFFD93D),
    Color(0xFF8BC34A),
    Color(0xFFE63946),
  ];

  // === Mood colors (не меняются) ===
  static const Color moodExcellent = Color(0xFF8BC34A);
  static const Color moodGood = Color(0xFFFFD93D);
  static const Color moodOkay = Color(0xFFFF8C42);
  static const Color moodAnxious = Color(0xFFFFA726);
  static const Color moodBad = Color(0xFFFF5B5B);
  static const Color moodVeryBad = Color(0xFFE63946);

  // === Sidebar ===
  static Color get sidebar => _isDark ? const Color(0xFF0F0F1C) : const Color(0xFFFFFFFF);
  static Color get sidebarForeground => _isDark ? const Color(0xFFEDE8E0) : const Color(0xFF111827);
  static const Color sidebarPrimary = Color(0xFFFF8C42);
  static const Color sidebarPrimaryForeground = Color(0xFF0C0C14);
  static Color get sidebarAccent => _isDark ? const Color(0xFF1A1A2A) : const Color(0xFFF3F4F6);
  static Color get sidebarAccentForeground => _isDark ? const Color(0xFFEDE8E0) : const Color(0xFF111827);
  static Color get sidebarBorder => _isDark
      ? const Color.fromRGBO(255, 140, 66, 0.14)
      : const Color.fromRGBO(0, 0, 0, 0.1);
  static const Color sidebarRing = Color(0xFFFF8C42);

  // === Border radius ===
  static const double radiusSm = 10.0;
  static const double radiusMd = 12.0;
  static const double radius = 14.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;
  static const double borderRadius = 14.0;

  // === Common helper ===
  static Color get inputFieldBackground => _isDark
      ? const Color(0xFFFFFFFF).withOpacity(0.06)
      : const Color(0xFF000000).withOpacity(0.05);
  static Color get subtleBg => _isDark
      ? const Color.fromRGBO(255, 255, 255, 0.04)
      : const Color.fromRGBO(0, 0, 0, 0.03);
  static Color get subtleBorder => _isDark
      ? const Color.fromRGBO(255, 255, 255, 0.06)
      : const Color.fromRGBO(0, 0, 0, 0.08);
  static Color get dimForeground => _isDark ? const Color(0xFF5A5468) : const Color(0xFF9CA3AF);
  static const Color warmText = Color(0xFFC8B89A);
}
