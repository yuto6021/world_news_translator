import 'package:flutter/material.dart';
import '../widgets/app_background.dart';
import 'package:intl/intl.dart';
import '../services/comments_service.dart';
import '../utils/app_snackbar.dart';

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
      AppSnackBar.warning(context, 'コメントを入力してください');
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
      reactions: {},
    );
    await CommentsService.addComment(comment);
    _newCommentController.clear();
    setState(() => _replyTo = null);
    await _loadComments();
    if (!mounted) return;
    AppSnackBar.success(context, 'コメントを追加しました');
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
                AppSnackBar.warning(context, 'コメントを入力してください');
                return;
              }
              await CommentsService.updateComment(
                comment.createdAt,
                controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              _loadComments();
              AppSnackBar.success(context, 'コメントを更新しました');
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
    // スレッド構造を構築: 親コメント -> 子返信一覧
    final Map<DateTime, List<ArticleComment>> childrenMap = {};
    for (final c in _comments) {
      if (c.parentCreatedAt != null) {
        childrenMap.putIfAbsent(c.parentCreatedAt!, () => []).add(c);
      }
    }
    final roots = _comments.where((c) => c.parentCreatedAt == null).toList();
    // 新しい順の並びを維持（_commentsは新しい順）→ roots もそのまま順序
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
                      itemCount: roots.length,
                      itemBuilder: (context, index) {
                        final root = roots[index];
                        final replies = childrenMap[root.createdAt] ?? [];
                        return _ThreadCard(
                          comment: root,
                          replies: replies,
                          formatDate: _formatDate,
                          onReply: (c) {
                            setState(() => _replyTo = c.createdAt);
                            _newCommentController.text = '@返信: ';
                            AppSnackBar.info(
                                context, '返信先をセットしました。下の入力欄から投稿できます');
                          },
                          onEdit: _showEditDialog,
                          onDelete: (c) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('確認'),
                                content: const Text('このコメントを削除しますか？(返信も含む)'),
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
                              await CommentsService.deleteComment(c.createdAt);
                              _loadComments();
                            }
                          },
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

// スレッドカード: 親コメント + 返信一覧
class _ThreadCard extends StatelessWidget {
  final ArticleComment comment; // 親
  final List<ArticleComment> replies; // 直接の子返信（新しい順想定）
  final String Function(DateTime) formatDate;
  final void Function(ArticleComment) onReply;
  final void Function(ArticleComment) onEdit;
  final void Function(ArticleComment) onDelete;

  const _ThreadCard({
    required this.comment,
    required this.replies,
    required this.formatDate,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildSingleComment(BuildContext context, ArticleComment c,
      {bool isReply = false}) {
    final quoteBlock = c.quote.isNotEmpty
        ? Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  c.quote,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 16 : 0,
        right: 0,
        top: isReply ? 4 : 0,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReply)
            Row(
              children: [
                Icon(Icons.reply, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('返信',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          if (c.articleUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                c.articleTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          quoteBlock,
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              c.comment,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDate(c.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => onEdit(c),
                    tooltip: '編集',
                  ),
                  IconButton(
                    icon: const Icon(Icons.reply, size: 20),
                    onPressed: () => onReply(c),
                    tooltip: '返信',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => onDelete(c),
                    tooltip: '削除',
                  ),
                ],
              ),
            ],
          ),
          // リアクションバー
          const SizedBox(height: 4),
          _ReactionBar(comment: c),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSingleComment(context, comment),
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: replies
                      .map(
                          (r) => _buildSingleComment(context, r, isReply: true))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReactionBar extends StatefulWidget {
  final ArticleComment comment;
  const _ReactionBar({required this.comment});

  @override
  State<_ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<_ReactionBar> {
  static const defaultEmojis = ['👍', '❤️', '😂', '😮', '🤔'];
  bool _expanded = false;

  Future<void> _add(String emoji) async {
    await CommentsService.addReaction(widget.comment.createdAt, emoji);
    // 親の一覧再読込が理想だが簡易再構築のため setState + SnackBarで知らせる
    if (mounted) {
      AppSnackBar.success(context, 'リアクション $emoji を追加しました');
    }
  }

  Future<void> _remove(String emoji) async {
    await CommentsService.decrementReaction(widget.comment.createdAt, emoji);
    if (mounted) {
      AppSnackBar.info(context, 'リアクション $emoji を減らしました');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reactions = widget.comment.reactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reactions.isNotEmpty || _expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'タップで追加、長押しで削除',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Wrap(
          spacing: 6,
          runSpacing: -4,
          children: [
            for (final entry in reactions.entries)
              GestureDetector(
                onTap: () => _add(entry.key), // 追加
                onLongPress: () => _remove(entry.key), // 長押しで減算
                child: Chip(
                  label: Text('${entry.key} ${entry.value}'),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            if (_expanded)
              for (final e in defaultEmojis)
                if (!reactions.containsKey(e))
                  GestureDetector(
                    onTap: () => _add(e),
                    child: Chip(
                      label: Text(e),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Chip(
                label: Text(_expanded ? '閉じる' : '＋'),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('タップで追加 / 長押しで減算',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}
