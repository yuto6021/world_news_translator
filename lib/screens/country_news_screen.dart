import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../services/translation_service.dart';
import '../services/offline_service.dart';
import '../widgets/news_card.dart';
// import '../widgets/headline_banner.dart'; // ユーザー要望により削除
import '../services/forex_service.dart';
import '../widgets/fx_ticker.dart';
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
                    itemCount: 1 + visibleIdx.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // 先頭: ドル円ティッカー +（USのみ）概要 + 関連トピック
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ティッカー
                              FutureBuilder<double?>(
                                future: ForexService.getUsdJpy(),
                                builder: (context, fx) {
                                  final rate = fx.data;
                                  final text = rate != null
                                      ? 'USD/JPY: ${rate.toStringAsFixed(3)}'
                                      : 'USD/JPY: 取得失敗';
                                  return Container(
                                    height: 38,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: Colors.indigo.withOpacity(0.12),
                                      border: Border.all(
                                          color: Colors.indigo.shade300
                                              .withOpacity(0.5)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: FxTicker(
                                      duration: const Duration(seconds: 12),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 16),
                                          Icon(Icons.trending_flat,
                                              color: Colors.indigo.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            text,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5),
                                          ),
                                          const SizedBox(width: 32),
                                          Text(
                                            '為替レート (exchangerate.host) | 更新毎回取得',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.indigo.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
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
    );
  }
}
