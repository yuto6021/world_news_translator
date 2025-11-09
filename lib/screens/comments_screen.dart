import 'package:flutter/material.dart';
import '../widgets/app_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/comments_service.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  List<ArticleComment> _comments = [];
  bool _loading = true;
  final TextEditingController _newCommentController = TextEditingController();
  DateTime? _replyTo; // 返信対象の createdAt

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    final comments = await CommentsService.getComments();
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _addNewComment() async {
    final text = _newCommentController.text.trim();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コメントを入力してください')),
      );
      return;
    }
    final comment = ArticleComment(
      articleUrl: '',
      articleTitle: 'メモ',
      quote: '',
      comment: text,
      createdAt: DateTime.now(),
      articleImage: null,
      parentCreatedAt: _replyTo,
    );
    await CommentsService.addComment(comment);
    _newCommentController.clear();
    setState(() => _replyTo = null);
    await _loadComments();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コメントを追加しました')),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  void _showEditDialog(ArticleComment comment) {
    final controller = TextEditingController(text: comment.comment);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメントを編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'コメント',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('コメントを入力してください')),
                );
                return;
              }
              await CommentsService.updateComment(
                comment.createdAt,
                controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              _loadComments();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('コメントを更新しました')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('記事コメント'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_comments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('確認'),
                    content: const Text('すべてのコメントを削除しますか？'),
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
                  await CommentsService.clearAll();
                  _loadComments();
                }
              },
              tooltip: 'すべてクリア',
            ),
        ],
      ),
      body: Stack(
        children: [
          AppBackground(dark: isDark),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.comment_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'コメントがありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '記事詳細から\n「記事にコメント」でコメントを追加できます',
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
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final isReply = comment.parentCreatedAt != null;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isReply)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 12, top: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.reply,
                                          size: 14,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text('返信',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              // 記事情報
                              if (comment.articleUrl.isNotEmpty) ...[
                                InkWell(
                                  onTap: () =>
                                      launchUrl(Uri.parse(comment.articleUrl)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        if (comment.articleImage != null)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: CachedNetworkImage(
                                              imageUrl: comment.articleImage!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              placeholder: (c, u) => Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey.shade200,
                                              ),
                                              errorWidget: (c, u, e) =>
                                                  Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                    Icons.broken_image),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.articleTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              const Row(
                                                children: [
                                                  Icon(Icons.link, size: 12),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '記事を開く',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                              // 引用部分
                              if (comment.quote.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.grey.shade100,
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.format_quote, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            '引用',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.quote,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // コメント本文
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.comment,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(comment.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              onPressed: () =>
                                                  _showEditDialog(comment),
                                              tooltip: '編集',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.reply,
                                                  size: 20),
                                              onPressed: () {
                                                setState(() => _replyTo =
                                                    comment.createdAt);
                                                _newCommentController.text =
                                                    '@返信: ';
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          '返信先をセットしました。下の入力欄から投稿できます')),
                                                );
                                              },
                                              tooltip: '返信',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 20),
                                              onPressed: () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('確認'),
                                                    content: const Text(
                                                        'このコメントを削除しますか？'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, false),
                                                        child:
                                                            const Text('キャンセル'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, true),
                                                        child: const Text('削除'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await CommentsService
                                                      .deleteComment(
                                                          comment.createdAt);
                                                  _loadComments();
                                                }
                                              },
                                              tooltip: '削除',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          // 画面下に新規コメント入力欄
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCommentController,
                  decoration: InputDecoration(
                    hintText: _replyTo == null ? 'コメントを入力...' : '返信を入力...',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: _replyTo != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: '返信を解除',
                            onPressed: () => setState(() => _replyTo = null),
                          )
                        : null,
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _addNewComment,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('投稿'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
