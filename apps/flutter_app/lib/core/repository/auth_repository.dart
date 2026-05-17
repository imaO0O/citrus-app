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
  final String? avatarUrl;
  final String? phone;
  final String token;

  User({
    required this.id,
    required this.email,
    this.name,
    this.themeId,
    this.avatarUrl,
    this.phone,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      themeId: json['theme_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
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

  /// Получить профиль пользователя
  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Ошибка загрузки профиля: ${response.statusCode}');
    }
  }

  /// Обновить профиль пользователя (имя, телефон)
  Future<Map<String, dynamic>> updateProfile(String token, {String? name, String? phone}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Ошибка обновления профиля: ${response.statusCode}');
    }
  }

  /// Загрузить аватар пользователя
  Future<String> uploadAvatar(String token, String filePath, List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/avatar'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['avatar_url'] as String;
    } else {
      throw Exception('Ошибка загрузки аватара: ${response.statusCode}');
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
      debugPrint('AuthRepository: init start');
      final storage = StorageService();
      
      // Проверяем, было ли сохранение сессии с флагом "Запомнить меня"
      final rememberMe = await storage.getString('remember_me').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      debugPrint('AuthRepository: remember_me = $rememberMe');
      
      // Если пользователь не хотел запоминать сессию - не восстанавливаем её
      if (rememberMe != 'true') {
        debugPrint('AuthRepository: remember_me is not true, skipping session restore');
        await _clearSession();
        return;
      }
      
      final savedToken = await storage.getString('auth_token').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      final savedUserId = await storage.getString('auth_user_id').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      final savedEmail = await storage.getString('auth_user_email').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      final savedName = await storage.getString('auth_user_name').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      final savedThemeId = await storage.getString('auth_user_theme_id').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      final savedAvatarUrl = await storage.getString('auth_user_avatar_url').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      final savedPhone = await storage.getString('auth_user_phone').timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      if (savedToken != null && savedToken.isNotEmpty && savedUserId != null) {
        _currentUser = User(
          id: savedUserId,
          email: savedEmail ?? '',
          name: savedName,
          themeId: savedThemeId,
          avatarUrl: savedAvatarUrl,
          phone: savedPhone,
          token: savedToken,
        );
        debugPrint('AuthRepository: session restored, userId=$savedUserId');
      } else {
        debugPrint('AuthRepository: no saved session found');
      }
    } catch (e) {
      debugPrint('AuthRepository init error: $e');
    }
  }

  /// Сохранить данные пользователя в постоянное хранилище
  Future<void> saveSession(User user) async {
    try {
      final storage = StorageService();
      
      // Проверяем, нужно ли сохранять сессию
      final rememberMe = await storage.getString('remember_me');
      if (rememberMe != 'true') {
        debugPrint('AuthRepository: remember_me is false, not saving session');
        // Очищаем старую сессию из хранилища, если она была
        await _clearSession();
        // Сохраняем только в память, но не в хранилище
        return;
      }
      
      await storage.setString('auth_token', user.token);
      await storage.setString('auth_user_id', user.id);
      await storage.setString('auth_user_email', user.email);
      if (user.name != null) await storage.setString('auth_user_name', user.name!);
      if (user.themeId != null) await storage.setString('auth_user_theme_id', user.themeId!);
      if (user.avatarUrl != null) await storage.setString('auth_user_avatar_url', user.avatarUrl!);
      if (user.phone != null) await storage.setString('auth_user_phone', user.phone!);
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
      await storage.remove('auth_user_avatar_url');
      await storage.remove('auth_user_phone');
      // Не удаляем remember_me, чтобы знать настройку пользователя
    } catch (e) {
      debugPrint('AuthRepository clear error: $e');
    }
  }

  /// Полный выход с очисткой всех данных включая remember_me
  Future<void> logoutComplete() async {
    _currentUser = null;
    try {
      final storage = StorageService();
      await storage.remove('auth_token');
      await storage.remove('auth_user_id');
      await storage.remove('auth_user_email');
      await storage.remove('auth_user_name');
      await storage.remove('auth_user_theme_id');
      await storage.remove('auth_user_avatar_url');
      await storage.remove('auth_user_phone');
      await storage.remove('remember_me');
      await storage.remove('saved_email');
      await storage.remove('saved_password');
    } catch (e) {
      debugPrint('AuthRepository complete logout error: $e');
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
    await saveSession(_currentUser!);
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
    await saveSession(_currentUser!);
    return _currentUser!;
  }

  /// Выход
  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
  }
}
