import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../core/services/storage_service.dart';

/// Модель темы оформления
class Theme {
  final String id;
  final String name;
  final bool isDark;
  final String primaryColor;
  final String accentColor;

  Theme({
    required this.id,
    required this.name,
    required this.isDark,
    required this.primaryColor,
    required this.accentColor,
  });

  factory Theme.fromJson(Map<String, dynamic> json) {
    return Theme(
      id: json['id'] as String,
      name: json['name'] as String,
      isDark: json['is_dark'] as bool,
      primaryColor: json['primary_color'] as String,
      accentColor: json['accent_color'] as String,
    );
  }
}

/// Модель пользователя
class User {
  final String id;
  final String email;
  final String? name;
  final String? themeId;
  final String token;

  User({
    required this.id,
    required this.email,
    this.name,
    this.themeId,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      themeId: json['theme_id'] as String?,
      token: json['token'] as String,
    );
  }
}

/// API сервис для авторизации
class AuthApiService {
  final String baseUrl;
  final http.Client _client;

  AuthApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  /// Регистрация
  Future<User> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('Пользователь уже существует');
    } else {
      final error = jsonDecode(response.body)['message'] as String?;
      throw Exception(error ?? 'Ошибка регистрации');
    }
  }

  /// Вход
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Неверный email или пароль');
    } else {
      final error = jsonDecode(response.body)['message'] as String?;
      throw Exception(error ?? 'Ошибка входа');
    }
  }

  void dispose() {
    _client.close();
  }

  /// Получить список тем
  Future<List<Theme>> getThemes() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/themes'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Theme.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки тем: ${response.statusCode}');
    }
  }

  /// Обновить тему пользователя
  Future<void> updateTheme(String token, String themeId) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/user/theme'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'theme_id': themeId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления темы: ${response.statusCode}');
    }
  }
}

/// Репозиторий для авторизации
class AuthRepository {
  final AuthApiService _apiService;

  // Хранение в памяти + постоянное хранилище
  User? _currentUser;

  AuthRepository({AuthApiService? apiService})
      : _apiService = apiService ?? AuthApiService();

  // Публичный геттер для API сервиса
  AuthApiService get apiService => _apiService;

  User? get currentUser => _currentUser;
  set currentUser(User? user) => _currentUser = user;
  bool get isAuthenticated => _currentUser != null;
  String? get token => _currentUser?.token;

  /// Инициализация — восстанавливаем данные из хранилища
  Future<void> init() async {
    try {
      final storage = StorageService();
      final savedToken = await storage.getString('auth_token');
      final savedUserId = await storage.getString('auth_user_id');
      final savedEmail = await storage.getString('auth_user_email');
      final savedName = await storage.getString('auth_user_name');
      final savedThemeId = await storage.getString('auth_user_theme_id');

      if (savedToken != null && savedToken.isNotEmpty && savedUserId != null) {
        _currentUser = User(
          id: savedUserId,
          email: savedEmail ?? '',
          name: savedName,
          themeId: savedThemeId,
          token: savedToken,
        );
      }
    } catch (e) {
      debugPrint('AuthRepository init error: $e');
    }
  }

  /// Сохранить данные пользователя в постоянное хранилище
  Future<void> _saveSession(User user) async {
    try {
      final storage = StorageService();
      await storage.setString('auth_token', user.token);
      await storage.setString('auth_user_id', user.id);
      await storage.setString('auth_user_email', user.email);
      if (user.name != null) await storage.setString('auth_user_name', user.name!);
      if (user.themeId != null) await storage.setString('auth_user_theme_id', user.themeId!);
    } catch (e) {
      debugPrint('AuthRepository save error: $e');
    }
  }

  /// Очистить сохранённую сессию
  Future<void> _clearSession() async {
    try {
      final storage = StorageService();
      await storage.remove('auth_token');
      await storage.remove('auth_user_id');
      await storage.remove('auth_user_email');
      await storage.remove('auth_user_name');
      await storage.remove('auth_user_theme_id');
    } catch (e) {
      debugPrint('AuthRepository clear error: $e');
    }
  }

  /// Регистрация
  Future<User> register({
    required String email,
    required String password,
    String? name,
  }) async {
    _currentUser = await _apiService.register(
      email: email,
      password: password,
      name: name,
    );
    await _saveSession(_currentUser!);
    return _currentUser!;
  }

  /// Вход
  Future<User> login({
    required String email,
    required String password,
  }) async {
    _currentUser = await _apiService.login(
      email: email,
      password: password,
    );
    await _saveSession(_currentUser!);
    return _currentUser!;
  }

  /// Выход
  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
  }
}
