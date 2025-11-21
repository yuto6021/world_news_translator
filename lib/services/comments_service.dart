import 'package:hive_flutter/hive_flutter.dart';
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
  static const String _boxName = 'article_comments';
  static Box<String>? _box;

  /// 初期化（main.dartから呼び出す）
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }
  }

  static Future<List<ArticleComment>> getComments() async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final jsonList = box.values.toList();
    return jsonList
        .map((str) => ArticleComment.fromJson(json.decode(str)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 新しい順
  }

  static Future<void> addComment(ArticleComment comment) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final key = comment.createdAt.millisecondsSinceEpoch.toString();
    await box.put(key, json.encode(comment.toJson()));
  }

  static Future<void> deleteComment(DateTime createdAt) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final comments = await getComments();
    // 親コメント削除時は子返信もまとめて削除（カスケード）
    final toDelete = comments.where((c) {
      if (c.createdAt == createdAt) return true; // 本人
      if (c.parentCreatedAt != null && c.parentCreatedAt == createdAt) {
        return true; // 返信 (子)
      }
      return false;
    }).toList();

    for (var c in toDelete) {
      final key = c.createdAt.millisecondsSinceEpoch.toString();
      await box.delete(key);
    }
  }

  static Future<void> updateComment(
      DateTime originalCreatedAt, String newComment) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final comments = await getComments();
    final target = comments.firstWhere((c) => c.createdAt == originalCreatedAt,
        orElse: () => throw Exception('Comment not found'));
    final updated = ArticleComment(
      articleUrl: target.articleUrl,
      articleTitle: target.articleTitle,
      quote: target.quote,
      comment: newComment,
      createdAt: target.createdAt,
      articleImage: target.articleImage,
      parentCreatedAt: target.parentCreatedAt,
      reactions: target.reactions,
    );
    final key = originalCreatedAt.millisecondsSinceEpoch.toString();
    await box.put(key, json.encode(updated.toJson()));
  }

  static Future<void> addReaction(DateTime createdAt, String emoji) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final comments = await getComments();
    final target = comments.firstWhere((c) => c.createdAt == createdAt,
        orElse: () => throw Exception('Comment not found'));
    final newMap = Map<String, int>.from(target.reactions);
    newMap.update(emoji, (v) => v + 1, ifAbsent: () => 1);
    final updated = ArticleComment(
      articleUrl: target.articleUrl,
      articleTitle: target.articleTitle,
      quote: target.quote,
      comment: target.comment,
      createdAt: target.createdAt,
      articleImage: target.articleImage,
      parentCreatedAt: target.parentCreatedAt,
      reactions: newMap,
    );
    final key = createdAt.millisecondsSinceEpoch.toString();
    await box.put(key, json.encode(updated.toJson()));
  }

  static Future<void> decrementReaction(
      DateTime createdAt, String emoji) async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    final comments = await getComments();
    final target = comments.firstWhere((c) => c.createdAt == createdAt,
        orElse: () => throw Exception('Comment not found'));
    final newMap = Map<String, int>.from(target.reactions);
    if (newMap.containsKey(emoji)) {
      final next = newMap[emoji]! - 1;
      if (next <= 0) {
        newMap.remove(emoji);
      } else {
        newMap[emoji] = next;
      }
    }
    final updated = ArticleComment(
      articleUrl: target.articleUrl,
      articleTitle: target.articleTitle,
      quote: target.quote,
      comment: target.comment,
      createdAt: target.createdAt,
      articleImage: target.articleImage,
      parentCreatedAt: target.parentCreatedAt,
      reactions: newMap,
    );
    final key = createdAt.millisecondsSinceEpoch.toString();
    await box.put(key, json.encode(updated.toJson()));
  }

  static Future<void> clearAll() async {
    final box = _box ?? await Hive.openBox<String>(_boxName);
    await box.clear();
  }
}
