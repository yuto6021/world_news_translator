import '../models/news_insight.dart';

class NewsAnalysisService {
  static NewsAnalysisService? _instance;
  static NewsAnalysisService get instance {
    _instance ??= NewsAnalysisService._();
    return _instance!;
  }

  NewsAnalysisService._();

  // 簡易ルールベースの分析。記事が英語か日本語かを自動判定して適切な処理を行う。
  Future<NewsAnalysis> analyzeContent(String content) async {
    if (content.trim().isEmpty) {
      return NewsAnalysis(
        summary: '内容なし',
        mood: 'neutral',
        keywords: [],
        analyzedAt: DateTime.now(),
      );
    }

    final isEnglish = _isProbablyEnglish(content);

    // 感情分析（簡易版）
  String mood = 'neutral';
    if (isEnglish) {
      if (content.contains(RegExp(
          r'success|achieve|victory|discover|innovation|hope|positive|progress|agreement|collaboration|breakthrough',
          caseSensitive: false))) {
        mood = 'positive';
      } else if (content.contains(RegExp(
          r'fail|defeat|accident|disaster|crisis|death|damage|tragedy|conflict|war',
          caseSensitive: false))) {
        mood = 'negative';
      } else if (content.contains(RegExp(
          r'surprise|shock|radical|revolution|explosive|dramatic|urgent|emergency|breaking',
          caseSensitive: false))) {
        mood = 'exciting';
      } else if (content.contains(RegExp(
          r'concern|warn|caution|uncertain|risk|tension',
          caseSensitive: false))) {
        mood = 'cautious';
      }
    } else {
      if (content.contains(RegExp(r'成功|達成|勝利|発見|革新|期待|前進|合意|協力|進展'))) {
        mood = 'positive';
      } else if (content.contains(RegExp(r'失敗|敗北|事故|災害|危機|死亡|被害|悲劇|紛争|戦争'))) {
        mood = 'negative';
      } else if (content.contains(RegExp(r'驚き|衝撃|急進|革命|爆発的|劇的|緊急|速報'))) {
        mood = 'exciting';
      } else if (content.contains(RegExp(r'懸念|警告|注意|不透明|リスク|緊張'))) {
        mood = 'cautious';
      }
    }

    // キーワード抽出
    final keywords = _extractKeywords(content, isEnglish: isEnglish);

    // 要約（簡易）: 先頭を切り取る
    final summary =
        content.length > 120 ? '${content.substring(0, 117)}...' : content;

    return NewsAnalysis(
      summary: summary,
      mood: mood,
      keywords: keywords,
      analyzedAt: DateTime.now(),
    );
  }

  // 英語かどうかを簡易判定（アルファベット文字の割合 vs 日本語文字）
  bool _isProbablyEnglish(String content) {
    final engMatches = RegExp(r'[A-Za-z]').allMatches(content).length;
    final jpMatches = RegExp(r'[ぁ-んァ-ン一-龥]').allMatches(content).length;
    return engMatches >= jpMatches;
  }

  List<String> _extractKeywords(String content, {required bool isEnglish}) {
    if (isEnglish) {
      // 英語用の簡易ストップワード
      const englishStop = {
        'the',
        'is',
        'at',
        'which',
        'on',
        'a',
        'an',
        'and',
        'or',
        'but',
        'in',
        'into',
        'to',
        'for',
        'with',
        'by',
        'of',
        'as',
        'from',
        'that',
        'this',
        'are',
        'was',
        'were',
        'be',
        'has',
        'have'
      };

      final words = content
          .toLowerCase()
          .split(RegExp(r"[^a-zA-Z]+"))
          .where((w) => w.length > 2 && !englishStop.contains(w))
          .toList();

      // 上位のユニークな語を返す
      final seen = <String>{};
      final out = <String>[];
      for (final w in words) {
        if (seen.add(w)) out.add(w);
        if (out.length >= 5) break;
      }
      return out;
    }

    // 日本語: 既存の実装を活かす
    final words = content
        .split(RegExp(r'[\\s,\\.。、]+'))
        .where((word) => word.length >= 2 && !_stopWords.contains(word))
        .toList();

    return words.take(5).toList();
  }

  // 簡易的なストップワード（日本語）
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
    if (news.analysis == null) return 0.45; // 分析なしはやや低め

    double score = 0.0;

    // ムード（より細分化）
    switch (news.analysis!.mood.toLowerCase()) {
      case 'exciting':
        score += 0.25;
        break;
      case 'positive':
      case 'negative':
        score += 0.18;
        break;
      case 'cautious':
        score += 0.14;
        break;
      default:
        score += 0.1;
    }

    // キーワード
    score += (news.analysis!.keywords.length * 0.05).clamp(0.0, 0.25);

    // 画像の有無（視認性や注目度）
    if ((news.urlToImage ?? '').isNotEmpty) score += 0.05;

    // 新しさ（最大0.12）
    final hoursAgo = DateTime.now().difference(news.analysis!.analyzedAt).inHours;
    if (hoursAgo < 24) {
      score += (24 - hoursAgo) * 0.005; // 最大約0.12
    }

    // 正規化（全体を少し圧縮して「重要」ばかりになるのを防ぐ）
    score = (score * 0.85).clamp(0.0, 1.0);
    return score;
  }
}
