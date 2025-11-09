import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/news_api_service.dart';
import '../services/offline_service.dart';
import '../services/translation_service.dart';
import '../services/news_analysis_service.dart';
import '../models/article.dart';
import '../models/news_insight.dart';
import '../screens/article_detail_screen.dart';
import '../widgets/news_card_skeleton.dart';

/// 1件分のトレンド表示用データ（翻訳＋分析済み）
class _TrendingEntry {
  final Article article;
  final String translation;
  final NewsInsight insight;
  final double importance;
  _TrendingEntry({
    required this.article,
    required this.translation,
    required this.insight,
    required this.importance,
  });
}

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});
  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final List<_TrendingEntry> _entries = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _endReached = false;
  bool _refreshing = false;
  String? _errorMessage; // エラーメッセージ保存用

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_endReached || _loadingMore || _initialLoading) return;
    final threshold = 400.0; // 下からどの程度で追加読み込みするか
    if (_scrollController.position.pixels + threshold >=
        _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _errorMessage = null;
    });
    try {
      final articles =
          await NewsApiService.fetchTrendingArticles(null, _currentPage);
      // オフラインキャッシュへ保存
      await OfflineService.instance.upsertArticles(articles);
      await _processAndAppend(articles);
      if (articles.length < NewsApiService.pageSize) _endReached = true;
    } catch (e) {
      // エラーメッセージを保存
      setState(() => _errorMessage = e.toString());

      // ネットワーク失敗時はローカルキャッシュから復元
      final cached = await OfflineService.instance.getArticles(limit: 20);
      if (cached.isNotEmpty) {
        await _processAndAppend(cached);
      }
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_endReached) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final articles =
          await NewsApiService.fetchTrendingArticles(null, nextPage);
      if (articles.isEmpty) {
        _endReached = true;
      } else {
        _currentPage = nextPage;
        await OfflineService.instance.upsertArticles(articles);
        await _processAndAppend(articles);
        if (articles.length < NewsApiService.pageSize) _endReached = true;
      }
    } catch (e) {
      // 追加ロード失敗時はオフライン記事を更に読み込む（ページング風に offset 計算）
      final localNextPage = _currentPage + 1; // ネット失敗でもページ進行を試みる
      final offset = (_currentPage) * NewsApiService.pageSize;
      final cached = await OfflineService.instance
          .getArticles(limit: NewsApiService.pageSize, offset: offset);
      if (cached.isEmpty) {
        _endReached = true;
      } else {
        _currentPage = localNextPage;
        await _processAndAppend(cached);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _processAndAppend(List<Article> articles) async {
    final List<_TrendingEntry> newEntries = [];
    await Future.wait(articles.map((article) async {
      final text = (article.description != null &&
              article.description!.trim().isNotEmpty)
          ? article.description!
          : article.title;
      final analysis = await NewsAnalysisService.instance.analyzeContent(text);
      final translation = await TranslationService.translateToJapanese(text);
      final insight = NewsInsight(
        title: article.title,
        description: article.description,
        url: article.url,
        urlToImage: article.urlToImage,
        analysis: analysis,
      );
      final importance =
          NewsAnalysisService.instance.calculateImportance(insight);
      newEntries.add(_TrendingEntry(
        article: article,
        translation: translation,
        insight: insight,
        importance: importance,
      ));
    }));
    // ソートして追加（重要度降順）
    newEntries.sort((a, b) => b.importance.compareTo(a.importance));
    setState(() => _entries.addAll(newEntries));
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _entries.clear();
      _currentPage = 1;
      _endReached = false;
    });
    await _loadInitial();
    if (mounted) setState(() => _refreshing = false);
  }

  Widget _buildImportanceBadge(double importance) {
    // しきい値を調整して分布を広げる
    Color color;
    String label;
    if (importance >= 0.9) {
      color = Colors.red.shade700;
      label = '緊急';
    } else if (importance >= 0.7) {
      color = Colors.orange.shade700;
      label = '重要';
    } else if (importance >= 0.55) {
      color = Colors.amber.shade700;
      label = '注目';
    } else if (importance >= 0.35) {
      color = Colors.blue.shade700;
      label = '一般';
    } else {
      color = Colors.green.shade700;
      label = '参考';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  String _localizedMood(String? mood) {
    switch ((mood ?? '').toLowerCase()) {
      case 'positive':
        return '好調';
      case 'negative':
        return '不調';
      case 'exciting':
        return '速報';
      case 'cautious':
        return '警戒';
      case 'neutral':
      default:
        return '中立';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => const NewsCardSkeleton(),
      );
    }

    // トップ記事を分離してヒーローセクション化（スクロール内に組み込み）
    final topEntry = _entries.isNotEmpty ? _entries.first : null;
    final restEntries =
        _entries.length > 1 ? _entries.sublist(1) : <_TrendingEntry>[];

    return Column(
      children: [
        // エラーメッセージ表示
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ニュース取得エラー',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (_entries.isNotEmpty)
                  Text(
                    'キャッシュから ${_entries.length} 件の記事を表示中',
                    style:
                        TextStyle(color: Colors.orange.shade700, fontSize: 11),
                  ),
              ],
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: 1 + restEntries.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, idx) {
                // トップ記事ヒーローセクション（インデックス0）
                if (idx == 0) {
                  if (topEntry == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _buildHeroSection(topEntry),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.newspaper, size: 20),
                            const SizedBox(width: 8),
                            Text('最新ニュース',
                                style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            if (_refreshing)
                              const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // ローディングインジケータ
                if (idx > restEntries.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // 通常の記事カード
                final entry = restEntries[idx - 1];
                final article = entry.article;
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: article),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.urlToImage != null &&
                            article.urlToImage!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: article.urlToImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(
                                  height: 120, color: Colors.grey.shade200),
                              errorWidget: (c, u, e) => Container(
                                height: 120,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(child: Icon(Icons.image)),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          article.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.translation,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildImportanceBadge(entry.importance),
                            const SizedBox(width: 8),
                            Text(
                                'ムード: ${_localizedMood(entry.insight.analysis?.mood)}',
                                style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            Text('${(entry.importance * 100).round()}%',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(_TrendingEntry entry) {
    final article = entry.article;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: article),
        ),
      ),
      child: Container(
        height: 380,
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: article.urlToImage!,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey.shade300),
                  errorWidget: (c, u, e) => Container(
                    color: Colors.grey.shade300,
                    child:
                        const Center(child: Icon(Icons.broken_image, size: 64)),
                  ),
                )
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getImportanceColor(entry.importance),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _getImportanceLabel(entry.importance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
                      entry.translation,
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
      ),
    );
  }

  Color _getImportanceColor(double importance) {
    if (importance >= 0.8) return Colors.red.shade700;
    if (importance >= 0.6) return Colors.orange.shade700;
    if (importance >= 0.4) return Colors.blue.shade700;
    if (importance >= 0.2) return Colors.green.shade700;
    return Colors.grey.shade700;
  }

  String _getImportanceLabel(double importance) {
    if (importance >= 0.8) return "重要";
    if (importance >= 0.6) return "注目";
    if (importance >= 0.4) return "一般";
    if (importance >= 0.2) return "参考";
    return "その他";
  }
}
