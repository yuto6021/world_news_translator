/// クエストモデル
class Quest {
  final String id;
  final String name;
  final String description;
  final QuestType type; // daily/weekly/achievement
  final QuestCategory category; // battle/care/collection/special

  // 目標
  final int targetValue; // 目標値
  final String targetType; // win/feed/evolve/collect など

  // 報酬
  final int coinReward;
  final Map<String, int> itemRewards; // {item_id: quantity}
  final int expReward;

  // 条件
  final int requiredLevel;
  final DateTime? expiresAt; // 期限（日次クエストなど）

  Quest({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.targetValue,
    required this.targetType,
    this.coinReward = 0,
    this.itemRewards = const {},
    this.expReward = 0,
    this.requiredLevel = 1,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'category': category.name,
        'targetValue': targetValue,
        'targetType': targetType,
        'coinReward': coinReward,
        'itemRewards': itemRewards,
        'expReward': expReward,
        'requiredLevel': requiredLevel,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: QuestType.values.firstWhere((e) => e.name == json['type']),
        category:
            QuestCategory.values.firstWhere((e) => e.name == json['category']),
        targetValue: json['targetValue'] as int,
        targetType: json['targetType'] as String,
        coinReward: json['coinReward'] as int? ?? 0,
        itemRewards: Map<String, int>.from(json['itemRewards'] ?? {}),
        expReward: json['expReward'] as int? ?? 0,
        requiredLevel: json['requiredLevel'] as int? ?? 1,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );

  // 定義済みクエスト
  static final List<Quest> predefinedQuests = [
    // デイリークエスト
    Quest(
      id: 'daily_feed_3',
      name: '食事3回',
      description: 'ペットに3回食事を与える',
      type: QuestType.daily,
      category: QuestCategory.care,
      targetValue: 3,
      targetType: 'feed',
      coinReward: 100,
      expReward: 50,
    ),
    Quest(
      id: 'daily_play_5',
      name: '遊び5回',
      description: 'ペットと5回遊ぶ',
      type: QuestType.daily,
      category: QuestCategory.care,
      targetValue: 5,
      targetType: 'play',
      coinReward: 150,
      expReward: 80,
    ),
    Quest(
      id: 'daily_clean_2',
      name: '掃除2回',
      description: 'ペットを2回掃除する',
      type: QuestType.daily,
      category: QuestCategory.care,
      targetValue: 2,
      targetType: 'clean',
      coinReward: 100,
      expReward: 50,
    ),
    Quest(
      id: 'daily_battle_3',
      name: 'バトル3回',
      description: 'バトルを3回行う',
      type: QuestType.daily,
      category: QuestCategory.battle,
      targetValue: 3,
      targetType: 'battle',
      coinReward: 200,
      itemRewards: {'energy_drink': 1},
      expReward: 100,
    ),
    Quest(
      id: 'daily_win_2',
      name: '勝利2回',
      description: 'バトルで2回勝利する',
      type: QuestType.daily,
      category: QuestCategory.battle,
      targetValue: 2,
      targetType: 'win',
      coinReward: 300,
      expReward: 150,
    ),

    // ウィークリークエスト
    Quest(
      id: 'weekly_win_10',
      name: '週間勝利10回',
      description: '1週間でバトルに10回勝利する',
      type: QuestType.weekly,
      category: QuestCategory.battle,
      targetValue: 10,
      targetType: 'win',
      coinReward: 1000,
      itemRewards: {'exp_potion_m': 1, 'lucky_charm': 1},
      expReward: 500,
      requiredLevel: 5,
    ),
    Quest(
      id: 'weekly_evolve_1',
      name: '週間進化1回',
      description: 'ペットを1回進化させる',
      type: QuestType.weekly,
      category: QuestCategory.collection,
      targetValue: 1,
      targetType: 'evolve',
      coinReward: 2000,
      itemRewards: {'evolution_stone': 1},
      expReward: 1000,
      requiredLevel: 10,
    ),

    // アチーブメント
    Quest(
      id: 'achieve_win_100',
      name: '勝利の覇者',
      description: '通算100回勝利する',
      type: QuestType.achievement,
      category: QuestCategory.battle,
      targetValue: 100,
      targetType: 'win_total',
      coinReward: 5000,
      itemRewards: {'rainbow_feather': 1, 'battle_pass': 1},
      expReward: 2000,
    ),
    Quest(
      id: 'achieve_boss_10',
      name: 'ボスハンター',
      description: 'ボスを10体倒す',
      type: QuestType.achievement,
      category: QuestCategory.battle,
      targetValue: 10,
      targetType: 'boss_defeat',
      coinReward: 3000,
      itemRewards: {'dark_fragment': 3},
      expReward: 1500,
      requiredLevel: 15,
    ),
    Quest(
      id: 'achieve_ultimate',
      name: '究極への道',
      description: 'ペットを究極体まで進化させる',
      type: QuestType.achievement,
      category: QuestCategory.collection,
      targetValue: 1,
      targetType: 'ultimate_evolve',
      coinReward: 10000,
      itemRewards: {'rainbow_feather': 3, 'gacha_ticket': 5},
      expReward: 5000,
      requiredLevel: 30,
    ),
    Quest(
      id: 'achieve_secret_boss',
      name: '伝説の挑戦者',
      description: 'シークレットボスを倒す',
      type: QuestType.achievement,
      category: QuestCategory.battle,
      targetValue: 1,
      targetType: 'secret_boss_defeat',
      coinReward: 50000,
      itemRewards: {'rainbow_feather': 10, 'dark_fragment': 10},
      expReward: 10000,
      requiredLevel: 50,
    ),
  ];

  static Quest? getQuestById(String id) {
    try {
      return predefinedQuests.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Quest> getQuestsByType(QuestType type) {
    return predefinedQuests.where((q) => q.type == type).toList();
  }

  static List<Quest> getActiveQuests(int playerLevel) {
    return predefinedQuests
        .where((q) => q.requiredLevel <= playerLevel)
        .toList();
  }
}

enum QuestType {
  daily, // 毎日リセット
  weekly, // 毎週リセット
  achievement, // 永続（1回のみ）
}

enum QuestCategory {
  battle, // バトル系
  care, // ケア系
  collection, // 収集系
  special, // 特殊系
}

/// クエスト進捗
class QuestProgress {
  final String questId;
  int currentValue;
  bool completed;
  bool rewardClaimed;
  DateTime? completedAt;

  QuestProgress({
    required this.questId,
    this.currentValue = 0,
    this.completed = false,
    this.rewardClaimed = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'questId': questId,
        'currentValue': currentValue,
        'completed': completed,
        'rewardClaimed': rewardClaimed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory QuestProgress.fromJson(Map<String, dynamic> json) => QuestProgress(
        questId: json['questId'] as String,
        currentValue: json['currentValue'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
        rewardClaimed: json['rewardClaimed'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
