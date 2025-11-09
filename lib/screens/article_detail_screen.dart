import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/translation_service.dart';
import '../services/app_settings_service.dart';
import '../services/time_capsule_service.dart';
import '../services/wikipedia_service.dart';
import '../services/wikipedia_history_service.dart';
import '../services/comments_service.dart';
import '../models/news_insight.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String? _translated;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // 自動翻訳が有効な場合のみ翻訳を行う
    if (AppSettingsService.instance.autoTranslate.value) {
      _fetchTranslation();
    } else {
      // ただし、将来切り替えた場合に対応するために listener を残しておく
      AppSettingsService.instance.autoTranslate.addListener(() {
        if (AppSettingsService.instance.autoTranslate.value &&
            _translated == null &&
            !_loading) {
          _fetchTranslation();
        }
      });
    }
  }

  Future<void> _fetchTranslation() async {
    setState(() {
      _loading = true;
    });
    final textToTranslate = (widget.article.description != null &&
            widget.article.description!.trim().isNotEmpty)
        ? widget.article.description!
        : widget.article.title;
    final t = await TranslationService.translateToJapanese(textToTranslate);
    setState(() {
      _translated = t;
      _loading = false;
    });
  }

  void _showWikipediaSearch(String query) async {
    if (query.trim().isEmpty) return;

    // まず要約を取得
    final summary = await WikipediaService.getSummary(query);

    // 要約付きで検索履歴に追加
    await WikipediaHistoryService.addToHistory(query, summary);

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
                              '別の単語を選択して試してみてください',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          snapshot.data!,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            final encodedQuery = Uri.encodeComponent(query);
                            launchUrl(Uri.parse(
                                'https://ja.wikipedia.org/wiki/$encodedQuery'));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('記事詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                '${widget.article.title}\n\n${widget.article.url}',
                subject: widget.article.title,
              );
            },
            tooltip: '記事を共有',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(Uri.parse(widget.article.url)),
            tooltip: '原文をブラウザで開く',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.article.url));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('記事のリンクをコピーしました')));
            },
            tooltip: 'リンクをコピー',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.article.urlToImage != null)
                Hero(
                  tag: widget.article.url,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.article.urlToImage!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (c, u) =>
                          Container(height: 220, color: Colors.grey.shade200),
                      errorWidget: (c, u, e) => Container(
                        height: 220,
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SelectableText(
                widget.article.title,
                style: Theme.of(context).textTheme.titleLarge,
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: [
                      ...editableTextState.contextMenuButtonItems,
                      ContextMenuButtonItem(
                        onPressed: () {
                          final selection =
                              editableTextState.textEditingValue.selection;
                          final selectedText = editableTextState
                              .textEditingValue.text
                              .substring(selection.start, selection.end);
                          ContextMenuController.removeAny();
                          _showWikipediaSearch(selectedText);
                        },
                        label: 'Wikipediaで検索',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              if (widget.article.description != null &&
                  widget.article.description!.isNotEmpty)
                SelectableText(
                  widget.article.description!,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: [
                        ...editableTextState.contextMenuButtonItems,
                        ContextMenuButtonItem(
                          onPressed: () {
                            final selection =
                                editableTextState.textEditingValue.selection;
                            final selectedText = editableTextState
                                .textEditingValue.text
                                .substring(selection.start, selection.end);
                            ContextMenuController.removeAny();
                            _showWikipediaSearch(selectedText);
                          },
                          label: 'Wikipediaで検索',
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('日本語翻訳', style: Theme.of(context).textTheme.titleMedium),
                  if (_loading) const CircularProgressIndicator(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchTranslation,
                    tooltip: '翻訳を再試行',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _translated != null
                    ? SelectableText(
                        _translated!,
                        contextMenuBuilder: (context, editableTextState) {
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            anchors: editableTextState.contextMenuAnchors,
                            buttonItems: [
                              ...editableTextState.contextMenuButtonItems,
                              ContextMenuButtonItem(
                                onPressed: () {
                                  final selection = editableTextState
                                      .textEditingValue.selection;
                                  final selectedText = editableTextState
                                      .textEditingValue.text
                                      .substring(
                                          selection.start, selection.end);
                                  ContextMenuController.removeAny();
                                  _showWikipediaSearch(selectedText);
                                },
                                label: 'Wikipediaで検索',
                              ),
                            ],
                          );
                        },
                      )
                    : Text(_loading ? '翻訳中...' : '（翻訳なし）'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  // 解禁日時を選択
                  // ignore: use_build_context_synchronously
                  // ignore: use_build_context_synchronously
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date == null) return;
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (!mounted) return;
                  final unlock = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time?.hour ?? 12,
                    time?.minute ?? 0,
                  );
                  final insight = NewsInsight.fromArticle(widget.article);
                  await TimeCapsuleService.instance
                      .addToCapsule(insight, unlock);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイムカプセルに保存しました')),
                  );
                },
                icon: const Icon(Icons.hourglass_bottom),
                label: const Text('タイムカプセルに保存'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showCommentDialog(),
                icon: const Icon(Icons.comment),
                label: const Text('記事にコメント'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => launchUrl(Uri.parse(widget.article.url)),
        child: const Icon(Icons.open_in_new),
        tooltip: '原文をブラウザで開く',
      ),
    );
  }

  void _showCommentDialog() {
    final quoteController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記事にコメント'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.article.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quoteController,
                decoration: const InputDecoration(
                  labelText: '引用部分（任意）',
                  hintText: '記事から引用したい部分を入力',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'コメント *',
                  hintText: 'あなたの考えや感想を入力',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('コメントを入力してください')),
                );
                return;
              }

              final comment = ArticleComment(
                articleUrl: widget.article.url,
                articleTitle: widget.article.title,
                quote: quoteController.text.trim(),
                comment: commentController.text.trim(),
                createdAt: DateTime.now(),
                articleImage: widget.article.urlToImage,
              );

              await CommentsService.addComment(comment);

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('コメントを保存しました')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
