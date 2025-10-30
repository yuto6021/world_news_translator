import 'package:flutter/material.dart';
import '../models/article.dart';
// url_launcher not used here; open article in-app detail screen instead
import '../screens/article_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HeadlineBanner extends StatelessWidget {
  final Article article;
  final String translatedText;

  const HeadlineBanner(
      {super.key, required this.article, required this.translatedText});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article)),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.indigo.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage != null)
              Hero(
                tag: article.url,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: article.urlToImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(height: 200, color: Colors.grey.shade200),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                      // gradient overlay for readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.indigo.withOpacity(0.2)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(
              translatedText,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
