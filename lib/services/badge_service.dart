import 'package:shared_preferences/shared_preferences.dart';

/// バッジ管理サービス（統計画面の獲得バッジとは別管理）
class BadgeService {
  static const String _badgesKey = 'unlocked_badges';

  /// バッジを解除
  static Future<void> unlockBadge(String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList(_badgesKey) ?? [];
    
    if (!badges.contains(emoji)) {
      badges.add(emoji);
      await prefs.setStringList(_badgesKey, badges);
    }
  }

  /// 複数バッジを解除
  static Future<void> unlockBadges(List<String> emojis) async {
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList(_badgesKey) ?? [];
    
    bool changed = false;
    for (final emoji in emojis) {
      if (!badges.contains(emoji)) {
        badges.add(emoji);
        changed = true;
      }
    }
    
    if (changed) {
      await prefs.setStringList(_badgesKey, badges);
    }
  }

  /// 解除済みバッジ一覧取得
  static Future<List<String>> getUnlockedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_badgesKey) ?? [];
  }

  /// バッジが解除済みか確認
  static Future<bool> isBadgeUnlocked(String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList(_badgesKey) ?? [];
    return badges.contains(emoji);
  }

  /// 全バッジリセット（デバッグ用）
  static Future<void> resetAllBadges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_badgesKey);
  }
}
