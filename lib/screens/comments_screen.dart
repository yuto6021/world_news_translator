import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Comment {
  final String text;
  final DateTime createdAt;

  Comment({required this.text, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();
  List<Comment> _comments = [];
  static const _prefsKey = 'anonymous_comments_v1';

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _comments = decoded.map((e) => Comment.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // エラー処理（今回は簡単のため省略）
    }
  }

  Future<void> _saveComments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _comments.map((c) => c.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(encoded));
    } catch (e) {
      // エラー処理（今回は簡単のため省略）
    }
  }

  void _addComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.insert(0, Comment(text: text, createdAt: DateTime.now()));
      _controller.clear();
    });
    _saveComments();
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('匿名コメント')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'コメントを入力（匿名）',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Text('まだコメントはありません'),
                  )
                : ListView.separated(
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return ListTile(
                        title: Text(comment.text),
                        subtitle: Text(
                          _formatDate(comment.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
