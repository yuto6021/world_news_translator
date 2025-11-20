import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ArticleComment {
  final String articleUrl;
  final String articleTitle;
  final String quote; // 引用部分
  final String comment; // ユーザーのコメント
  final DateTime createdAt;
  final String? articleImage;
  final DateTime? parentCreatedAt; // 返信対象コメントの createdAt （スレッド紐付け）
  final Map<String, int> reactions; // 絵文字 => カウント

  ArticleComment({
    required this.articleUrl,
    required this.articleTitle,
    required this.quote,
    required this.comment,
    required this.createdAt,
    this.articleImage,
    this.parentCreatedAt,
    Map<String, int>? reactions,
  }) : reactions = reactions ?? {};

  Map<String, dynamic> toJson() => {
        'articleUrl': articleUrl,
        'articleTitle': articleTitle,
        'quote': quote,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'articleImage': articleImage,
        'parentCreatedAt': parentCreatedAt?.toIso8601String(),
        'reactions': reactions,
      };

  factory ArticleComment.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'];
    Map<String, int> rx = {};
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        if (k is String) {
          final intVal = (v is int)
              ? v
              : (v is String)
                  ? int.tryParse(v) ?? 0
                  : 0;
          if (intVal > 0) rx[k] = intVal;
        }
      });
    }
    return ArticleComment(
      articleUrl: json['articleUrl'] as String,
      articleTitle: json['articleTitle'] as String,
      quote: json['quote'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      articleImage: json['articleImage'] as String?,
      parentCreatedAt: json['parentCreatedAt'] != null
          ? DateTime.parse(json['parentCreatedAt'])
          : null,
      reactions: rx,
    );
  }
}

class CommentsService {
  static const String _key = 'article_comments';

  static Future<List<ArticleComment>> getComments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((str) => ArticleComment.fromJson(json.decode(str)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 新しい順
  }

  static Future<void> addComment(ArticleComment comment) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    jsonList.insert(0, json.encode(comment.toJson()));
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> deleteComment(DateTime createdAt) async {
    final prefs = await SharedPreferences.getInstance();
    final comments = await getComments();
    // 親コメント削除時は子返信もまとめて削除（カスケード）
    final filtered = comments
        .where((c) {
          if (c.createdAt == createdAt) return false; // 本人
          if (c.parentCreatedAt != null && c.parentCreatedAt == createdAt) {
            return false; // 返信 (子)
          }
          return true;
        })
        .map((c) => json.encode(c.toJson()))
        .toList();
    await prefs.setStringList(_key, filtered);
  }

  static Future<void> updateComment(
      DateTime originalCreatedAt, String newComment) async {
    final prefs = await SharedPreferences.getInstance();
    final comments = await getComments();
    final updated = comments.map((c) {
      if (c.createdAt == originalCreatedAt) {
        return ArticleComment(
          articleUrl: c.articleUrl,
          articleTitle: c.articleTitle,
          quote: c.quote,
          comment: newComment,
          createdAt: c.createdAt,
          articleImage: c.articleImage,
          parentCreatedAt: c.parentCreatedAt, // スレッド保持
          reactions: c.reactions,
        );
      }
      return c;
    }).toList();
    await prefs.setStringList(
        _key, updated.map((c) => json.encode(c.toJson())).toList());
  }

  static Future<void> addReaction(DateTime createdAt, String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final comments = await getComments();
    final updated = comments.map((c) {
      if (c.createdAt == createdAt) {
        final newMap = Map<String, int>.from(c.reactions);
        newMap.update(emoji, (v) => v + 1, ifAbsent: () => 1);
        return ArticleComment(
          articleUrl: c.articleUrl,
          articleTitle: c.articleTitle,
          quote: c.quote,
          comment: c.comment,
          createdAt: c.createdAt,
          articleImage: c.articleImage,
          parentCreatedAt: c.parentCreatedAt,
          reactions: newMap,
        );
      }
      return c;
    }).toList();
    await prefs.setStringList(
        _key, updated.map((c) => json.encode(c.toJson())).toList());
  }

  static Future<void> decrementReaction(
      DateTime createdAt, String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final comments = await getComments();
    final updated = comments.map((c) {
      if (c.createdAt == createdAt) {
        final newMap = Map<String, int>.from(c.reactions);
        if (newMap.containsKey(emoji)) {
          final next = newMap[emoji]! - 1;
          if (next <= 0) {
            newMap.remove(emoji);
          } else {
            newMap[emoji] = next;
          }
        }
        return ArticleComment(
          articleUrl: c.articleUrl,
          articleTitle: c.articleTitle,
          quote: c.quote,
          comment: c.comment,
          createdAt: c.createdAt,
          articleImage: c.articleImage,
          parentCreatedAt: c.parentCreatedAt,
          reactions: newMap,
        );
      }
      return c;
    }).toList();
    await prefs.setStringList(
        _key, updated.map((c) => json.encode(c.toJson())).toList());
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
