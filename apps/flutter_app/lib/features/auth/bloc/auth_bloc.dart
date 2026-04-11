import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/repository/auth_repository.dart';
import '../../../core/utils/theme_service.dart';

// События
abstract class AuthEvent {
  const AuthEvent();
}

class AuthInit extends AuthEvent {
  const AuthInit();
}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  const AuthLogin({required this.email, required this.password});
}

class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  final String? name;

  const AuthRegister({required this.email, required this.password, this.name});
}

class AuthLogout extends AuthEvent {
  const AuthLogout();
}

class AuthThemeChanged extends AuthEvent {
  final User user;

  const AuthThemeChanged(this.user);
}

// Состояния
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthInit>(_onInit);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<AuthThemeChanged>(_onThemeChanged);
  }

  Future<void> _onInit(AuthInit event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _repository.init();

    if (_repository.isAuthenticated) {
      final user = _repository.currentUser!;
      
      // Применяем тему пользователя при инициализации
      if (user.themeId != null) {
        final themeService = ThemeService();
        final isDark = user.themeId == '00000000-0000-0000-0000-000000000002';
        themeService.toggleTheme(isDark);
      }
      
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    print('AuthBloc: Вход пользователя ${event.email}...');
    emit(const AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      print('AuthBloc: Успешный вход! User: ${user.email}');
      
      // Применяем тему пользователя
      if (user.themeId != null) {
        final themeService = ThemeService();
        // Тёмная тема по умолчанию для ID 00000000-0000-0000-0000-000000000002
        final isDark = user.themeId == '00000000-0000-0000-0000-000000000002';
        themeService.toggleTheme(isDark);
      }
      
      emit(AuthAuthenticated(user));
      print('AuthBloc: Токен пользователя: ${user.token.isEmpty ? "ПУСТОЙ" : "length=${user.token.length}"}');

      // Сохраняем токен в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', user.token);
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_email', user.email);
    } catch (e) {
      print('AuthBloc: Ошибка входа: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    print('AuthBloc: Регистрация пользователя ${event.email}...');
    emit(const AuthLoading());
    try {
      final user = await _repository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      print('AuthBloc: Успешно! User: ${user.email}');
      
      // Применяем тему пользователя (по умолчанию светлая)
      if (user.themeId != null) {
        final themeService = ThemeService();
        final isDark = user.themeId == '00000000-0000-0000-0000-000000000002';
        themeService.toggleTheme(isDark);
      }
      
      emit(AuthAuthenticated(user));

      // Сохраняем токен в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', user.token);
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_email', user.email);
    } catch (e) {
      print('AuthBloc: Ошибка регистрации: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    await _repository.logout();
    // Очищаем токен из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    emit(const AuthUnauthenticated());
  }

  Future<void> _onThemeChanged(AuthThemeChanged event, Emitter<AuthState> emit) async {
    // Обновляем пользователя в репозитории
    _repository.currentUser = event.user;
    // Обновляем состояние
    emit(AuthAuthenticated(event.user));
  }
}
