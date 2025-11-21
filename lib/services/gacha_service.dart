import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// 実績ガチャサービス
class GachaService {
  static const String _lastGachaKey = 'last_gacha_date';
  static const String _gachaCountKey = 'gacha_count';
  static const String _activeChallengeKey = 'active_challenge';

  /// 今日のガチャが可能かチェック
  static Future<bool> canGachaToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGachaStr = prefs.getString(_lastGachaKey);
    if (lastGachaStr == null) return true;

    final lastGacha = DateTime.parse(lastGachaStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastGacha.year, lastGacha.month, lastGacha.day);

    return today.isAfter(lastDay);
  }

  /// ガチャを引く（チャレンジ実績を生成）
  static Future<Achievement> drawGacha() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_lastGachaKey, now.toIso8601String());
    
    final count = prefs.getInt(_gachaCountKey) ?? 0;
    await prefs.setInt(_gachaCountKey, count + 1);

    // ランダムでレア度決定（重み付き）
    final rng = math.Random();
    final rarityRoll = rng.nextInt(100);
    AchievementRarity rarity;
    if (rarityRoll < 50) {
      rarity = AchievementRarity.common;
    } else if (rarityRoll < 80) {
      rarity = AchievementRarity.rare;
    } else if (rarityRoll < 95) {
      rarity = AchievementRarity.epic;
    } else {
      rarity = AchievementRarity.legendary;
    }

    // レア度に応じたチャレンジ実績を生成
    final challenge = _generateChallenge(rarity);
    
    // アクティブチャレンジとして保存
    await prefs.setString(_activeChallengeKey, json.encode(challenge.toJson()));
    
    return challenge;
  }

  /// アクティブなチャレンジを取得
  static Future<Achievement?> getActiveChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final challengeStr = prefs.getString(_activeChallengeKey);
    if (challengeStr == null) return null;

    final challengeJson = json.decode(challengeStr);
    final challenge = Achievement.fromJson(challengeJson);
    
    // 期限切れチェック（24時間）
    final createdAt = challenge.unlockedAt ?? DateTime.now();
    if (DateTime.now().difference(createdAt).inHours >= 24) {
      await prefs.remove(_activeChallengeKey);
      return null;
    }

    return challenge;
  }

  /// チャレンジをクリア
  static Future<void> completeChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final challengeStr = prefs.getString(_activeChallengeKey);
    if (challengeStr == null) return;

    final challengeJson = json.decode(challengeStr);
    final challenge = Achievement.fromJson(challengeJson);
    
    // 実績として記録
    final updatedChallenge = challenge.copyWith(
      progress: challenge.target,
      unlockedAt: DateTime.now(),
    );
    
    await prefs.setString(_activeChallengeKey, json.encode(updatedChallenge.toJson()));
  }

  /// チャレンジ実績を生成
  static Achievement _generateChallenge(AchievementRarity rarity) {
    final rng = math.Random();
    final challengeTypes = [
      'read_articles',
      'play_game',
      'comment',
      'favorite',
      'quiz_score',
    ];
    
    final type = challengeTypes[rng.nextInt(challengeTypes.length)];
    
    String id, title, description, icon;
    int target;
    
    switch (type) {
      case 'read_articles':
        target = _getTargetByRarity(rarity, [3, 5, 10, 20]);
        id = 'gacha_read_$target';
        title = '$target記事読破チャレンジ';
        description = '24時間以内に$target記事を読む';
        icon = '📚';
        break;
      case 'play_game':
        target = _getTargetByRarity(rarity, [100, 200, 500, 1000]);
        id = 'gacha_game_$target';
        title = 'ゲームスコア$targetチャレンジ';
        description = '24時間以内に任意のゲームで$target点を達成';
        icon = '🎮';
        break;
      case 'comment':
        target = _getTargetByRarity(rarity, [3, 5, 10, 15]);
        id = 'gacha_comment_$target';
        title = '$targetコメントチャレンジ';
        description = '24時間以内に$target件コメントを投稿';
        icon = '💬';
        break;
      case 'favorite':
        target = _getTargetByRarity(rarity, [5, 10, 20, 30]);
        id = 'gacha_favorite_$target';
        title = '$targetお気に入りチャレンジ';
        description = '24時間以内に$target件お気に入り登録';
        icon = '❤️';
        break;
      case 'quiz_score':
      default:
        target = _getTargetByRarity(rarity, [70, 85, 95, 100]);
        id = 'gacha_quiz_$target';
        title = 'クイズ$target点チャレンジ';
        description = '24時間以内にクイズで$target点以上を獲得';
        icon = '🧠';
        break;
    }
    
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      target: target,
      rarity: rarity,
      progress: 0,
      unlockedAt: DateTime.now(), // チャレンジ開始時刻として使用
    );
  }

  /// レア度別のターゲット値を取得
  static int _getTargetByRarity(AchievementRarity rarity, List<int> values) {
    switch (rarity) {
      case AchievementRarity.common:
        return values[0];
      case AchievementRarity.rare:
        return values[1];
      case AchievementRarity.epic:
        return values[2];
      case AchievementRarity.legendary:
        return values[3];
    }
  }

  /// 総ガチャ回数を取得
  static Future<int> getTotalGachaCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gachaCountKey) ?? 0;
  }
}
