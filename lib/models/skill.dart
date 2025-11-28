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
      );

  // 定義済みスキル一覧
  static final List<Skill> predefinedSkills = [
    // パッシブスキル
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

    // アクティブスキル
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
      id: 'active_heal',
      name: 'ヒール',
      description: 'HPを30%回復する',
      type: SkillType.active,
      category: SkillCategory.support,
      cooldown: 3,
      manaCost: 20,
      effects: {'heal': 30},
      requiredLevel: 10,
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
      requiredLevel: 15,
    ),
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
