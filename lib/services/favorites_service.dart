import 'package:flutter/foundation.dart';
import '../models/article.dart';

class FavoritesService {
  FavoritesService._privateConstructor();
  static final FavoritesService instance =
      FavoritesService._privateConstructor();

  // Map of url -> Article so we can show favorited articles later
  final ValueNotifier<Map<String, Article>> favorites = ValueNotifier({});

  bool isFavorite(String url) => favorites.value.containsKey(url);

  void toggleFavorite(Article article) {
    final map = Map<String, Article>.from(favorites.value);
    if (map.containsKey(article.url)) {
      map.remove(article.url);
    } else {
      map[article.url] = article;
    }
    favorites.value = map;
  }
}
