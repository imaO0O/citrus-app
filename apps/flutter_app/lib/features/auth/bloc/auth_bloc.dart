import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/auth_repository.dart';
import '../../../core/repository/notification_preferences_repository.dart';
import '../../../core/utils/network_error.dart';
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
  final bool clearRememberMe;
  const AuthLogout({this.clearRememberMe = true});
}

class AuthThemeChanged extends AuthEvent {
  final User user;

  const AuthThemeChanged(this.user);
}

class AuthProfileUpdated extends AuthEvent {
  final User user;

  const AuthProfileUpdated(this.user);
}

class AuthRequestNotificationPermissions extends AuthEvent {
  const AuthRequestNotificationPermissions();
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
  final NotificationPreferencesRepository _notificationRepository;

  AuthBloc({
    required AuthRepository repository,
    NotificationPreferencesRepository? notificationRepository,
  })  : _repository = repository,
        _notificationRepository = notificationRepository ?? NotificationPreferencesRepository(),
        super(const AuthInitial()) {
    on<AuthInit>(_onInit);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<AuthThemeChanged>(_onThemeChanged);
    on<AuthProfileUpdated>(_onProfileUpdated);
    on<AuthRequestNotificationPermissions>(_onRequestPermissions);
  }

  Future<void> _onInit(AuthInit event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _repository.init();

    if (_repository.isAuthenticated) {
      final user = _repository.currentUser!;
      ThemeService().setUserCredentials(user.token, user.id);
      // Тема уже загружена в ThemeService при старте приложения,
      // не нужно вызывать toggleTheme — он перезаписывает серверную тему
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );

      ThemeService().setUserCredentials(user.token, user.id);
      if (user.themeId != null) {
        final isDark = user.themeId == '00000000-0000-0000-0000-000000000002';
        ThemeService().toggleTheme(isDark);
      }

      // Запрашиваем разрешения на уведомления (не блокируем UI)
      _requestNotificationPermissions();

      // Показываем приветственное уведомление
      await _notificationRepository.notificationService.showInstantNotification(
        title: '👋 С возвращением!',
        body: 'Рады видеть вас снова, ${user.name ?? user.email}',
        channelId: 'general',
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      // Сетевые ошибки переводим в понятный текст, осмысленные (неверный пароль) сохраняем
      emit(AuthError(friendlyError(e, fallback: e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      ThemeService().setUserCredentials(user.token, user.id);
      if (user.themeId != null) {
        final isDark = user.themeId == '00000000-0000-0000-0000-000000000002';
        ThemeService().toggleTheme(isDark);
      }

      // Запрашиваем разрешения на уведомления (не блокируем UI)
      _requestNotificationPermissions();

      // Показываем приветственное уведомление для нового пользователя
      await _notificationRepository.notificationService.showInstantNotification(
        title: '🎉 Добро пожаловать!',
        body: 'Спасибо за регистрацию, ${user.name ?? user.email}! Начните заботиться о себе.',
        channelId: 'general',
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      // Сетевые ошибки переводим в понятный текст, осмысленные (email занят) сохраняем
      emit(AuthError(friendlyError(e, fallback: e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    if (event.clearRememberMe) {
      await _repository.logoutComplete();
    } else {
      await _repository.logout();
    }
    ThemeService().clearUserCredentials();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onRequestPermissions(
    AuthRequestNotificationPermissions event,
    Emitter<AuthState> emit,
  ) async {
    await _requestNotificationPermissions();
  }

  /// Запросить разрешения на уведомления
  Future<void> _requestNotificationPermissions() async {
    try {
      final granted = await _notificationRepository.requestPermissions();
      debugPrint('AuthBloc: разрешения на уведомления = $granted');
    } catch (e) {
      debugPrint('AuthBloc: ошибка запроса разрешений: $e');
    }
  }

  Future<void> _onThemeChanged(AuthThemeChanged event, Emitter<AuthState> emit) async {
    _repository.currentUser = event.user;
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onProfileUpdated(AuthProfileUpdated event, Emitter<AuthState> emit) async {
    _repository.currentUser = event.user;
    await _repository.saveSession(event.user);
    emit(AuthAuthenticated(event.user));
  }
}
