/// スキルモデル - ペットが習得する技・特性
class Skill {
  final String id;
  final String name;
  final String description;
  final SkillType type; // passive/active
  final SkillCategory category; // attack/defense/support/special

  // 効果パラメータ
  final int power; // 攻撃力倍率 (100 = 1.0倍)
  final int accuracy; // 命中率 (100 = 100%)
  final int cooldown; // クールダウン（ターン数）
  final int manaCost; // 消費スタミナ

  // 付加効果
  final Map<String, dynamic>
      effects; // {statBoost: {attack: 10}, statusEffect: 'burn'}

  // 習得条件
  final int requiredLevel;
  final String? requiredItem; // スキルブックなど

  // 追加属性
  final String? element; // fire/water/grass/electric/ice/dark/light
  final String? targetType; // single/all/self

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    this.power = 100,
    this.accuracy = 100,
    this.cooldown = 0,
    this.manaCost = 0,
    this.effects = const {},
    this.requiredLevel = 1,
    this.requiredItem,
    this.element,
    this.targetType = 'single',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'category': category.name,
        'power': power,
        'accuracy': accuracy,
        'cooldown': cooldown,
        'manaCost': manaCost,
        'effects': effects,
        'requiredLevel': requiredLevel,
        'requiredItem': requiredItem,
        'element': element,
        'targetType': targetType,
      };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: SkillType.values.firstWhere((e) => e.name == json['type']),
        category:
            SkillCategory.values.firstWhere((e) => e.name == json['category']),
        power: json['power'] as int? ?? 100,
        accuracy: json['accuracy'] as int? ?? 100,
        cooldown: json['cooldown'] as int? ?? 0,
        manaCost: json['manaCost'] as int? ?? 0,
        effects: (json['effects'] as Map<String, dynamic>?) ?? {},
        requiredLevel: json['requiredLevel'] as int? ?? 1,
        requiredItem: json['requiredItem'] as String?,
        element: json['element'] as String?,
        targetType: json['targetType'] as String? ?? 'single',
      );

  // 定義済みスキル一覧
  static final List<Skill> predefinedSkills = [
    // === パッシブスキル (10種) ===
    Skill(
      id: 'passive_regen',
      name: '自然回復',
      description: '毎ターンHPが5%回復する',
      type: SkillType.passive,
      category: SkillCategory.support,
      effects: {'hpRegen': 5},
      requiredLevel: 10,
    ),
    Skill(
      id: 'passive_tough',
      name: '頑丈',
      description: '防御力が20%アップ',
      type: SkillType.passive,
      category: SkillCategory.defense,
      effects: {'defenseMod': 20},
      requiredLevel: 15,
    ),
    Skill(
      id: 'passive_speed',
      name: '迅速',
      description: '素早さが30%アップ',
      type: SkillType.passive,
      category: SkillCategory.support,
      effects: {'speedMod': 30},
      requiredLevel: 12,
    ),
    Skill(
      id: 'passive_crit',
      name: '会心',
      description: 'クリティカル率が15%アップ',
      type: SkillType.passive,
      category: SkillCategory.attack,
      effects: {'critRate': 15},
      requiredLevel: 18,
    ),
    Skill(
      id: 'passive_luck',
      name: '幸運',
      description: 'アイテムドロップ率が20%アップ',
      type: SkillType.passive,
      category: SkillCategory.special,
      effects: {'dropRate': 20},
      requiredLevel: 20,
    ),
    Skill(
      id: 'passive_counter',
      name: 'カウンター',
      description: '被ダメージの30%を反射',
      type: SkillType.passive,
      category: SkillCategory.defense,
      effects: {'counterRate': 30},
      requiredLevel: 25,
    ),
    Skill(
      id: 'passive_life_drain',
      name: '生命吸収',
      description: '与ダメージの20%をHP吸収',
      type: SkillType.passive,
      category: SkillCategory.attack,
      effects: {'lifeDrain': 20},
      requiredLevel: 22,
    ),
    Skill(
      id: 'passive_focus',
      name: '集中力',
      description: '攻撃の命中率+15%',
      type: SkillType.passive,
      category: SkillCategory.attack,
      effects: {'accuracyMod': 15},
      requiredLevel: 14,
    ),
    Skill(
      id: 'passive_barrier',
      name: 'バリア',
      description: '受けるダメージを10%軽減',
      type: SkillType.passive,
      category: SkillCategory.defense,
      effects: {'damageReduction': 10},
      requiredLevel: 20,
    ),
    Skill(
      id: 'passive_berserk',
      name: 'バーサーク',
      description: 'HP50%以下で攻撃力1.5倍',
      type: SkillType.passive,
      category: SkillCategory.attack,
      effects: {'berserkMod': 50},
      requiredLevel: 30,
    ),

    // === 通常攻撃スキル (8種) ===
    Skill(
      id: 'active_powerslash',
      name: 'パワースラッシュ',
      description: '強力な一撃（攻撃力1.5倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 150,
      accuracy: 90,
      cooldown: 2,
      manaCost: 15,
      requiredLevel: 8,
    ),
    Skill(
      id: 'active_megablast',
      name: 'メガブラスト',
      description: '超威力の攻撃（攻撃力2.0倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 200,
      accuracy: 85,
      cooldown: 4,
      manaCost: 25,
      requiredLevel: 25,
      requiredItem: 'skill_book',
    ),
    Skill(
      id: 'active_combo',
      name: 'コンボアタック',
      description: '連続攻撃（3回×60%威力）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 60,
      accuracy: 95,
      cooldown: 3,
      manaCost: 20,
      effects: {'hits': 3},
      requiredLevel: 20,
    ),
    Skill(
      id: 'active_rapid_strike',
      name: '連続斬り',
      description: '高速5連撃（各40%威力）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 40,
      accuracy: 90,
      cooldown: 4,
      manaCost: 22,
      effects: {'hits': 5},
      requiredLevel: 28,
    ),
    Skill(
      id: 'active_final_blow',
      name: '渾身の一撃',
      description: '低命中だが超威力（2.5倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 250,
      accuracy: 70,
      cooldown: 5,
      manaCost: 30,
      requiredLevel: 35,
    ),
    Skill(
      id: 'active_critical_strike',
      name: 'クリティカルストライク',
      description: '必ずクリティカル（1.3倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 130,
      accuracy: 100,
      cooldown: 3,
      manaCost: 18,
      effects: {'guaranteedCrit': true},
      requiredLevel: 24,
    ),
    Skill(
      id: 'active_piercing_shot',
      name: '貫通攻撃',
      description: '防御無視（1.2倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 120,
      accuracy: 95,
      cooldown: 3,
      manaCost: 20,
      effects: {'ignoreDef': true},
      requiredLevel: 26,
    ),
    Skill(
      id: 'active_all_attack',
      name: '全体攻撃',
      description: '全敵に攻撃（各80%威力）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 80,
      accuracy: 90,
      cooldown: 5,
      manaCost: 35,
      targetType: 'all',
      requiredLevel: 32,
      requiredItem: 'skill_book',
    ),

    // === 属性攻撃スキル (7種) ===
    Skill(
      id: 'active_fire_blast',
      name: 'ファイアブラスト',
      description: '炎属性攻撃（1.4倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 140,
      accuracy: 90,
      cooldown: 3,
      manaCost: 20,
      element: 'fire',
      requiredLevel: 16,
    ),
    Skill(
      id: 'active_aqua_jet',
      name: 'アクアジェット',
      description: '水属性攻撃（1.4倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 140,
      accuracy: 95,
      cooldown: 3,
      manaCost: 20,
      element: 'water',
      requiredLevel: 16,
    ),
    Skill(
      id: 'active_thunder_bolt',
      name: 'サンダーボルト',
      description: '電気属性攻撃（1.5倍）麻痺20%',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 150,
      accuracy: 85,
      cooldown: 4,
      manaCost: 22,
      element: 'electric',
      effects: {'statusChance': 20, 'status': 'paralysis'},
      requiredLevel: 22,
    ),
    Skill(
      id: 'active_ice_beam',
      name: 'アイスビーム',
      description: '氷属性攻撃（1.3倍）凍結15%',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 130,
      accuracy: 95,
      cooldown: 3,
      manaCost: 18,
      element: 'ice',
      effects: {'statusChance': 15, 'status': 'freeze'},
      requiredLevel: 18,
    ),
    Skill(
      id: 'active_leaf_storm',
      name: 'リーフストーム',
      description: '草属性攻撃（1.4倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 140,
      accuracy: 90,
      cooldown: 3,
      manaCost: 20,
      element: 'grass',
      requiredLevel: 16,
    ),
    Skill(
      id: 'active_dark_pulse',
      name: 'ダークパルス',
      description: '闇属性攻撃（1.5倍）混乱20%',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 150,
      accuracy: 85,
      cooldown: 4,
      manaCost: 22,
      element: 'dark',
      effects: {'statusChance': 20, 'status': 'confusion'},
      requiredLevel: 24,
    ),
    Skill(
      id: 'active_holy_ray',
      name: 'ホーリーレイ',
      description: '光属性攻撃（1.5倍）',
      type: SkillType.active,
      category: SkillCategory.attack,
      power: 150,
      accuracy: 95,
      cooldown: 4,
      manaCost: 24,
      element: 'light',
      requiredLevel: 28,
    ),

    // === 補助・回復スキル (8種) ===
    Skill(
      id: 'active_heal',
      name: 'ヒール',
      description: 'HPを30%回復する',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 3,
      manaCost: 20,
      effects: {'heal': 30},
      targetType: 'self',
      requiredLevel: 10,
    ),
    Skill(
      id: 'active_full_heal',
      name: 'フルヒール',
      description: 'HPを完全回復',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 8,
      manaCost: 50,
      effects: {'heal': 100},
      targetType: 'self',
      requiredLevel: 40,
      requiredItem: 'skill_book',
    ),
    Skill(
      id: 'active_shield',
      name: 'シールド',
      description: '2ターン防御力2倍',
      type: SkillType.active,
      category: SkillCategory.defense,
      cooldown: 5,
      manaCost: 15,
      effects: {'defenseBuff': 100, 'duration': 2},
      targetType: 'self',
      requiredLevel: 15,
    ),
    Skill(
      id: 'active_atk_boost',
      name: 'パワーアップ',
      description: '3ターン攻撃力1.5倍',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 5,
      manaCost: 18,
      effects: {'attackBuff': 50, 'duration': 3},
      targetType: 'self',
      requiredLevel: 18,
    ),
    Skill(
      id: 'active_speed_boost',
      name: 'スピードアップ',
      description: '3ターン素早さ2倍',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 5,
      manaCost: 16,
      effects: {'speedBuff': 100, 'duration': 3},
      targetType: 'self',
      requiredLevel: 20,
    ),
    Skill(
      id: 'active_focus_up',
      name: '集中',
      description: '2ターン命中率+30%',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 4,
      manaCost: 12,
      effects: {'accuracyBuff': 30, 'duration': 2},
      targetType: 'self',
      requiredLevel: 14,
    ),
    Skill(
      id: 'active_meditation',
      name: '瞑想',
      description: 'HP20%回復＋状態異常解除',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 6,
      manaCost: 25,
      effects: {'heal': 20, 'cleanse': true},
      targetType: 'self',
      requiredLevel: 26,
    ),
    Skill(
      id: 'active_revive',
      name: 'リザレクション',
      description: '瀕死から復活（HP50%）',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 10,
      manaCost: 60,
      effects: {'revive': 50},
      targetType: 'self',
      requiredLevel: 45,
      requiredItem: 'skill_book',
    ),

    // === 状態異常・妨害スキル (7種) ===
    Skill(
      id: 'active_poison',
      name: 'ポイズン',
      description: '敵を毒状態にする',
      type: SkillType.active,
      category: SkillCategory.special,
      accuracy: 80,
      cooldown: 3,
      manaCost: 10,
      effects: {'statusEffect': 'poison', 'duration': 3},
      requiredLevel: 12,
    ),
    Skill(
      id: 'active_burn',
      name: 'バーン',
      description: '敵を火傷状態にする',
      type: SkillType.active,
      category: SkillCategory.special,
      accuracy: 75,
      cooldown: 3,
      manaCost: 12,
      effects: {'statusEffect': 'burn', 'duration': 3},
      requiredLevel: 15,
    ),
    Skill(
      id: 'active_paralyze',
      name: 'マヒさせる',
      description: '敵を麻痺状態にする',
      type: SkillType.active,
      category: SkillCategory.special,
      accuracy: 80,
      cooldown: 4,
      manaCost: 15,
      effects: {'statusEffect': 'paralysis', 'duration': 2},
      requiredLevel: 16,
    ),
    Skill(
      id: 'active_sleep',
      name: 'ねむらせる',
      description: '敵を眠らせる（2ターン）',
      type: SkillType.active,
      category: SkillCategory.special,
      accuracy: 70,
      cooldown: 5,
      manaCost: 18,
      effects: {'statusEffect': 'sleep', 'duration': 2},
      requiredLevel: 20,
    ),
    Skill(
      id: 'active_confuse',
      name: '混乱させる',
      description: '敵を混乱状態にする',
      type: SkillType.active,
      category: SkillCategory.special,
      accuracy: 75,
      cooldown: 4,
      manaCost: 14,
      effects: {'statusEffect': 'confusion', 'duration': 2},
      requiredLevel: 18,
    ),
    Skill(
      id: 'active_curse',
      name: '呪いをかける',
      description: '敵を呪い状態にする',
      type: SkillType.active,
      category: SkillCategory.special,
      accuracy: 80,
      cooldown: 5,
      manaCost: 20,
      effects: {'statusEffect': 'curse', 'duration': 4},
      requiredLevel: 24,
    ),
    Skill(
      id: 'active_debuff',
      name: 'デバフ',
      description: '敵の攻撃・防御30%ダウン',
      type: SkillType.active,
      category: SkillCategory.special,
      accuracy: 90,
      cooldown: 5,
      manaCost: 20,
      effects: {'attackDebuff': -30, 'defenseDebuff': -30, 'duration': 3},
      requiredLevel: 22,
    ),
  ];

  static Skill? getSkillById(String id) {
    try {
      return predefinedSkills.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Skill> getSkillsByType(SkillType type) {
    return predefinedSkills.where((s) => s.type == type).toList();
  }

  static List<Skill> getLearnableSkills(int level) {
    return predefinedSkills
        .where((s) => s.requiredLevel <= level && s.requiredItem == null)
        .toList();
  }
}

enum SkillType {
  passive, // 常時発動
  active, // 手動発動
}

enum SkillCategory {
  attack, // 攻撃系
  defense, // 防御系
  support, // 補助系
  special, // 特殊系
}
