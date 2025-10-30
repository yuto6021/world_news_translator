import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../widgets/news_card.dart';
import '../models/article.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お気に入り')),
      body: ValueListenableBuilder<Map<String, Article>>(
        valueListenable: FavoritesService.instance.favorites,
        builder: (context, map, _) {
          final articles = map.values.toList();
          if (articles.isEmpty) {
            return const Center(child: Text('お気に入りはまだありません'));
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, idx) {
              final article = articles[idx];
              return NewsCard(article: article, translatedText: '（翻訳なし）');
            },
          );
        },
      ),
    );
  }
}
