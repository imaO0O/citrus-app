import 'package:flutter_bloc/flutter_bloc.dart';

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  ChatbotBloc() : super(ChatbotInitial()) {
    on<SendMessage>((event, emit) {
      emit(ChatbotLoaded());
    });
  }
}

abstract class ChatbotEvent {}
class SendMessage extends ChatbotEvent {
  final String message;
  SendMessage(this.message);
}

abstract class ChatbotState {}
class ChatbotInitial extends ChatbotState {}
class ChatbotLoading extends ChatbotState {}
class ChatbotLoaded extends ChatbotState {}