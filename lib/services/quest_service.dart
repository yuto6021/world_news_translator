import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/quest.dart';
import '../services/inventory_service.dart';
import '../services/pet_service.dart';

/// クエスト管理サービス
class QuestService {
  static const String _progressKey = 'quest_progress';
  static const String _lastResetKey = 'quest_last_reset';

  /// 全クエスト進捗を取得
  static Future<Map<String, QuestProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_progressKey);

    if (data == null) return {};

    final Map<String, dynamic> decoded = json.decode(data);
    return decoded.map((key, value) =>
        MapEntry(key, QuestProgress.fromJson(value as Map<String, dynamic>)));
  }

  /// 特定クエストの進捗を取得
  static Future<QuestProgress> getProgress(String questId) async {
    final allProgress = await getAllProgress();
    return allProgress[questId] ?? QuestProgress(questId: questId);
  }

  /// 進捗を更新
  static Future<void> updateProgress(
    String questId,
    int increment,
  ) async {
    final quest = Quest.getQuestById(questId);
    if (quest == null) return;

    final progress = await getProgress(questId);

    // 既にクリア済みならスキップ
    if (progress.completed) return;

    progress.currentValue += increment;

    // 目標達成チェック
    if (progress.currentValue >= quest.targetValue) {
      progress.currentValue = quest.targetValue;
      progress.completed = true;
      progress.completedAt = DateTime.now();
    }

    await _saveProgress(questId, progress);
  }

  /// 進捗を保存
  static Future<void> _saveProgress(
    String questId,
    QuestProgress progress,
  ) async {
    final allProgress = await getAllProgress();
    allProgress[questId] = progress;

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      allProgress.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_progressKey, encoded);
  }

  /// 報酬を受け取る
  static Future<Map<String, dynamic>> claimReward(String questId) async {
    final quest = Quest.getQuestById(questId);
    if (quest == null) {
      return {'success': false, 'message': 'クエストが見つかりません'};
    }

    final progress = await getProgress(questId);

    if (!progress.completed) {
      return {'success': false, 'message': 'まだクリアしていません'};
    }

    if (progress.rewardClaimed) {
      return {'success': false, 'message': '既に受け取り済みです'};
    }

    // 報酬付与
    if (quest.coinReward > 0) {
      await InventoryService.addCoins(quest.coinReward);
    }

    for (final entry in quest.itemRewards.entries) {
      await InventoryService.addItem(entry.key, quantity: entry.value);
    }

    if (quest.expReward > 0) {
      final pet = await PetService.getActivePet();
      if (pet != null) {
        await PetService.addExp(pet.id, quest.expReward);
      }
    }

    // 受け取り済みにする
    progress.rewardClaimed = true;
    await _saveProgress(questId, progress);

    return {
      'success': true,
      'message': '報酬を受け取りました！',
      'coins': quest.coinReward,
      'items': quest.itemRewards,
      'exp': quest.expReward,
    };
  }

  /// アクション時にクエスト進捗を更新
  static Future<void> trackAction(String actionType) async {
    final allQuests = Quest.predefinedQuests;

    for (final quest in allQuests) {
      if (quest.targetType == actionType) {
        await updateProgress(quest.id, 1);
      }
    }
  }

  /// デイリーリセットチェック
  static Future<void> checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('${_lastResetKey}_daily');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? lastReset;
    if (lastResetStr != null) {
      lastReset = DateTime.parse(lastResetStr);
    }

    // 日付が変わっていたらリセット
    if (lastReset == null || lastReset.isBefore(today)) {
      await _resetQuests(QuestType.daily);
      await prefs.setString('${_lastResetKey}_daily', today.toIso8601String());
    }
  }

  /// ウィークリーリセットチェック
  static Future<void> checkWeeklyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('${_lastResetKey}_weekly');

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

    DateTime? lastReset;
    if (lastResetStr != null) {
      lastReset = DateTime.parse(lastResetStr);
    }

    // 週が変わっていたらリセット
    if (lastReset == null || lastReset.isBefore(thisWeek)) {
      await _resetQuests(QuestType.weekly);
      await prefs.setString(
          '${_lastResetKey}_weekly', thisWeek.toIso8601String());
    }
  }

  /// クエストをリセット
  static Future<void> _resetQuests(QuestType type) async {
    final quests = Quest.getQuestsByType(type);
    final allProgress = await getAllProgress();

    for (final quest in quests) {
      // アチーブメントはリセットしない
      if (quest.type == QuestType.achievement) continue;

      allProgress[quest.id] = QuestProgress(questId: quest.id);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      allProgress.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_progressKey, encoded);
  }

  /// クエスト一覧を取得（フィルタ付き）
  static Future<List<Map<String, dynamic>>> getQuestList({
    QuestType? type,
    int? playerLevel,
  }) async {
    List<Quest> quests = Quest.predefinedQuests;

    if (type != null) {
      quests = quests.where((q) => q.type == type).toList();
    }

    if (playerLevel != null) {
      quests = quests.where((q) => q.requiredLevel <= playerLevel).toList();
    }

    final allProgress = await getAllProgress();

    final List<Map<String, dynamic>> result = [];
    for (final quest in quests) {
      final progress =
          allProgress[quest.id] ?? QuestProgress(questId: quest.id);
      result.add({
        'quest': quest,
        'progress': progress,
        'percentage':
            (progress.currentValue / quest.targetValue * 100).clamp(0, 100),
      });
    }

    return result;
  }

  /// 統計情報取得
  static Future<Map<String, int>> getStats() async {
    final allProgress = await getAllProgress();

    int totalCompleted = 0;
    int dailyCompleted = 0;
    int weeklyCompleted = 0;
    int achievementCompleted = 0;
    int rewardsClaimed = 0;

    for (final entry in allProgress.entries) {
      final quest = Quest.getQuestById(entry.key);
      if (quest == null) continue;

      if (entry.value.completed) {
        totalCompleted++;

        switch (quest.type) {
          case QuestType.daily:
            dailyCompleted++;
            break;
          case QuestType.weekly:
            weeklyCompleted++;
            break;
          case QuestType.achievement:
            achievementCompleted++;
            break;
        }
      }

      if (entry.value.rewardClaimed) {
        rewardsClaimed++;
      }
    }

    return {
      'totalCompleted': totalCompleted,
      'dailyCompleted': dailyCompleted,
      'weeklyCompleted': weeklyCompleted,
      'achievementCompleted': achievementCompleted,
      'rewardsClaimed': rewardsClaimed,
    };
  }

  /// 初期化（デバッグ用）
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove('${_lastResetKey}_daily');
    await prefs.remove('${_lastResetKey}_weekly');
  }
}
