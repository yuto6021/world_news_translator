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
    },
    'shop_amulet_shield': {
      'effect': {'defense': 1.08}, // 防御+8%
      'name': 'シールドアミュレット',
      'image': 'assets/items/equipment/shop_amulet_shield.png',
    },
    'shop_boots_speed': {
      'effect': {'speed': 1.10}, // 素早さ+10%
      'name': 'スピードブーツ',
      'image': 'assets/items/equipment/shop_boots_speed.png',
    },
    'shop_necklace_hp': {
      'effect': {'hp': 1.12}, // HP+12%
      'name': 'HPネックレス',
      'image': 'assets/items/equipment/shop_necklace_hp.png',
    },
    'shop_crown_exp': {
      'effect': {'exp_bonus': 1.15}, // 経験値+15%
      'name': 'クラウン',
      'image': 'assets/items/equipment/shop_crown_exp.png',
    },
    'shop_gloves_crit': {
      'effect': {'crit_rate': 0.08}, // クリティカル率+8%
      'name': 'グローブ',
      'image': 'assets/items/equipment/shop_gloves_crit.png',
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

  /// 素材の日本語名を取得
  static String getMaterialName(String materialId) {
    const names = {
      // 鉱石
      'ore_fire_crystal': '炎の結晶',
      'ore_water_pearl': '水の真珠',
      'ore_nature_leafstone': '自然の葉石',
      'ore_rock_fragment': '岩石の欠片',
      'ore_light_shard': '光の欠片',
      'ore_dark_shard': '闇の欠片',
      // 獣
      'beast_fang': '獣の牙',
      'beast_claw': '鋭い爪',
      'beast_hide': '獣の毛皮',
      // ドラゴン
      'dragon_scale': 'ドラゴンの鱗',
      'dragon_bone': 'ドラゴンの骨',
      'dragon_flame_sac': '炎袋',
      // 魔法
      'magic_core_small': '小型魔力核',
      'magic_core_medium': '中型魔力核',
      'magic_core_large': '大型魔力核',
      'enchanted_thread': '魔法糸',
      // 共通
      'wood_plank': '木板',
      'iron_ingot': '鉄インゴット',
      'leather_strip': '革ひも',
      'rune_stone': 'ルーン石',
    };
    return names[materialId] ?? materialId;
  }

  /// 素材の画像パスを取得
  static String? getMaterialImage(String materialId) {
    return dropMaterials[materialId];
  }
}
