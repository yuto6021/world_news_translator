class Article {
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final double? importance; // 重要度スコア

  Article({
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    this.importance,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'],
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      importance: json['importance']?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'importance': importance,
    };
  }
}
