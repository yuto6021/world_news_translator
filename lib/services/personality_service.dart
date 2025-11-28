import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 性格管理サービス - ペットの行動パターンから性格を判定
class PersonalityService {
  static const String _behaviorKey = 'pet_behavior_log';
  static const String _personalityKey = 'pet_personality';

  /// 行動ログを記録
  static Future<void> recordBehavior(
    String petId,
    String behaviorType,
  ) async {
    final log = await _getBehaviorLog(petId);

    log.add({
      'type': behaviorType,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // 最新100件のみ保持
    if (log.length > 100) {
      log.removeRange(0, log.length - 100);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_behaviorKey\_$petId', json.encode(log));

    // 行動が一定数溜まったら性格を更新
    if (log.length >= 20) {
      await _updatePersonality(petId);
    }
  }

  /// 行動ログ取得
  static Future<List<Map<String, dynamic>>> _getBehaviorLog(
    String petId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_behaviorKey\_$petId');

    if (data == null) return [];

    final List<dynamic> decoded = json.decode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// 性格を判定・更新
  static Future<void> _updatePersonality(String petId) async {
    final log = await _getBehaviorLog(petId);

    if (log.isEmpty) return;

    // 行動カウント
    final Map<String, int> counts = {};
    for (final entry in log) {
      final type = entry['type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final total = log.length;

    // パーセンテージ計算
    final battleRate = (counts['battle'] ?? 0) / total;
    final feedRate = (counts['feed'] ?? 0) / total;
    final playRate = (counts['play'] ?? 0) / total;
    final cleanRate = (counts['clean'] ?? 0) / total;
    final shopRate = (counts['shop'] ?? 0) / total;

    // 性格判定
    String personality = _determinePersonality(
      battleRate: battleRate,
      feedRate: feedRate,
      playRate: playRate,
      cleanRate: cleanRate,
      shopRate: shopRate,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_personalityKey\_$petId', personality);
  }

  /// 性格判定ロジック
  static String _determinePersonality({
    required double battleRate,
    required double feedRate,
    required double playRate,
    required double cleanRate,
    required double shopRate,
  }) {
    // バトル重視
    if (battleRate > 0.4) {
      if (cleanRate > 0.2) {
        return 'warrior'; // 戦士タイプ（バトル+清潔）
      } else {
        return 'berserker'; // 狂戦士タイプ（バトルのみ）
      }
    }

    // 遊び重視
    if (playRate > 0.4) {
      if (feedRate > 0.2) {
        return 'cheerful'; // 陽気タイプ（遊び+食事）
      } else {
        return 'playful'; // やんちゃタイプ（遊びのみ）
      }
    }

    // 食事重視
    if (feedRate > 0.4) {
      return 'glutton'; // 食いしん坊タイプ
    }

    // 清潔重視
    if (cleanRate > 0.3) {
      return 'neat'; // きれい好きタイプ
    }

    // ショップ重視
    if (shopRate > 0.3) {
      return 'collector'; // コレクタータイプ
    }

    // バランス型
    if (battleRate > 0.15 &&
        playRate > 0.15 &&
        feedRate > 0.15 &&
        cleanRate > 0.15) {
      return 'balanced'; // バランスタイプ
    }

    // デフォルト
    return 'normal'; // ノーマルタイプ
  }

  /// 現在の性格を取得
  static Future<String> getPersonality(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_personalityKey\_$petId') ?? 'normal';
  }

  /// 性格情報を取得
  static Future<Map<String, dynamic>> getPersonalityInfo(String petId) async {
    final personality = await getPersonality(petId);
    final log = await _getBehaviorLog(petId);

    // 行動カウント
    final Map<String, int> counts = {};
    for (final entry in log) {
      final type = entry['type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return {
      'personality': personality,
      'personalityName': _getPersonalityName(personality),
      'description': _getPersonalityDescription(personality),
      'bonus': _getPersonalityBonus(personality),
      'behaviorCounts': counts,
      'totalBehaviors': log.length,
    };
  }

  /// 性格名取得
  static String _getPersonalityName(String personality) {
    const names = {
      'warrior': '⚔️ 戦士',
      'berserker': '💥 狂戦士',
      'cheerful': '😊 陽気',
      'playful': '🎮 やんちゃ',
      'glutton': '🍖 食いしん坊',
      'neat': '✨ きれい好き',
      'collector': '💰 コレクター',
      'balanced': '⚖️ バランス',
      'normal': '🐾 ノーマル',
    };
    return names[personality] ?? 'ノーマル';
  }

  /// 性格説明取得
  static String _getPersonalityDescription(String personality) {
    const descriptions = {
      'warrior': 'バトルを好む勇敢な性格。攻撃力と防御力にボーナス。',
      'berserker': 'バトル一筋の猛者。攻撃力大幅UPだが防御DOWN。',
      'cheerful': '遊ぶのが大好きな明るい性格。機嫌が上がりやすい。',
      'playful': '遊びが大好き！経験値獲得ボーナス。',
      'glutton': '食べることが生きがい。HP回復効果UP。',
      'neat': '清潔を保つ几帳面な性格。病気になりにくい。',
      'collector': 'アイテム収集が趣味。ドロップ率UP。',
      'balanced': 'すべてをバランスよくこなす。全能力が少しUP。',
      'normal': '標準的な性格。特別なボーナスなし。',
    };
    return descriptions[personality] ?? 'ノーマルな性格';
  }

  /// 性格ボーナス取得
  static Map<String, double> _getPersonalityBonus(String personality) {
    const bonuses = {
      'warrior': {'attack': 1.15, 'defense': 1.1},
      'berserker': {'attack': 1.3, 'defense': 0.8},
      'cheerful': {'mood': 1.2, 'intimacy': 1.15},
      'playful': {'exp': 1.2},
      'glutton': {'hpHeal': 1.3, 'hunger': 1.2},
      'neat': {'sickResist': 1.5, 'dirty': 0.7},
      'collector': {'dropRate': 1.25, 'coins': 1.1},
      'balanced': {'all': 1.05},
      'normal': <String, double>{},
    };
    return Map<String, double>.from(bonuses[personality] ?? {});
  }

  /// 全性格リスト取得
  static List<Map<String, dynamic>> getAllPersonalities() {
    const personalities = [
      'warrior',
      'berserker',
      'cheerful',
      'playful',
      'glutton',
      'neat',
      'collector',
      'balanced',
      'normal',
    ];

    return personalities
        .map((p) => {
              'id': p,
              'name': _getPersonalityName(p),
              'description': _getPersonalityDescription(p),
              'bonus': _getPersonalityBonus(p),
            })
        .toList();
  }

  /// 行動ログクリア
  static Future<void> clearBehaviorLog(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_behaviorKey\_$petId');
    await prefs.remove('$_personalityKey\_$petId');
  }

  /// 統計情報取得
  static Future<Map<String, dynamic>> getStats(String petId) async {
    final log = await _getBehaviorLog(petId);
    final personality = await getPersonality(petId);

    final Map<String, int> counts = {};
    for (final entry in log) {
      final type = entry['type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return {
      'totalBehaviors': log.length,
      'personality': personality,
      'behaviorBreakdown': counts,
    };
  }
}
