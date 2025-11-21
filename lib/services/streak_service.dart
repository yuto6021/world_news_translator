import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  static const _daysKey = 'streak_days'; // List<String> yyyy-MM-dd
  static const _lastKey = 'streak_last_date';
  static const _consecutiveKey = 'consecutive_days';

  Future<void> onAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastStr = prefs.getString(_lastKey);
    var days = prefs.getStringList(_daysKey) ?? <String>[];
    final todayStr = _fmt(today);

    if (!days.contains(todayStr)) {
      days.add(todayStr);
      await prefs.setStringList(_daysKey, days);
    }

    if (lastStr == null) {
      await prefs.setString(_lastKey, todayStr);
      await prefs.setInt(_consecutiveKey, 1);
      return;
    }

    final last = _parse(lastStr);
    final diff = today.difference(last).inDays;
    int cons = prefs.getInt(_consecutiveKey) ?? 1;
    if (diff == 1) {
      cons += 1;
    } else if (diff > 1) {
      cons = 1; // reset
    }
    await prefs.setInt(_consecutiveKey, cons);
    await prefs.setString(_lastKey, todayStr);
  }

  Future<Map<DateTime, int>> getRecentCounts({int daysBack = 56}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_daysKey) ?? <String>[];
    final set = list.toSet();
    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack - 1));
    final data = <DateTime, int>{};
    for (int i = 0; i < daysBack; i++) {
      final d =
          DateTime(start.year, start.month, start.day).add(Duration(days: i));
      data[d] = set.contains(_fmt(d)) ? 1 : 0;
    }
    return data;
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  DateTime _parse(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }
}
