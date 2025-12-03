import '../services/pet_service.dart';
import '../services/inventory_service.dart';
import '../services/skill_service.dart';
import '../models/game_item.dart';
import '../models/skill.dart';

/// アイテム効果適用サービス
class ItemEffectService {
  /// アイテム使用処理
  static Future<ItemUseResult> useItem(String itemId, String petId) async {
    final item = GameItems.getItemById(itemId);
    if (item == null) {
      return ItemUseResult(success: false, message: 'アイテムが見つかりません');
    }

    // 所持チェック
    final hasItem = await InventoryService.hasItem(itemId);
    if (!hasItem) {
      return ItemUseResult(success: false, message: 'アイテムを持っていません');
    }

    // カテゴリ別処理
    switch (item.category) {
      case 'consumables':
        return await _useConsumable(item, petId);
      case 'equipment':
        return ItemUseResult(
          success: false,
          message: '装備は自動適用されます',
        );
      case 'rare':
        return await _useRareItem(item, petId);
      default:
        return ItemUseResult(success: false, message: '使用できません');
    }
  }

  /// 消費アイテム使用
  static Future<ItemUseResult> _useConsumable(
      GameItem item, String petId) async {
    final pet = await PetService.getActivePet();
    if (pet == null) {
      return ItemUseResult(success: false, message: 'ペットが見つかりません');
    }

    String message = '';

    switch (item.id) {
      case 'food':
        await PetService.feedPet(petId);
        message = 'お腹+30、機嫌+5';
        break;

      case 'candy':
        // 特別な効果（機嫌大幅UP）
        await PetService.playWithPet(petId, 'special');
        message = '機嫌+40！超ご機嫌！';
        break;

      case 'medicine':
        if (pet.isSick) {
          await PetService.giveMedicine(petId);
          message = '病気が治りました！';
        } else {
          return ItemUseResult(
            success: false,
            message: '病気ではありません',
            shouldConsume: false,
          );
        }
        break;

      case 'energy_drink':
        // スタミナ回復
        // PetServiceに直接スタミナ更新メソッドがないので、間接的に回復
        await PetService.playWithPet(petId, 'rest'); // 仮実装
        message = 'スタミナ+50回復！';
        break;

      case 'revival_medicine':
        if (!pet.isAlive) {
          // 復活処理（PetServiceに復活メソッドがないので仮実装）
          message = '復活しました！（未実装）';
          return ItemUseResult(success: false, message: message);
        } else {
          return ItemUseResult(
            success: false,
            message: '元気です',
            shouldConsume: false,
          );
        }

      case 'toy':
        await PetService.playWithPet(petId, 'toy');
        message = '楽しく遊びました！機嫌+20';
        break;

      case 'bath_set':
        await PetService.cleanPet(petId);
        message = 'ピカピカになりました！';
        break;

      case 'breeding_supplement':
        message = '配合時に効果を発揮します';
        // 実際の効果は配合時に適用
        break;

      default:
        return ItemUseResult(success: false, message: '使用方法不明');
    }

    // アイテム消費
    await InventoryService.removeItem(item.id, quantity: 1);
    return ItemUseResult(success: true, message: message);
  }

  /// レアアイテム使用
  static Future<ItemUseResult> _useRareItem(GameItem item, String petId) async {
    final pet = await PetService.getActivePet();
    if (pet == null) {
      return ItemUseResult(success: false, message: 'ペットが見つかりません');
    }

    String message = '';

    switch (item.id) {
      case 'evolution_stone':
        // 進化条件を緩和してチェック
        final evolutions = await PetService.getAvailableEvolutions(petId);

        // 通常の進化先がない場合でも、ステージに応じたデフォルト進化先を提供
        List<String> availableEvolutions = evolutions;
        if (availableEvolutions.isEmpty) {
          // ステージ別デフォルト進化先
          if (pet.stage == 'egg') {
            availableEvolutions = ['koromon', 'tsunomon'];
          } else if (pet.stage == 'baby') {
            availableEvolutions = ['agumon', 'gabumon', 'patamon'];
          } else if (pet.stage == 'child') {
            availableEvolutions = ['greymon', 'garurumon', 'angemon'];
          } else if (pet.stage == 'adult') {
            availableEvolutions = ['metalgreymon', 'weregarurumon'];
          } else {
            return ItemUseResult(
              success: false,
              message: 'これ以上進化できません',
              shouldConsume: false,
            );
          }
        }

        // 最初の進化先に強制進化
        await PetService.evolvePet(petId, availableEvolutions.first);
        message = '${availableEvolutions.first}に進化しました！';
        break;

      case 'exp_potion_s':
        await PetService.addExp(petId, 100);
        message = '経験値+100獲得！';
        break;

      case 'exp_potion_m':
        await PetService.addExp(petId, 500);
        message = '経験値+500獲得！';
        break;

      case 'exp_potion_l':
        await PetService.addExp(petId, 2000);
        message = '経験値+2000獲得！';
        break;

      case 'skill_book':
        // 取得前後で差分をとり、PetModelにも同期
        final before = await SkillService.getPetSkills(petId);
        final learned = await SkillService.learnSkillFromItem(petId, item.id);
        if (learned) {
          final after = await SkillService.getPetSkills(petId);
          // Hive上のペットにも同期してUI反映
          await PetService.updatePetSkills(petId, after);

          // どのスキルか特定してメッセージに表示
          final gained = after.firstWhere(
            (id) => !before.contains(id),
            orElse: () => '',
          );
          final gainedSkill =
              gained.isNotEmpty ? Skill.getSkillById(gained) : null;
          message = gainedSkill != null
              ? '新しいスキル「${gainedSkill.name}」を覚えました！'
              : '新しいスキルを覚えました！';
        } else {
          // より詳細なエラーメッセージ
          final currentSkills = await SkillService.getPetSkills(petId);
          if (currentSkills.length >= 10) {
            return ItemUseResult(
              success: false,
              message: 'スキル枠が満杯です（最大10個）',
              shouldConsume: false,
            );
          }
          return ItemUseResult(
            success: false,
            message: '全てのスキルを習得済みです',
            shouldConsume: false,
          );
        }
        break;

      case 'friendship_badge':
        // 親密度アップ（PetServiceに親密度更新メソッド必要）
        message = '親密度が上がりました！（未実装）';
        return ItemUseResult(success: false, message: message);

      case 'gacha_ticket':
        message = 'ガチャ画面で使用してください';
        return ItemUseResult(
            success: false, message: message, shouldConsume: false);

      case 'lucky_charm':
        message = '装備すると効果を発揮します';
        return ItemUseResult(
            success: false, message: message, shouldConsume: false);

      case 'battle_pass':
        message = 'バトル報酬アップ（自動適用）';
        return ItemUseResult(
            success: false, message: message, shouldConsume: false);

      case 'rainbow_feather':
        message = '特別な進化に必要なアイテムです';
        return ItemUseResult(
            success: false, message: message, shouldConsume: false);

      case 'dark_fragment':
        message = '闇の力を秘めた破片...何かに使えそう';
        return ItemUseResult(
            success: false, message: message, shouldConsume: false);

      case 'time_capsule':
        message = 'タイムカプセル画面で使用してください';
        return ItemUseResult(
            success: false, message: message, shouldConsume: false);

      default:
        return ItemUseResult(success: false, message: '使用方法不明');
    }

    // アイテム消費
    await InventoryService.removeItem(item.id, quantity: 1);
    return ItemUseResult(success: true, message: message);
  }

  /// 装備アイテムの効果を計算
  static Future<Map<String, int>> getEquipmentBonus(String petId) async {
    final inventory = await InventoryService.getInventory();
    final Map<String, int> bonus = {
      'attack': 0,
      'defense': 0,
      'speed': 0,
      'maxHp': 0,
      'critRate': 0,
      'expRate': 0,
    };

    for (final entry in inventory.entries) {
      final item = GameItems.getItemById(entry.key);
      if (item != null && item.category == 'equipment' && entry.value > 0) {
        item.stats?.forEach((key, value) {
          bonus[key] = (bonus[key] ?? 0) + (value as int);
        });
      }
    }

    return bonus;
  }

  /// バトル報酬倍率を取得
  static Future<double> getBattleRewardMultiplier() async {
    double multiplier = 1.0;

    // バトルパス所持チェック
    if (await InventoryService.hasItem('battle_pass')) {
      multiplier += 0.5;
    }

    // ラッキーチャーム所持チェック
    if (await InventoryService.hasItem('lucky_charm')) {
      multiplier += 0.3;
    }

    return multiplier;
  }

  /// アイテムドロップ率ボーナス取得
  static Future<double> getDropRateBonus() async {
    double bonus = 0.0;

    // ラッキーチャーム
    if (await InventoryService.hasItem('lucky_charm')) {
      bonus += 0.2;
    }

    return bonus;
  }
}

/// アイテム使用結果
class ItemUseResult {
  final bool success;
  final String message;
  final bool shouldConsume;

  ItemUseResult({
    required this.success,
    required this.message,
    this.shouldConsume = true,
  });
}
