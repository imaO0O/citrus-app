import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'storage_service.dart';

/// Офлайн-очередь («outbox») для записей, не ушедших на сервер из-за сети.
/// Запись кладётся локально и до-отправляется при следующем успехе/запуске.
/// Конфликтов нет: сервер сам генерирует id, так что повторная отправка просто
/// создаёт запись один раз (при успехе элемент удаляется из очереди).
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const _key = 'offline_outbox_v1';

  Future<List<Map<String, dynamic>>> _read() async {
    final raw = await StorageService().getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<Map<String, dynamic>> ops) async {
    await StorageService().setString(_key, jsonEncode(ops));
  }

  /// Добавить операцию в очередь (kind: 'mood' | 'diary' | 'sleep').
  Future<void> enqueue(String kind, Map<String, dynamic> data) async {
    final ops = await _read();
    ops.add({'kind': kind, 'data': data, 'queuedAt': DateTime.now().toIso8601String()});
    await _write(ops);
  }

  Future<int> count() async => (await _read()).length;

  /// Проиграть очередь. [replayers] — функция отправки по типу.
  /// На сетевой ошибке останавливаемся, сохраняя невыполненное (сеть ещё лежит).
  /// На прочих ошибках (валидация и т.п.) элемент отбрасываем, чтобы не зациклить.
  /// Возвращает число успешно отправленных.
  Future<int> flush(
    Map<String, Future<void> Function(Map<String, dynamic>)> replayers,
  ) async {
    final ops = await _read();
    if (ops.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    var flushed = 0;
    var stopped = false;

    for (final op in ops) {
      if (stopped) {
        remaining.add(op);
        continue;
      }
      final replay = replayers[op['kind']];
      if (replay == null) continue; // неизвестный тип — отбрасываем
      try {
        await replay(Map<String, dynamic>.from(op['data'] as Map));
        flushed++;
      } catch (e) {
        if (isNetworkError(e)) {
          remaining.add(op);
          stopped = true; // сеть всё ещё недоступна — стоп, дотолкнём позже
        } else {
          // ignore: avoid_print
          print('Outbox: пропускаю операцию ${op['kind']} из-за не-сетевой ошибки: $e');
        }
      }
    }

    await _write(remaining);
    return flushed;
  }

  /// Эвристика «это сетевая ошибка» — решаем, ставить ли запись в очередь.
  static bool isNetworkError(Object e) {
    if (e is SocketException || e is TimeoutException) return true;
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection') ||
        s.contains('network is unreachable') ||
        s.contains('timeout') ||
        s.contains('clientexception');
  }
}
