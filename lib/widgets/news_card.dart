import 'package:flutter/material.dart';
import '../models/article.dart';
// url_launcher not needed here; article opens in-app detail screen
import '../screens/article_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/favorites_service.dart';
import '../services/translation_service.dart';
import '../services/app_settings_service.dart';
import '../services/ui_service.dart';

class NewsCard extends StatefulWidget {
  final Article article;
  final String? translatedText;

  const NewsCard({super.key, required this.article, this.translatedText});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _hovered = false;
  String? _localTranslated;
  bool _loadingTranslation = false;

  @override
  void initState() {
    super.initState();
    // If caller didn't provide a translatedText, fetch one lazily (respecting user settings)
    if ((widget.translatedText == null || widget.translatedText!.isEmpty) &&
        AppSettingsService.instance.autoTranslate.value) {
      _fetchLocalTranslation();
    }
    AppSettingsService.instance.autoTranslate.addListener(() {
      if (AppSettingsService.instance.autoTranslate.value &&
          (widget.translatedText == null || widget.translatedText!.isEmpty) &&
          _localTranslated == null &&
          !_loadingTranslation) {
        _fetchLocalTranslation();
      }
    });
  }

  Future<void> _fetchLocalTranslation() async {
    setState(() => _loadingTranslation = true);
    final textForTranslation = (widget.article.description != null &&
            widget.article.description!.trim().isNotEmpty)
        ? widget.article.description!
        : widget.article.title;
    final t = await TranslationService.translateToJapanese(textForTranslation);
    if (!mounted) return;
    setState(() {
      _localTranslated = t;
      _loadingTranslation = false;
    });
  }

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: widget.article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UIService.instance.hoverEnabled,
      builder: (context, hoverEnabled, _) {
        return MouseRegion(
          onEnter: hoverEnabled ? (_) => setState(() => _hovered = true) : null,
          onExit: hoverEnabled ? (_) => setState(() => _hovered = false) : null,
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _hovered
                  ? [
                      const BoxShadow(
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
                      ClipRRect(
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
                          // 翻訳ステータスバッジ
                          const SizedBox(height: 6),
                          Builder(builder: (ctx) {
                            final effective = (widget.translatedText != null &&
                                    widget.translatedText!.isNotEmpty)
                                ? widget.translatedText
                                : _localTranslated;
                            if (_loadingTranslation) {
                              return Row(children: [
                                Chip(
                                    label: Text('翻訳中...'),
                                    visualDensity: VisualDensity.compact),
                                const SizedBox(width: 6),
                              ]);
                            }
                            if (effective != null) {
                              final isPseudo = effective.contains('簡易翻訳') ||
                                  effective.contains('未翻訳');
                              return Row(children: [
                                Chip(
                                    label: Text(isPseudo ? '簡易訳' : '翻訳済み'),
                                    backgroundColor: isPseudo
                                        ? Colors.orange.shade100
                                        : Colors.green.shade100,
                                    visualDensity: VisualDensity.compact),
                                const SizedBox(width: 6),
                              ]);
                            }
                            return const SizedBox.shrink();
                          }),
                          Text(
                            (widget.translatedText != null &&
                                    widget.translatedText!.isNotEmpty)
                                ? widget.translatedText!
                                : (_localTranslated ??
                                    (_loadingTranslation
                                        ? '翻訳中...'
                                        : '（翻訳なし）')),
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
                                FavoritesService.instance
                                    .toggleFavorite(widget.article);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        // 手動翻訳ボタン: 自動翻訳がオフでも一覧から翻訳を取得できる
                        IconButton(
                          tooltip: '翻訳を取得',
                          icon:
                              const Icon(Icons.translate, color: Colors.indigo),
                          onPressed: _loadingTranslation
                              ? null
                              : () async {
                                  await _fetchLocalTranslation();
                                },
                        ),
                        // クイック要約ボタン（簡易表示）
                        IconButton(
                          tooltip: '要約を見る',
                          icon: const Icon(Icons.subject, color: Colors.indigo),
                          onPressed: () async {
                            final excerpt =
                                (widget.article.description != null &&
                                        widget.article.description!.isNotEmpty)
                                    ? widget.article.description!
                                    : widget.article.title;
                            final short = excerpt.length > 240
                                ? '${excerpt.substring(0, 237)}...'
                                : excerpt;
                            String translated = '';
                            if (AppSettingsService
                                .instance.autoTranslate.value) {
                              translated =
                                  await TranslationService.translateToJapanese(
                                      short);
                            }
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('要約'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(short),
                                      if (translated.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        Text(translated),
                                      ]
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('閉じる')),
                                ],
                              ),
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
