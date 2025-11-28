import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 図鑑サービス - 敵・ペット・アイテムの収集管理
class DexService {
  static const String _enemyDexKey = 'enemy_dex';
  static const String _petDexKey = 'pet_dex';
  static const String _itemDexKey = 'item_dex';

  // 敵図鑑
  static const List<String> allEnemies = [
    'slime',
    'goblin',
    'wolf',
    'zombie',
    'fairy',
    'elemental',
    'dragon',
    'golem',
    'titan', // boss
    'darklord', // boss
    'secret_boss', // ???
  ];

  // ペット種族図鑑
  static const List<String> allPetSpecies = [
    'default',
    'fire',
    'water',
    'thunder',
    'forest',
    'dark',
    'light',
    'dragon',
    'ultimate_dragon',
  ];

  // アイテム図鑑
  static const List<String> allItems = [
    'food',
    'candy',
    'medicine',
    'energy_drink',
    'revival_medicine',
    'toy',
    'bath_set',
    'breeding_supplement',
    'power_ring',
    'shield_amulet',
    'speed_boots',
    'hp_necklace',
    'critical_gloves',
    'exp_crown',
    'evolution_stone',
    'exp_potion_s',
    'exp_potion_m',
    'exp_potion_l',
    'skill_book',
    'friendship_badge',
    'gacha_ticket',
    'lucky_charm',
    'battle_pass',
    'rainbow_feather',
    'dark_fragment',
    'time_capsule',
  ];

  /// 敵図鑑に登録
  static Future<bool> registerEnemy(String enemyType) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_enemyDexKey);

    Set<String> registered = {};
    if (data != null) {
      registered = Set<String>.from(json.decode(data));
    }

    final isNew = !registered.contains(enemyType);
    registered.add(enemyType);

    await prefs.setString(_enemyDexKey, json.encode(registered.toList()));
    return isNew;
  }

  /// ペット図鑑に登録
  static Future<bool> registerPet(String species) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_petDexKey);

    Set<String> registered = {};
    if (data != null) {
      registered = Set<String>.from(json.decode(data));
    }

    final isNew = !registered.contains(species);
    registered.add(species);

    await prefs.setString(_petDexKey, json.encode(registered.toList()));
    return isNew;
  }

  /// アイテム図鑑に登録
  static Future<bool> registerItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_itemDexKey);

    Set<String> registered = {};
    if (data != null) {
      registered = Set<String>.from(json.decode(data));
    }

    final isNew = !registered.contains(itemId);
    registered.add(itemId);

    await prefs.setString(_itemDexKey, json.encode(registered.toList()));
    return isNew;
  }

  /// 敵図鑑取得
  static Future<Set<String>> getEnemyDex() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_enemyDexKey);

    if (data == null) return {};
    return Set<String>.from(json.decode(data));
  }

  /// ペット図鑑取得
  static Future<Set<String>> getPetDex() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_petDexKey);

    if (data == null) return {};
    return Set<String>.from(json.decode(data));
  }

  /// アイテム図鑑取得
  static Future<Set<String>> getItemDex() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_itemDexKey);

    if (data == null) return {};
    return Set<String>.from(json.decode(data));
  }

  /// 図鑑完成度取得
  static Future<Map<String, dynamic>> getCompletionStats() async {
    final enemyDex = await getEnemyDex();
    final petDex = await getPetDex();
    final itemDex = await getItemDex();

    return {
      'enemy': {
        'collected': enemyDex.length,
        'total': allEnemies.length,
        'percentage': (enemyDex.length / allEnemies.length * 100).toInt(),
      },
      'pet': {
        'collected': petDex.length,
        'total': allPetSpecies.length,
        'percentage': (petDex.length / allPetSpecies.length * 100).toInt(),
      },
      'item': {
        'collected': itemDex.length,
        'total': allItems.length,
        'percentage': (itemDex.length / allItems.length * 100).toInt(),
      },
      'totalPercentage': ((enemyDex.length + petDex.length + itemDex.length) /
              (allEnemies.length + allPetSpecies.length + allItems.length) *
              100)
          .toInt(),
    };
  }

  /// 図鑑リセット
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enemyDexKey);
    await prefs.remove(_petDexKey);
    await prefs.remove(_itemDexKey);
  }
}
