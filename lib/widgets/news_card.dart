import 'package:flutter/material.dart';
import '../models/article.dart';
// url_launcher not needed here; article opens in-app detail screen
import '../screens/article_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsCard extends StatelessWidget {
  final Article article;
  final String translatedText;

  const NewsCard(
      {super.key, required this.article, required this.translatedText});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: article.urlToImage != null
            ? Hero(
                tag: article.url,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: article.urlToImage!,
                    width: 100,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(width: 100, color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              )
            : null,
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(article: article)),
              );
            },
            child: Text(
              article.title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.indigo,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        subtitle: Text(translatedText),
        trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
      ),
    );
  }
}
