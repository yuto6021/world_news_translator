import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../services/translation_service.dart';
import '../services/offline_service.dart';
import '../widgets/news_card.dart';
import '../widgets/headline_banner.dart';
import '../widgets/news_card_skeleton.dart';
import '../models/article.dart';
import '../services/wikipedia_service.dart';
import '../screens/article_detail_screen.dart';

class CountryNewsScreen extends StatefulWidget {
  final String countryCode;
  final String countryName;

  const CountryNewsScreen(
      {super.key, required this.countryCode, required this.countryName});

  @override
  State<CountryNewsScreen> createState() => _CountryNewsScreenState();
}

class _CountryNewsScreenState extends State<CountryNewsScreen> {
  late Future<List<Article>> _articles;
  // 翻訳済みテキストの Future（並列で取得）
  Future<List<String>>? _translationsFuture;
  bool _isOffline = false;

  // 追加UI用の状態
  String? _topicFilter;
  List<String> _topKeywords = [];
  List<int> _relatedIdx = [];
  Future<String?>? _countrySummaryFuture;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    _articles = NewsApiService.fetchArticlesByCountry(widget.countryCode)
        .then((articles) async {
      // オフラインキャッシュへ保存
      await OfflineService.instance.upsertArticles(articles);
      _isOffline = false;
      _prepareEnhancements(articles);
      return articles;
    }).catchError((error) async {
      // ネット失敗時はローカルキャッシュから復元
      _isOffline = true;
      final cached = await OfflineService.instance.getArticles(limit: 20);
      _prepareEnhancements(cached);
      return cached;
    });

    // 記事一覧取得後に翻訳を並列で走らせる
    _translationsFuture = _articles.then((articles) {
      // 翻訳する本文が無ければタイトルを代わりに翻訳する
      final futures = articles.map((a) {
        final textForTranslation =
            (a.description != null && a.description!.trim().isNotEmpty)
                ? a.description!
                : a.title;
        return TranslationService.translateToJapanese(textForTranslation);
      }).toList();
      return Future.wait(futures);
    });
    // 国の概要（Wikipedia）を取得（初回のみ作成）
    _countrySummaryFuture ??= WikipediaService.getSummary(widget.countryName);
  }

  void _prepareEnhancements(List<Article> articles) {
    if (articles.isEmpty) return;
    // トップ記事に対する関連記事抽出とトップキーワード抽出
    final first = articles.first;
    final related = <int>[];
    final firstTokens =
        _tokenize(first.title) + _tokenize(first.description ?? '');
    final firstSet = firstTokens.toSet();

    final freq = <String, int>{};
    for (int i = 0; i < articles.length; i++) {
      final a = articles[i];
      if (i != 0) {
        final tokens = (_tokenize(a.title) + _tokenize(a.description ?? ''));
        final overlap = tokens.where(firstSet.contains).toSet();
        if (overlap.length >= 2) {
          related.add(i);
        }
      }
      for (final t in _tokenize(a.title) + _tokenize(a.description ?? '')) {
        freq[t] = (freq[t] ?? 0) + 1;
      }
    }
    // 上位キーワード抽出（汎用語は除外）
    final stop = _stopwords;
    final sorted = freq.entries
        .where((e) => !stop.contains(e.key) && e.key.length >= 3)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _relatedIdx = related.take(10).toList();
      _topKeywords = sorted.take(8).map((e) => e.key).toList();
    });
  }

  List<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final parts = lower.split(RegExp(r'[^a-z0-9]+'));
    return parts.where((p) => p.isNotEmpty).toList();
  }

  Set<String> get _stopwords => {
        'the',
        'and',
        'for',
        'with',
        'from',
        'that',
        'this',
        'have',
        'has',
        'will',
        'says',
        'after',
        'over',
        'into',
        'amid',
        'new',
        'more',
        'than',
        'its',
        'not',
        'are',
        'was',
        'were',
        'been',
        'their',
        'them',
        'they',
        'you',
        'your',
        'our',
        'may',
        'can',
        'how',
        'why',
        'what',
        'when',
        'where',
        'who',
        'said',
        'saying',
        'say'
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.countryName.toUpperCase()}のニュース'),
        actions: [
          if (_isOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Chip(
                avatar: Icon(Icons.wifi_off, size: 16),
                label: Text('オフライン', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.orange,
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Article>>(
        future: _articles,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const NewsCardSkeleton(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('記事が見つかりませんでした'));
          }

          final articles = snapshot.data!;
          // 翻訳を待つ FutureBuilder
          return FutureBuilder<List<String>>(
            future: _translationsFuture,
            builder: (context, tSnapshot) {
              final translations = tSnapshot.data;
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadArticles();
                  });
                  await _articles;
                  await (_translationsFuture ?? Future.value([]));
                },
                child: Builder(builder: (context) {
                  // フィルタ適用後の可視インデックス（先頭バナーは別枠）
                  final visibleIdx = <int>[];
                  for (int i = 1; i < articles.length; i++) {
                    if (_topicFilter == null) {
                      visibleIdx.add(i);
                    } else {
                      final a = articles[i];
                      final text = ((a.title + ' ' + (a.description ?? '')))
                          .toLowerCase();
                      if (text.contains(_topicFilter!.toLowerCase())) {
                        visibleIdx.add(i);
                      }
                    }
                  }

                  return ListView.builder(
                    itemCount: 1 + visibleIdx.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // ヘッダー部（バナー＋追加セクション）
                        final firstArticle = articles[0];
                        final firstTranslation =
                            translations != null && translations.isNotEmpty
                                ? translations[0]
                                : (tSnapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? '翻訳中...'
                                    : '（翻訳なし）');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HeadlineBanner(
                                article: firstArticle,
                                translatedText: firstTranslation),
                            const SizedBox(height: 12),
                            if (_topKeywords.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.local_offer,
                                        color: Colors.indigo),
                                    title: const Text('関連トピック'),
                                    trailing: _topicFilter != null
                                        ? TextButton.icon(
                                            onPressed: () => setState(
                                                () => _topicFilter = null),
                                            icon: const Icon(Icons.clear,
                                                size: 18),
                                            label: const Text('クリア'),
                                          )
                                        : null,
                                    childrenPadding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _topKeywords
                                            .map((k) => FilterChip(
                                                  label: Text(k),
                                                  selected: _topicFilter == k,
                                                  onSelected: (_) => setState(
                                                      () => _topicFilter = k),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (_countrySummaryFuture != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: FutureBuilder<String?>(
                                  future: _countrySummaryFuture,
                                  builder: (context, s) {
                                    if (s.connectionState !=
                                            ConnectionState.done ||
                                        !s.hasData ||
                                        s.data == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: ExpansionTile(
                                        leading: const Icon(Icons.flag,
                                            color: Colors.indigo),
                                        title: Text('${widget.countryName}の概要'),
                                        childrenPadding:
                                            const EdgeInsets.fromLTRB(
                                                16, 0, 16, 16),
                                        children: [
                                          Text(
                                            s.data!,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (_relatedIdx.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.link,
                                        color: Colors.indigo),
                                    title: const Text('関連記事'),
                                    children: [
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 170,
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (context, i) {
                                            final idx = _relatedIdx[i];
                                            if (idx < 0 ||
                                                idx >= articles.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final a = articles[idx];
                                            return SizedBox(
                                              width: 240,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ArticleDetailScreen(
                                                            article: a),
                                                  ),
                                                ),
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      if (a.urlToImage !=
                                                              null &&
                                                          a.urlToImage!
                                                              .isNotEmpty)
                                                        Image.network(
                                                          a.urlToImage!,
                                                          fit: BoxFit.cover,
                                                        )
                                                      else
                                                        Container(
                                                            color: Colors
                                                                .grey.shade200),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                            colors: [
                                                              Colors
                                                                  .transparent,
                                                              Colors.black
                                                                  .withOpacity(
                                                                      0.55),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: 10,
                                                        right: 10,
                                                        bottom: 10,
                                                        child: Text(
                                                          a.title,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            shadows: [
                                                              Shadow(
                                                                  color: Colors
                                                                      .black54,
                                                                  blurRadius: 3,
                                                                  offset:
                                                                      Offset(0,
                                                                          1)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 12),
                                          itemCount: _relatedIdx.length,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }

                      // 通常のニュースカード（フィルタ適用後）
                      final realIdx = visibleIdx[index - 1];
                      final article = articles[realIdx];
                      final translated = (translations != null &&
                              translations.length > realIdx)
                          ? translations[realIdx]
                          : (tSnapshot.connectionState ==
                                  ConnectionState.waiting
                              ? '翻訳中...'
                              : '（翻訳なし）');
                      return NewsCard(
                          article: article, translatedText: translated);
                    },
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }
}
