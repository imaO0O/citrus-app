import 'package:flutter_bloc/flutter_bloc.dart';
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
  final bool clearRememberMe;
  const AuthLogout({this.clearRememberMe = true});
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

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
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

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
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

  Future<void> _onThemeChanged(AuthThemeChanged event, Emitter<AuthState> emit) async {
    _repository.currentUser = event.user;
    emit(AuthAuthenticated(event.user));
  }
}
