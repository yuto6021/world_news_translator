/// 実績レア度
enum AchievementRarity {
  common, // コモン（灰色）
  rare, // レア（青）
  epic, // エピック（紫）
  legendary, // レジェンダリー（金）
}

/// 実績モデル（Hive永続化対応）
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji or asset path
  final DateTime? unlockedAt;
  final int progress; // 0-100
  final int target; // 達成条件値
  final AchievementRarity rarity; // レア度
  final bool isSecret; // シークレット実績（解除前は条件非公開）

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.progress = 0,
    this.target = 1,
    this.rarity = AchievementRarity.common,
    this.isSecret = false,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'progress': progress,
        'target': target,
        'rarity': rarity.index,
        'isSecret': isSecret,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'] as String)
            : null,
        progress: json['progress'] as int? ?? 0,
        target: json['target'] as int? ?? 1,
        rarity: AchievementRarity.values[json['rarity'] as int? ?? 0],
        isSecret: json['isSecret'] as bool? ?? false,
      );

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    DateTime? unlockedAt,
    int? progress,
    int? target,
    AchievementRarity? rarity,
    bool? isSecret,
  }) =>
      Achievement(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        progress: progress ?? this.progress,
        target: target ?? this.target,
        rarity: rarity ?? this.rarity,
        isSecret: isSecret ?? this.isSecret,
      );
}
