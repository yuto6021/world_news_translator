import 'package:flutter/material.dart';
import 'article.dart';

class NewsAnalysis {
  final String summary;
  final String mood;
  final List<String> keywords;
  final DateTime analyzedAt;

  NewsAnalysis({
    required this.summary,
    required this.mood,
    required this.keywords,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'mood': mood,
        'keywords': keywords,
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  factory NewsAnalysis.fromJson(Map<String, dynamic> json) {
    return NewsAnalysis(
      summary: json['summary'] as String,
      mood: json['mood'] as String,
      keywords: (json['keywords'] as List).cast<String>(),
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }

  // ニュースの雰囲気に基づいて色を提案
  Color getMoodColor() {
    switch (mood.toLowerCase()) {
      case 'positive':
        return Colors.green.shade100;
      case 'negative':
        return Colors.red.shade50;
      case 'neutral':
        return Colors.blue.shade50;
      case 'exciting':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade50;
    }
  }
}

class NewsInsight {
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final NewsAnalysis? analysis;
  final DateTime? savedForLater;

  NewsInsight({
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    this.analysis,
    this.savedForLater,
  });

  // Article から NewsInsight を作成
  static NewsInsight fromArticle(Article article) {
    return NewsInsight(
      title: article.title,
      description: article.description,
      url: article.url,
      urlToImage: article.urlToImage,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'url': url,
        'urlToImage': urlToImage,
        'analysis': analysis?.toJson(),
        'savedForLater': savedForLater?.toIso8601String(),
      };

  factory NewsInsight.fromJson(Map<String, dynamic> json) {
    return NewsInsight(
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String,
      urlToImage: json['urlToImage'] as String?,
      analysis: json['analysis'] != null
          ? NewsAnalysis.fromJson(json['analysis'])
          : null,
      savedForLater: json['savedForLater'] != null
          ? DateTime.parse(json['savedForLater'])
          : null,
    );
  }
}
