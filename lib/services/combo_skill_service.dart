/// 連携技サービス - 特定スキルの組み合わせで特殊効果発動
class ComboSkillService {
  /// 連携技の定義
  static final List<ComboSkill> _combos = [
    ComboSkill(
      id: 'fire_water_combo',
      name: '紅蓮の蒸気',
      skillIds: ['active_fire_blast', 'active_aqua_jet'],
      description: '炎と水の融合攻撃',
      powerMultiplier: 1.8,
      effect: '敵の防御-20% 2ターン',
    ),
    ComboSkill(
      id: 'thunder_water_combo',
      name: '雷雨の猛撃',
      skillIds: ['active_thunder_bolt', 'active_aqua_jet'],
      description: '電撃と水流の連携',
      powerMultiplier: 2.0,
      effect: '麻痺確率50%',
    ),
    ComboSkill(
      id: 'ice_dark_combo',
      name: '絶対零度の闇',
      skillIds: ['active_ice_beam', 'active_dark_pulse'],
      description: '氷と闇の恐怖',
      powerMultiplier: 1.9,
      effect: '凍結+混乱同時付与30%',
    ),
    ComboSkill(
      id: 'triple_slash_combo',
      name: '三段突き',
      skillIds: ['active_powerslash', 'active_critical_strike', 'active_combo'],
      description: '連続斬撃の奥義',
      powerMultiplier: 2.2,
      effect: '必ずクリティカル',
    ),
    ComboSkill(
      id: 'heal_shield_combo',
      name: '聖なる守護',
      skillIds: ['active_heal', 'active_shield'],
      description: '回復と防御の融合',
      powerMultiplier: 1.5,
      effect: 'HP50%回復+防御2倍3ターン',
    ),
    ComboSkill(
      id: 'all_buff_combo',
      name: '覚醒',
      skillIds: ['active_atk_boost', 'active_speed_boost', 'active_shield'],
      description: '全能力強化',
      powerMultiplier: 1.0,
      effect: '攻撃・防御・速さ全て1.5倍 3ターン',
    ),
    ComboSkill(
      id: 'poison_curse_combo',
      name: '呪毒の霧',
      skillIds: ['active_poison', 'active_curse'],
      description: '毒と呪いの複合',
      powerMultiplier: 1.3,
      effect: '毒+呪い同時付与80%',
    ),
    ComboSkill(
      id: 'rapid_final_combo',
      name: '無限連撃',
      skillIds: ['active_rapid_strike', 'active_final_blow'],
      description: '連続攻撃からの必殺',
      powerMultiplier: 2.5,
      effect: '10連撃（各30%威力）',
    ),
  ];

  /// 最近使用したスキル履歴（最大5件）
  static final List<String> _recentSkills = [];

  /// スキルを履歴に追加
  static void recordSkillUse(String skillId) {
    _recentSkills.add(skillId);
    if (_recentSkills.length > 5) {
      _recentSkills.removeAt(0);
    }
  }

  /// 連携技が発動可能かチェック
  static ComboSkill? checkCombo() {
    if (_recentSkills.length < 2) return null;

    for (final combo in _combos) {
      if (_isComboTriggered(combo)) {
        return combo;
      }
    }
    return null;
  }

  /// 連携技が成立しているか判定
  static bool _isComboTriggered(ComboSkill combo) {
    final requiredSkills = combo.skillIds.toSet();
    final recentSet = _recentSkills.toSet();

    // 必要なスキルがすべて履歴に含まれているか
    if (!requiredSkills.every((skill) => recentSet.contains(skill))) {
      return false;
    }

    // 連続性チェック（最新N件内に全て含まれているか）
    final windowSize = combo.skillIds.length + 1;
    final window = _recentSkills.length >= windowSize
        ? _recentSkills.sublist(_recentSkills.length - windowSize)
        : _recentSkills;

    return requiredSkills.every((skill) => window.contains(skill));
  }

  /// 連携技を発動（履歴をクリア）
  static void activateCombo() {
    _recentSkills.clear();
  }

  /// 履歴をリセット（バトル終了時）
  static void reset() {
    _recentSkills.clear();
  }

  /// 全連携技リストを取得
  static List<ComboSkill> getAllCombos() => List.unmodifiable(_combos);

  /// 特定スキルが含まれる連携技を取得
  static List<ComboSkill> getCombosForSkill(String skillId) {
    return _combos.where((c) => c.skillIds.contains(skillId)).toList();
  }
}

/// 連携技モデル
class ComboSkill {
  final String id;
  final String name;
  final List<String> skillIds; // 必要なスキルID
  final String description;
  final double powerMultiplier; // 威力倍率
  final String effect; // 追加効果説明

  ComboSkill({
    required this.id,
    required this.name,
    required this.skillIds,
    required this.description,
    required this.powerMultiplier,
    required this.effect,
  });
}
