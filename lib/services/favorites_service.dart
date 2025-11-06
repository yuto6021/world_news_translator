import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class FavoritesService {
  static final FavoritesService instance =
      FavoritesService._privateConstructor();
  FavoritesService._privateConstructor() {
    _loadFromPrefs();
  }

  // Map of url -> Article so we can show favorited articles later
  final ValueNotifier<Map<String, Article>> favorites = ValueNotifier({});

  static const _prefsKey = 'favorites_v1';

  // load persisted favorites asynchronously
  void _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final map = decoded.map((k, v) =>
          MapEntry(k, Article.fromJson(Map<String, dynamic>.from(v))));
      favorites.value = Map<String, Article>.from(map);
    } catch (_) {
      // ignore errors and keep defaults
    }
  }

  // persist current favorites
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = favorites.value.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_prefsKey, jsonEncode(encoded));
    } catch (_) {}
  }

  // (constructor placed above)

  bool isFavorite(String url) => favorites.value.containsKey(url);

  void toggleFavorite(Article article) {
    final map = Map<String, Article>.from(favorites.value);
    if (map.containsKey(article.url)) {
      map.remove(article.url);
    } else {
      map[article.url] = article;
    }
    favorites.value = map;
    _saveToPrefs();
  }
}
