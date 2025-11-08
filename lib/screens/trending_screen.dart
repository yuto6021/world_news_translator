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
    setState(() => _initialLoading = true);
    try {
      final articles =
          await NewsApiService.fetchTrendingArticles(null, _currentPage);
      // オフラインキャッシュへ保存
      await OfflineService.instance.upsertArticles(articles);
      await _processAndAppend(articles);
      if (articles.length < NewsApiService.pageSize) _endReached = true;
    } catch (e) {
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
    Color color;
    String label;
    if (importance >= 0.8) {
      color = Colors.red.shade600;
      label = '重要';
    } else if (importance >= 0.6) {
      color = Colors.orange.shade600;
      label = '注目';
    } else if (importance >= 0.4) {
      color = Colors.blue.shade600;
      label = '一般';
    } else if (importance >= 0.2) {
      color = Colors.green.shade600;
      label = '参考';
    } else {
      color = Colors.grey.shade600;
      label = 'その他';
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

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => const NewsCardSkeleton(),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.public),
              const SizedBox(width: 8),
              const Text('Global trending'),
              const Spacer(),
              if (_refreshing)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _entries.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, idx) {
                if (idx >= _entries.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final entry = _entries[idx];
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
                                'ムード: ${entry.insight.analysis?.mood ?? 'N/A'}',
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
}
