import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';

/// Сервис для управления темой приложения с сохранением
class ThemeService extends ChangeNotifier {
  ThemeService._internal();
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() => _instance;

  static const String _fileName = 'theme_config.json';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  /// Токен и ID пользователя для сохранения темы в БД
  String? _userToken;
  String? _userId;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;

  /// Установить данные пользователя для синхронизации темы с БД
  void setUserCredentials(String? token, String? userId) {
    _userToken = token;
    _userId = userId;
  }

  /// Инициализация сервиса
  Future<void> init() async {
    await _loadTheme();
  }

  /// Загрузка темы из файла
  Future<void> _loadTheme() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final isDark = data['isDarkMode'] as bool? ?? false;
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      debugPrint('Ошибка загрузки темы: $e');
      _themeMode = ThemeMode.light;
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Сохранение темы в файл
  Future<void> _saveTheme(bool isDark) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      final data = {'isDarkMode': isDark};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Ошибка сохранения темы: $e');
    }
  }

  /// Сохранение темы в БД
  Future<void> _saveThemeToDb(bool isDark) async {
    if (_userToken == null || _userToken!.isEmpty || _userId == null) return;

    try {
      // Тёмная тема = ID 00000000-0000-0000-0000-000000000002
      // Светлая тема = ID 00000000-0000-0000-0000-000000000001
      final themeId = isDark
          ? '00000000-0000-0000-0000-000000000002'
          : '00000000-0000-0000-0000-000000000001';

      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/user/theme'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
        body: jsonEncode({'theme_id': themeId}),
      );
    } catch (e) {
      debugPrint('Ошибка сохранения темы в БД: $e');
    }
  }

  /// Переключение темы
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _saveTheme(isDark);
    await _saveThemeToDb(isDark);
  }
}
