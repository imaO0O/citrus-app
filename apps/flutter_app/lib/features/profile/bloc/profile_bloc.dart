import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/auth_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository;

  ProfileBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(ProfileInitial()) {
    on<LoadProfile>((event, emit) {
      final user = _authRepository.currentUser;
      if (user != null) {
        emit(ProfileLoaded(user: user));
      } else {
        emit(ProfileError('Пользователь не найден'));
      }
    });
  }
}

abstract class ProfileEvent {}
class LoadProfile extends ProfileEvent {}

abstract class ProfileState {}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final User user;
  ProfileLoaded({required this.user});
}
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}