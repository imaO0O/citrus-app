import 'dart:convert';
import 'package:http/http.dart' as http;

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

  AuthApiService({this.baseUrl = 'http://192.168.0.102:8081', http.Client? client})
      : _client = client ?? http.Client();

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

  // Хранение в памяти (сбрасывается при перезапуске)
  User? _currentUser;

  AuthRepository({AuthApiService? apiService})
      : _apiService = apiService ?? AuthApiService();

  // Публичный геттер для API сервиса
  AuthApiService get apiService => _apiService;

  User? get currentUser => _currentUser;
  set currentUser(User? user) => _currentUser = user;
  bool get isAuthenticated => _currentUser != null;
  String? get token => _currentUser?.token;

  /// Инициализация (для совместимости)
  Future<void> init() async {
    // В памяти ничего не загружаем
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
    return _currentUser!;
  }

  /// Выход
  Future<void> logout() async {
    _currentUser = null;
  }
}
