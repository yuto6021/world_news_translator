import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../models/article.dart';
import '../widgets/news_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Future<List<Article>>? _results;

  void _doSearch() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _results = NewsApiService.searchArticles(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ニュース検索')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'キーワードで検索',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _doSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _doSearch, child: const Text('検索')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results == null
                  ? const Center(child: Text('検索ワードを入力してください'))
                  : FutureBuilder<List<Article>>(
                      future: _results,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final articles = snapshot.data ?? [];
                        if (articles.isEmpty) {
                          return const Center(child: Text('該当する記事が見つかりませんでした'));
                        }
                        return ListView.builder(
                          itemCount: articles.length,
                          itemBuilder: (context, idx) {
                            final a = articles[idx];
                            return NewsCard(
                                article: a,
                                translatedText: a.description ?? '（翻訳なし）');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
