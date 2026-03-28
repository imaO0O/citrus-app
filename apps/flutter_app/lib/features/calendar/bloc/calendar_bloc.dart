import 'package:flutter_bloc/flutter_bloc.dart';

// События
abstract class CalendarEvent {}
class LoadCalendar extends CalendarEvent {}

// Состояния
abstract class CalendarState {}
class CalendarInitial extends CalendarState {}
class CalendarLoading extends CalendarState {}
class CalendarLoaded extends CalendarState {}

// BLoC
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc() : super(CalendarInitial()) {
    on<LoadCalendar>((event, emit) {
      emit(CalendarLoaded());
    });
  }
}