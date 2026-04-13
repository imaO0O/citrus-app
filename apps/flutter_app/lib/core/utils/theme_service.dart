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

  ThemeMode get themeMode {
    print('>>> ThemeService.themeMode getter: $_themeMode');
    return _themeMode;
  }
  bool get isDarkMode {
    final result = _themeMode == ThemeMode.dark;
    print('>>> ThemeService.isDarkMode getter: $result');
    return result;
  }
  bool get isLoaded => _isLoaded;

  /// Инициализация сервиса
  Future<void> init() async {
    print('ThemeService.init() вызван');
    await _loadTheme();
    print('ThemeService.init() завершён, isDarkMode=$isDarkMode, isLoaded=$_isLoaded');
  }

  /// Загрузка темы из файла
  Future<void> _loadTheme() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      print('ThemeService: загружаю тему из ${file.path}');

      if (await file.exists()) {
        final content = await file.readAsString();
        print('ThemeService: содержимое файла: $content');
        final data = jsonDecode(content) as Map<String, dynamic>;
        final isDark = data['isDarkMode'] as bool? ?? false;

        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        print('ThemeService: загружена тема isDark=$isDark');
      } else {
        print('ThemeService: файл темы не найден, использую светлую');
      }
    } catch (e) {
      debugPrint('ThemeService: ОШИБКА загрузки темы: $e');
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
    try {
      print('>>> ThemeService.toggleTheme(isDark=$isDark) START');
      print('>>> До: themeMode=$_themeMode, isDarkMode=${_themeMode == ThemeMode.dark}');
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      print('>>> После: themeMode=$_themeMode, isDarkMode=${_themeMode == ThemeMode.dark}');
      await _saveTheme(isDark);
      print('>>> Вызываю notifyListeners()...');
      notifyListeners();
      print('>>> notifyListeners() вызван успешно');
      print('>>> ThemeService.toggleTheme END');
    } catch (e, st) {
      print('>>> ThemeService: КРИТИЧЕСКАЯ ОШИБКА при переключении темы: $e');
      print('>>> Stack trace: $st');
    }
  }
}
