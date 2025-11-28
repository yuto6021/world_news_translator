import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/status_effect.dart';
import 'dart:math';

/// 状態異常管理サービス
class StatusEffectService {
  static const String _effectsKey = 'battle_status_effects';

  /// バトル中の状態異常リストを取得
  static Future<List<ActiveStatusEffect>> getBattleEffects(
    String battleId,
    String target, // 'pet' or 'enemy'
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_effectsKey}_${battleId}_$target';
    final data = prefs.getString(key);

    if (data == null) return [];

    final List<dynamic> decoded = json.decode(data);
    return decoded
        .map((e) => ActiveStatusEffect.fromJson(e as Map<String, dynamic>))
        .where((effect) => !effect.isExpired())
        .toList();
  }

  /// 状態異常を適用
  static Future<bool> applyEffect(
      String battleId, String target, String effectId,
      {int? duration}) async {
    final baseEffect = StatusEffect.getById(effectId);
    if (baseEffect == null) return false;

    final effects = await getBattleEffects(battleId, target);

    // 既に同じ効果がある場合はターン数を更新
    final existingIndex = effects.indexWhere((e) => e.effect.id == effectId);

    if (existingIndex != -1) {
      // 既存のターン数と新規のターン数で大きい方を採用
      final newTurns = duration ?? baseEffect.duration;
      if (newTurns > effects[existingIndex].remainingTurns) {
        effects[existingIndex].remainingTurns = newTurns;
      }
    } else {
      // 新規適用
      effects.add(ActiveStatusEffect(
        effect: baseEffect,
        remainingTurns: duration ?? baseEffect.duration,
        appliedAt: DateTime.now(),
      ));
    }

    await _saveEffects(battleId, target, effects);
    return true;
  }

  /// 状態異常を解除
  static Future<void> removeEffect(
    String battleId,
    String target,
    String effectId,
  ) async {
    final effects = await getBattleEffects(battleId, target);
    effects.removeWhere((e) => e.effect.id == effectId);
    await _saveEffects(battleId, target, effects);
  }

  /// 全状態異常をクリア
  static Future<void> clearEffects(String battleId, String target) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_effectsKey}_${battleId}_$target';
    await prefs.remove(key);
  }

  /// ターン経過処理
  static Future<Map<String, dynamic>> processTurnEffects(
    String battleId,
    String target,
    int currentHp,
    int maxHp,
  ) async {
    final effects = await getBattleEffects(battleId, target);

    int totalDamage = 0;
    int totalHeal = 0;
    bool canAct = true;
    final List<String> messages = [];

    for (final activeEffect in effects) {
      final effect = activeEffect.effect;

      // ダメージ系
      if (effect.params.containsKey('damagePercent')) {
        final damage =
            (maxHp * (effect.params['damagePercent'] as int) / 100).round();
        totalDamage += damage;
        messages.add('${effect.name}で${damage}ダメージ');
      }

      // 回復系
      if (effect.params.containsKey('healPercent')) {
        final heal =
            (maxHp * (effect.params['healPercent'] as int) / 100).round();
        totalHeal += heal;
        messages.add('${effect.name}で${heal}回復');
      }

      // 行動不能
      if (effect.params['cannotAct'] == true) {
        canAct = false;
        messages.add('${effect.name}で行動不能！');
      }

      // 確率行動不能
      if (effect.params.containsKey('skipChance')) {
        final chance = effect.params['skipChance'] as int;
        if (Random().nextInt(100) < chance) {
          canAct = false;
          messages.add('${effect.name}で動けない！');
        }
      }

      // ターン減少
      activeEffect.decrementTurn();

      if (activeEffect.isExpired()) {
        messages.add('${effect.name}が解除された');
      }
    }

    // 期限切れの効果を削除
    final activeEffects = effects.where((e) => !e.isExpired()).toList();
    await _saveEffects(battleId, target, activeEffects);

    return {
      'damage': totalDamage,
      'heal': totalHeal,
      'canAct': canAct,
      'messages': messages,
    };
  }

  /// ステータス補正を計算
  static Future<Map<String, double>> calculateStatModifiers(
    String battleId,
    String target,
  ) async {
    final effects = await getBattleEffects(battleId, target);

    final Map<String, double> modifiers = {
      'attack': 1.0,
      'defense': 1.0,
      'speed': 1.0,
    };

    for (final activeEffect in effects) {
      final params = activeEffect.effect.params;

      if (params.containsKey('attackUp')) {
        modifiers['attack'] =
            modifiers['attack']! * (1 + params['attackUp'] / 100);
      }
      if (params.containsKey('attackDown')) {
        modifiers['attack'] =
            modifiers['attack']! * (1 - params['attackDown'] / 100);
      }
      if (params.containsKey('defenseUp')) {
        modifiers['defense'] =
            modifiers['defense']! * (1 + params['defenseUp'] / 100);
      }
      if (params.containsKey('defenseDown')) {
        modifiers['defense'] =
            modifiers['defense']! * (1 - params['defenseDown'] / 100);
      }
      if (params.containsKey('speedUp')) {
        modifiers['speed'] =
            modifiers['speed']! * (1 + params['speedUp'] / 100);
      }
      if (params.containsKey('speedDown')) {
        modifiers['speed'] =
            modifiers['speed']! * (1 - params['speedDown'] / 100);
      }
    }

    return modifiers;
  }

  /// ダメージ軽減率を計算
  static Future<double> calculateDamageReduction(
    String battleId,
    String target,
  ) async {
    final effects = await getBattleEffects(battleId, target);
    double reduction = 0.0;

    for (final activeEffect in effects) {
      final params = activeEffect.effect.params;

      // 無敵状態
      if (params['noDamage'] == true) {
        return 1.0; // 100%軽減
      }

      // シールド等
      if (params.containsKey('damageReduction')) {
        reduction += params['damageReduction'] / 100;
      }
    }

    return reduction.clamp(0.0, 1.0);
  }

  /// 回復可能かチェック
  static Future<bool> canHeal(String battleId, String target) async {
    final effects = await getBattleEffects(battleId, target);

    for (final activeEffect in effects) {
      if (activeEffect.effect.params['noHeal'] == true) {
        return false;
      }
    }

    return true;
  }

  /// 効果保存
  static Future<void> _saveEffects(
    String battleId,
    String target,
    List<ActiveStatusEffect> effects,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_effectsKey}_${battleId}_$target';
    final encoded = json.encode(effects.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  /// バトル終了時のクリーンアップ
  static Future<void> cleanupBattle(String battleId) async {
    await clearEffects(battleId, 'pet');
    await clearEffects(battleId, 'enemy');
  }
}
