import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet_service.dart';

/// 装備・クラフトシステム
class EquipmentService {
  static const String _keyInventory = 'equipment_inventory';

  /// ショップ専用装備（クラフト不可、購入のみ）
  static final Map<String, Map<String, dynamic>> shopEquipment = {
    'shop_ring_power': {
      'effect': {'attack': 1.08}, // 攻撃+8%
      'name': 'パワーリング',
      'image': 'assets/items/equipment/shop_ring_power.png',
      'slot': 'accessory',
    },
    'shop_amulet_shield': {
      'effect': {'defense': 1.08}, // 防御+8%
      'name': 'シールドアミュレット',
      'image': 'assets/items/equipment/item_shield_amulet.png',
      'slot': 'accessory',
    },
    'shop_boots_speed': {
      'effect': {'speed': 1.10}, // 素早さ+10%
      'name': 'スピードブーツ',
      'image': 'assets/items/equipment/item_speed_boots.png',
      'slot': 'accessory',
    },
    'shop_necklace_hp': {
      'effect': {'hp': 1.12}, // HP+12%
      'name': 'HPネックレス',
      'image': 'assets/items/equipment/shop_necklace_hp.png',
      'slot': 'accessory',
    },
    'shop_crown_exp': {
      'effect': {'exp_bonus': 1.15}, // 経験値+15%
      'name': 'クラウン',
      'image': 'assets/items/equipment/item_exp_crown.png',
      'slot': 'accessory',
    },
    'shop_gloves_crit': {
      'effect': {'crit_rate': 0.08}, // クリティカル率+8%
      'name': 'グローブ',
      'image': 'assets/items/equipment/item_critical_gloves.png',
      'slot': 'accessory',
    },
  };

  /// クラフトレシピ（素材 → 装備）
  static const Map<String, Map<String, dynamic>> recipes = {
    // === 剣系 ===
    'item_sword_bronze': {
      'material': 'iron_ingot',
      'requiredCount': 2,
      'effect': {'attack': 1.1}, // 攻撃+10%
      'name': 'ブロンズソード',
      'image': 'assets/items/equipment/item_sword_bronze.png',
    },
    'item_sword_iron': {
      'material': 'iron_ingot',
      'requiredCount': 3,
      'effect': {'attack': 1.15}, // 攻撃+15%
      'name': 'アイアンソード',
      'image': 'assets/items/equipment/item_sword_iron.png',
    },
    'item_sword_dragon': {
      'material': 'dragon_scale',
      'requiredCount': 3,
      'effect': {'attack': 1.25}, // 攻撃+25%
      'name': 'ドラゴンソード',
      'image': 'assets/items/equipment/item_sword_dragon.png',
    },
    // === 盾系 ===
    'item_shield_wood': {
      'material': 'wood_plank',
      'requiredCount': 2,
      'effect': {'defense': 1.1}, // 防御+10%
      'name': '木の盾',
      'image': 'assets/items/equipment/item_shield_wood.png',
    },
    'item_shield_iron': {
      'material': 'iron_ingot',
      'requiredCount': 3,
      'effect': {'defense': 1.15}, // 防御+15%
      'name': '鉄の盾',
      'image': 'assets/items/equipment/item_shield_iron.png',
    },
    'item_shield_dragon': {
      'material': 'dragon_scale',
      'requiredCount': 3,
      'effect': {'defense': 1.25}, // 防御+25%
      'name': 'ドラゴンシールド',
      'image': 'assets/items/equipment/item_shield_dragon.png',
    },
    // === 鎧系 ===
    'item_armor_leather': {
      'material': 'leather_strip',
      'requiredCount': 2,
      'effect': {'hp': 1.1}, // HP+10%
      'name': 'レザーメイル',
      'image': 'assets/items/equipment/item_armor_leather.png',
    },
    'item_armor_chain': {
      'material': 'iron_ingot',
      'requiredCount': 4,
      'effect': {'hp': 1.2}, // HP+20%
      'name': 'チェインメイル',
      'image': 'assets/items/equipment/item_armor_chain.png',
    },
    'item_armor_paladin': {
      'material': 'ore_light_shard',
      'requiredCount': 3,
      'effect': {'hp': 1.25, 'defense': 1.1}, // HP+25% 防御+10%
      'name': 'パラディンアーマー',
      'image': 'assets/items/equipment/item_armor_paladin.png',
    },
    // === 杖系 ===
    'item_staff_oak': {
      'material': 'wood_plank',
      'requiredCount': 2,
      'effect': {'support': 1.1}, // サポート効果+10%
      'name': 'オークスタッフ',
      'image': 'assets/items/equipment/item_staff_oak.png',
    },
    'item_staff_mage': {
      'material': 'magic_core_medium',
      'requiredCount': 2,
      'effect': {'skill_power': 1.15}, // スキル威力+15%
      'name': 'メイジスタッフ',
      'image': 'assets/items/equipment/item_staff_mage.png',
    },
    'item_staff_seraph': {
      'material': 'ore_light_shard',
      'requiredCount': 3,
      'effect': {'skill_power': 1.25}, // スキル威力+25%
      'name': 'セラフロッド',
      'image': 'assets/items/equipment/item_staff_seraph.png',
    },
    // === アクセサリ ===
    'item_ring_crit': {
      'material': 'rune_stone',
      'requiredCount': 2,
      'effect': {'crit_rate': 0.1}, // クリティカル率+10%
      'name': 'クリティカルリング',
      'image': 'assets/items/equipment/item_ring_crit.png',
    },
    'item_amulet_guard': {
      'material': 'rune_stone',
      'requiredCount': 2,
      'effect': {'defense': 1.1}, // 防御+10%
      'name': 'ガードアミュレット',
      'image': 'assets/items/equipment/item_amulet_guard.png',
    },
    'item_boots_swift': {
      'material': 'leather_strip',
      'requiredCount': 2,
      'effect': {'speed': 1.15}, // 素早さ+15%
      'name': 'スウィフトブーツ',
      'image': 'assets/items/equipment/item_boots_swift.png',
    },

    // === エネミードロップ素材装備 ===
    // ノーマル敵素材
    'item_sword_slime': {
      'material': 'slime_jelly',
      'requiredCount': 3,
      'effect': {'hp': 1.15, 'defense': 1.05}, // HP+15% 防御+5%
      'name': 'スライムソード',
      'image': 'assets/items/equipment/item_sword_slime.png',
    },
    'item_sword_goblin': {
      'material': 'goblin_sword',
      'requiredCount': 2,
      'effect': {'attack': 1.2}, // 攻撃+20%
      'name': 'ゴブリンソード',
      'image': 'assets/items/equipment/item_sword_goblin.png',
    },
    'item_armor_wolf': {
      'material': 'wolf_fang',
      'requiredCount': 3,
      'effect': {'attack': 1.1, 'speed': 1.1}, // 攻撃+10% 素早さ+10%
      'name': 'ウルフアーマー',
      'image': 'assets/items/equipment/item_armor_wolf.png',
    },
    'item_staff_zombie': {
      'material': 'zombie_bone',
      'requiredCount': 3,
      'effect': {'skill_power': 1.2}, // スキル威力+20%
      'name': 'ゾンビスタッフ',
      'image': 'assets/items/equipment/item_staff_zombie.png',
    },
    'item_ring_fairy': {
      'material': 'fairy_dust',
      'requiredCount': 2,
      'effect': {'hp': 1.2, 'support': 1.15}, // HP+20% サポート+15%
      'name': 'フェアリーリング',
      'image': 'assets/items/equipment/item_ring_fairy.png',
    },
    'item_amulet_elemental': {
      'material': 'elemental_crystal',
      'requiredCount': 2,
      'effect': {'skill_power': 1.25}, // スキル威力+25%
      'name': 'エレメンタルアミュレット',
      'image': 'assets/items/equipment/item_amulet_elemental.png',
    },
    'item_shield_golem': {
      'material': 'golem_core',
      'requiredCount': 2,
      'effect': {'defense': 1.3, 'hp': 1.1}, // 防御+30% HP+10%
      'name': 'ゴーレムシールド',
      'image': 'assets/items/equipment/item_shield_golem.png',
    },

    // ボス素材
    'item_hammer_titan': {
      'material': 'titan_hammer',
      'requiredCount': 1,
      'effect': {'attack': 1.4, 'hp': 1.2}, // 攻撃+40% HP+20%
      'name': 'タイタンハンマー',
      'image': 'assets/items/equipment/item_hammer_titan.png',
    },
    'item_sword_darklord': {
      'material': 'dark_sword',
      'requiredCount': 1,
      'effect': {'attack': 1.5, 'crit_rate': 0.15}, // 攻撃+50% クリティカル率+15%
      'name': 'ダークロードソード',
      'image': 'assets/items/equipment/item_sword_darklord.png',
    },

    // 裏ボス素材（最強装備）
    'item_armor_ultimate': {
      'material': 'ultimate_crystal',
      'requiredCount': 1,
      'effect': {
        'attack': 1.3,
        'defense': 1.3,
        'hp': 1.3,
        'speed': 1.3,
        'skill_power': 1.3
      }, // 全ステータス+30%
      'name': '究極の鎧',
      'image': 'assets/items/equipment/item_armor_ultimate.png',
    },

    // === 精霊王・死神系装備 ===
    'elemental_sword': {
      'materials': {
        'kingcore': 1,
        'firecore': 1,
        'watercore': 1,
        'woodcore': 1,
        'thundercore': 1,
        'lightcore': 1,
      },
      'effect': {
        'attack': 1.5,
        'defense': 1.2,
        'hp': 1.2,
        'speed': 1.2,
        'skill_power': 1.5
      }, // 全属性ダメージ+50%, 全ステータス+20%
      'name': '精霊王の剣',
      'image': 'assets/items/equipment/elemental_sword.png',
    },
    'elemental_nec': {
      'materials': {
        'kingcore': 1,
        'firecore': 1,
        'watercore': 1,
        'woodcore': 1,
        'thundercore': 1,
        'lightcore': 1,
      },
      'effect': {
        'hp': 1.5,
        'defense': 1.3,
        'resistance': 1.3
      }, // HP+50%, 全属性耐性+30%
      'name': '精霊王のネックレス',
      'image': 'assets/items/equipment/elemental_nec.png',
    },
    'sinigami_sword': {
      'material': 'sinigamicore',
      'requiredCount': 1,
      'effect': {
        'attack': 1.6,
        'crit_rate': 0.1,
        'instant_kill': 0.1
      }, // 攻撃+60%, 即死確率+10%
      'name': '死神の剣',
      'image': 'assets/items/equipment/sinigami_sword.png',
    },
  };

  /// ドロップ装備（敵から直接ドロップ、クラフト不可）
  static final Map<String, Map<String, dynamic>> dropEquipment = {
    'piero_face': {
      'effect': {'crit_rate': 0.2, 'evasion': 0.15}, // クリティカル率+20%, 回避+15%
      'name': 'ピエロ仮面',
      'image': 'assets/items/equipment/piero_face.png',
      'slot': 'accessory',
      'dropFrom': 'ピエモン',
    },
    'metal_wing': {
      'effect': {'speed': 1.3, 'defense': 1.2}, // 素早さ+30%, 防御+20%
      'name': '鋼鉄の翼',
      'image': 'assets/items/equipment/metal_wing.png',
      'slot': 'accessory',
      'dropFrom': 'ミラージュガオガモン',
    },
    'thunder_fang': {
      'effect': {'attack': 1.25, 'element_thunder': 1.3}, // 攻撃+25%, 雷属性ダメージ+30%
      'name': '稲妻の入れ歯',
      'image': 'assets/items/equipment/thunder_fang.png',
      'slot': 'accessory',
      'dropFrom': 'マッハガオガモン',
    },
  };

  /// ドロップ可能素材リスト（画像パス付き）
  static const Map<String, String> dropMaterials = {
    // 鉱石系
    'ore_fire_crystal': 'assets/materials/ores/ore_fire_crystal.png',
    'ore_water_pearl': 'assets/materials/ores/ore_water_pearl.png',
    'ore_nature_leafstone': 'assets/materials/ores/ore_nature_leafstone.png',
    'ore_rock_fragment': 'assets/materials/ores/ore_rock_fragment.png',
    'ore_light_shard': 'assets/materials/ores/ore_light_shard.png',
    'ore_dark_shard': 'assets/materials/ores/ore_dark_shard.png',
    // 獣系
    'beast_fang': 'assets/materials/beast/beast_fang.png',
    'beast_claw': 'assets/materials/beast/beast_claw.png',
    'beast_hide': 'assets/materials/beast/beast_hide.png',
    // ドラゴン系
    'dragon_scale': 'assets/materials/dragon/dragon_scale.png',
    'dragon_bone': 'assets/materials/dragon/dragon_bone.png',
    'dragon_flame_sac': 'assets/materials/dragon/dragon_flame_sac.png',
    // 魔法系
    'magic_core_small': 'assets/materials/magical/magic_core_small.png',
    'magic_core_medium': 'assets/materials/magical/magic_core_medium.png',
    'magic_core_large': 'assets/materials/magical/magic_core_large.png',
    'enchanted_thread': 'assets/materials/magical/enchanted_thread.png',
    // 共通素材
    'wood_plank': 'assets/materials/common/wood_plank.png',
    'iron_ingot': 'assets/materials/common/iron_ingot.png',
    'leather_strip': 'assets/materials/common/leather_strip.png',
    'rune_stone': 'assets/materials/common/rune_stone.png',

    // エネミードロップ素材
    'slime_jelly': 'assets/materials/common/slime_jelly.png',
    'goblin_sword': 'assets/materials/common/goblin_sword.png',
    'wolf_fang': 'assets/materials/beast/wolf_fang.png',
    'zombie_bone': 'assets/materials/common/zombie_bone.png',
    'fairy_dust': 'assets/materials/magical/fairy_dust.png',
    'elemental_crystal': 'assets/materials/magical/elemental_crystal.png',
    'golem_core': 'assets/materials/common/golem_core.png',

    // ボス素材
    'titan_hammer': 'assets/materials/rare/titan_hammer.png',
    'dark_sword': 'assets/materials/rare/dark_sword.png',
    'titancore': 'assets/materials/rare/titancore.png',
    'darkcore': 'assets/materials/rare/darkcore.png',

    // 裏ボス素材
    'ultimate_crystal': 'assets/materials/rare/ultimate_crystal.png',
    'truehart': 'assets/materials/rare/truehart.png',
    'kingcore': 'assets/materials/rare/kingcore.png',

    // 属性騎士素材
    'firecore': 'assets/materials/ores/firecore.png',
    'watercore': 'assets/materials/ores/watercore.png',
    'woodcore': 'assets/materials/ores/woodcore.png',
    'thundercore': 'assets/materials/ores/thundercore.png',
    'lightcore': 'assets/materials/ores/lightcore.png',

    // 特殊敵素材
    'sinigamicore': 'assets/materials/rare/sinigamicore.png',
    'golden_horn': 'assets/materials/rare/golden_horn.png',
  };

  /// インベントリ取得
  static Future<Map<String, int>> getInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyInventory) ?? '{}';
    final Map<String, dynamic> inventory = json.decode(data);
    return inventory.map((key, value) => MapEntry(key, value as int));
  }

  /// 素材を追加
  static Future<void> addMaterial(String material, int count) async {
    final inventory = await getInventory();
    inventory[material] = (inventory[material] ?? 0) + count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInventory, json.encode(inventory));
  }

  /// 装備を追加（ショップ購入時など）
  static Future<void> addEquipment(String equipmentId, int count) async {
    final inventory = await getInventory();
    inventory[equipmentId] = (inventory[equipmentId] ?? 0) + count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInventory, json.encode(inventory));
  }

  /// クラフト実行
  static Future<bool> craft(String equipmentId) async {
    final recipe = recipes[equipmentId];
    if (recipe == null) return false;

    final inventory = await getInventory();
    final material = recipe['material'] as String;
    final required = recipe['requiredCount'] as int;

    if ((inventory[material] ?? 0) < required) {
      return false; // 素材不足
    }

    // 素材消費
    inventory[material] = inventory[material]! - required;

    // 装備を追加
    inventory[equipmentId] = (inventory[equipmentId] ?? 0) + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInventory, json.encode(inventory));

    return true;
  }

  /// 装備を装着
  static Future<bool> equip(
      String petId, String equipmentId, String slot) async {
    final inventory = await getInventory();
    if ((inventory[equipmentId] ?? 0) < 1) return false;

    final updates = <String, dynamic>{};
    switch (slot) {
      case 'weapon':
        updates['equippedWeapon'] = equipmentId;
        break;
      case 'armor':
        updates['equippedArmor'] = equipmentId;
        break;
      case 'accessory':
        updates['equippedAccessory'] = equipmentId;
        break;
      default:
        return false;
    }

    await PetService.updatePet(petId, updates);
    return true;
  }

  /// 装備を外す
  static Future<void> unequip(String petId, String slot) async {
    final updates = <String, dynamic>{};
    switch (slot) {
      case 'weapon':
        updates['equippedWeapon'] = null;
        break;
      case 'armor':
        updates['equippedArmor'] = null;
        break;
      case 'accessory':
        updates['equippedAccessory'] = null;
        break;
    }
    await PetService.updatePet(petId, updates);
  }

  /// 装備の効果を取得
  static Map<String, double> getEquipmentEffect(String equipmentId) {
    // ショップ専用装備をチェック
    final shopItem = shopEquipment[equipmentId];
    if (shopItem != null) {
      return Map<String, double>.from(shopItem['effect'] as Map);
    }

    // クラフト装備をチェック
    final recipe = recipes[equipmentId];
    if (recipe == null) return {};
    return Map<String, double>.from(recipe['effect'] as Map);
  }

  /// 装備の詳細情報を取得（名前、画像、効果）
  static Map<String, dynamic>? getEquipmentDetails(String equipmentId) {
    // ショップ専用装備をチェック
    if (shopEquipment.containsKey(equipmentId)) {
      return shopEquipment[equipmentId];
    }

    // クラフト装備をチェック
    if (recipes.containsKey(equipmentId)) {
      return recipes[equipmentId];
    }

    return null;
  }

  /// すべての装備を取得（ショップ専用＋クラフト）
  static Map<String, Map<String, dynamic>> getAllEquipment() {
    return {
      ...shopEquipment,
      ...recipes,
    };
  }

  /// ペットの全装備効果を計算
  static Map<String, double> getTotalEquipmentBonus(
    String? weapon,
    String? armor,
    String? accessory,
  ) {
    final Map<String, double> total = {};

    for (final equipment in [weapon, armor, accessory]) {
      if (equipment != null) {
        getEquipmentEffect(equipment).forEach((key, value) {
          total[key] = (total[key] ?? 1.0) * value;
        });
      }
    }

    // セットボーナス（簡易）
    final ids = [weapon, armor, accessory].whereType<String>().toList();
    if (ids.isNotEmpty) {
      final hasDragon = ids.where((id) => id.contains('dragon')).length >= 2;
      if (hasDragon) {
        total['attack'] = (total['attack'] ?? 1.0) * 1.10;
        total['defense'] = (total['defense'] ?? 1.0) * 1.10;
      }

      final hasIron = ids.where((id) => id.contains('iron')).length >= 2;
      if (hasIron) {
        total['defense'] = (total['defense'] ?? 1.0) * 1.05;
      }

      final swiftAndCrit =
          ids.contains('item_boots_swift') && ids.contains('item_ring_crit');
      if (swiftAndCrit) {
        total['speed'] = (total['speed'] ?? 1.0) * 1.05;
      }
    }

    return total;
  }

  /// 素材の日本語名を取得（LocalizationHelperに委譲）
  static String getMaterialName(String materialId) {
    // 互換性のためにLocalizationHelperを使用
    return materialId;
  }

  /// 素材の画像パスを取得
  static String? getMaterialImage(String materialId) {
    return dropMaterials[materialId];
  }
}
