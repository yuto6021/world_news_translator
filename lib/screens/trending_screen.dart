import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../models/article.dart';
import '../screens/article_detail_screen.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  late Future<List<Article>> _articles;
  String? _selectedCountryCode;

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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Text('国別トレンド:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedCountryCode,
                      hint: const Text('すべて（デフォルト）'),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('Global')),
                        ...countryCodes.entries.map((e) =>
                            DropdownMenuItem<String?>(
                                value: e.value,
                                child: Text(e.key.toUpperCase()))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCountryCode = val;
                          _articles = NewsApiService.fetchTrendingArticles(val);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _articles = NewsApiService.fetchTrendingArticles(
                        _selectedCountryCode);
                  });
                  await _articles;
                },
                child: ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, idx) {
                    final article = articles[idx];
                    return MouseRegion(
                      onHover: (_) {},
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ArticleDetailScreen(article: article)),
                          );
                        },
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
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) => Container(
                                        height: 100,
                                        color: Colors.grey.shade200),
                                    errorWidget: (c, u, e) => Container(
                                      height: 100,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                          child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 100,
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
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
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
