import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/auth_repository.dart';

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
  }

  Future<void> _onInit(AuthInit event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _repository.init();
    
    if (_repository.isAuthenticated) {
      emit(AuthAuthenticated(_repository.currentUser!));
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
      emit(AuthAuthenticated(user));
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
      emit(AuthAuthenticated(user));
    } catch (e) {
      print('AuthBloc: Ошибка регистрации: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }
}
