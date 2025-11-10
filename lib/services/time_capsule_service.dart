import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/news_insight.dart';

class TimeCapsuleService {
  static final TimeCapsuleService instance = TimeCapsuleService._();
  TimeCapsuleService._() {
    _loadCapsules();
  }

  static const _prefsKey = 'time_capsules_v1';

  // 保存された記事とその解禁日時のマップ
  final ValueNotifier<Map<String, NewsInsight>> capsules = ValueNotifier({});

  // 記事をタイムカプセルに保存
  // unlockDate: この日時以降に記事が表示可能になる
  Future<void> addToCapsule(NewsInsight news, DateTime unlockDate) async {
    final map = Map<String, NewsInsight>.from(capsules.value);
    final newsWithDate = NewsInsight(
      title: news.title,
      description: news.description,
      url: news.url,
      urlToImage: news.urlToImage,
      analysis: news.analysis,
      savedForLater: unlockDate,
    );
    map[news.url] = newsWithDate;
    capsules.value = map;
    await _saveCapsules();

    // タイムカプセル使用実績を記録
    await _recordTimeCapsuleUsed();
  }

  Future<void> _recordTimeCapsuleUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('time_capsule_used', true);
    } catch (_) {
      // エラー無視
    }
  }

  // 指定したURLの記事をタイムカプセルから削除
  Future<void> removeFromCapsule(String url) async {
    final map = Map<String, NewsInsight>.from(capsules.value);
    map.remove(url);
    capsules.value = map;
    await _saveCapsules();
  }

  // 現時点で読めるようになっている記事のみを返す
  List<NewsInsight> getUnlockedNews() {
    final now = DateTime.now();
    return capsules.value.values
        .where((news) => news.savedForLater?.isBefore(now) ?? false)
        .toList();
  }

  // まだ読めない記事のみを返す（残り時間でソート）
  List<NewsInsight> getLockedNews() {
    final now = DateTime.now();
    return capsules.value.values
        .where((news) => news.savedForLater?.isAfter(now) ?? false)
        .toList()
      ..sort(
          (a, b) => (a.savedForLater ?? now).compareTo(b.savedForLater ?? now));
  }

  // 指定した記事までの残り時間を計算
  Duration? getTimeUntilUnlock(NewsInsight news) {
    if (news.savedForLater == null) return null;
    final now = DateTime.now();
    if (news.savedForLater!.isBefore(now)) return Duration.zero;
    return news.savedForLater!.difference(now);
  }

  Future<void> _loadCapsules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(raw);
      final map = {
        for (var item in decoded)
          (item['url'] as String): NewsInsight.fromJson(item)
      };
      capsules.value = map;
    } catch (e) {
      debugPrint('Error loading time capsules: $e');
    }
  }

  Future<void> _saveCapsules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = capsules.value.values.map((news) => news.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving time capsules: $e');
    }
  }
}
