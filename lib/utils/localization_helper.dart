/// 日本語化ユーティリティ
class LocalizationHelper {
  /// ペット種族の日本語名マップ
  static const Map<String, String> petSpeciesNames = {
    // Baby
    'koromon': 'コロモン',
    'tsunomon': 'ツノモン',
    'tokomon': 'トコモン',
    'genki': 'ゲンキ',

    // Child
    'agumon': 'アグモン',
    'gabumon': 'ガブモン',
    'patamon': 'パタモン',
    'tentomon': 'テントモン',
    'veemon': 'ブイモン',
    'hagurumon': 'ハグルモン',
    'warrior': 'ウォーリアー',
    'beast': 'ビースト',
    'angel': 'エンジェル',
    'demon': 'デーモン',

    // Adult
    'greymon': 'グレイモン',
    'metalgreymon': 'メタルグレイモン',
    'garurumon': 'ガルルモン',
    'weregarurumon': 'ワーガルルモン',
    'angemon': 'エンジェモン',
    'gatomon': 'ゲートモン',
    'devimon': 'デビモン',
    'myotismon': 'ヴァンデモン',
    'leomon': 'レオモン',
    'ignisaur': 'イグニソール',
    'seadramon': 'シードラモン',
    'kabuterimon': 'カブテリモン',
    'kuwagamon': 'クワガーモン',
    'exveemon': 'エクスブイモン',
    'guardromon': 'ガードロモン',

    // Ultimate
    'wargreymon': 'ウォーグレイモン',
    'metalgarurumon': 'メタルガルルモン',
    'seraphimon': 'セラフィモン',
    'angewomon': 'エンジェウーモン',
    'daemon': 'デーモン',
    'venommyotismon': 'ベノムヴァンデモン',
    'saberleomon': 'サーベルレオモン',
    'volcanisaur': 'ボルカニソール',
    'megaseadramon': 'メガシードラモン',
    'atlurkabuterimon': 'アトラーカブテリモン',
    'paildramon': 'パイルドラモン',
    'andromon': 'アンドロモン',
    'omegamon': 'オメガモン',
    'alphamon': 'アルファモン',
    'susanoomon': 'スサノオモン',
    'gallantmon': 'ガレントモン',
    'apocalymon': 'アポカリモン',
  };

  /// ステージの日本語名マップ
  static const Map<String, String> stageNames = {
    'egg': 'タマゴ',
    'baby': '幼年期',
    'child': '成長期',
    'adult': '成熟期',
    'ultimate': '完全体',
  };

  /// 素材の日本語名マップ
  static const Map<String, String> materialNames = {
    // 鉱石系
    'ore_fire_crystal': '炎の結晶',
    'ore_water_pearl': '水の真珠',
    'ore_nature_leafstone': '自然の葉石',
    'ore_rock_fragment': '岩石の欠片',
    'ore_light_shard': '光の欠片',
    'ore_dark_shard': '闇の欠片',

    // 獣系
    'beast_fang': '獣の牙',
    'beast_claw': '鋭い爪',
    'beast_hide': '獣の毛皮',

    // ドラゴン系
    'dragon_scale': 'ドラゴンの鱗',
    'dragon_bone': 'ドラゴンの骨',
    'dragon_flame_sac': '炎袋',

    // 魔法系
    'magic_core_small': '小型魔力核',
    'magic_core_medium': '中型魔力核',
    'magic_core_large': '大型魔力核',
    'enchanted_thread': '魔法糸',

    // 共通素材
    'wood_plank': '木板',
    'iron_ingot': '鉄インゴット',
    'leather_strip': '革ひも',
    'rune_stone': 'ルーン石',

    // エネミー専用ドロップアイテム（クラフト素材として使用）
    'slime_jelly': 'スライムゼリー',
    'goblin_sword': 'ゴブリンの剣',
    'wolf_fang': '狼の牙',
    'zombie_bone': 'ゾンビの骨',
    'fairy_dust': '妖精の粉',
    'elemental_crystal': 'エレメンタルの結晶',
    'golem_core': 'ゴーレムの核',

    // ボス素材
    'titan_hammer': 'タイタンのハンマー',
    'dark_sword': 'ダークソード',
    'titancore': 'タイタンコア',
    'darkcore': 'ダークコア',

    // 裏ボス素材
    'ultimate_crystal': '究極の水晶',
    'truehart': '真実の心臓',
    'kingcore': '精霊王のコア',

    // 属性騎士素材
    'firecore': '炎のコア',
    'watercore': '水のコア',
    'woodcore': '木のコア',
    'thundercore': '雷のコア',
    'lightcore': '光のコア',

    // 特殊敵素材
    'sinigamicore': '死神のコア',
    'golden_horn': '黄金の角',
  };

  /// 装備の日本語名マップ
  static const Map<String, String> equipmentNames = {
    // 剣系
    'item_sword_bronze': 'ブロンズソード',
    'item_sword_iron': 'アイアンソード',
    'item_sword_dragon': 'ドラゴンソード',

    // 盾系
    'item_shield_wood': '木の盾',
    'item_shield_iron': '鉄の盾',
    'item_shield_dragon': 'ドラゴンシールド',

    // 鎧系
    'item_armor_leather': 'レザーメイル',
    'item_armor_chain': 'チェインメイル',
    'item_armor_paladin': 'パラディンアーマー',

    // 杖系
    'item_staff_oak': 'オークスタッフ',
    'item_staff_mage': 'メイジスタッフ',
    'item_staff_seraph': 'セラフロッド',

    // アクセサリ系
    'item_ring_crit': 'クリティカルリング',
    'item_amulet_guard': 'ガードアミュレット',
    'item_boots_swift': 'スウィフトブーツ',

    // ショップ専用
    'shop_ring_power': 'パワーリング',
    'shop_amulet_shield': 'シールドアミュレット',
    'shop_boots_speed': 'スピードブーツ',
    'shop_necklace_hp': 'HPネックレス',
    'shop_crown_exp': 'クラウン',
    'shop_gloves_crit': 'グローブ',

    // エネミードロップ素材装備
    'item_sword_slime': 'スライムソード',
    'item_sword_goblin': 'ゴブリンソード',
    'item_armor_wolf': 'ウルフアーマー',
    'item_staff_zombie': 'ゾンビスタッフ',
    'item_ring_fairy': 'フェアリーリング',
    'item_amulet_elemental': 'エレメンタルアミュレット',
    'item_shield_golem': 'ゴーレムシールド',
    'item_hammer_titan': 'タイタンハンマー',
    'item_sword_darklord': 'ダークロードソード',
    'item_armor_ultimate': '究極の鎧',

    // 新装備（精霊王・死神系）
    'elemental_sword': '精霊王の剣',
    'elemental_nec': '精霊王のネックレス',
    'sinigami_sword': '死神の剣',

    // ドロップ装備
    'piero_face': 'ピエロ仮面',
    'metal_wing': '鋼鉄の翼',
    'thunder_fang': '稲妻の入れ歯',
  };

  /// ペット種族名を日本語で取得
  static String getPetSpeciesName(String species) {
    return petSpeciesNames[species.toLowerCase()] ?? species;
  }

  /// ステージ名を日本語で取得
  static String getStageName(String stage) {
    return stageNames[stage.toLowerCase()] ?? stage;
  }

  /// 素材名を日本語で取得
  static String getMaterialName(String materialId) {
    return materialNames[materialId] ?? materialId;
  }

  /// 装備名を日本語で取得
  static String getEquipmentName(String equipmentId) {
    return equipmentNames[equipmentId] ?? equipmentId;
  }

  /// アイテム名を日本語で取得（素材または装備）
  static String getItemName(String itemId) {
    // まず素材を確認
    if (materialNames.containsKey(itemId)) {
      return materialNames[itemId]!;
    }
    // 次に装備を確認
    if (equipmentNames.containsKey(itemId)) {
      return equipmentNames[itemId]!;
    }
    // どちらでもなければIDをそのまま返す
    return itemId;
  }
}
