import 'package:hive/hive.dart';
import '../models/pet.dart';
import 'dart:math';

class PetService {
  static const String _boxName = 'pets';
  static Box<PetModel>? _box;

  // 初期化
  static Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<PetModel>(_boxName);
    }
  }

  // === 基本世話機能 ===

  /// 餌やり
  static Future<void> feedPet(String petId,
      {String foodType = 'normal'}) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    int hungerIncrease = 30;
    int moodIncrease = 5;
    int dirtyIncrease = 15;

    if (foodType == 'premium') {
      hungerIncrease = 50;
      moodIncrease = 10;
    }

    pet.hunger = (pet.hunger + hungerIncrease).clamp(0, 100);
    pet.mood = (pet.mood + moodIncrease).clamp(0, 100);
    pet.dirty = (pet.dirty + dirtyIncrease).clamp(0, 100);
    pet.lastFed = DateTime.now();

    // 親密度+1
    pet.intimacy = (pet.intimacy + 1).clamp(0, 100);

    await pet.save();
  }

  /// 遊ぶ
  static Future<void> playWithPet(String petId, String gameType) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    pet.mood = (pet.mood + 20).clamp(0, 100);
    pet.stamina = (pet.stamina - 10).clamp(0, 100);
    pet.lastPlayed = DateTime.now();
    pet.playCount += 1;

    // 親密度+2
    pet.intimacy = (pet.intimacy + 2).clamp(0, 100);

    // 経験値+10
    pet.exp += 10;
    await _checkLevelUpLogic(pet);

    await pet.save();
  }

  /// 清掃
  static Future<void> cleanPet(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    pet.dirty = 0;
    pet.mood = (pet.mood + 15).clamp(0, 100);
    pet.lastCleaned = DateTime.now();
    pet.cleanCount += 1;

    await pet.save();
  }

  /// 薬を与える
  static Future<void> giveMedicine(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    if (pet.isSick) {
      pet.isSick = false;
      pet.sickness = null;
      pet.mood = (pet.mood + 10).clamp(0, 100);
    }

    await pet.save();
  }

  // === ゲージ自動更新 ===

  /// 時間経過によるゲージ減少
  static Future<void> updateGauges(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    final now = DateTime.now();
    final hoursSinceLastCheck =
        now.difference(pet.lastHealthCheck ?? now).inHours;

    if (hoursSinceLastCheck > 0) {
      // お腹ゲージ: 3時間で-10
      pet.hunger =
          (pet.hunger - (hoursSinceLastCheck * 10 / 3).round()).clamp(0, 100);

      // 機嫌ゲージ: 1時間で-5（怒り状態なら-20）
      int moodDecrease = pet.mood < 30 ? 20 : 5;
      pet.mood =
          (pet.mood - (hoursSinceLastCheck * moodDecrease)).clamp(0, 100);

      // 汚れゲージ: 1時間で+5
      pet.dirty = (pet.dirty + (hoursSinceLastCheck * 5)).clamp(0, 100);

      // 汚れ50超えで機嫌-10/時
      if (pet.dirty > 50) {
        pet.mood = (pet.mood - (hoursSinceLastCheck * 10)).clamp(0, 100);
      }

      // 睡眠中は体力回復（22:00-06:00）
      final hour = now.hour;
      if (hour >= 22 || hour < 6) {
        pet.stamina = (pet.stamina + (hoursSinceLastCheck * 5)).clamp(0, 100);
      }

      pet.lastHealthCheck = now;
    }

    // 日数計算
    pet.age = now.difference(pet.birthDate).inDays;

    await pet.save();
    await checkSickness(petId);
    await checkDeath(petId);
  }

  /// 病気判定
  static Future<bool> checkSickness(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive || pet.isSick) return false;

    final random = Random();

    // お腹ゲージ0が3時間継続 → 風邪（確率50%）
    if (pet.hunger == 0 &&
        DateTime.now().difference(pet.lastFed).inHours >= 3) {
      if (random.nextDouble() < 0.5) {
        pet.isSick = true;
        pet.sickness = 'cold';
        await pet.save();
        return true;
      }
    }

    // 汚れゲージ80超過が6時間 → 腹痛（確率70%）
    if (pet.dirty > 80 &&
        DateTime.now().difference(pet.lastCleaned).inHours >= 6) {
      if (random.nextDouble() < 0.7) {
        pet.isSick = true;
        pet.sickness = 'stomachache';
        await pet.save();
        return true;
      }
    }

    // 体力ゲージ0が1時間 → 過労（確率30%）
    if (pet.stamina == 0 &&
        DateTime.now()
                .difference(pet.lastHealthCheck ?? DateTime.now())
                .inHours >=
            1) {
      if (random.nextDouble() < 0.3) {
        pet.isSick = true;
        pet.sickness = 'fatigue';
        await pet.save();
        return true;
      }
    }

    return false;
  }

  /// 死亡判定
  static Future<void> checkDeath(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    // 病気放置12時間
    if (pet.isSick && pet.sickness != null) {
      final hoursSinceLastCheck = DateTime.now()
          .difference(pet.lastHealthCheck ?? DateTime.now())
          .inHours;
      if (hoursSinceLastCheck >= 12) {
        pet.isAlive = false;
        await pet.save();
        return;
      }
    }

    // お腹ゲージ0が24時間継続
    if (pet.hunger == 0 &&
        DateTime.now().difference(pet.lastFed).inHours >= 24) {
      pet.isAlive = false;
      await pet.save();
      return;
    }

    // 寿命（30日）
    if (pet.age >= 30) {
      pet.isAlive = false;
      await pet.save();
    }
  }

  // === 進化システム ===

  /// 進化可能かチェック
  static Future<bool> canEvolve(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return false;

    // たまご → 幼年期（1日経過）
    if (pet.stage == 'egg' && pet.age >= 1) return true;

    // 幼年期 → 成長期（レベル10以上、3日経過）
    if (pet.stage == 'baby' && pet.level >= 10 && pet.age >= 3) return true;

    // 成長期 → 成熟期（レベル30以上、6日経過、条件達成）
    if (pet.stage == 'child' && pet.level >= 30 && pet.age >= 6) {
      return _checkEvolutionConditions(pet);
    }

    // 成熟期 → 究極体（レベル70以上、11日経過、特殊条件）
    if (pet.stage == 'adult' && pet.level >= 70 && pet.age >= 11) {
      return _checkUltimateEvolutionConditions(pet);
    }

    return false;
  }

  /// 進化条件チェック（成長期→成熟期）
  static bool _checkEvolutionConditions(PetModel pet) {
    // 各種進化先の条件例
    final businessArticles = pet.genreStats['business'] ?? 0;
    final sportsArticles = pet.genreStats['sports'] ?? 0;
    final politicsArticles = pet.genreStats['politics'] ?? 0;

    // グレイモン条件: ビジネス記事30本 + 体力60以上
    if (businessArticles >= 30 && pet.stamina >= 60) return true;

    // ガルルモン条件: スポーツ記事30本 + 機嫌80以上
    if (sportsArticles >= 30 && pet.mood >= 80) return true;

    // エンジェモン条件: 国際政治記事30本 + 病気0回
    if (politicsArticles >= 30 && !pet.isSick) return true;

    // デビモン条件: 放置（機嫌20以下）
    if (pet.mood <= 20) return true;

    return false;
  }

  /// 究極進化条件チェック
  static bool _checkUltimateEvolutionConditions(PetModel pet) {
    // ウォーグレイモン: グレイモン + 親密度100 + 対戦50勝
    if (pet.species == 'greymon' && pet.intimacy >= 100 && pet.wins >= 50)
      return true;

    // メタルガルルモン: ガルルモン + 全ジャンル記事50本
    if (pet.species == 'garurumon') {
      final allGenresAbove50 =
          pet.genreStats.values.every((count) => count >= 50);
      if (allGenresAbove50) return true;
    }

    return false;
  }

  /// 利用可能な進化先リスト取得
  static Future<List<String>> getAvailableEvolutions(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return [];

    final evolutions = <String>[];

    if (pet.stage == 'egg') {
      evolutions.add('baby_genki');
      evolutions.add('baby_shy');
    } else if (pet.stage == 'baby' && pet.level >= 10) {
      evolutions.addAll(['warrior', 'beast', 'angel', 'demon']);
    } else if (pet.stage == 'child' && pet.level >= 30) {
      final businessArticles = pet.genreStats['business'] ?? 0;
      final sportsArticles = pet.genreStats['sports'] ?? 0;
      final politicsArticles = pet.genreStats['politics'] ?? 0;

      if (businessArticles >= 30 && pet.stamina >= 60)
        evolutions.add('greymon');
      if (sportsArticles >= 30 && pet.mood >= 80) evolutions.add('garurumon');
      if (politicsArticles >= 30 && !pet.isSick) evolutions.add('angemon');
      if (pet.mood <= 20) evolutions.add('devimon');
    } else if (pet.stage == 'adult' && pet.level >= 70) {
      if (pet.species == 'greymon' && pet.intimacy >= 100 && pet.wins >= 50) {
        evolutions.add('wargreymon');
      }
      if (pet.species == 'garurumon') {
        final allGenresAbove50 =
            pet.genreStats.values.every((count) => count >= 50);
        if (allGenresAbove50) evolutions.add('metalgarurumon');
      }
    }

    return evolutions;
  }

  /// 進化実行
  static Future<void> evolvePet(String petId, String targetSpecies) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    pet.species = targetSpecies;

    // ステージ更新
    if (pet.stage == 'egg') {
      pet.stage = 'baby';
    } else if (pet.stage == 'baby') {
      pet.stage = 'child';
    } else if (pet.stage == 'child') {
      pet.stage = 'adult';
    } else if (pet.stage == 'adult') {
      pet.stage = 'ultimate';
    }

    // ステータスボーナス
    pet.attack += 10;
    pet.defense += 10;
    pet.speed += 5;

    await pet.save();
  }

  // === ユーティリティ ===

  /// 全ペット取得
  static Future<List<PetModel>> getAllPets() async {
    await init();
    return _box!.values.toList();
  }

  /// アクティブペット取得
  static Future<PetModel?> getActivePet() async {
    await init();
    return _box!.values.firstWhere(
      (pet) => pet.isActive && pet.isAlive,
      orElse: () => _box!.values.first,
    );
  }

  /// ペット切り替え
  static Future<void> setActivePet(String petId) async {
    await init();
    // 全ペットのisActiveをfalseに
    for (var pet in _box!.values) {
      pet.isActive = false;
      await pet.save();
    }
    // 指定ペットをアクティブに
    final targetPet = _box!.get(petId);
    if (targetPet != null) {
      targetPet.isActive = true;
      await targetPet.save();
    }
  }

  /// レベルアップチェック
  static Future<void> _checkLevelUpLogic(PetModel pet) async {
    while (pet.canLevelUp()) {
      pet.level += 1;
      pet.exp -= pet.expToNextLevel;
      pet.attack += 2;
      pet.defense += 2;
      pet.speed += 1;
    }
  }

  /// ジャンル別経験値加算（記事閲覧時に呼び出し）
  static Future<void> incrementGenreStat(String petId, String genre) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null || !pet.isAlive) return;

    pet.genreStats[genre] = (pet.genreStats[genre] ?? 0) + 1;
    pet.exp += 5; // 記事1本で経験値+5
    pet.intimacy = (pet.intimacy + 1).clamp(0, 100);

    await _checkLevelUpLogic(pet);
    await pet.save();
  }

  /// 親密度更新
  static Future<void> updateIntimacy(String petId, int delta) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return;

    pet.intimacy = (pet.intimacy + delta).clamp(0, 100);
    await pet.save();
  }

  /// ペット統計取得
  static Future<Map<String, dynamic>> getPetStats(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return {};

    return {
      'name': pet.name,
      'species': pet.species,
      'level': pet.level,
      'age': pet.age,
      'intimacyLevel': pet.intimacyLevel,
      'healthStatus': pet.healthStatus,
      'wins': pet.wins,
      'losses': pet.losses,
      'playCount': pet.playCount,
      'genreStats': pet.genreStats,
    };
  }

  /// 思い出アルバム（死亡したペット一覧）
  static Future<List<PetModel>> getPetAlbum() async {
    await init();
    return _box!.values.where((pet) => !pet.isAlive).toList();
  }

  /// バトル勝利記録
  static Future<void> incrementWins(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return;
    pet.wins += 1;
    pet.battleCount += 1;
    await pet.save();
  }

  /// バトル敗北記録
  static Future<void> incrementLosses(String petId) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return;
    pet.losses += 1;
    pet.battleCount += 1;
    await pet.save();
  }

  /// 経験値追加
  static Future<void> addExp(String petId, int expAmount) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return;

    pet.exp += expAmount;

    // レベルアップチェック
    while (pet.exp >= pet.expToNextLevel && pet.level < 99) {
      pet.exp -= pet.expToNextLevel;
      pet.level += 1;
      pet.attack += 3;
      pet.defense += 2;
      pet.speed += 2;
      pet.hp += 10;
    }

    await pet.save();
  }

  /// 配合（2体のペットから新しいたまご生成）
  static Future<String> breedPets(String parentId1, String parentId2) async {
    await init();
    final parent1 = _box!.get(parentId1);
    final parent2 = _box!.get(parentId2);

    if (parent1 == null || parent2 == null) return '';
    if (parent1.stage != 'adult' && parent1.stage != 'ultimate') return '';
    if (parent2.stage != 'adult' && parent2.stage != 'ultimate') return '';

    // 新しいたまご作成
    final egg = PetModel.createEgg('配合たまご');

    // 親のスキルを継承（ランダムで2つ）
    final allSkills = [...parent1.skills, ...parent2.skills];
    allSkills.shuffle();
    egg.skills = allSkills.take(2).toList();

    await _box!.put(egg.id, egg);
    return egg.id;
  }
}
