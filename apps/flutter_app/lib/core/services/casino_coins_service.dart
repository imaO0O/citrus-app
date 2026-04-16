import 'dart:convert';
import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Задание для получения монет
class CasinoQuest {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int reward;

  const CasinoQuest({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.reward,
  });
}

/// Сервис для управления монетами казино:
/// - ежедневный лимит 100 монет
/// - выполнение заданий для получения дополнительных монет
class CasinoCoinsService {
  static final CasinoCoinsService _instance = CasinoCoinsService._internal();
  factory CasinoCoinsService() => _instance;
  CasinoCoinsService._internal();

  final _storage = StorageService();

  // Ключи хранилища
  static const _coinsKey = 'casino_coins';
  static const _dailyKey = 'casino_daily_limit';
  static const _questsKey = 'casino_quests_done';

  /// Ежедневный лимит бесплатных монет
  static const int dailyFreeLimit = 100;

  /// Награда за каждое задание
  static const int questReward = 25;

  /// Доступные задания
  static const quests = [
    CasinoQuest(
      id: 'diary',
      emoji: '📝',
      title: 'Запись в дневнике',
      description: 'Сделай запись в дневнике',
      reward: 25,
    ),
    CasinoQuest(
      id: 'sleep',
      emoji: '🌙',
      title: 'Записать сон',
      description: 'Запиши данные о сне',
      reward: 25,
    ),
    CasinoQuest(
      id: 'exercise',
      emoji: '🧘',
      title: 'Выполнить упражнение',
      description: 'Выполни дыхательное упражнение',
      reward: 25,
    ),
    CasinoQuest(
      id: 'mood',
      emoji: '🍊',
      title: 'Отметить настроение',
      description: 'Поставь сегодняшнюю эмоцию с помощью дольки',
      reward: 25,
    ),
  ];

  /// Получить текущий баланс монет
  Future<int> getCoins() async {
    final raw = await _storage.getString(_coinsKey);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  /// Установить баланс монет
  Future<void> setCoins(int amount) async {
    await _storage.setString(_coinsKey, amount.toString());
  }

  /// Добавить монеты (с проверкой лимитов)
  /// Возвращает реально добавленное количество
  Future<int> addCoins(int amount, {bool isQuestReward = false}) async {
    final coins = await getCoins();
    final newAmount = coins + amount;
    await setCoins(newAmount);
    return amount;
  }

  /// Списать монеты. Возвращает false если недостаточно.
  Future<bool> spendCoins(int amount) async {
    final coins = await getCoins();
    if (coins < amount) return false;
    await setCoins(coins - amount);
    return true;
  }

  /// Получить дату последнего обновления дневного лимита
  Future<String?> _getDailyDate() async {
    return await _storage.getString(_dailyKey);
  }

  /// Получить текущую дату как строку YYYY-MM-DD
  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Проверить, наступил ли новый день, и сбросить лимит если нужно
  Future<void> _checkDailyReset() async {
    final lastDate = await _getDailyDate();
    final today = _todayStr();

    if (lastDate != today) {
      // Новый день — сбрасываем лимит и выдаем бесплатные монеты
      await _storage.setString(_dailyKey, today);
      await _clearQuestsDone();
      // Начисляем ежедневный лимит
      final coins = await getCoins();
      await setCoins(coins + dailyFreeLimit);
    }
  }

  /// Инициализация при первом запуске дня
  Future<void> ensureDailyCoins() async {
    await _checkDailyReset();
  }

  /// Получить сколько бесплатных монет уже получено сегодня
  Future<int> getDailyFreeReceived() async {
    final lastDate = await _getDailyDate();
    if (lastDate != _todayStr()) return 0;
    // Если дата совпадает — лимит уже выдан
    return dailyFreeLimit;
  }

  /// Получить список выполненных сегодня заданий
  Future<Set<String>> getQuestsDone() async {
    final lastDate = await _getDailyDate();
    if (lastDate != _todayStr()) return {};

    final raw = await _storage.getString(_questsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// Очистить выполненные задания (при смене дня)
  Future<void> _clearQuestsDone() async {
    await _storage.setString(_questsKey, '[]');
  }

  /// Отметить задание как выполненное и начислить награду
  /// Возвращает true если задание было отмечено (первый раз за день)
  Future<bool> completeQuest(String questId) async {
    await _checkDailyReset();

    final done = await getQuestsDone();
    if (done.contains(questId)) return false; // Уже выполнено

    // Находим награду за задание
    final quest = quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => const CasinoQuest(id: '', emoji: '', title: '', description: '', reward: 0),
    );
    if (quest.id.isEmpty) return false;

    // Отмечаем задание и начисляем монеты
    done.add(questId);
    await _storage.setString(_questsKey, jsonEncode(done.toList()));
    await addCoins(quest.reward, isQuestReward: true);
    debugPrint('Casino quest completed: $questId, +${quest.reward} coins');
    return true;
  }

  /// Проверить, выполнено ли конкретное задание сегодня
  Future<bool> isQuestDone(String questId) async {
    final done = await getQuestsDone();
    return done.contains(questId);
  }

  /// Полный сброс (для отладки)
  Future<void> resetAll() async {
    await _storage.remove(_coinsKey);
    await _storage.remove(_dailyKey);
    await _storage.remove(_questsKey);
  }
}
