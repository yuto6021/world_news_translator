import 'package:flutter/material.dart';
import '../models/article.dart';
// url_launcher not needed here; article opens in-app detail screen
import '../screens/article_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/favorites_service.dart';
import '../services/ui_service.dart';

class NewsCard extends StatefulWidget {
  final Article article;
  final String translatedText;

  const NewsCard(
      {super.key, required this.article, required this.translatedText});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _hovered = false;

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: widget.article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UIService.instance.hoverEnabled,
      builder: (context, hoverEnabled, _) {
        return MouseRegion(
          onEnter: hoverEnabled
              ? (_) => setState(() => _hovered = true)
              : null,
          onExit: hoverEnabled
              ? (_) => setState(() => _hovered = false)
              : null,
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _openDetail,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    if (widget.article.urlToImage != null)
                      Hero(
                        tag: widget.article.url,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: widget.article.urlToImage!,
                            width: 110,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                                width: 110, color: Colors.grey.shade200),
                            errorWidget: (context, url, error) => Container(
                              width: 110,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article.title,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.indigo,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.translatedText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<Map<String, Article>>(
                          valueListenable: FavoritesService.instance.favorites,
                          builder: (context, map, _) {
                            final isFav = map.containsKey(widget.article.url);
                            return IconButton(
                              tooltip: isFav ? 'お気に入りから外す' : 'お気に入りに追加',
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.redAccent : Colors.grey,
                              ),
                              onPressed: () {
                                FavoritesService.instance.toggleFavorite(widget.article);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right, color: Colors.indigo),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
