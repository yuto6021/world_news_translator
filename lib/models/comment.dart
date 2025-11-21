/// コメントモデル（Hive永続化対応）
class Comment {
  final String id;
  final String articleId;
  final String text;
  final DateTime createdAt;
  final String? parentId; // 返信先コメントID
  final List<String> reactions; // 絵文字リアクション

  Comment({
    required this.id,
    required this.articleId,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.reactions = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'articleId': articleId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'parentId': parentId,
        'reactions': reactions,
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        articleId: json['articleId'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        parentId: json['parentId'] as String?,
        reactions: (json['reactions'] as List?)?.cast<String>() ?? [],
      );
}
