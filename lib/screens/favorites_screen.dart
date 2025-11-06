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
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('お気に入りはまだありません', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home),
                      label: const Text('ホームに戻る'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // まだ永続化していないので単に短時間の待機で刷新とする
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: articles.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final article = articles[idx];
                return Dismissible(
                  key: ValueKey(article.url),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    FavoritesService.instance.toggleFavorite(article);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('お気に入りから削除しました')),
                    );
                  },
                  child: NewsCard(
                    article: article,
                    translatedText: article.description ?? '（翻訳なし）',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
