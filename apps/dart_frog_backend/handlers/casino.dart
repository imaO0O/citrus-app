part of '../server.dart';

Future<Response> _getCasinoStatus(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');
  try {
    await _dbQuery("CREATE TABLE IF NOT EXISTS casino_users (user_id UUID PRIMARY KEY, coins INTEGER DEFAULT 0, last_daily_claim TIMESTAMP, quests_done TEXT[] DEFAULT '{}', total_spins INTEGER DEFAULT 0, total_wins INTEGER DEFAULT 0)");
    final result = await _dbQuery("SELECT coins, last_daily_claim, quests_done, total_spins, total_wins FROM casino_users WHERE user_id = '$userId'");
    if (result.isEmpty) {
      await _dbQuery("INSERT INTO casino_users (user_id, coins, last_daily_claim, quests_done) VALUES ('$userId', 100, NOW(), '{}')");
      return Response.json(body: {'coins': 100, 'quests_done': [], 'daily_claimed': true, 'total_spins': 0, 'total_wins': 0});
    }
    final row = result.first;
    final lastDaily = row[1] as DateTime?;
    var questsDone = row[2] as List? ?? [];
    final totalSpins = row[3] as int? ?? 0;
    final totalWins = row[4] as int? ?? 0;
    final now = DateTime.now();
    bool dailyClaimed = lastDaily != null && lastDaily.year == now.year && lastDaily.month == now.month && lastDaily.day == now.day;
    if (!dailyClaimed) {
      // Новый день: начисляем ежедневные монеты и сбрасываем выполненные задания
      await _dbQuery("UPDATE casino_users SET coins = coins + 100, last_daily_claim = NOW(), quests_done = '{}' WHERE user_id = '$userId'");
      dailyClaimed = true;
      questsDone = [];
    }
    final updated = await _dbQuery("SELECT coins FROM casino_users WHERE user_id = '$userId'");
    final coins = updated.isNotEmpty ? (updated.first[0] as int? ?? 0) : 0;
    return Response.json(body: {'coins': coins, 'quests_done': questsDone.map((e) => e.toString()).toList(), 'daily_claimed': dailyClaimed, 'total_spins': totalSpins, 'total_wins': totalWins});
  } catch (e) { return Response(statusCode: 500, body: 'Error: $e'); }
}

Future<Response> _claimDailyCoins(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');
  try {
    final now = DateTime.now();
    final check = await _dbQuery("SELECT last_daily_claim FROM casino_users WHERE user_id = '$userId'");
    if (check.isNotEmpty) {
      final lastClaim = check.first[0] as DateTime?;
      if (lastClaim != null && lastClaim.year == now.year && lastClaim.month == now.month && lastClaim.day == now.day) {
        return Response(statusCode: 400, body: 'Daily already claimed');
      }
    }
    await _dbQuery("INSERT INTO casino_users (user_id, coins, last_daily_claim) VALUES ('$userId', 100, NOW()) ON CONFLICT (user_id) DO UPDATE SET coins = casino_users.coins + 100, last_daily_claim = NOW()");
    
    final result = await _dbQuery("SELECT coins, last_daily_claim, quests_done, total_spins, total_wins FROM casino_users WHERE user_id = '$userId'");
    if (result.isEmpty) return Response(statusCode: 500, body: 'User not found');
    final row = result.first;
    final coins = row[0] as int? ?? 0;
    final lastDaily = row[1] as DateTime?;
    final questsDone = (row[2] as List? ?? []).map((e) => e.toString()).toList();
    final totalSpins = row[3] as int? ?? 0;
    final totalWins = row[4] as int? ?? 0;
    final dailyClaimed = lastDaily != null && lastDaily.year == now.year && lastDaily.month == now.month && lastDaily.day == now.day;
    
    return Response.json(body: {
      'coins': coins,
      'quests_done': questsDone,
      'daily_claimed': dailyClaimed,
      'total_spins': totalSpins,
      'total_wins': totalWins
    });
  } catch (e) { return Response(statusCode: 500, body: 'Error: $e'); }
}

Future<Response> _completeQuest(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');
  try {
    final body = await context.request.json();
    final questId = body['quest_id'] as String?;
    if (questId == null) return Response(statusCode: 400, body: 'quest_id required');
    
    await _dbQuery("INSERT INTO casino_users (user_id, coins, last_daily_claim, quests_done) VALUES ('$userId', 0, NULL, '{}') ON CONFLICT (user_id) DO NOTHING");
    
    final check = await _dbQuery("SELECT quests_done FROM casino_users WHERE user_id = '$userId'");
    if (check.isNotEmpty) {
      final quests = check.first[0] as List? ?? [];
      if (quests.contains(questId)) return Response(statusCode: 400, body: 'Quest already completed');
    }
    await _dbQuery("UPDATE casino_users SET coins = coins + 25, quests_done = array_append(quests_done, '$questId') WHERE user_id = '$userId'");
    
    final result = await _dbQuery("SELECT coins, last_daily_claim, quests_done, total_spins, total_wins FROM casino_users WHERE user_id = '$userId'");
    if (result.isEmpty) return Response(statusCode: 500, body: 'User not found');
    final row = result.first;
    final coins = row[0] as int? ?? 0;
    final lastDaily = row[1] as DateTime?;
    final questsDone = (row[2] as List? ?? []).map((e) => e.toString()).toList();
    final totalSpins = row[3] as int? ?? 0;
    final totalWins = row[4] as int? ?? 0;
    final now = DateTime.now();
    final dailyClaimed = lastDaily != null && lastDaily.year == now.year && lastDaily.month == now.month && lastDaily.day == now.day;
    
    return Response.json(body: {
      'coins': coins,
      'quests_done': questsDone,
      'daily_claimed': dailyClaimed,
      'total_spins': totalSpins,
      'total_wins': totalWins
    });
  } catch (e) { return Response(statusCode: 500, body: 'Error: $e'); }
}

Future<Response> _casinoSpin(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');
  try {
    final body = await context.request.json();
    final bet = body['bet'] as int? ?? 10;
    final symbols = body['symbols'] as List?;
    final win = body['win'] as int? ?? 0;
    
    if (symbols == null || symbols.length != 3) {
      return Response(statusCode: 400, body: 'symbols required');
    }
    
    final check = await _dbQuery("SELECT coins FROM casino_users WHERE user_id = '$userId'");
    final coins = check.isNotEmpty ? (check.first[0] as int? ?? 0) : 0;
    if (coins < bet) return Response(statusCode: 400, body: 'Not enough coins');
    
    await _dbQuery("UPDATE casino_users SET coins = coins - $bet + $win, total_spins = total_spins + 1 WHERE user_id = '$userId'");
    return Response.json(body: {'success': true, 'new_balance': coins - bet + win});
  } catch (e) { return Response(statusCode: 500, body: 'Error: $e'); }
}
