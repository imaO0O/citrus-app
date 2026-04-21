import 'dart:async';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import '../api/casino_api_service.dart';

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

class SpinResult {
  final bool success;
  final int newBalance;

  const SpinResult({
    required this.success,
    required this.newBalance,
  });

  factory SpinResult.fromJson(Map<String, dynamic> json) {
    return SpinResult(
      success: json['success'] as bool? ?? false,
      newBalance: json['new_balance'] as int? ?? 0,
    );
  }
}

class CasinoCoinsService {
  static final CasinoCoinsService _instance = CasinoCoinsService._internal();
  factory CasinoCoinsService() => _instance;
  CasinoCoinsService._internal();

  final _storage = StorageService();
  CasinoApiService? _api;
  CasinoStatus? _cachedStatus;
  bool _initialized = false;
  final _statusController = StreamController<CasinoStatus>.broadcast();

  Stream<CasinoStatus> get statusStream => _statusController.stream;

  static const int dailyFreeLimit = 100;
  static const int questReward = 25;

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

  Future<CasinoApiService> _getApi() async {
    if (_api != null) return _api!;
    final token = await _storage.getString('auth_token');
    _api = CasinoApiService(token: token);
    return _api!;
  }

Future<void> initialize() async {
    if (_initialized) return;
    await _refreshStatus(force: true);
    _initialized = true;
  }

  Future<void> refreshStatus() async {
    await _refreshStatus(force: true);
  }

  Future<void> _refreshStatus({bool force = false}) async {
    try {
      final api = await _getApi();
      final newStatus = await api.getStatus();
      _cachedStatus = newStatus;
      _statusController.add(newStatus);
    } catch (e) {
      debugPrint('Casino status refresh failed: $e');
    }
  }

  int get currentCoins => _cachedStatus?.coins ?? 0;
  Set<String> get questsDone => _cachedStatus?.questsDone.toSet() ?? {};
  bool get dailyClaimed => _cachedStatus?.dailyClaimed ?? false;

  Future<int> getCoins() async {
    if (_cachedStatus == null) {
      await _refreshStatus(force: true);
    }
    return _cachedStatus?.coins ?? 0;
  }

  Future<void> setCoins(int amount) async {
    debugPrint('setCoins not supported on server-based service');
  }

  Future<int> addCoins(int amount, {bool isQuestReward = false}) async {
    debugPrint('addCoins not supported on server-based service');
    return amount;
  }

  Future<bool> canAfford(int amount) async {
    final coins = await getCoins();
    return coins >= amount;
  }

  Future<SpinResult?> spin(int bet, List<String> symbols, int win) async {
    try {
      final api = await _getApi();
      final result = await api.spin(bet, symbols, win);
      _cachedStatus = CasinoStatus(
        coins: result.newBalance,
        dailyClaimed: _cachedStatus?.dailyClaimed ?? false,
        questsDone: _cachedStatus?.questsDone ?? [],
        totalSpins: (_cachedStatus?.totalSpins ?? 0) + 1,
        totalWins: _cachedStatus?.totalWins ?? 0,
      );
      _statusController.add(_cachedStatus!);
      return SpinResult(
        success: result.success,
        newBalance: result.newBalance,
      );
    } catch (e) {
      debugPrint('Spin failed: $e');
      return null;
    }
  }

  Future<bool> spendCoins(int amount) async {
    return canAfford(amount);
  }

  Future<void> ensureDailyCoins() async {
    await initialize();
  }

  Future<int> getDailyFreeReceived() async {
    await initialize();
    if (_cachedStatus?.dailyClaimed == true) return dailyFreeLimit;
    return 0;
  }

  Future<Set<String>> getQuestsDone() async {
    await initialize();
    return _cachedStatus?.questsDone.toSet() ?? {};
  }

  Future<bool> completeQuest(String questId) async {
    try {
      final api = await _getApi();
      _cachedStatus = await api.completeQuest(questId);
      _statusController.add(_cachedStatus!);
      debugPrint('Quest completed: $questId');
      return true;
    } catch (e) {
      debugPrint('Complete quest failed: $e');
      return false;
    }
  }

  Future<bool> isQuestDone(String questId) async {
    final done = await getQuestsDone();
    return done.contains(questId);
  }

  Future<bool> claimDaily() async {
    try {
      final api = await _getApi();
      _cachedStatus = await api.claimDaily();
      _statusController.add(_cachedStatus!);
      debugPrint('Daily claimed');
      return true;
    } catch (e) {
      debugPrint('Claim daily failed: $e');
      return false;
    }
  }

  Future<void> resetAll() async {
    debugPrint('resetAll not supported on server-based service');
  }

  void clearCache() {
    _cachedStatus = null;
    _api = null;
    _initialized = false;
  }
}