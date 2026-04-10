import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/diary_repository.dart';

abstract class DiaryEvent {
  const DiaryEvent();
}

class LoadDiaryEntries extends DiaryEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? search;

  const LoadDiaryEntries({this.startDate, this.endDate, this.search});
}

class CreateDiaryEntry extends DiaryEvent {
  final String content;
  final int? moodValue;
  final DateTime? entryDate;

  const CreateDiaryEntry({required this.content, this.moodValue, this.entryDate});
}

class UpdateDiaryEntry extends DiaryEvent {
  final String id;
  final String content;
  final int? moodValue;

  const UpdateDiaryEntry({required this.id, required this.content, this.moodValue});
}

class DeleteDiaryEntry extends DiaryEvent {
  final String id;

  const DeleteDiaryEntry(this.id);
}

abstract class DiaryState {
  const DiaryState();
}

class DiaryInitial extends DiaryState {
  const DiaryInitial();
}

class DiaryLoading extends DiaryState {
  const DiaryLoading();
}

class DiaryLoaded extends DiaryState {
  final List<DiaryEntry> entries;

  const DiaryLoaded(this.entries);
}

class DiaryError extends DiaryState {
  final String message;

  const DiaryError(this.message);
}

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final DiaryRepository _repository;

  DiaryBloc({required DiaryRepository repository})
      : _repository = repository,
        super(const DiaryInitial()) {
    on<LoadDiaryEntries>(_onLoadEntries);
    on<CreateDiaryEntry>(_onCreateEntry);
    on<UpdateDiaryEntry>(_onUpdateEntry);
    on<DeleteDiaryEntry>(_onDeleteEntry);
  }

  void updateUserId(String userId, {String? token}) {
    _repository.setUserId(userId, token: token);
    add(const LoadDiaryEntries());
  }

  Future<void> _onLoadEntries(LoadDiaryEntries event, Emitter<DiaryState> emit) async {
    emit(const DiaryLoading());

    try {
      final entries = await _repository.getEntries(
        startDate: event.startDate,
        endDate: event.endDate,
        search: event.search,
      );
      emit(DiaryLoaded(entries));
    } catch (e) {
      emit(DiaryError('Ошибка загрузки: $e'));
    }
  }

  Future<void> _onCreateEntry(CreateDiaryEntry event, Emitter<DiaryState> emit) async {
    try {
      await _repository.createEntry(
        content: event.content,
        moodValue: event.moodValue,
        entryDate: event.entryDate,
      );
      // Перезагружаем записи
      if (state is DiaryLoaded) add(const LoadDiaryEntries());
    } catch (e) {
      emit(DiaryError('Ошибка создания: $e'));
    }
  }

  Future<void> _onUpdateEntry(UpdateDiaryEntry event, Emitter<DiaryState> emit) async {
    try {
      await _repository.updateEntry(
        id: event.id,
        content: event.content,
        moodValue: event.moodValue,
      );
      if (state is DiaryLoaded) add(const LoadDiaryEntries());
    } catch (e) {
      emit(DiaryError('Ошибка обновления: $e'));
    }
  }

  Future<void> _onDeleteEntry(DeleteDiaryEntry event, Emitter<DiaryState> emit) async {
    try {
      await _repository.deleteEntry(event.id);
      if (state is DiaryLoaded) add(const LoadDiaryEntries());
    } catch (e) {
      emit(DiaryError('Ошибка удаления: $e'));
    }
  }
}
