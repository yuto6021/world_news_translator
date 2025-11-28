class GameItem {
  final String id;
  final String name;
  final String description;
  final String category; // consumable, equipment, rare
  final String imagePath;
  final int price;
  final String effect;
  final Map<String, dynamic>? stats; // 装備品のステータス

  const GameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imagePath,
    required this.price,
    required this.effect,
    this.stats,
  });
}

class GameItems {
  // 消費アイテム
  static const List<GameItem> consumables = [
    GameItem(
      id: 'food_premium',
      name: 'プレミアムフード',
      description: 'お腹+50、機嫌+10',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_food_premium.png',
      price: 100,
      effect: 'feed_premium',
    ),
    GameItem(
      id: 'candy',
      name: 'キャンディ',
      description: '機嫌+30',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_candy.png',
      price: 50,
      effect: 'mood_boost',
    ),
    GameItem(
      id: 'medicine',
      name: '薬',
      description: '病気を治療',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_medicine.png',
      price: 150,
      effect: 'cure_disease',
    ),
    GameItem(
      id: 'energy_drink',
      name: 'エナジードリンク',
      description: '体力全回復',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_energy.png',
      price: 120,
      effect: 'stamina_full',
    ),
    GameItem(
      id: 'revive',
      name: '復活の薬',
      description: '瀕死から復活（HP50%回復）',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_revive.png',
      price: 500,
      effect: 'revive',
    ),
    GameItem(
      id: 'toy',
      name: 'おもちゃ',
      description: '遊び時の経験値2倍',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_toy.png',
      price: 80,
      effect: 'exp_boost_play',
    ),
    GameItem(
      id: 'bath_set',
      name: 'お風呂セット',
      description: '汚れ-100、機嫌+20',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_bath.png',
      price: 100,
      effect: 'super_clean',
    ),
    GameItem(
      id: 'breed_item',
      name: '配合の証',
      description: '配合に必要なアイテム',
      category: 'consumable',
      imagePath: 'assets/items/consumables/item_breed.png',
      price: 1000,
      effect: 'breeding',
    ),
  ];

  // 装備品
  static const List<GameItem> equipment = [
    GameItem(
      id: 'power_ring',
      name: 'パワーリング',
      description: '攻撃力+10',
      category: 'equipment',
      imagePath: 'assets/items/equipment/item_power_ring.png',
      price: 300,
      effect: 'equip_attack',
      stats: {'attack': 10},
    ),
    GameItem(
      id: 'shield_amulet',
      name: 'シールドアミュレット',
      description: '防御力+10',
      category: 'equipment',
      imagePath: 'assets/items/equipment/item_shield_amulet.png',
      price: 300,
      effect: 'equip_defense',
      stats: {'defense': 10},
    ),
    GameItem(
      id: 'speed_boots',
      name: 'スピードブーツ',
      description: '速さ+10',
      category: 'equipment',
      imagePath: 'assets/items/equipment/item_speed_boots.png',
      price: 300,
      effect: 'equip_speed',
      stats: {'speed': 10},
    ),
    GameItem(
      id: 'hp_necklace',
      name: 'HPネックレス',
      description: '最大HP+50',
      category: 'equipment',
      imagePath: 'assets/items/equipment/item_hp_necklace.png',
      price: 400,
      effect: 'equip_hp',
      stats: {'hp': 50},
    ),
    GameItem(
      id: 'critical_gloves',
      name: 'クリティカルグローブ',
      description: '会心率+20%',
      category: 'equipment',
      imagePath: 'assets/items/equipment/item_critical_gloves.png',
      price: 500,
      effect: 'equip_critical',
      stats: {'critical': 20},
    ),
    GameItem(
      id: 'exp_crown',
      name: 'EXPクラウン',
      description: '獲得経験値+50%',
      category: 'equipment',
      imagePath: 'assets/items/equipment/item_exp_crown.png',
      price: 800,
      effect: 'equip_exp_boost',
      stats: {'exp_boost': 50},
    ),
  ];

  // レアアイテム
  static const List<GameItem> rare = [
    GameItem(
      id: 'evolution_stone',
      name: '進化の石',
      description: '強制的に進化可能',
      category: 'rare',
      imagePath: 'assets/items/rare/item_evolution_stone.png',
      price: 2000,
      effect: 'force_evolve',
    ),
    GameItem(
      id: 'exp_potion_s',
      name: '経験の薬（小）',
      description: '経験値+100',
      category: 'rare',
      imagePath: 'assets/items/rare/item_exp_potion_s.png',
      price: 200,
      effect: 'exp_100',
    ),
    GameItem(
      id: 'exp_potion_m',
      name: '経験の薬（中）',
      description: '経験値+500',
      category: 'rare',
      imagePath: 'assets/items/rare/item_exp_potion_m.png',
      price: 800,
      effect: 'exp_500',
    ),
    GameItem(
      id: 'exp_potion_l',
      name: '経験の薬（大）',
      description: '経験値+2000',
      category: 'rare',
      imagePath: 'assets/items/rare/item_exp_potion_l.png',
      price: 3000,
      effect: 'exp_2000',
    ),
    GameItem(
      id: 'skill_book',
      name: 'スキルブック',
      description: 'ランダムスキル習得',
      category: 'rare',
      imagePath: 'assets/items/rare/item_skill_book.png',
      price: 1500,
      effect: 'learn_skill',
    ),
    GameItem(
      id: 'friendship_badge',
      name: '親友バッジ',
      description: '親密度+20',
      category: 'rare',
      imagePath: 'assets/items/rare/item_friendship_badge.png',
      price: 500,
      effect: 'intimacy_20',
    ),
    GameItem(
      id: 'gacha_ticket',
      name: 'ガチャチケット',
      description: 'プレミアムガチャ1回',
      category: 'rare',
      imagePath: 'assets/items/rare/item_gacha_ticket.png',
      price: 1000,
      effect: 'gacha_premium',
    ),
    GameItem(
      id: 'lucky_charm',
      name: '幸運のお守り',
      description: 'アイテムドロップ率2倍（1時間）',
      category: 'rare',
      imagePath: 'assets/items/rare/item_lucky_charm.png',
      price: 600,
      effect: 'drop_rate_boost',
    ),
    GameItem(
      id: 'battle_pass',
      name: 'バトルパス',
      description: 'シークレットボス出現率UP',
      category: 'rare',
      imagePath: 'assets/items/rare/item_battle_pass.png',
      price: 5000,
      effect: 'secret_boss_boost',
    ),
    GameItem(
      id: 'rainbow_feather',
      name: '虹の羽',
      description: '全ステータス+5',
      category: 'rare',
      imagePath: 'assets/items/rare/item_rainbow_feather.png',
      price: 10000,
      effect: 'all_stats_boost',
    ),
    GameItem(
      id: 'dark_fragment',
      name: '闇の欠片',
      description: '闇進化に必要',
      category: 'rare',
      imagePath: 'assets/items/rare/item_dark_fragment.png',
      price: 3000,
      effect: 'dark_evolution',
    ),
    GameItem(
      id: 'timecapsule',
      name: 'タイムカプセル',
      description: 'ペットの状態を保存',
      category: 'rare',
      imagePath: 'assets/items/rare/item_timecapsule.png',
      price: 2000,
      effect: 'save_state',
    ),
  ];

  static List<GameItem> getAllItems() {
    return [...consumables, ...equipment, ...rare];
  }

  static GameItem? getItemById(String id) {
    try {
      return getAllItems().firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<GameItem> getItemsByCategory(String category) {
    return getAllItems().where((item) => item.category == category).toList();
  }
}
