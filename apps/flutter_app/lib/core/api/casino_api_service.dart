import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CasinoStatus {
  final int coins;
  final bool dailyClaimed;
  final List<String> questsDone;
  final int totalSpins;
  final int totalWins;

  const CasinoStatus({
    required this.coins,
    required this.dailyClaimed,
    required this.questsDone,
    required this.totalSpins,
    required this.totalWins,
  });

  factory CasinoStatus.fromJson(Map<String, dynamic> json) {
    return CasinoStatus(
      coins: json['coins'] as int? ?? 0,
      dailyClaimed: json['daily_claimed'] as bool? ?? false,
      questsDone: (json['quests_done'] as List?)?.cast<String>() ?? [],
      totalSpins: json['total_spins'] as int? ?? 0,
      totalWins: json['total_wins'] as int? ?? 0,
    );
  }
}

class SpinResponse {
  final bool success;
  final int newBalance;

  const SpinResponse({
    required this.success,
    required this.newBalance,
  });

  factory SpinResponse.fromJson(Map<String, dynamic> json) {
    return SpinResponse(
      success: json['success'] as bool? ?? false,
      newBalance: json['new_balance'] as int? ?? 0,
    );
  }
}

class CasinoApiService {
  final String baseUrl;
  final String? _token;
  final http.Client _client;

  CasinoApiService({
    String? baseUrl,
    http.Client? client,
    String? token,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client(),
        _token = token;

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<CasinoStatus> getStatus() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/casino/status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CasinoStatus.fromJson(data);
    }
    throw Exception('Failed to get casino status: ${response.statusCode}');
  }

  Future<CasinoStatus> claimDaily() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/casino/daily'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CasinoStatus.fromJson(data);
    }
    throw Exception('Failed to claim daily: ${response.statusCode}');
  }

  Future<CasinoStatus> completeQuest(String questId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/casino/quest'),
      headers: _headers,
      body: jsonEncode({'quest_id': questId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CasinoStatus.fromJson(data);
    }
    throw Exception('Failed to complete quest: ${response.statusCode}');
  }

  Future<SpinResponse> spin(int bet, List<String> symbols, int win) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/casino/spin'),
      headers: _headers,
      body: jsonEncode({'bet': bet, 'symbols': symbols, 'win': win}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SpinResponse.fromJson(data);
    }
    throw Exception('Failed to spin: ${response.statusCode}');
  }
}