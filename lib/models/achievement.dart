/// 実績モデル（Hive永続化対応）
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji or asset path
  final DateTime? unlockedAt;
  final int progress; // 0-100
  final int target; // 達成条件値

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.progress = 0,
    this.target = 1,
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
      );

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    DateTime? unlockedAt,
    int? progress,
    int? target,
  }) =>
      Achievement(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        progress: progress ?? this.progress,
        target: target ?? this.target,
      );
}
