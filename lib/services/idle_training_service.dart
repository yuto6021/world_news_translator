import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievement_service.dart';
import 'pet_service.dart';
import 'quest_service.dart';

/// 放置トレーニング（計画）管理サービス
/// - アクティブな計画を1つだけ保持
/// - 経過時間に応じて完了→受取でSP付与＋マスタリーXP加算
class IdleTrainingService {
  static const String _keyActive = 'idle_training_active';
  static const String _keyMastery = 'idle_training_mastery';
  static const int _devDurationScale = 1; // デバッグ短縮: 1=通常

  /// 提供プラン一覧
  /// durationSecは実運用ではより長く（例: 1800=30分）。
  static const Map<String, Map<String, dynamic>> plans = {
    'power': {
      'name': '筋力トレ',
      'emoji': '💪',
      'durationSec': 600, // 10分
      'sp': 1,
      'mastery': 'attack',
      'masteryXp': 25,
    },
    'guard': {
      'name': '盾の型',
      'emoji': '🛡️',
      'durationSec': 600,
      'sp': 1,
      'mastery': 'defense',
      'masteryXp': 25,
    },
    'agility': {
      'name': 'フットワーク',
      'emoji': '🏃',
      'durationSec': 600,
      'sp': 1,
      'mastery': 'speed',
      'masteryXp': 25,
    },
    'focus': {
      'name': '集中瞑想',
      'emoji': '🧘',
      'durationSec': 300, // 5分
      'sp': 1,
      'mastery': 'speed',
      'masteryXp': 10,
    },
  };

  /// マスタリー1レベルに必要なXP
  static const int masteryXpPerLevel = 100;

  /// アクティブ計画情報
  static Future<Map<String, dynamic>?> getActivePlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActive);
    if (raw == null) return null;
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      // 破損チェック
      if (data['planId'] == null || data['petId'] == null) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// 放置トレーニング開始
  static Future<void> startPlan({
    required String petId,
    required String planId,
  }) async {
    final config = plans[planId];
    if (config == null) throw Exception('無効なプラン');

    final duration = (config['durationSec'] as int) ~/ _devDurationScale;
    final payload = {
      'petId': petId,
      'planId': planId,
      'startAt': DateTime.now().millisecondsSinceEpoch,
      'durationSec': duration,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActive, json.encode(payload));

    // クエスト/実績フック
    await QuestService.trackAction('train_start');
    await AchievementService.unlock('training_idle_start');
  }

  /// 取り消し
  static Future<void> cancelPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActive);
  }

  /// 残り秒数（負値なら完了）
  static Future<int?> getRemainingSeconds() async {
    final active = await getActivePlan();
    if (active == null) return null;
    final startAt = active['startAt'] as int;
    final duration = active['durationSec'] as int;
    final elapsed = (DateTime.now().millisecondsSinceEpoch - startAt) ~/ 1000;
    return duration - elapsed;
  }

  /// 受取可能か
  static Future<bool> canClaim() async {
    final remain = await getRemainingSeconds();
    return remain != null && remain <= 0;
  }

  /// 受取処理（SP付与＋マスタリー更新）。結果を返す。
  static Future<Map<String, dynamic>> claim() async {
    final active = await getActivePlan();
    if (active == null) {
      return {'success': false, 'message': 'アクティブな計画がありません'};
    }
    final planId = active['planId'] as String;
    final petId = active['petId'] as String;
    final config = plans[planId]!;

    if (!(await canClaim())) {
      final remain = await getRemainingSeconds();
      return {
        'success': false,
        'message': remain != null ? '完了まで${remain.abs()}秒残っています' : '未開始の状態です'
      };
    }

    // SP付与
    final pet = await PetService.getPetById(petId);
    if (pet == null) {
      await cancelPlan();
      return {'success': false, 'message': 'ペットが見つかりません'};
    }

    final spGain = config['sp'] as int;
    await PetService.updatePet(petId, {
      'skillPoints': pet.skillPoints + spGain,
    });

    // マスタリーXP更新
    final masteryKey = config['mastery'] as String; // attack/defense/speed
    final xpGain = config['masteryXp'] as int;
    final mastery = await _getMasteryData();
    final petData = mastery[petId] as Map<String, dynamic>? ?? {};
    final statData = Map<String, dynamic>.from(
        petData[masteryKey] as Map<String, dynamic>? ??
            {
              'level': 0,
              'xp': 0,
            });
    int level = (statData['level'] as int?) ?? 0;
    int xp = (statData['xp'] as int?) ?? 0;
    xp += xpGain;
    while (xp >= masteryXpPerLevel) {
      xp -= masteryXpPerLevel;
      level += 1;
    }
    statData['level'] = level;
    statData['xp'] = xp;
    petData[masteryKey] = statData;
    mastery[petId] = petData;
    await _saveMasteryData(mastery);

    // 計画クリア → 解除
    await cancelPlan();

    // クエスト/実績フック
    await QuestService.trackAction('train_complete');
    await AchievementService.unlock('training_idle_claim_1');

    return {
      'success': true,
      'sp': spGain,
      'mastery': {
        'stat': masteryKey,
        'level': level,
        'xp': xp,
      }
    };
  }

  /// マスタリーの取得（ペット別）
  static Future<Map<String, dynamic>> getMastery(String petId) async {
    final data = await _getMasteryData();
    return Map<String, dynamic>.from(
        data[petId] as Map<String, dynamic>? ?? {});
  }

  static Future<Map<String, dynamic>> _getMasteryData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMastery);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(json.decode(raw));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveMasteryData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMastery, json.encode(data));
  }
}
