import '../models/pet.dart';
import 'pet_service.dart';

/// 覚醒システムサービス - 究極体のさらに上の段階
class AwakeningService {
  /// 覚醒条件
  static const awakeningRequirements = {
    'minLevel': 50, // 最低レベル
    'minIntimacy': 80, // 親密度80以上
    'minWins': 50, // 勝利数50以上
    'requiredStage': 'ultimate', // 究極体必須
  };

  /// 覚醒ボーナス
  static const awakeningBonus = {
    'attackMultiplier': 1.5, // 攻撃力1.5倍
    'defenseMultiplier': 1.5, // 防御力1.5倍
    'speedMultiplier': 1.5, // 速さ1.5倍
    'hpBonus': 50, // HP+50
    'newSkillSlots': 5, // スキル枠+5（最大15個）
    'auraColor': '✨', // オーラ表示
  };

  /// 覚醒可能かチェック
  static bool canAwaken(PetModel pet) {
    if (pet.stage != awakeningRequirements['requiredStage']) return false;
    if (pet.level < (awakeningRequirements['minLevel'] as int)) return false;
    if (pet.intimacy < (awakeningRequirements['minIntimacy'] as int)) {
      return false;
    }
    if (pet.wins < (awakeningRequirements['minWins'] as int)) return false;

    // 既に覚醒済みかチェック
    if (pet.evolutionProgress.containsKey('awakened') &&
        pet.evolutionProgress['awakened'] == true) {
      return false;
    }

    return true;
  }

  /// 覚醒実行
  static Future<void> executeAwakening(String petId) async {
    final pet = await PetService.getPetById(petId);
    if (pet == null) throw Exception('ペットが見つかりません');

    if (!canAwaken(pet)) {
      throw Exception('覚醒条件を満たしていません');
    }

    // ステータス大幅強化
    final newAttack =
        (pet.attack * (awakeningBonus['attackMultiplier'] as double)).round();
    final newDefense =
        (pet.defense * (awakeningBonus['defenseMultiplier'] as double)).round();
    final newSpeed =
        (pet.speed * (awakeningBonus['speedMultiplier'] as double)).round();

    await PetService.updatePetStats(
      petId,
      attack: newAttack,
      defense: newDefense,
      speed: newSpeed,
    );

    // 覚醒フラグセット
    final progress = pet.evolutionProgress;
    progress['awakened'] = true;
    progress['awakening_date'] = DateTime.now().toIso8601String();

    // 種族名に「覚醒」を付加
    final awakenedSpecies = '覚醒${pet.species}';

    // 更新を保存
    pet.species = awakenedSpecies;
    pet.evolutionProgress = progress;
    await pet.save();
  }

  /// 覚醒済みかチェック
  static bool isAwakened(PetModel pet) {
    return pet.evolutionProgress.containsKey('awakened') &&
        pet.evolutionProgress['awakened'] == true;
  }

  /// 覚醒ステータスを取得
  static Map<String, dynamic> getAwakeningStatus(PetModel pet) {
    if (!isAwakened(pet)) {
      return {
        'awakened': false,
        'canAwaken': canAwaken(pet),
        'requirements': _getRequirementStatus(pet),
      };
    }

    return {
      'awakened': true,
      'awakeningDate': pet.evolutionProgress['awakening_date'],
      'bonuses': awakeningBonus,
    };
  }

  /// 条件達成状況を取得
  static Map<String, dynamic> _getRequirementStatus(PetModel pet) {
    return {
      'level': {
        'current': pet.level,
        'required': awakeningRequirements['minLevel'],
        'met': pet.level >= (awakeningRequirements['minLevel'] as int),
      },
      'intimacy': {
        'current': pet.intimacy,
        'required': awakeningRequirements['minIntimacy'],
        'met': pet.intimacy >= (awakeningRequirements['minIntimacy'] as int),
      },
      'wins': {
        'current': pet.wins,
        'required': awakeningRequirements['minWins'],
        'met': pet.wins >= (awakeningRequirements['minWins'] as int),
      },
      'stage': {
        'current': pet.stage,
        'required': awakeningRequirements['requiredStage'],
        'met': pet.stage == awakeningRequirements['requiredStage'],
      },
    };
  }

  /// 覚醒オーラエフェクトを取得
  static String getAuraEffect(PetModel pet) {
    if (!isAwakened(pet)) return '';
    return awakeningBonus['auraColor'] as String;
  }

  /// 覚醒による実効ステータスを計算
  static Map<String, int> getEffectiveAwakeningStats(PetModel pet) {
    if (!isAwakened(pet)) {
      return {
        'attack': pet.attack,
        'defense': pet.defense,
        'speed': pet.speed,
      };
    }

    // 覚醒ボーナスは既に適用済みなので、現在値をそのまま返す
    return {
      'attack': pet.attack,
      'defense': pet.defense,
      'speed': pet.speed,
    };
  }

  /// 覚醒可能通知メッセージ
  static String? getAwakeningNotification(PetModel pet) {
    if (isAwakened(pet)) return null;
    if (!canAwaken(pet)) return null;

    return '✨ ${pet.name}は覚醒可能です！\n'
        '究極の力を解放して、さらなる高みへ！';
  }

  /// 覚醒条件の進捗率（0-100%）
  static double getAwakeningProgress(PetModel pet) {
    if (isAwakened(pet)) return 100.0;

    final status = _getRequirementStatus(pet);
    int metCount = 0;
    int totalCount = 4;

    if (status['level']['met'] == true) metCount++;
    if (status['intimacy']['met'] == true) metCount++;
    if (status['wins']['met'] == true) metCount++;
    if (status['stage']['met'] == true) metCount++;

    return (metCount / totalCount * 100);
  }
}
