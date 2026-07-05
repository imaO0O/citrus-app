import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/app_size.dart';

/// Единая типошкала приложения. Использует адаптивный масштаб AppSize и цвета AppColors.
/// Цель — одинаковые заголовки/текст на всех экранах для премиального вида.
class AppText {
  AppText._();

  /// Крупный заголовок экрана / приветствие.
  static TextStyle get displayTitle =>
      TextStyle(fontSize: AppSize.s(24), fontWeight: FontWeight.w800, color: AppColors.foreground, height: 1.2);

  /// Заголовок экрана (AppBar / шапка).
  static TextStyle get title =>
      TextStyle(fontSize: AppSize.s(19), fontWeight: FontWeight.w700, color: AppColors.foreground);

  /// Заголовок секции.
  static TextStyle get sectionTitle =>
      TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w700, color: AppColors.foreground);

  /// Заголовок карточки.
  static TextStyle get cardTitle =>
      TextStyle(fontSize: AppSize.s(15), fontWeight: FontWeight.w700, color: AppColors.foreground);

  /// Основной текст.
  static TextStyle get body =>
      TextStyle(fontSize: AppSize.s(14), color: AppColors.foreground, height: 1.5);

  /// Второстепенный текст.
  static TextStyle get bodyMuted =>
      TextStyle(fontSize: AppSize.s(13), color: AppColors.mutedForeground, height: 1.45);

  /// Подпись/мелкий текст.
  static TextStyle get caption =>
      TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground);

  /// Метка (мелкая, приглушённая).
  static TextStyle get label =>
      TextStyle(fontSize: AppSize.s(11), fontWeight: FontWeight.w600, color: AppColors.dimForeground);
}
