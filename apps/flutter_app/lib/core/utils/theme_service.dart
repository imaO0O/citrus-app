import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Сервис для управления темой приложения с сохранением
class ThemeService extends ChangeNotifier {
  ThemeService._internal();
  static final ThemeService _instance = ThemeService._internal();
  
  factory ThemeService() {
    return _instance;
  }

  static const String _fileName = 'theme_config.json';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;

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
      print('ThemeService: сохраняю тему в ${file.path}, isDark=$isDark');

      final data = {'isDarkMode': isDark};
      await file.writeAsString(jsonEncode(data));
      print('ThemeService: тема сохранена успешно');
    } catch (e) {
      print('ThemeService: ОШИБКА сохранения темы: $e');
    }
  }

  /// Установка режима темы
  Future<void> setThemeMode(ThemeMode mode) async {
    final isDark = mode == ThemeMode.dark;
    _themeMode = mode;
    await _saveTheme(isDark);
    notifyListeners();
  }

  /// Переключение темы
  Future<void> toggleTheme(bool isDark) async {
    print('ThemeService.toggleTheme(isDark=$isDark)');
    try {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      print('ThemeService: themeMode=$_themeMode, isDarkMode=$isDarkMode');
      await _saveTheme(isDark);
      print('ThemeService: тема сохранена');
      notifyListeners();
      print('ThemeService: notifyListeners вызван');
    } catch (e) {
      print('ThemeService: ОШИБКА при переключении темы: $e');
    }
  }
}
