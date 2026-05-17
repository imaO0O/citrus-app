import 'package:flutter_bloc/flutter_bloc.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc() : super(MediaInitial()) {
    on<LoadMedia>((event, emit) {
      emit(MediaLoaded());
    });
  }
}

abstract class MediaEvent {}
class LoadMedia extends MediaEvent {}

abstract class MediaState {}
class MediaInitial extends MediaState {}
class MediaLoading extends MediaState {}
class MediaLoaded extends MediaState {}