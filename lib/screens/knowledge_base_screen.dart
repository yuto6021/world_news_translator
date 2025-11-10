import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_api_service.dart';
import '../services/wikipedia_service.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final Map<String, String> _wikiCache = {};
  bool _loading = true;
  List<Article> _articles = [];
  Map<String, List<String>> _articleEntities = {};

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _loading = true);
    try {
      _articles = await NewsApiService.getTopHeadlines();
      for (final article in _articles) {
        final entities = await WikipediaService.extractEntities(article.title);
        if (entities.isNotEmpty) {
          _articleEntities[article.url] = entities.keys.toList();
          _wikiCache.addAll(entities);
        }
      }
    } catch (e) {
      print('Error loading knowledge base: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        final entities = _articleEntities[article.url] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              article.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              if (article.description != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(article.description!),
                ),
              if (entities.isNotEmpty)
                Column(
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '関連知識',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...entities
                              .map((entity) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: Colors.grey.shade100,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entity,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _wikiCache[entity] ?? '情報を読み込み中...',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
