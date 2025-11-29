import 'dart:math';
import '../models/skill.dart';

/// バトルAIサービス - 敵の戦術的判断を行う
class BattleAIService {
  static final _random = Random();

  /// 敵の行動を選択（状況に応じて最適な行動を判断）
  static String selectEnemyAction({
    required int enemyHp,
    required int enemyMaxHp,
    required int playerHp,
    required int playerMaxHp,
    required String enemyType,
    required List<Skill> availableSkills,
    required List<String> playerWeaknesses, // プレイヤーの弱点属性
    required bool playerHasBuffs,
    required int turnCount,
  }) {
    final hpRatio = enemyHp / enemyMaxHp;
    final playerHpRatio = playerHp / playerMaxHp;

    // 緊急回復判定（HP30%以下で回復スキル優先）
    if (hpRatio < 0.3) {
      final healSkill = availableSkills.firstWhere(
        (s) =>
            s.type == SkillType.active &&
            s.effects.containsKey('heal') &&
            _random.nextDouble() < 0.7,
        orElse: () => availableSkills.first,
      );
      if (healSkill.effects.containsKey('heal')) {
        return healSkill.id;
      }
    }

    // 補助効果判定（HP50%以上で強化スキル使用）
    if (hpRatio > 0.5 && turnCount <= 2 && _random.nextDouble() < 0.5) {
      final buffSkill = availableSkills.firstWhere(
        (s) =>
            s.type == SkillType.active &&
            (s.effects.containsKey('attackBuff') ||
                s.effects.containsKey('defenseBuff') ||
                s.effects.containsKey('speedBuff')),
        orElse: () => availableSkills.first,
      );
      if (buffSkill.effects.isNotEmpty &&
          (buffSkill.effects.containsKey('attackBuff') ||
              buffSkill.effects.containsKey('defenseBuff'))) {
        return buffSkill.id;
      }
    }

    // 弱点属性を突く（プレイヤーの弱点属性に合致する技を優先）
    if (playerWeaknesses.isNotEmpty) {
      final weaknessSkill = availableSkills.firstWhere(
        (s) =>
            s.type == SkillType.active &&
            s.element != null &&
            playerWeaknesses.contains(s.element) &&
            _random.nextDouble() < 0.8,
        orElse: () => availableSkills.first,
      );
      if (weaknessSkill.element != null &&
          playerWeaknesses.contains(weaknessSkill.element)) {
        return weaknessSkill.id;
      }
    }

    // プレイヤーが瀕死なら全力攻撃
    if (playerHpRatio < 0.3) {
      final powerSkill = availableSkills
          .where((s) => s.type == SkillType.active && s.power >= 150)
          .toList();
      if (powerSkill.isNotEmpty) {
        return powerSkill[_random.nextInt(powerSkill.length)].id;
      }
    }

    // 状態異常狙い（プレイヤーが無傷の場合）
    if (playerHpRatio > 0.8 && _random.nextDouble() < 0.4) {
      final statusSkill = availableSkills.firstWhere(
        (s) =>
            s.type == SkillType.active && s.effects.containsKey('statusEffect'),
        orElse: () => availableSkills.first,
      );
      if (statusSkill.effects.containsKey('statusEffect')) {
        return statusSkill.id;
      }
    }

    // 敵タイプ別の戦術傾向
    switch (enemyType) {
      case 'aggressive':
        // 攻撃的：高威力技優先
        final attackSkills = availableSkills
            .where((s) => s.type == SkillType.active && s.power >= 140)
            .toList();
        if (attackSkills.isNotEmpty && _random.nextDouble() < 0.7) {
          return attackSkills[_random.nextInt(attackSkills.length)].id;
        }
        break;

      case 'defensive':
        // 防御的：バフ・デバフ優先
        final supportSkills = availableSkills
            .where((s) =>
                s.type == SkillType.active &&
                (s.effects.containsKey('defenseBuff') ||
                    s.effects.containsKey('attackDebuff')))
            .toList();
        if (supportSkills.isNotEmpty && _random.nextDouble() < 0.6) {
          return supportSkills[_random.nextInt(supportSkills.length)].id;
        }
        break;

      case 'tricky':
        // トリッキー：状態異常多用
        final statusSkills = availableSkills
            .where((s) =>
                s.type == SkillType.active &&
                s.effects.containsKey('statusEffect'))
            .toList();
        if (statusSkills.isNotEmpty && _random.nextDouble() < 0.7) {
          return statusSkills[_random.nextInt(statusSkills.length)].id;
        }
        break;

      case 'balanced':
      default:
        // バランス型：状況に応じて選択
        break;
    }

    // デフォルト：ランダムに攻撃スキル選択
    final attackSkills = availableSkills
        .where((s) => s.type == SkillType.active && s.power > 0)
        .toList();
    if (attackSkills.isNotEmpty) {
      return attackSkills[_random.nextInt(attackSkills.length)].id;
    }

    // 最終的にスキルがない場合は通常攻撃
    return 'normal_attack';
  }

  /// 敵タイプを判定（敵名から推測）
  static String determineEnemyType(String enemyName) {
    if (enemyName.contains('ゴブリン') ||
        enemyName.contains('オーク') ||
        enemyName.contains('ドラゴン')) {
      return 'aggressive';
    } else if (enemyName.contains('ゴーレム') ||
        enemyName.contains('タートル') ||
        enemyName.contains('シールド')) {
      return 'defensive';
    } else if (enemyName.contains('ウィッチ') ||
        enemyName.contains('シャドウ') ||
        enemyName.contains('ピクシー')) {
      return 'tricky';
    }
    return 'balanced';
  }

  /// 属性相性を計算（1.5倍 / 1.0倍 / 0.5倍）
  static double getElementAdvantage(
      String? attackElement, String? defenseElement) {
    if (attackElement == null || defenseElement == null) return 1.0;

    // 相性マップ（攻撃側→防御側）
    const advantageMap = {
      'fire': {'grass': 1.5, 'water': 0.5, 'ice': 1.5},
      'water': {'fire': 1.5, 'grass': 0.5, 'electric': 0.5},
      'grass': {'water': 1.5, 'fire': 0.5},
      'electric': {'water': 1.5, 'grass': 0.5},
      'ice': {'grass': 1.5, 'fire': 0.5},
      'dark': {'light': 1.5, 'dark': 0.5},
      'light': {'dark': 1.5, 'light': 0.5},
    };

    return advantageMap[attackElement]?[defenseElement] ?? 1.0;
  }

  /// プレイヤーの弱点属性を推測（ペットの種族から）
  static List<String> guessPlayerWeaknesses(String petSpecies) {
    // 種族名から推測（簡易実装）
    if (petSpecies.contains('炎') || petSpecies.contains('ファイア')) {
      return ['water'];
    } else if (petSpecies.contains('水') || petSpecies.contains('アクア')) {
      return ['grass', 'electric'];
    } else if (petSpecies.contains('草') || petSpecies.contains('リーフ')) {
      return ['fire'];
    } else if (petSpecies.contains('電') || petSpecies.contains('サンダー')) {
      return ['grass'];
    } else if (petSpecies.contains('氷') || petSpecies.contains('アイス')) {
      return ['fire'];
    } else if (petSpecies.contains('闇') || petSpecies.contains('ダーク')) {
      return ['light'];
    } else if (petSpecies.contains('光') || petSpecies.contains('ライト')) {
      return ['dark'];
    }
    return [];
  }

  /// スキル選択の優先度スコアを計算
  static int calculateSkillPriority(
    Skill skill,
    double hpRatio,
    double playerHpRatio,
    List<String> playerWeaknesses,
  ) {
    int score = 0;

    // HP低下時は回復優先
    if (hpRatio < 0.3 && skill.effects.containsKey('heal')) {
      score += 100;
    }

    // 弱点を突ける場合は高優先度
    if (skill.element != null && playerWeaknesses.contains(skill.element)) {
      score += 80;
    }

    // 威力の高い技は基本的に優先
    score += (skill.power / 10).round();

    // プレイヤーが瀕死なら攻撃優先
    if (playerHpRatio < 0.3 && skill.power > 0) {
      score += 50;
    }

    // 命中率が低い技は減点
    score -= (100 - skill.accuracy) ~/ 2;

    return score;
  }
}
