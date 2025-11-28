import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ランキングサービス
class RankingService {
  static const String _rankingKey = 'local_ranking';

  /// ランキングデータ構造
  static Future<Map<String, List<RankingEntry>>> getAllRankings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_rankingKey);

    if (data == null) {
      return {
        'totalWins': [],
        'winStreak': [],
        'maxLevel': [],
        'evolutionCount': [],
        'totalCoins': [],
        'bossKills': [],
        'fastestEvolution': [],
      };
    }

    final Map<String, dynamic> decoded = json.decode(data);
    return decoded.map((key, value) {
      final List<dynamic> entries = value as List<dynamic>;
      return MapEntry(
        key,
        entries
            .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    });
  }

  /// ランキングを更新
  static Future<void> updateRanking(String category, String petName, int score,
      {Map<String, dynamic>? metadata}) async {
    final rankings = await getAllRankings();

    if (!rankings.containsKey(category)) {
      rankings[category] = [];
    }

    final entry = RankingEntry(
      petName: petName,
      score: score,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    rankings[category]!.add(entry);

    // スコア降順でソート
    rankings[category]!.sort((a, b) => b.score.compareTo(a.score));

    // トップ100のみ保持
    if (rankings[category]!.length > 100) {
      rankings[category] = rankings[category]!.take(100).toList();
    }

    await _saveRankings(rankings);
  }

  /// ランキング保存
  static Future<void> _saveRankings(
    Map<String, List<RankingEntry>> rankings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      rankings.map(
          (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
    );
    await prefs.setString(_rankingKey, encoded);
  }

  /// 特定カテゴリのトップN取得
  static Future<List<RankingEntry>> getTopRankings(
    String category, {
    int limit = 10,
  }) async {
    final rankings = await getAllRankings();
    final categoryRanking = rankings[category] ?? [];

    return categoryRanking.take(limit).toList();
  }

  /// 自分のランク取得
  static Future<int?> getMyRank(String category, String petName) async {
    final rankings = await getAllRankings();
    final categoryRanking = rankings[category] ?? [];

    for (int i = 0; i < categoryRanking.length; i++) {
      if (categoryRanking[i].petName == petName) {
        return i + 1; // 1位から始まる
      }
    }

    return null;
  }

  /// 勝利数ランキング更新
  static Future<void> updateWinsRanking(String petName, int wins) async {
    await updateRanking('totalWins', petName, wins);
  }

  /// 連勝記録更新
  static Future<void> updateWinStreakRanking(String petName, int streak) async {
    await updateRanking('winStreak', petName, streak);
  }

  /// 最高レベルランキング更新
  static Future<void> updateLevelRanking(String petName, int level) async {
    await updateRanking('maxLevel', petName, level);
  }

  /// 進化回数ランキング更新
  static Future<void> updateEvolutionRanking(
    String petName,
    int evolutionCount,
  ) async {
    await updateRanking('evolutionCount', petName, evolutionCount);
  }

  /// 総獲得コインランキング更新
  static Future<void> updateCoinsRanking(String petName, int totalCoins) async {
    await updateRanking('totalCoins', petName, totalCoins);
  }

  /// ボス討伐数ランキング更新
  static Future<void> updateBossKillsRanking(
    String petName,
    int bossKills,
  ) async {
    await updateRanking('bossKills', petName, bossKills);
  }

  /// 最速進化ランキング更新（秒数）
  static Future<void> updateFastestEvolution(
    String petName,
    int secondsToUltimate,
  ) async {
    await updateRanking(
      'fastestEvolution',
      petName,
      secondsToUltimate,
      metadata: {
        'displayTime': _formatDuration(secondsToUltimate),
      },
    );
  }

  /// 統計情報取得
  static Future<Map<String, int>> getStats() async {
    final rankings = await getAllRankings();

    return {
      'totalEntries': rankings.values.fold(0, (sum, list) => sum + list.length),
      'categories': rankings.keys.length,
      'totalWinsEntries': rankings['totalWins']?.length ?? 0,
      'winStreakEntries': rankings['winStreak']?.length ?? 0,
      'maxLevelEntries': rankings['maxLevel']?.length ?? 0,
    };
  }

  /// 時間フォーマット
  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}時間${minutes}分${secs}秒';
    } else if (minutes > 0) {
      return '${minutes}分${secs}秒';
    } else {
      return '${secs}秒';
    }
  }

  /// ランキングリセット
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rankingKey);
  }
}

/// ランキングエントリ
class RankingEntry {
  final String petName;
  final int score;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  RankingEntry({
    required this.petName,
    required this.score,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'petName': petName,
        'score': score,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
        petName: json['petName'] as String,
        score: json['score'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );
}
