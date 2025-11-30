import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 配合レシピデータクラス
class BreedingRecipe {
  final List<String> requiredParents;
  final String resultSpecies;
  final String name;
  final String description;
  final String rarity; // 'legendary', 'mythic'
  final bool requiresAllUltimate;

  const BreedingRecipe({
    required this.requiredParents,
    required this.resultSpecies,
    required this.name,
    required this.description,
    required this.rarity,
    this.requiresAllUltimate = false,
  });
}

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

  // ペット種族図鑑（60種以上）
  static const List<String> allPetSpecies = [
    'default',
    // === 通常種族 ===
    // 炎系統（6種）
    'agumon',
    'greymon',
    'metalgreymon',
    'wargreymon',
    'tyrannomon',
    'mastertyranomon',
    // 氷・水系統（6種）
    'gabumon',
    'garurumon',
    'weregarurumon',
    'metalgarurumon',
    'seadramon',
    'megaseadramon',
    // 光・天使系統（6種）
    'patamon',
    'angemon',
    'angewomon',
    'seraphimon',
    'gatomon',
    'magnaangemon',
    // 昆虫系統（5種）
    'tentomon',
    'kabuterimon',
    'atlurkabuterimon',
    'herculeskabuterimon',
    'kuwagamon',
    // 闇・悪魔系統（6種）
    'devimon',
    'myotismon',
    'venommyotismon',
    'piedmon',
    'deathmon',
    'phantomon',
    // 獣系統（6種）
    'leomon',
    'saberleomon',
    'bancholeomon',
    'gaomon',
    'machgaogamon',
    'miragegaogamon',
    // ドラゴン系統（6種）
    'veemon',
    'exveemon',
    'paildramon',
    'imperialdramon',
    'dorumon',
    'dorugoramon',
    // 機械系統（5種）
    'hagurumon',
    'guardromon',
    'andromon',
    'machinedramon',
    'cyberdramon',
    // 植物系統（4種）
    'palmon',
    'togemon',
    'lillymon',
    'rosemon',
    // 妖精・魔法系統（4種）
    'wizardmon',
    'mysticmon',
    'sorcerymon',
    'beelzemon',
    // === 配合限定種族（10種）===
    'omegamon', // WarGreymon × MetalGarurumon
    'alphamon', // Omegamon × Imperialdramon
    'susanoomon', // Seraphimon × BanchoLeomon
    'imperialdramon_pm', // Imperialdramon × Omegamon（パラディンモード）
    'gallantmon', // WarGreymon × Seraphimon
    'beelzebumon', // Beelzemon × VenomMyotismon
    'apocalymon', // 全究極体配合
    'lucemon', // Seraphimon × Piedmon
    'chaosmon', // BanchoLeomon × Darkdramon
    'darkdramon', // Cyberdramon × Devimon
    // 旧種族（互換性）
    'fire',
    'water',
    'thunder',
    'forest',
    'dark',
    'light',
    'dragon',
    'ultimate_dragon',
  ];

  // === 配合レシピ（特定の親の組み合わせで特別なペット誕生）===
  static const Map<String, BreedingRecipe> breedingRecipes = {
    'omegamon': BreedingRecipe(
      requiredParents: ['wargreymon', 'metalgarurumon'],
      resultSpecies: 'omegamon',
      name: 'オメガモン',
      description: '戦士の絆が生み出す究極の騎士',
      rarity: 'legendary',
    ),
    'alphamon': BreedingRecipe(
      requiredParents: ['omegamon', 'imperialdramon'],
      resultSpecies: 'alphamon',
      name: 'アルファモン',
      description: '空座の十三騎士団の筆頭',
      rarity: 'mythic',
    ),
    'imperialdramon_pm': BreedingRecipe(
      requiredParents: ['imperialdramon', 'omegamon'],
      resultSpecies: 'imperialdramon_pm',
      name: 'インペリアルドラモン（PM）',
      description: 'パラディンモードに覚醒した最強形態',
      rarity: 'mythic',
    ),
    'gallantmon': BreedingRecipe(
      requiredParents: ['wargreymon', 'seraphimon'],
      resultSpecies: 'gallantmon',
      name: 'デュークモン',
      description: '炎と光の融合戦士',
      rarity: 'legendary',
    ),
    'susanoomon': BreedingRecipe(
      requiredParents: ['seraphimon', 'bancholeomon'],
      resultSpecies: 'susanoomon',
      name: 'スサノオモン',
      description: '十闘士の力を継承する神',
      rarity: 'mythic',
    ),
    'beelzebumon': BreedingRecipe(
      requiredParents: ['beelzemon', 'venommyotismon'],
      resultSpecies: 'beelzebumon',
      name: 'ベルゼブモン',
      description: '闇の力を極めし魔王',
      rarity: 'legendary',
    ),
    'lucemon': BreedingRecipe(
      requiredParents: ['seraphimon', 'piedmon'],
      resultSpecies: 'lucemon',
      name: 'ルーチェモン',
      description: '光と闇の両面を持つ堕天使',
      rarity: 'mythic',
    ),
    'darkdramon': BreedingRecipe(
      requiredParents: ['cyberdramon', 'devimon'],
      resultSpecies: 'darkdramon',
      name: 'ダークドラモン',
      description: '機械と闇が融合した破壊兵器',
      rarity: 'legendary',
    ),
    'chaosmon': BreedingRecipe(
      requiredParents: ['bancholeomon', 'darkdramon'],
      resultSpecies: 'chaosmon',
      name: 'カオスモン',
      description: '秩序と混沌の化身',
      rarity: 'mythic',
    ),
    'apocalymon': BreedingRecipe(
      requiredParents: ['omegamon', 'alphamon'],
      resultSpecies: 'apocalymon',
      name: 'アポカリモン',
      description: '全てを終わらせる終焉の存在',
      rarity: 'mythic',
      requiresAllUltimate: true,
    ),
  };

  /// 配合レシピに一致するか確認
  static String? checkBreedingRecipe(
      String parent1Species, String parent2Species) {
    for (final entry in breedingRecipes.entries) {
      final recipe = entry.value;
      final required = recipe.requiredParents;

      // 順不同で一致確認
      if ((required[0] == parent1Species && required[1] == parent2Species) ||
          (required[0] == parent2Species && required[1] == parent1Species)) {
        return recipe.resultSpecies;
      }
    }
    return null;
  }

  /// 配合レシピ情報を取得
  static BreedingRecipe? getBreedingRecipe(String recipeId) {
    return breedingRecipes[recipeId];
  }

  /// 配合限定ペットかどうか
  static bool isBreedingExclusive(String species) {
    return breedingRecipes.values.any((r) => r.resultSpecies == species);
  }

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
