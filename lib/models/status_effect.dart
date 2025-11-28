/// 状態異常モデル
class StatusEffect {
  final String id;
  final String name;
  final String description;
  final StatusEffectType type;
  final int duration; // ターン数
  final Map<String, dynamic> params; // 効果パラメータ

  StatusEffect({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.duration,
    this.params = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'duration': duration,
        'params': params,
      };

  factory StatusEffect.fromJson(Map<String, dynamic> json) => StatusEffect(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: StatusEffectType.values.firstWhere((e) => e.name == json['type']),
        duration: json['duration'] as int,
        params: json['params'] as Map<String, dynamic>? ?? {},
      );

  // 定義済み状態異常
  static final Map<String, StatusEffect> predefined = {
    'poison': StatusEffect(
      id: 'poison',
      name: '毒',
      description: '毎ターン最大HPの10%ダメージ',
      type: StatusEffectType.negative,
      duration: 3,
      params: {'damagePercent': 10},
    ),
    'burn': StatusEffect(
      id: 'burn',
      name: '火傷',
      description: '毎ターン最大HPの8%ダメージ、攻撃力-20%',
      type: StatusEffectType.negative,
      duration: 4,
      params: {'damagePercent': 8, 'attackDown': 20},
    ),
    'sleep': StatusEffect(
      id: 'sleep',
      name: '眠り',
      description: '行動不能（攻撃を受けると解除）',
      type: StatusEffectType.negative,
      duration: 2,
      params: {'cannotAct': true, 'wakeOnDamage': true},
    ),
    'paralysis': StatusEffect(
      id: 'paralysis',
      name: '麻痺',
      description: '25%の確率で行動不能、速度-50%',
      type: StatusEffectType.negative,
      duration: 3,
      params: {'skipChance': 25, 'speedDown': 50},
    ),
    'freeze': StatusEffect(
      id: 'freeze',
      name: '凍結',
      description: '行動不能、防御力-30%',
      type: StatusEffectType.negative,
      duration: 2,
      params: {'cannotAct': true, 'defenseDown': 30},
    ),
    'confusion': StatusEffect(
      id: 'confusion',
      name: '混乱',
      description: '33%の確率で自分を攻撃',
      type: StatusEffectType.negative,
      duration: 3,
      params: {'selfAttackChance': 33},
    ),
    'curse': StatusEffect(
      id: 'curse',
      name: '呪い',
      description: '回復無効、攻撃・防御-15%',
      type: StatusEffectType.negative,
      duration: 5,
      params: {'noHeal': true, 'attackDown': 15, 'defenseDown': 15},
    ),
    'attackUp': StatusEffect(
      id: 'attackUp',
      name: '攻撃UP',
      description: '攻撃力+50%',
      type: StatusEffectType.positive,
      duration: 3,
      params: {'attackUp': 50},
    ),
    'defenseUp': StatusEffect(
      id: 'defenseUp',
      name: '防御UP',
      description: '防御力+50%',
      type: StatusEffectType.positive,
      duration: 3,
      params: {'defenseUp': 50},
    ),
    'speedUp': StatusEffect(
      id: 'speedUp',
      name: '素早さUP',
      description: '速度+50%',
      type: StatusEffectType.positive,
      duration: 3,
      params: {'speedUp': 50},
    ),
    'regeneration': StatusEffect(
      id: 'regeneration',
      name: '再生',
      description: '毎ターン最大HPの15%回復',
      type: StatusEffectType.positive,
      duration: 3,
      params: {'healPercent': 15},
    ),
    'shield': StatusEffect(
      id: 'shield',
      name: 'シールド',
      description: '受けるダメージを50%軽減',
      type: StatusEffectType.positive,
      duration: 2,
      params: {'damageReduction': 50},
    ),
    'invincible': StatusEffect(
      id: 'invincible',
      name: '無敵',
      description: 'すべてのダメージを無効化',
      type: StatusEffectType.positive,
      duration: 1,
      params: {'noDamage': true},
    ),
    'berserk': StatusEffect(
      id: 'berserk',
      name: '狂戦士',
      description: '攻撃力+100%、防御力-50%',
      type: StatusEffectType.special,
      duration: 3,
      params: {'attackUp': 100, 'defenseDown': 50},
    ),
  };

  static StatusEffect? getById(String id) => predefined[id];
}

enum StatusEffectType {
  negative, // デバフ
  positive, // バフ
  special, // 特殊（メリット・デメリット両方）
}

/// 状態異常の適用状態
class ActiveStatusEffect {
  final StatusEffect effect;
  int remainingTurns;
  final DateTime appliedAt;

  ActiveStatusEffect({
    required this.effect,
    required this.remainingTurns,
    required this.appliedAt,
  });

  bool isExpired() => remainingTurns <= 0;

  void decrementTurn() {
    if (remainingTurns > 0) remainingTurns--;
  }

  Map<String, dynamic> toJson() => {
        'effectId': effect.id,
        'remainingTurns': remainingTurns,
        'appliedAt': appliedAt.toIso8601String(),
      };

  factory ActiveStatusEffect.fromJson(Map<String, dynamic> json) {
    final effectId = json['effectId'] as String;
    final effect = StatusEffect.getById(effectId);

    if (effect == null) {
      throw Exception('Unknown status effect: $effectId');
    }

    return ActiveStatusEffect(
      effect: effect,
      remainingTurns: json['remainingTurns'] as int,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
    );
  }
}
