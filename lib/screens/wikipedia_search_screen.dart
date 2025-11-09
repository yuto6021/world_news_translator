import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wikipedia_service.dart';
import '../services/wikipedia_history_service.dart';

class WikipediaSearchScreen extends StatefulWidget {
  const WikipediaSearchScreen({super.key});

  @override
  State<WikipediaSearchScreen> createState() => _WikipediaSearchScreenState();
}

class _WikipediaSearchScreenState extends State<WikipediaSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<String> _suggestions = [];
  List<WikipediaHistoryItem> _history = [];
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _controller.addListener(() => _onQueryChanged(_controller.text));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await WikipediaHistoryService.getHistory();
    if (!mounted) return;
    setState(() => _history = list);
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      if (q.trim().isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      setState(() => _loading = true);
      final results = await WikipediaService.searchArticles(q);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  Future<void> _showSummary(String query) async {
    if (query.trim().isEmpty) return;

    // まず要約を取得
    final summary = await WikipediaService.getSummary(query);

    // 要約付きで履歴に追加
    await WikipediaHistoryService.addToHistory(query, summary);
    _loadHistory();

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
                    child: Text('Wikipedia: $query',
                        style: Theme.of(context).textTheme.titleLarge),
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
                child: FutureBuilder<String?>(
                  future: WikipediaService.getSummary(query),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('情報が見つかりませんでした'),
                            SizedBox(height: 8),
                            Text('別の単語を試してみてください',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    return ListView(
                      controller: scrollController,
                      children: [
                        Text(snapshot.data!,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final encoded = Uri.encodeComponent(query);
                            final uri = Uri.parse(
                                'https://ja.wikipedia.org/wiki/$encoded');
                            await launchUrl(uri);
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Wikipediaで全文を読む'),
                        ),
                      ],
                    );
                  },
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
    final query = _controller.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      label: 'Wikipedia 検索フィールド',
                      child: TextField(
                        focusNode: _focus,
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Wikipedia を検索（例: Elon Musk / NATO / WTO）',
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: _showSummary,
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    IconButton(
                      tooltip: 'クリア',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _suggestions = []);
                        _focus.requestFocus();
                      },
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _showSummary(query),
                    icon: const Icon(Icons.search),
                    label: const Text('検索'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (query.isEmpty && _history.isNotEmpty) ...[
            const Text('履歴', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length > 10 ? 10 : _history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.indigo),
                  title: Text(item.query,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: item.summary != null
                      ? Text(
                          item.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () async {
                      await WikipediaHistoryService.removeFromHistory(
                          item.query);
                      _loadHistory();
                    },
                  ),
                  onTap: () {
                    _controller.text = item.query;
                    _showSummary(item.query);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          if (query.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.list_alt, size: 18),
                const SizedBox(width: 6),
                Text('候補 (${_suggestions.length})'),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          const SizedBox(height: 8),
          Expanded(
            child: query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Wikipedia を検索してみましょう',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : (_suggestions.isEmpty && !_loading)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('「$query」に一致する候補がありません',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.article_outlined),
                            title: Text(s),
                            onTap: () {
                              _controller.text = s;
                              _showSummary(s);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
