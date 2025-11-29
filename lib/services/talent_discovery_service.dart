import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/pet.dart';

/// 才能発見サービス - 特定条件で才能値を公開
class TalentDiscoveryService {
  static const String _keyDiscoveryData = 'talent_discovery_data';

  /// 才能発見の条件
  static const int requiredLevel = 10;
  static const int requiredTrainingCount = 10;
  static const int requiredBattleCount = 5;

  /// ペットの才能発見条件をチェック
  static Future<bool> checkDiscoveryConditions(PetModel pet) async {
    // 既に発見済みの場合はfalse
    if (pet.talentDiscovered) return false;

    // 条件: レベル10以上 AND (特訓10回以上 OR バトル5回以上)
    final trainingCount = await _getTrainingCount(pet.id);

    return pet.level >= requiredLevel &&
        (trainingCount >= requiredTrainingCount ||
            pet.battleCount >= requiredBattleCount);
  }

  /// 才能を発見する（talentDiscoveredフラグを立てる）
  static Future<void> discoverTalent(PetModel pet) async {
    if (pet.talentDiscovered) return;

    pet.talentDiscovered = true;
    await pet.save();
  }

  /// 才能発見時のボーナスメッセージ
  static Map<String, dynamic> getTalentInfo(PetModel pet) {
    return {
      'attack': {
        'value': pet.talentAttack,
        'rank': _getTalentRank(pet.talentAttack),
        'description': _getTalentDescription(pet.talentAttack, '攻撃'),
      },
      'defense': {
        'value': pet.talentDefense,
        'rank': _getTalentRank(pet.talentDefense),
        'description': _getTalentDescription(pet.talentDefense, '防御'),
      },
      'speed': {
        'value': pet.talentSpeed,
        'rank': _getTalentRank(pet.talentSpeed),
        'description': _getTalentDescription(pet.talentSpeed, '速度'),
      },
    };
  }

  /// 才能値のランク判定
  static String _getTalentRank(int talentValue) {
    if (talentValue >= 80) return 'S (天才)';
    if (talentValue >= 70) return 'A (優秀)';
    if (talentValue >= 60) return 'B (良好)';
    if (talentValue >= 50) return 'C (平均)';
    if (talentValue >= 40) return 'D (やや低い)';
    return 'E (要努力)';
  }

  /// 才能値の説明文
  static String _getTalentDescription(int talentValue, String statName) {
    if (talentValue >= 80) {
      return '${statName}の成長が非常に優れています！';
    } else if (talentValue >= 70) {
      return '${statName}の成長が優秀です。';
    } else if (talentValue >= 60) {
      return '${statName}の成長は良好です。';
    } else if (talentValue >= 50) {
      return '${statName}の成長は平均的です。';
    } else if (talentValue >= 40) {
      return '${statName}の成長はやや控えめです。';
    } else {
      return '${statName}は努力でカバーしましょう。';
    }
  }

  /// 才能発見の進捗状況を取得
  static Future<Map<String, dynamic>> getDiscoveryProgress(PetModel pet) async {
    final trainingCount = await _getTrainingCount(pet.id);

    return {
      'discovered': pet.talentDiscovered,
      'level': pet.level,
      'levelRequired': requiredLevel,
      'levelMet': pet.level >= requiredLevel,
      'trainingCount': trainingCount,
      'trainingRequired': requiredTrainingCount,
      'trainingMet': trainingCount >= requiredTrainingCount,
      'battleCount': pet.battleCount,
      'battleRequired': requiredBattleCount,
      'battleMet': pet.battleCount >= requiredBattleCount,
      'canDiscover': await checkDiscoveryConditions(pet),
    };
  }

  /// 特訓回数を取得
  static Future<int> _getTrainingCount(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyDiscoveryData) ?? '{}';
    final Map<String, dynamic> discoveryData = json.decode(data);
    return (discoveryData[petId] as Map<String, dynamic>?)?['trainingCount']
            as int? ??
        0;
  }

  /// 特訓回数を記録
  static Future<void> recordTraining(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyDiscoveryData) ?? '{}';
    final Map<String, dynamic> discoveryData = json.decode(data);

    if (discoveryData[petId] == null) {
      discoveryData[petId] = {'trainingCount': 0};
    }

    final petData = discoveryData[petId] as Map<String, dynamic>;
    petData['trainingCount'] = (petData['trainingCount'] as int? ?? 0) + 1;

    await prefs.setString(_keyDiscoveryData, json.encode(discoveryData));
  }

  /// 才能値の合計スコア
  static int getTotalTalent(PetModel pet) {
    return pet.talentAttack + pet.talentDefense + pet.talentSpeed;
  }

  /// 才能値の平均
  static double getAverageTalent(PetModel pet) {
    return getTotalTalent(pet) / 3.0;
  }

  /// 最も高い才能
  static String getHighestTalent(PetModel pet) {
    final talents = {
      '攻撃': pet.talentAttack,
      '防御': pet.talentDefense,
      '速度': pet.talentSpeed,
    };

    final maxValue = talents.values.reduce((a, b) => a > b ? a : b);
    return talents.entries.firstWhere((e) => e.value == maxValue).key;
  }

  /// 最も低い才能
  static String getLowestTalent(PetModel pet) {
    final talents = {
      '攻撃': pet.talentAttack,
      '防御': pet.talentDefense,
      '速度': pet.talentSpeed,
    };

    final minValue = talents.values.reduce((a, b) => a < b ? a : b);
    return talents.entries.firstWhere((e) => e.value == minValue).key;
  }
}
