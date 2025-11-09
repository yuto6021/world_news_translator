import 'package:flutter/material.dart';
import '../models/article.dart';
// url_launcher not needed here; article opens in-app detail screen
import '../screens/article_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/favorites_service.dart';
import '../services/translation_service.dart';
import '../services/app_settings_service.dart';
import '../services/ui_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _visible = false;
  double? _computedImportance; // 再計算された重要度
  String? _mood; // 簡易ムード

  Color _getImportanceColor(double importance) {
    if (importance >= 0.9) return Colors.red.shade700; // 緊急
    if (importance >= 0.7) return Colors.orange.shade700; // 重要
    if (importance >= 0.55) return Colors.amber.shade700; // 注目
    if (importance >= 0.35) return Colors.blue.shade700; // 一般
    return Colors.green.shade700; // 参考
  }

  String _getImportanceLabel(double importance) {
    if (importance >= 0.9) return "緊急";
    if (importance >= 0.7) return "重要";
    if (importance >= 0.55) return "注目";
    if (importance >= 0.35) return "一般";
    return "参考";
  }

  @override
  void initState() {
    super.initState();
    // appearance animation
    _visible = false;
    Future.delayed(
        Duration(milliseconds: 60 + (widget.article.url.hashCode.abs() % 220)),
        () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
    // If caller didn't provide a translatedText, fetch one lazily (respecting user settings)
    if ((widget.translatedText == null || widget.translatedText!.isEmpty) &&
        AppSettingsService.instance.autoTranslate.value) {
      _fetchLocalTranslation();
    }
    _computeImportanceAndMood();
    AppSettingsService.instance.autoTranslate.addListener(() {
      if (AppSettingsService.instance.autoTranslate.value &&
          (widget.translatedText == null || widget.translatedText!.isEmpty) &&
          _localTranslated == null &&
          !_loadingTranslation) {
        _fetchLocalTranslation();
      }
    });
  }

  void _computeImportanceAndMood() {
    final text = (widget.article.description != null &&
            widget.article.description!.trim().isNotEmpty)
        ? widget.article.description!
        : widget.article.title;
    final lower = text.toLowerCase();
    double score = widget.article.importance ?? 0.5;
    // キーワードによる補正
    if (RegExp(r'breaking|urgent|emergency|earthquake|wildfire|crisis')
        .hasMatch(lower)) {
      score += 0.3;
    } else if (RegExp(r'warn|alert|security|inflation|rate hike|policy')
        .hasMatch(lower)) {
      score += 0.15;
    } else if (RegExp(r'celebrate|win|growth|record|innovation|discover')
        .hasMatch(lower)) {
      score += 0.05;
    }
    // 長さ（情報量）
    if (text.length > 160) score += 0.05;
    if (text.length > 300) score += 0.05;
    // 数字（統計・指標）
    final numbers = RegExp(r'\d+').allMatches(text).length;
    if (numbers >= 2) score += 0.05;
    if (numbers >= 5) score += 0.05;
    // 記号（% や $）
    if (text.contains('%')) score += 0.03;
    if (text.contains('\$')) score += 0.0; // no-op safeguard
    if (text.contains('')) score += 0.0; // placeholder
    // ムード推定
    if (RegExp(r'success|win|growth|record|innovation|progress|improve')
        .hasMatch(lower)) {
      _mood = 'positive';
    } else if (RegExp(r'fail|loss|decline|drop|crisis|war|conflict|death')
        .hasMatch(lower)) {
      _mood = 'negative';
    } else if (RegExp(r'breaking|urgent|shock|surge|plunge|spike')
        .hasMatch(lower)) {
      _mood = 'volatile';
    } else {
      _mood = 'neutral';
    }
    _computedImportance = score.clamp(0.0, 1.0);
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
          child: AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.all(8),
              transform: Matrix4.identity()..scale(_hovered ? 1.01 : 1.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _hovered
                    ? const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _openDetail,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: ValueListenableBuilder<String>(
                    valueListenable: UIService.instance.cardMode,
                    builder: (context, cardMode, _) {
                      final hasImage = widget.article.urlToImage != null &&
                          widget.article.urlToImage!.isNotEmpty;
                      return Row(
                        children: [
                          if (hasImage)
                            // 画像をより大きく表示。オーバーレイ表示モードのときのみタイトルを画像上に重ねる。
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 200,
                                height: 130,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: widget.article.urlToImage!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                          color: Colors.grey.shade200),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                    if (cardMode == 'overlay') ...[
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.55),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 10,
                                        right: 10,
                                        bottom: 10,
                                        child: Text(
                                          widget.article.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 3,
                                                  offset: Offset(0, 1)),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          if (hasImage) const SizedBox(width: 12),

                          // Expanded area: either show text block (list mode) or summary (overlay mode)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 重要度 & ムードチップ
                                if (_computedImportance != null) ...[
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildImportanceChip(
                                          _computedImportance!),
                                      _buildMoodChip(_mood),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (cardMode != 'overlay') ...[
                                  Text(
                                    widget.article.title,
                                    style: GoogleFonts.notoSans(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Builder(builder: (ctx) {
                                    final effective = (widget.translatedText !=
                                                null &&
                                            widget.translatedText!.isNotEmpty)
                                        ? widget.translatedText
                                        : _localTranslated;
                                    if (_loadingTranslation) {
                                      return Row(children: [
                                        const Chip(
                                            label: Text('翻訳中...'),
                                            visualDensity:
                                                VisualDensity.compact),
                                        const SizedBox(width: 6),
                                      ]);
                                    }
                                    if (effective != null) {
                                      final isPseudo =
                                          effective.contains('簡易翻訳') ||
                                              effective.contains('未翻訳');
                                      if (!isPseudo) {
                                        return Row(children: [
                                          Chip(
                                              label: const Text('翻訳済み'),
                                              backgroundColor:
                                                  Colors.green.shade100,
                                              visualDensity:
                                                  VisualDensity.compact),
                                          const SizedBox(width: 6),
                                        ]);
                                      }
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
                                ] else ...[
                                  // overlay mode: show short description or source
                                  Text(
                                    Uri.tryParse(widget.article.url)?.host ??
                                        '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    (widget.translatedText != null &&
                                            widget.translatedText!.isNotEmpty)
                                        ? widget.translatedText!
                                        : (_localTranslated ??
                                            (widget.article.description ?? '')),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ]
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // action icons
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<Map<String, Article>>(
                                valueListenable:
                                    FavoritesService.instance.favorites,
                                builder: (context, map, _) {
                                  final isFav =
                                      map.containsKey(widget.article.url);
                                  return ValueListenableBuilder<bool>(
                                    valueListenable:
                                        UIService.instance.expandHitTargets,
                                    builder: (context, expand, _) {
                                      return IconButton(
                                        tooltip:
                                            isFav ? 'お気に入りから外す' : 'お気に入りに追加',
                                        iconSize: expand ? 28 : 22,
                                        padding:
                                            EdgeInsets.all(expand ? 12 : 4),
                                        icon: Icon(
                                          isFav
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFav
                                              ? Colors.redAccent
                                              : Colors.grey,
                                        ),
                                        onPressed: () {
                                          FavoritesService.instance
                                              .toggleFavorite(widget.article);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    UIService.instance.expandHitTargets,
                                builder: (context, expand, _) {
                                  return IconButton(
                                    tooltip: '翻訳を取得',
                                    iconSize: expand ? 28 : 22,
                                    padding: EdgeInsets.all(expand ? 12 : 4),
                                    icon: const Icon(Icons.translate,
                                        color: Colors.indigo),
                                    onPressed: _loadingTranslation
                                        ? null
                                        : () async {
                                            await _fetchLocalTranslation();
                                          },
                                  );
                                },
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    UIService.instance.expandHitTargets,
                                builder: (context, expand, _) {
                                  return IconButton(
                                    tooltip: '要約を見る',
                                    iconSize: expand ? 28 : 22,
                                    padding: EdgeInsets.all(expand ? 12 : 4),
                                    icon: const Icon(Icons.subject,
                                        color: Colors.indigo),
                                    onPressed: () async {
                                      final excerpt =
                                          (widget.article.description != null &&
                                                  widget.article.description!
                                                      .isNotEmpty)
                                              ? widget.article.description!
                                              : widget.article.title;
                                      final short = excerpt.length > 240
                                          ? '${excerpt.substring(0, 237)}...'
                                          : excerpt;
                                      String translated = '';
                                      if (AppSettingsService
                                          .instance.autoTranslate.value) {
                                        translated = await TranslationService
                                            .translateToJapanese(short);
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
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('閉じる')),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              const Icon(Icons.chevron_right,
                                  color: Colors.indigo),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodChip(String? mood) {
    if (mood == null) return const SizedBox.shrink();
    Color base;
    String label;
    switch (mood) {
      case 'positive':
        base = Colors.green.shade600;
        label = '好調';
        break;
      case 'negative':
        base = Colors.red.shade600;
        label = '不調';
        break;
      case 'volatile':
        base = Colors.orange.shade700;
        label = '変動';
        break;
      default:
        base = Colors.blueGrey.shade600;
        label = '中立';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.withOpacity(0.45)),
      ),
      child: Text(label, style: TextStyle(color: base, fontSize: 11)),
    );
  }

  Widget _buildImportanceChip(double importance) {
    Color color = _getImportanceColor(importance);
    String label;
    if (importance >= 0.9) {
      label = '緊急';
    } else if (importance >= 0.7) {
      label = '重要';
    } else if (importance >= 0.55) {
      label = '注目';
    } else if (importance >= 0.35) {
      label = '一般';
    } else {
      label = '参考';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
