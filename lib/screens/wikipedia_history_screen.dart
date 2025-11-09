import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wikipedia_service.dart';
import '../services/wikipedia_history_service.dart';

class WikipediaHistoryScreen extends StatefulWidget {
  const WikipediaHistoryScreen({super.key});

  @override
  State<WikipediaHistoryScreen> createState() => _WikipediaHistoryScreenState();
}

class _WikipediaHistoryScreenState extends State<WikipediaHistoryScreen> {
  List<WikipediaHistoryItem> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final history = await WikipediaHistoryService.getHistory();
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  void _showWikipediaSearch(String query) async {
    if (query.trim().isEmpty) return;
    // 要約を取得してから履歴に追加（再検索時も先頭に移動）
    final summary = await WikipediaService.getSummary(query);
    await WikipediaHistoryService.addToHistory(query, summary);
    await _loadHistory();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.public, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Wikipedia: $query',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: (summary == null)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              '「$query」の情報が見つかりませんでした',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '別の単語を試してみてください',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        children: [
                          Text(
                            summary,
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final encodedQuery = Uri.encodeComponent(query);
                              final uri = Uri.parse(
                                  'https://ja.wikipedia.org/wiki/$encodedQuery');
                              await launchUrl(uri);
                            },
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Wikipediaで全文を読む'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wikipedia検索履歴'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('確認'),
                    content: const Text('すべての検索履歴を削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('削除'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await WikipediaHistoryService.clearHistory();
                  _loadHistory();
                }
              },
              tooltip: 'すべてクリア',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        '検索履歴がありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '記事詳細で単語を選択して\nWikipedia検索すると履歴が表示されます',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading:
                            const Icon(Icons.history, color: Colors.indigo),
                        title: Text(
                          item.query,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: item.summary != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  item.summary!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              )
                            : const Text(
                                '要約なし',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () async {
                            await WikipediaHistoryService.removeFromHistory(
                                item.query);
                            _loadHistory();
                          },
                          tooltip: '削除',
                        ),
                        onTap: () => _showWikipediaSearch(item.query),
                      ),
                    );
                  },
                ),
    );
  }
}
