import 'package:hive/hive.dart';
import '../models/pet.dart';
import 'dart:math';
import 'training_policy_service.dart';
import 'dex_service.dart';

class PetService {
  static const String _boxName = 'pets';
  static Box<PetModel>? _box;

  // 初期化
  static Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<PetModel>(_boxName);
    }
  }

  // Boxを取得
  static Future<Box<PetModel>> getBox() async {
    await init();
    return _box!;
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

    // ケアミス判定（空腹10未満で餌やり = 過剰）
    if (pet.hunger < 10) {
      pet.careMistakes = (pet.careMistakes + 1).clamp(0, 999);
    }

    pet.hunger = (pet.hunger + hungerIncrease).clamp(0, 100);
    pet.mood = (pet.mood + moodIncrease).clamp(0, 100);
    pet.dirty = (pet.dirty + dirtyIncrease).clamp(0, 100);
    pet.lastFed = DateTime.now();

    // 親密度+1
    pet.intimacy = (pet.intimacy + 1).clamp(0, 100);

    // ケア品質更新
    _updateCareQuality(pet);

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

    // ケアミス判定（汚れ90超過で放置）
    if (pet.dirty > 90) {
      pet.careMistakes = (pet.careMistakes + 1).clamp(0, 999);
    }

    pet.dirty = 0;
    pet.mood = (pet.mood + 15).clamp(0, 100);
    pet.lastCleaned = DateTime.now();
    pet.cleanCount += 1;

    // ケア品質更新
    _updateCareQuality(pet);

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

  /// ケア品質を更新
  static void _updateCareQuality(PetModel pet) {
    // ケアミス数に基づいてケア品質を計算
    pet.careQuality = (100 - (pet.careMistakes * 5)).clamp(0, 100);
  }

  /// 性格を決定（年齢3日で確定）
  static void _determinePersonality(PetModel pet) {
    if (pet.truePersonality != null) return; // すでに決定済み

    final playCount = pet.playCount;
    final cleanCount = pet.cleanCount;
    final battleCount = pet.wins + pet.losses;
    final mistakes = pet.careMistakes;

    // 優先順位: ミス多→戦闘多→遊び多→掃除多
    if (mistakes >= 10) {
      pet.truePersonality = '臆病'; // 全ステ-5%
    } else if (battleCount >= 20) {
      pet.truePersonality = '勇敢'; // SPD+10%
    } else if (playCount >= 30) {
      pet.truePersonality = 'わんぱく'; // ATK+10%
    } else if (cleanCount >= 25) {
      pet.truePersonality = 'おとなしい'; // DEF+10%
    } else {
      pet.truePersonality = 'ふつう'; // ボーナスなし
    }
  }

  /// 性格によるステータス補正を取得
  static Map<String, double> getPersonalityBonus(String? personality) {
    switch (personality) {
      case 'わんぱく':
        return {'attack': 1.1};
      case 'おとなしい':
        return {'defense': 1.1};
      case '勇敢':
        return {'speed': 1.1};
      case '臆病':
        return {'attack': 0.95, 'defense': 0.95, 'speed': 0.95};
      default:
        return {};
    }
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
    if (pet.stage == 'baby' && pet.level >= 10 && pet.age >= 3) {
      // 年齢3日で性格決定
      _determinePersonality(pet);
      return true;
    }

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

    // デビモン条件: 放置（機嫌20以下 or ケア品質50以下）
    if (pet.mood <= 20 || pet.careQuality <= 50) return true;

    return false;
  }

  /// 究極進化条件チェック
  static bool _checkUltimateEvolutionConditions(PetModel pet) {
    // ケア品質による分岐
    final highQuality = pet.careQuality >= 80;
    final lowQuality = pet.careQuality <= 50;

    // ウォーグレイモン: グレイモン + 親密度100 + 対戦50勝 + 高品質ケア
    if (pet.species == 'greymon' &&
        pet.intimacy >= 100 &&
        pet.wins >= 50 &&
        highQuality) return true;

    // スカルグレイモン: グレイモン + 低品質ケア
    if (pet.species == 'greymon' && lowQuality) return true;

    // メタルガルルモン: ガルルモン + 全ジャンル記事50本 + 高品質ケア
    if (pet.species == 'garurumon' && highQuality) {
      final allGenresAbove50 =
          pet.genreStats.values.every((count) => count >= 50);
      if (allGenresAbove50) return true;
    }

    // ダークドラモン: ガルルモン + 低品質ケア
    if (pet.species == 'garurumon' && lowQuality) return true;

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
      if (pet.mood <= 20 || pet.careQuality <= 50) evolutions.add('devimon');
    } else if (pet.stage == 'adult' && pet.level >= 70) {
      final highQuality = pet.careQuality >= 80;
      final lowQuality = pet.careQuality <= 50;

      if (pet.species == 'greymon') {
        if (pet.intimacy >= 100 && pet.wins >= 50 && highQuality) {
          evolutions.add('wargreymon');
        } else if (lowQuality) {
          evolutions.add('skullgreymon'); // 低品質進化
        }
      }
      if (pet.species == 'garurumon') {
        final allGenresAbove50 =
            pet.genreStats.values.every((count) => count >= 50);
        if (allGenresAbove50 && highQuality) {
          evolutions.add('metalgarurumon');
        } else if (lowQuality) {
          evolutions.add('darkdramon'); // 低品質進化
        }
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

  /// レベルアップコールバック（アニメーション用）
  static void Function(int level)? onLevelUp;

  /// レベルアップチェック
  static Future<void> _checkLevelUpLogic(PetModel pet) async {
    while (pet.canLevelUp()) {
      pet.level += 1;
      pet.exp -= pet.expToNextLevel;

      // 才能値による基礎成長量
      final baseAttackGrowth = 2 + (pet.talentAttack / 30).floor();
      final baseDefenseGrowth = 2 + (pet.talentDefense / 30).floor();
      final baseSpeedGrowth = 1 + (pet.talentSpeed / 40).floor();

      // 育成方針による補正を適用
      final policy = await TrainingPolicyService.getPolicy(pet.id);
      final bonusStats = TrainingPolicyService.applyPolicyBonus(
        policy,
        baseAttackGrowth,
        baseDefenseGrowth,
        baseSpeedGrowth,
      );

      pet.attack += bonusStats['attack']!;
      pet.defense += bonusStats['defense']!;
      pet.speed += bonusStats['speed']!;

      // レベルアップコールバック実行
      onLevelUp?.call(pet.level);
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

  // === ヘルパーメソッド（他サービスから使用） ===

  /// ペットをIDで取得
  static Future<PetModel?> getPetById(String petId) async {
    await init();
    return _box!.get(petId);
  }

  /// ペットのステータスを更新
  static Future<void> updatePetStats(
    String petId, {
    int? attack,
    int? defense,
    int? speed,
    int? hp,
  }) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return;

    if (attack != null) pet.attack = attack;
    if (defense != null) pet.defense = defense;
    if (speed != null) pet.speed = speed;
    if (hp != null) pet.hp = hp.clamp(0, 100);

    await pet.save();
  }

  /// ペットのスキルリストを更新
  static Future<void> updatePetSkills(String petId, List<String> skills) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return;

    pet.skills = skills;
    await pet.save();
  }

  /// ペットの任意フィールドを更新（汎用メソッド）
  static Future<void> updatePet(
      String petId, Map<String, dynamic> updates) async {
    await init();
    final pet = _box!.get(petId);
    if (pet == null) return;

    updates.forEach((key, value) {
      switch (key) {
        case 'skillPoints':
          pet.skillPoints = value as int;
          break;
        case 'skillMastery':
          pet.skillMastery = Map<String, int>.from(value as Map);
          break;
        case 'skills':
          pet.skills = List<String>.from(value as List);
          break;
        case 'careMistakes':
          pet.careMistakes = value as int;
          break;
        case 'careQuality':
          pet.careQuality = value as int;
          break;
        case 'discipline':
          pet.discipline = value as int;
          break;
        case 'truePersonality':
          pet.truePersonality = value as String?;
          break;
        case 'trainingStreak':
          pet.trainingStreak = value as int;
          break;
        case 'lastTrainingDate':
          pet.lastTrainingDate = value as DateTime?;
          break;
        case 'equippedWeapon':
          pet.equippedWeapon = value as String?;
          break;
        case 'equippedArmor':
          pet.equippedArmor = value as String?;
          break;
        case 'equippedAccessory':
          pet.equippedAccessory = value as String?;
          break;
      }
    });

    await pet.save();
  }

  /// ペットBoxを取得（直接操作用）
  static Future<Box<PetModel>> getPetsBox() async {
    await init();
    return _box!;
  }

  /// 配合（2体のペットから新しいたまご生成）
  static Future<String> breedPets(String parentId1, String parentId2) async {
    await init();
    final parent1 = _box!.get(parentId1);
    final parent2 = _box!.get(parentId2);

    if (parent1 == null || parent2 == null) return '';
    if (parent1.stage != 'adult' && parent1.stage != 'ultimate') return '';
    if (parent2.stage != 'adult' && parent2.stage != 'ultimate') return '';

    // 配合レシピチェック
    String? recipeSpecies = DexService.checkBreedingRecipe(
      parent1.species,
      parent2.species,
    );

    // 新しいたまご作成
    final egg = recipeSpecies != null
        ? PetModel.createEgg('配合たまご - 特別な予感')
        : PetModel.createEgg('配合たまご');

    // 配合限定種族の場合は種族を設定
    if (recipeSpecies != null) {
      egg.species = recipeSpecies;
    } else {
      // 通常配合：親のどちらかの種族を継承
      egg.species =
          [parent1.species, parent2.species][DateTime.now().millisecond % 2];
    }

    // 親のスキルを継承（ランダムで2-3つ）
    final allSkills = [...parent1.skills, ...parent2.skills];
    allSkills.shuffle();
    final skillCount = recipeSpecies != null ? 3 : 2; // 配合限定は3つ
    egg.skills = allSkills.take(skillCount).toList();

    // ステータスは親の平均値 + ボーナス
    final bonus = recipeSpecies != null ? 1.2 : 1.0;
    egg.attack = ((parent1.attack + parent2.attack) / 2 * bonus).round();
    egg.defense = ((parent1.defense + parent2.defense) / 2 * bonus).round();
    egg.speed = ((parent1.speed + parent2.speed) / 2 * bonus).round();
    egg.hp = ((parent1.hp + parent2.hp) / 2 * bonus).round();

    await _box!.put(egg.id, egg);
    return egg.id;
  }
}
