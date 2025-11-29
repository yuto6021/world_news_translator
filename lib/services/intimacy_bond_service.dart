import '../models/pet.dart';
import '../models/skill.dart';
import 'pet_service.dart';

/// 絆レベルサービス - 親密度を5段階に区分し各段階で特典解放
class IntimacyBondService {
  /// 絆レベルの定義（親密度による段階分け）
  static const bondLevels = [
    {
      'level': 1,
      'name': '知り合い',
      'minIntimacy': 0,
      'maxIntimacy': 19,
      'icon': '👋',
      'description': '出会ったばかり',
      'bonus': {'attack': 0, 'defense': 0, 'speed': 0},
      'skills': <String>[],
    },
    {
      'level': 2,
      'name': '仲間',
      'minIntimacy': 20,
      'maxIntimacy': 39,
      'icon': '🤝',
      'description': '信頼関係が芽生える',
      'bonus': {'attack': 5, 'defense': 5, 'speed': 5},
      'skills': ['active_heal'], // ヒール解放
    },
    {
      'level': 3,
      'name': '親友',
      'minIntimacy': 40,
      'maxIntimacy': 59,
      'icon': '💙',
      'description': '深い絆で結ばれる',
      'bonus': {'attack': 10, 'defense': 10, 'speed': 10},
      'skills': ['active_shield', 'active_atk_boost'], // シールド・パワーアップ解放
    },
    {
      'level': 4,
      'name': 'ソウルメイト',
      'minIntimacy': 60,
      'maxIntimacy': 79,
      'icon': '💖',
      'description': '心が一つになる',
      'bonus': {'attack': 15, 'defense': 15, 'speed': 15},
      'skills': ['active_speed_boost', 'active_meditation'], // スピードアップ・瞑想解放
    },
    {
      'level': 5,
      'name': '究極の絆',
      'minIntimacy': 80,
      'maxIntimacy': 100,
      'icon': '✨',
      'description': '運命共同体',
      'bonus': {'attack': 25, 'defense': 25, 'speed': 25},
      'skills': ['active_full_heal', 'active_revive'], // フルヒール・リザレクション解放
    },
  ];

  /// 親密度から絆レベルを取得
  static int getBondLevel(int intimacy) {
    for (final level in bondLevels) {
      if (intimacy >= (level['minIntimacy'] as int) &&
          intimacy <= (level['maxIntimacy'] as int)) {
        return level['level'] as int;
      }
    }
    return 1;
  }

  /// 絆レベル情報を取得
  static Map<String, dynamic>? getBondInfo(int intimacy) {
    for (final level in bondLevels) {
      if (intimacy >= (level['minIntimacy'] as int) &&
          intimacy <= (level['maxIntimacy'] as int)) {
        return level;
      }
    }
    return null;
  }

  /// 絆レベルによるステータスボーナス取得
  static Map<String, int> getBondBonus(int intimacy) {
    final info = getBondInfo(intimacy);
    if (info == null) return {'attack': 0, 'defense': 0, 'speed': 0};
    return Map<String, int>.from(info['bonus'] as Map);
  }

  /// 絆レベルで解放されるスキル一覧
  static List<String> getUnlockedSkills(int intimacy) {
    final bondLevel = getBondLevel(intimacy);
    final List<String> allSkills = [];

    for (final level in bondLevels) {
      if ((level['level'] as int) <= bondLevel) {
        allSkills.addAll(List<String>.from(level['skills'] as List));
      }
    }
    return allSkills;
  }

  /// 次の絆レベルまでの必要親密度
  static int? getIntimacyToNextLevel(int currentIntimacy) {
    final currentLevel = getBondLevel(currentIntimacy);
    if (currentLevel >= 5) return null; // 最大レベル

    final nextLevelInfo = bondLevels.firstWhere(
      (l) => (l['level'] as int) == currentLevel + 1,
    );
    return (nextLevelInfo['minIntimacy'] as int) - currentIntimacy;
  }

  /// 絆レベルアップ時の特典メッセージ
  static String? getBondLevelUpMessage(int oldIntimacy, int newIntimacy) {
    final oldLevel = getBondLevel(oldIntimacy);
    final newLevel = getBondLevel(newIntimacy);

    if (newLevel > oldLevel) {
      final info = getBondInfo(newIntimacy);
      if (info != null) {
        final skills = List<String>.from(info['skills'] as List);
        final skillNames = skills
            .map((id) => Skill.getSkillById(id)?.name ?? '')
            .where((n) => n.isNotEmpty)
            .join('、');

        return '絆レベルが ${info['icon']} ${info['name']} になりました！\n'
            'ステータスボーナス: +${(info['bonus'] as Map)['attack']}\n'
            '${skillNames.isNotEmpty ? "新スキル解放: $skillNames" : ""}';
      }
    }
    return null;
  }

  /// ペットの絆レベルに応じたステータス補正を適用
  static Future<Map<String, int>> getEffectiveStats(PetModel pet) async {
    final bonus = getBondBonus(pet.intimacy);
    return {
      'attack': pet.attack + bonus['attack']!,
      'defense': pet.defense + bonus['defense']!,
      'speed': pet.speed + bonus['speed']!,
    };
  }

  /// 絆レベルで解放されたスキルを自動習得
  static Future<void> autoLearnBondSkills(String petId) async {
    final pet = await PetService.getPetById(petId);
    if (pet == null) return;

    final unlockedSkills = getUnlockedSkills(pet.intimacy);
    final currentSkills = pet.skills;

    for (final skillId in unlockedSkills) {
      if (!currentSkills.contains(skillId)) {
        // スキル追加（最大10個まで）
        if (currentSkills.length < 10) {
          currentSkills.add(skillId);
        }
      }
    }

    // スキルリスト更新
    await PetService.updatePetSkills(petId, currentSkills);
  }

  /// 親密度上昇時のチェック（絆レベルアップ判定）
  static Future<String?> checkBondLevelUp(
    String petId,
    int oldIntimacy,
    int newIntimacy,
  ) async {
    final message = getBondLevelUpMessage(oldIntimacy, newIntimacy);
    if (message != null) {
      // 絆スキル自動習得
      await autoLearnBondSkills(petId);
    }
    return message;
  }

  /// 全絆レベル一覧取得（図鑑用）
  static List<Map<String, dynamic>> getAllBondLevels() {
    return List<Map<String, dynamic>>.from(bondLevels);
  }

  /// 絆レベル進捗率（パーセント）
  static double getBondProgress(int intimacy) {
    final info = getBondInfo(intimacy);
    if (info == null) return 100.0;

    final min = info['minIntimacy'] as int;
    final max = info['maxIntimacy'] as int;
    final range = max - min + 1;
    final progress = intimacy - min;

    return (progress / range * 100).clamp(0.0, 100.0);
  }
}
