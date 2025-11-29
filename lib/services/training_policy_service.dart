import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 育成方針サービス - ペットの成長方向性を管理
class TrainingPolicyService {
  static const String _keyPolicies = 'training_policies';

  /// 育成方針の種類
  static const policies = {
    'balanced': {
      'name': 'バランス型',
      'description': '全てのステータスを均等に成長',
      'icon': '⚖️',
      'attackMod': 1.0,
      'defenseMod': 1.0,
      'speedMod': 1.0,
    },
    'offensive': {
      'name': '攻撃特化型',
      'description': '攻撃力を重点的に強化',
      'icon': '⚔️',
      'attackMod': 1.5,
      'defenseMod': 0.8,
      'speedMod': 0.9,
    },
    'defensive': {
      'name': '防御特化型',
      'description': '防御力を重点的に強化',
      'icon': '🛡️',
      'attackMod': 0.8,
      'defenseMod': 1.5,
      'speedMod': 0.9,
    },
    'speed': {
      'name': '速度特化型',
      'description': '素早さを重点的に強化',
      'icon': '⚡',
      'attackMod': 0.9,
      'defenseMod': 0.8,
      'speedMod': 1.5,
    },
  };

  /// ペットの育成方針を取得
  static Future<String> getPolicy(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyPolicies) ?? '{}';
    final Map<String, dynamic> policyData = json.decode(data);
    return policyData[petId] as String? ?? 'balanced';
  }

  /// ペットの育成方針を設定
  static Future<void> setPolicy(String petId, String policy) async {
    if (!policies.containsKey(policy)) {
      throw Exception('無効な育成方針');
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyPolicies) ?? '{}';
    final Map<String, dynamic> policyData = json.decode(data);

    policyData[petId] = policy;
    await prefs.setString(_keyPolicies, json.encode(policyData));
  }

  /// 育成方針の詳細情報を取得
  static Map<String, dynamic>? getPolicyInfo(String policyKey) {
    return policies[policyKey];
  }

  /// レベルアップ時の成長値を育成方針で補正
  static Map<String, int> applyPolicyBonus(
    String policyKey,
    int baseAttack,
    int baseDefense,
    int baseSpeed,
  ) {
    final policy = policies[policyKey];
    if (policy == null) {
      return {
        'attack': baseAttack,
        'defense': baseDefense,
        'speed': baseSpeed,
      };
    }

    return {
      'attack': (baseAttack * (policy['attackMod'] as double)).round(),
      'defense': (baseDefense * (policy['defenseMod'] as double)).round(),
      'speed': (baseSpeed * (policy['speedMod'] as double)).round(),
    };
  }

  /// 全育成方針のリストを取得
  static List<MapEntry<String, Map<String, dynamic>>> getAllPolicies() {
    return policies.entries.toList();
  }

  /// 育成方針変更の確認メッセージ
  static String getChangePolicyMessage(String oldPolicy, String newPolicy) {
    final oldInfo = policies[oldPolicy];
    final newInfo = policies[newPolicy];

    return '育成方針を ${oldInfo?['icon']} ${oldInfo?['name']} から\n'
        '${newInfo?['icon']} ${newInfo?['name']} に変更しますか？\n\n'
        '${newInfo?['description']}';
  }

  /// 育成方針による累計ボーナスを計算（表示用）
  static Map<String, double> calculateCumulativeBonus(
    String policyKey,
    int currentLevel,
  ) {
    final policy = policies[policyKey];
    if (policy == null) {
      return {'attack': 1.0, 'defense': 1.0, 'speed': 1.0};
    }

    // レベル1からの累積成長を考慮
    return {
      'attack': (policy['attackMod'] as double),
      'defense': (policy['defenseMod'] as double),
      'speed': (policy['speedMod'] as double),
    };
  }
}
