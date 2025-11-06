import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // 検索履歴（上位20件を保持）
  List<String> _history = [];
  static const _prefsKey = 'search_history_v1';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? [];
      setState(() {
        _history = raw;
      });
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _history);
    } catch (_) {}
  }

  void _addToHistory(String q) {
    q = q.trim();
    if (q.isEmpty) return;
    setState(() {
      _history.remove(q);
      _history.insert(0, q);
      if (_history.length > 20) _history = _history.sublist(0, 20);
    });
    _saveHistory();
  }

  void _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('検索履歴を消去しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('消去')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _history = []);
      _saveHistory();
    }
  }

  void _doSearch([String? fromHistory]) {
    final q = (fromHistory ?? _controller.text).trim();
    if (q.isEmpty) return;
    _controller.text = q;
    _addToHistory(q);
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

            // 履歴表示
            if (_history.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('検索履歴',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                      onPressed: _clearHistory, child: const Text('履歴を消去')),
                ],
              ),
            if (_history.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final s = _history[idx];
                    return ActionChip(
                      label: Text(s),
                      onPressed: () => _doSearch(s),
                    );
                  },
                ),
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
                          return const Center(child: Text('該当する記事はありません'));
                        }
                        return RefreshIndicator(
                          onRefresh: () async {
                            // 再検索
                            if (_controller.text.trim().isNotEmpty) {
                              setState(() => _results =
                                  NewsApiService.searchArticles(
                                      _controller.text.trim()));
                              await _results;
                            }
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: articles.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final article = articles[idx];
                              // 翻訳は記事詳細で遅延取得するシンプルなフローにする
                              return NewsCard(
                                  article: article, translatedText: '');
                            },
                          ),
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
