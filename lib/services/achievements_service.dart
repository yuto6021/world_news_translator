import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/achievement.dart';

/// 実績管理サービス（Hive使用）
class AchievementsService {
  static const String _boxName = 'achievements';
  static Box<String>? _box;

  /// 初期化
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }
    await _initDefaultAchievements();
  }

  /// デフォルト実績定義
  static Future<void> _initDefaultAchievements() async {
    final defaults = [
      Achievement(
          id: 'reading_30min',
          title: '読書家の第一歩',
          description: '累計30分読書',
          icon: '📖',
          target: 30,
          rarity: AchievementRarity.common),
      Achievement(
          id: 'reading_2hours',
          title: '集中力の証',
          description: '累計2時間読書',
          icon: '📚',
          target: 120,
          rarity: AchievementRarity.rare),
      Achievement(
          id: 'reading_10hours',
          title: '知識の探求者',
          description: '累計10時間読書',
          icon: '🎓',
          target: 600,
          rarity: AchievementRarity.epic),
      Achievement(
          id: 'streak_7',
          title: '1週間連続',
          description: '7日間連続ログイン',
          icon: '🔥',
          target: 7,
          rarity: AchievementRarity.common),
      Achievement(
          id: 'streak_30',
          title: '習慣化マスター',
          description: '30日間連続ログイン',
          icon: '⭐',
          target: 30,
          rarity: AchievementRarity.rare),
      Achievement(
          id: 'streak_100',
          title: '不屈の意志',
          description: '100日間連続ログイン',
          icon: '👑',
          target: 100,
          rarity: AchievementRarity.legendary),
      Achievement(
          id: 'quiz_perfect',
          title: 'クイズマスター',
          description: 'クイズ満点達成',
          icon: '🏆',
          target: 1,
          rarity: AchievementRarity.rare),
      Achievement(
          id: 'quiz_perfect_5',
          title: 'クイズの天才',
          description: 'クイズ満点5回達成',
          icon: '🌟',
          target: 5,
          rarity: AchievementRarity.epic),
      Achievement(
          id: 'comments_10',
          title: '活発な議論',
          description: 'コメント10件投稿',
          icon: '💬',
          target: 10,
          rarity: AchievementRarity.common),
      Achievement(
          id: 'favorites_50',
          title: 'コレクター',
          description: 'お気に入り50件保存',
          icon: '❤️',
          target: 50,
          rarity: AchievementRarity.rare),
      Achievement(
          id: 'snake_20',
          title: 'スネークマスター',
          description: 'スネーク長さ20達成',
          icon: '🐍',
          target: 20,
          rarity: AchievementRarity.rare),
      Achievement(
          id: '2048_512',
          title: '2048チャレンジャー',
          description: '512タイル達成',
          icon: '🎮',
          target: 512,
          rarity: AchievementRarity.epic),
      Achievement(
          id: 'bingo_complete',
          title: 'ビンゴマスター',
          description: 'ビンゴ完成',
          icon: '🎯',
          target: 1,
          rarity: AchievementRarity.rare),
    ];

    final box = _box ?? await Hive.openBox<String>(_boxName);
    for (var a in defaults) {
      if (!box.containsKey(a.id)) {
        await box.put(a.id, jsonEncode(a.toJson()));
      }
    }
  }

  /// 全実績取得
  static Future<List<Achievement>> getAll() async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    return box.values.map((s) => Achievement.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) {
          return a.isUnlocked ? -1 : 1;
        }
        return a.id.compareTo(b.id);
      });
  }

  /// 進捗更新（新規解除の場合はAchievementを返す）
  static Future<Achievement?> updateProgress(
      String id, int progress, int target) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final existing = box.get(id);
    if (existing == null) return null;

    final ach = Achievement.fromJson(jsonDecode(existing));
    final wasLocked = ach.unlockedAt == null;
    final nowUnlocked = progress >= target;

    final updated = ach.copyWith(
      progress: progress,
      target: target,
      unlockedAt: (nowUnlocked && wasLocked) ? DateTime.now() : ach.unlockedAt,
    );
    await box.put(id, jsonEncode(updated.toJson()));

    // 新規解除の場合は実績を返す
    return (wasLocked && nowUnlocked) ? updated : null;
  }

  /// アンロック
  static Future<void> unlock(String id) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final existing = box.get(id);
    if (existing == null) return;

    final ach = Achievement.fromJson(jsonDecode(existing));
    if (ach.isUnlocked) return;

    final updated = ach.copyWith(unlockedAt: DateTime.now());
    await box.put(id, jsonEncode(updated.toJson()));
  }

  /// アンロック済み数
  static Future<int> getUnlockedCount() async {
    final all = await getAll();
    return all.where((a) => a.isUnlocked).length;
  }

  /// シークレット実績を解除（本来のタイトルと説明を設定）
  static Future<void> unlockSecret(String id, String title, String description) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final existing = box.get(id);
    if (existing == null) return;

    final ach = Achievement.fromJson(jsonDecode(existing));
    if (ach.isUnlocked) return;

    final updated = ach.copyWith(
      title: title,
      description: description,
      unlockedAt: DateTime.now(),
    );
    await box.put(id, jsonEncode(updated.toJson()));
  }
}
