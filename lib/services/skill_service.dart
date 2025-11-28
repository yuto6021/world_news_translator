import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/skill.dart';

/// スキル管理サービス - ペットのスキル習得・管理
class SkillService {
  static const String _skillKey = 'pet_skills';

  /// ペットのスキル一覧を取得
  static Future<List<String>> getPetSkills(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_skillKey\_$petId');
    if (data == null) return [];

    final List<dynamic> decoded = json.decode(data);
    return decoded.cast<String>();
  }

  /// スキルを習得
  static Future<bool> learnSkill(String petId, String skillId) async {
    final skills = await getPetSkills(petId);

    if (skills.contains(skillId)) {
      return false; // 既に習得済み
    }

    // スキル数上限チェック（最大10個）
    if (skills.length >= 10) {
      return false;
    }

    skills.add(skillId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_skillKey\_$petId', json.encode(skills));
    return true;
  }

  /// スキルを忘れる
  static Future<bool> forgetSkill(String petId, String skillId) async {
    final skills = await getPetSkills(petId);

    if (!skills.contains(skillId)) {
      return false;
    }

    skills.remove(skillId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_skillKey\_$petId', json.encode(skills));
    return true;
  }

  /// スキル詳細リストを取得
  static Future<List<Skill>> getPetSkillDetails(String petId) async {
    final skillIds = await getPetSkills(petId);
    final List<Skill> skills = [];

    for (final id in skillIds) {
      final skill = Skill.getSkillById(id);
      if (skill != null) {
        skills.add(skill);
      }
    }

    return skills;
  }

  /// パッシブスキルの効果を取得
  static Future<Map<String, double>> getPassiveEffects(String petId) async {
    final skills = await getPetSkillDetails(petId);
    final Map<String, double> totalEffects = {};

    for (final skill in skills) {
      if (skill.type == SkillType.passive) {
        skill.effects.forEach((key, value) {
          if (value is num) {
            totalEffects[key] = (totalEffects[key] ?? 0.0) + value.toDouble();
          }
        });
      }
    }

    return totalEffects;
  }

  /// アクティブスキル使用可能かチェック
  static Future<bool> canUseActiveSkill(
    String petId,
    String skillId,
    int currentStamina,
  ) async {
    final skill = Skill.getSkillById(skillId);
    if (skill == null || skill.type != SkillType.active) {
      return false;
    }

    // スタミナチェック
    if (currentStamina < skill.manaCost) {
      return false;
    }

    // クールダウンチェック
    final lastUsed = await _getSkillLastUsed(petId, skillId);
    if (lastUsed != null) {
      final now = DateTime.now();
      final diff = now.difference(lastUsed).inSeconds;
      // クールダウン1ターン = 30秒として計算（簡易実装）
      if (diff < skill.cooldown * 30) {
        return false;
      }
    }

    return true;
  }

  /// スキル使用記録
  static Future<void> recordSkillUse(String petId, String skillId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'skill_use_$petId\_$skillId',
      DateTime.now().toIso8601String(),
    );
  }

  /// スキル最終使用時刻を取得
  static Future<DateTime?> _getSkillLastUsed(
      String petId, String skillId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('skill_use_$petId\_$skillId');
    if (data == null) return null;
    return DateTime.parse(data);
  }

  /// レベルアップ時に習得可能なスキルをチェック
  static Future<List<Skill>> checkLearnableSkills(
      String petId, int level) async {
    final currentSkills = await getPetSkills(petId);
    final learnable = Skill.getLearnableSkills(level);

    return learnable
        .where((skill) => !currentSkills.contains(skill.id))
        .toList();
  }

  /// アイテム使用でスキル習得
  static Future<bool> learnSkillFromItem(
    String petId,
    String itemId,
  ) async {
    // スキルブック使用
    if (itemId == 'skill_book') {
      // ランダムで習得可能なスキルを1つ選ぶ
      final allSkills = Skill.predefinedSkills
          .where((s) => s.requiredItem == 'skill_book')
          .toList();

      if (allSkills.isEmpty) return false;

      final currentSkills = await getPetSkills(petId);
      final unlearned =
          allSkills.where((s) => !currentSkills.contains(s.id)).toList();

      if (unlearned.isEmpty) return false;

      unlearned.shuffle();
      return await learnSkill(petId, unlearned.first.id);
    }

    return false;
  }

  /// スキル一覧をクリア（デバッグ用）
  static Future<void> clearSkills(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_skillKey\_$petId');
  }

  /// 統計情報取得
  static Future<Map<String, int>> getSkillStats(String petId) async {
    final skills = await getPetSkillDetails(petId);

    return {
      'total': skills.length,
      'passive': skills.where((s) => s.type == SkillType.passive).length,
      'active': skills.where((s) => s.type == SkillType.active).length,
      'attack': skills.where((s) => s.category == SkillCategory.attack).length,
      'defense':
          skills.where((s) => s.category == SkillCategory.defense).length,
      'support':
          skills.where((s) => s.category == SkillCategory.support).length,
      'special':
          skills.where((s) => s.category == SkillCategory.special).length,
    };
  }
}
