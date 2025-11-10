import 'package:flutter/material.dart';
import 'dart:async';
import '../services/news_api_service.dart';
import '../services/translation_service.dart';
import '../services/offline_service.dart';
import '../widgets/news_card.dart';
// import '../widgets/headline_banner.dart'; // ユーザー要望により削除
import '../widgets/fx_ticker.dart';
import '../services/market_data_service.dart';
import '../widgets/news_card_skeleton.dart';
import '../models/article.dart';
import '../services/wikipedia_service.dart';
// import '../screens/article_detail_screen.dart'; // 関連記事セクション削除により未使用

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
  // List<int> _relatedIdx = [];
  Future<String?>? _countrySummaryFuture;

  // ティッカー定期更新用
  Timer? _tickerTimer;
  List<String> _tickerItems = ['読み込み中...'];

  // 先頭へボタン用
  final ScrollController _scrollController = ScrollController();
  bool _showTopFab = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _refreshTicker();
    _tickerTimer =
        Timer.periodic(const Duration(minutes: 2), (_) => _refreshTicker());
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.offset;
      final shouldShow = offset > 300;
      if (shouldShow != _showTopFab) {
        setState(() => _showTopFab = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshTicker() async {
    final items =
        await MarketDataService.instance.fetchTickerItems(forceRefresh: true);
    if (mounted) {
      setState(() => _tickerItems = items);
    }
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
    // final first = articles.first; // 関連記事算出を削除したため未使用
    // final related = <int>[]; // 関連記事は非表示化
    // 関連記事機能を削除したため firstTokens/firstSet は不要

    final freq = <String, int>{};
    for (int i = 0; i < articles.length; i++) {
      final a = articles[i];
      // 関連記事の抽出は無効化
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
                    controller: _scrollController, // ScrollControllerを追加
                    itemCount: 1 + visibleIdx.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // 先頭: マルチティッカー + ヒーロー記事 +（USのみ）概要 + 関連トピック
                        final firstArticle = articles.first;
                        final firstTranslation =
                            (translations != null && translations.isNotEmpty)
                                ? translations.first
                                : (tSnapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? '翻訳中...'
                                    : '（翻訳なし）');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // マルチティッカー (USD/JPY + BTC) - タップで手動更新 + 自動2分更新
                              GestureDetector(
                                onTap: () {
                                  _refreshTicker();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ティッカーを更新しました'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.15),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    key: ValueKey(_tickerItems.join()),
                                    height: 44,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.indigo.shade50,
                                          Colors.indigo.shade100,
                                        ],
                                      ),
                                      border: Border.all(
                                          color: Colors.indigo.shade300
                                              .withOpacity(0.6)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 18),
                                        Icon(Icons.trending_flat,
                                            color: Colors.indigo.shade600),
                                        const SizedBox(width: 12),
                                        // 横幅はExpandedで確保し、内部はテキスト1本に連結してスクロール
                                        Expanded(
                                          child: FxTicker(
                                            duration:
                                                const Duration(seconds: 14),
                                            child: Text(
                                              _tickerItems.join('     '),
                                              maxLines: 1,
                                              overflow: TextOverflow.clip,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // ヒーロー記事
                              _buildHeroArticle(firstArticle, firstTranslation),
                              // US概要カード
                              if (widget.countryCode.toLowerCase() == 'us' &&
                                  _countrySummaryFuture != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: FutureBuilder<String?>(
                                    future: _countrySummaryFuture,
                                    builder: (context, s) {
                                      if (s.connectionState !=
                                              ConnectionState.done ||
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
                                          title: const Text('アメリカの概要'),
                                          childrenPadding:
                                              const EdgeInsets.fromLTRB(
                                                  16, 0, 16, 16),
                                          children: [
                                            Text(s.data!,
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              // 関連トピック（USのみ）
                              if (widget.countryCode.toLowerCase() == 'us' &&
                                  _topKeywords.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
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
                                      childrenPadding:
                                          const EdgeInsets.fromLTRB(
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
                              const SizedBox(height: 4),
                            ],
                          ),
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
      floatingActionButton: _showTopFab
          ? FloatingActionButton(
              heroTag: 'countryTopFab',
              tooltip: '先頭へ',
              elevation: 8,
              onPressed: () {
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOut);
              },
              child: const Icon(Icons.vertical_align_top),
            )
          : null,
    );
  }

  Widget _buildHeroArticle(Article a, String translation) {
    final imageUrl = a.urlToImage;
    return Container(
      height: 300,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ))
            else
              Container(
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.image, size: 64)),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('注目',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
