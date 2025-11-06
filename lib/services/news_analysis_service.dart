import '../models/news_insight.dart';

class NewsAnalysisService {
  static NewsAnalysisService? _instance;
  static NewsAnalysisService get instance {
    _instance ??= NewsAnalysisService._();
    return _instance!;
  }

  NewsAnalysisService._();

  // この例では簡易的なルールベースの分析を行います
  // 実際のアプリではより高度なAIサービスを利用することを想定
  Future<NewsAnalysis> analyzeContent(String content) async {
    if (content.trim().isEmpty) {
      return NewsAnalysis(
        summary: '内容なし',
        mood: 'neutral',
        keywords: [],
        analyzedAt: DateTime.now(),
      );
    }

    // 感情分析（簡易版）
    String mood = 'neutral';
    if (content.contains(RegExp(r'成功|達成|勝利|発見|革新|期待'))) {
      mood = 'positive';
    } else if (content.contains(RegExp(r'失敗|敗北|事故|災害|危機'))) {
      mood = 'negative';
    } else if (content.contains(RegExp(r'驚き|衝撃|急進|革命|爆発的'))) {
      mood = 'exciting';
    }

    // キーワード抽出（簡易版）
    final keywords = _extractKeywords(content);

    // 要約（簡易版）
    final summary =
        content.length > 100 ? '${content.substring(0, 97)}...' : content;

    return NewsAnalysis(
      summary: summary,
      mood: mood,
      keywords: keywords,
      analyzedAt: DateTime.now(),
    );
  }

  List<String> _extractKeywords(String content) {
    final words = content
        .split(RegExp(r'[\s,\.。、]+'))
        .where((word) => word.length >= 2 && !_stopWords.contains(word))
        .toList();

    return words.take(5).toList();
  }

  // 簡易的なストップワード
  static const _stopWords = {
    'これ',
    'それ',
    'あれ',
    'この',
    'その',
    'あの',
    'ます',
    'です',
    'した',
    'いる',
    'ある',
    'なる',
    'という',
    'として',
    'による',
    'ための',
  };

  // 未読記事の重要度を計算（0-1の範囲、1が最も重要）
  double calculateImportance(NewsInsight news) {
    if (news.analysis == null) return 0.5; // 分析なしは中程度

    double score = 0.0;

    // ムードに基づくスコア
    switch (news.analysis!.mood) {
      case 'exciting':
        score += 0.4;
        break;
      case 'positive':
      case 'negative':
        score += 0.3;
        break;
      default:
        score += 0.2;
    }

    // キーワード数に基づくスコア
    score += news.analysis!.keywords.length * 0.1; // 最大0.5

    // 新しさによるボーナス（24時間以内）
    final hoursAgo =
        DateTime.now().difference(news.analysis!.analyzedAt).inHours;
    if (hoursAgo < 24) {
      score += (24 - hoursAgo) * 0.01; // 最大0.24
    }

    return score.clamp(0.0, 1.0); // 0-1の範囲に収める
  }
}
