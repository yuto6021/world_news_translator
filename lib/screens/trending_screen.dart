import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../models/article.dart';
import '../screens/article_detail_screen.dart';
// removed unused constants import
import 'package:cached_network_image/cached_network_image.dart';
import '../services/translation_service.dart';
import '../services/news_analysis_service.dart';
import '../models/news_insight.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  late Future<List<Article>> _articles;
  // no country selection; global only for now

  @override
  void initState() {
    super.initState();
    _articles = NewsApiService.fetchTrendingArticles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _articles,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final articles = snapshot.data!;
        // Global トレンド: 各記事に対して翻訳と分析を並列で取得し、重要度でソートして表示
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: const [
                  Icon(Icons.public),
                  SizedBox(width: 8),
                  Text('Global trending'),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _articles = NewsApiService.fetchTrendingArticles();
                  });
                  await _articles;
                },
                child: FutureBuilder<List<dynamic>>(
                  // analysis + translation for each article (use snapshot.data directly)
                  future: Future.wait(articles.map((article) async {
                    final text = (article.description != null &&
                            article.description!.trim().isNotEmpty)
                        ? article.description!
                        : article.title;
                    final analysis =
                        await NewsAnalysisService.instance.analyzeContent(text);
                    final translation =
                        await TranslationService.translateToJapanese(text);
                    final insight = NewsInsight(
                      title: article.title,
                      description: article.description,
                      url: article.url,
                      urlToImage: article.urlToImage,
                      analysis: analysis,
                    );
                    final importance = NewsAnalysisService.instance
                        .calculateImportance(insight);
                    return {
                      'article': article,
                      'insight': insight,
                      'translation': translation,
                      'importance': importance
                    };
                  })),
                  builder: (context, snapshot2) {
                    if (snapshot2.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot2.data ?? [];
                    if (items.isEmpty)
                      return const Center(child: Text('記事が見つかりませんでした'));

                    // 重要度で降順ソート
                    items.sort((a, b) => (b['importance'] as double)
                        .compareTo(a['importance'] as double));

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final it = items[idx];
                        final article = it['article'] as Article;
                        final translation = it['translation'] as String;
                        final insight = it['insight'] as NewsInsight;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ArticleDetailScreen(article: article)),
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
                                          height: 120,
                                          color: Colors.grey.shade200),
                                      errorWidget: (c, u, e) => Container(
                                          height: 120,
                                          color: Colors.grey.shade300,
                                          child: const Center(
                                              child: Icon(Icons.broken_image))),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6)),
                                    child:
                                        const Center(child: Icon(Icons.image)),
                                  ),
                                const SizedBox(height: 8),
                                Text(article.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(translation,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                // 小さなラベル: 重要度とムード
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '重要度: ${(it['importance'] as double).toStringAsFixed(2)}'),
                                    Text(
                                        'ムード: ${insight.analysis?.mood ?? 'N/A'}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
