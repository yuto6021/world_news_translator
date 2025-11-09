import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WikipediaHistoryItem {
  final String query;
  final String? summary;
  final DateTime timestamp;

  WikipediaHistoryItem({
    required this.query,
    this.summary,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'query': query,
        'summary': summary,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WikipediaHistoryItem.fromJson(Map<String, dynamic> json) {
    return WikipediaHistoryItem(
      query: json['query'] as String,
      summary: json['summary'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class WikipediaHistoryService {
  static const String _key = 'wikipedia_search_history_v2';
  static const int _maxHistory = 50;

  static Future<List<WikipediaHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((jsonStr) {
          try {
            return WikipediaHistoryItem.fromJson(json.decode(jsonStr));
          } catch (e) {
            return null;
          }
        })
        .whereType<WikipediaHistoryItem>()
        .toList();
  }

  static Future<void> addToHistory(String query, String? summary) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // 既存の同じ検索語を削除（重複排除）
    history.removeWhere((item) => item.query == query);

    // 先頭に追加
    history.insert(0, WikipediaHistoryItem(query: query, summary: summary));

    // 上限を超えた分を削除
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }

    final jsonList = history.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((item) => item.query == query);
    final jsonList = history.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
