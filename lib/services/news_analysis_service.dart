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
    final lower = content.toLowerCase();

    // 追加語彙リスト（英語）
    const positiveWords = [
      'success',
      'achieve',
      'achievement',
      'victory',
      'win',
      'discover',
      'innovation',
      'hope',
      'positive',
      'progress',
      'agreement',
      'collaboration',
      'breakthrough',
      'growth',
      'record',
      'improve',
      'rebound',
      'recover',
      'expansion',
      'upgrade',
      'optimistic'
    ];
    const negativeWords = [
      'fail',
      'failure',
      'defeat',
      'accident',
      'disaster',
      'crisis',
      'death',
      'damage',
      'tragedy',
      'conflict',
      'war',
      'decline',
      'drop',
      'loss',
      'plunge',
      'cut',
      'shutdown',
      'collapse',
      'fraud',
      'lawsuit',
      'scandal'
    ];
    const excitingWords = [
      'surprise',
      'shock',
      'radical',
      'revolution',
      'explosive',
      'dramatic',
      'urgent',
      'emergency',
      'breaking',
      'spike',
      'surge',
      'plunge',
      'volatile',
      'flash',
      'rapid',
      'boost'
    ];
    const cautiousWords = [
      'concern',
      'warn',
      'warning',
      'caution',
      'uncertain',
      'uncertainty',
      'risk',
      'tension',
      'fear',
      'worried',
      'slowdown',
      'pressure'
    ];

    int posCount = 0, negCount = 0, excCount = 0, cauCount = 0;
    if (isEnglish) {
      for (final w in positiveWords) if (lower.contains(w)) posCount++;
      for (final w in negativeWords) if (lower.contains(w)) negCount++;
      for (final w in excitingWords) if (lower.contains(w)) excCount++;
      for (final w in cautiousWords) if (lower.contains(w)) cauCount++;
    } else {
      // 日本語語彙拡張
      const jpPos = [
        '成功',
        '達成',
        '勝利',
        '発見',
        '革新',
        '期待',
        '前進',
        '合意',
        '協力',
        '進展',
        '成長',
        '改善',
        '回復',
        '拡大',
        '記録'
      ];
      const jpNeg = [
        '失敗',
        '敗北',
        '事故',
        '災害',
        '危機',
        '死亡',
        '被害',
        '悲劇',
        '紛争',
        '戦争',
        '減少',
        '下落',
        '崩壊',
        '不正',
        '訴訟',
        'スキャンダル'
      ];
      const jpExc = [
        '驚き',
        '衝撃',
        '急進',
        '革命',
        '爆発的',
        '劇的',
        '緊急',
        '速報',
        '急騰',
        '急落',
        '急増'
      ];
      const jpCau = ['懸念', '警告', '注意', '不透明', 'リスク', '緊張', '恐れ', '圧力', '減速'];
      for (final w in jpPos) if (content.contains(w)) posCount++;
      for (final w in jpNeg) if (content.contains(w)) negCount++;
      for (final w in jpExc) if (content.contains(w)) excCount++;
      for (final w in jpCau) if (content.contains(w)) cauCount++;
    }

    String mood;
    if (excCount > 0 && excCount >= posCount && excCount >= negCount) {
      mood = 'exciting';
    } else if (posCount > negCount && posCount >= cauCount) {
      mood = 'positive';
    } else if (negCount > posCount && negCount >= cauCount) {
      mood = 'negative';
    } else if (cauCount > 0) {
      mood = 'cautious';
    } else {
      mood = 'neutral';
    }

    // キーワード抽出
    final keywords = _extractKeywords(content, isEnglish: isEnglish);

    // 要約: 文の途中で切り捨て。強調語があれば先頭に追加。
    final baseSummary =
        content.length > 140 ? '${content.substring(0, 137)}...' : content;
    final prefix = mood == 'exciting'
        ? '[速報] '
        : (mood == 'cautious' ? '[注意] ' : (mood == 'negative' ? '[警戒] ' : ''));
    final summary = '$prefix$baseSummary';

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
    if (news.analysis == null) return 0.32; // 分析なしは低めスタート

    double score = 0.0;
    final mood = news.analysis!.mood.toLowerCase();

    // ムード重み（spreadを意識）
    switch (mood) {
      case 'exciting':
        score += 0.30;
        break;
      case 'negative':
        score += 0.24;
        break;
      case 'positive':
        score += 0.20;
        break;
      case 'cautious':
        score += 0.16;
        break;
      default: // neutral
        score += 0.10;
    }

    // キーワード（数による段階加点）
    final kw = news.analysis!.keywords.length;
    if (kw >= 5)
      score += 0.20;
    else if (kw >= 3)
      score += 0.12;
    else if (kw >= 1) score += 0.06;

    // タイトル長さ（情報量）
    final len = (news.description ?? news.title).length; // title は non-null
    if (len > 300)
      score += 0.10;
    else if (len > 160)
      score += 0.06;
    else if (len > 60) score += 0.03;

    // 画像の有無
    if ((news.urlToImage ?? '').isNotEmpty) score += 0.05;

    // 緊急キーワード
    final text = ((news.description ?? '') + ' ' + news.title).toLowerCase();
    if (RegExp(r'breaking|urgent|emergency|earthquake|wildfire|evacuate')
        .hasMatch(text)) {
      score += 0.25; // 強い加点
    } else if (RegExp(
            r'warn|alert|inflation|rate hike|security|sanction|outage')
        .hasMatch(text)) {
      score += 0.12;
    }

    // 数字・統計
    final numbers = RegExp(r'\d+').allMatches(text).length;
    if (numbers >= 6)
      score += 0.10;
    else if (numbers >= 3)
      score += 0.06;
    else if (numbers >= 1) score += 0.03;

    // 新しさ（最大0.15）
    final hoursAgo =
        DateTime.now().difference(news.analysis!.analyzedAt).inHours;
    if (hoursAgo < 36) {
      score += (36 - hoursAgo) * 0.0042; // ~0.15 max
    }

    // 擬似ランダムな微小揺らぎ（安定性確保のためURLハッシュ利用）
    final hash = news.url.hashCode.abs() % 1000;
    score += (hash / 1000.0) * 0.025; // 最大 +0.025

    // 圧縮 & クリップ
    score = (score * 0.92).clamp(0.0, 1.0);
    return score;
  }
}
