import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/article.dart';

class NewsApiService {
  // NewsAPI.org (優先) - 無料枠あり
  static final String _newsApiOrgKey = dotenv.env['NEWS_API_KEY'] ?? '';
  static const String _newsApiOrgTopHeadlinesBaseUrl =
      'https://newsapi.org/v2/top-headlines';
  static const String _newsApiOrgEverythingBaseUrl =
      'https://newsapi.org/v2/everything';

  // GNews API (優先) - 150+国対応、100リクエスト/日
  static final String _gNewsApiKey = dotenv.env['GNEWS_API_KEY'] ?? '';
  static const String _gNewsBaseUrl = 'https://gnews.io/api/v4/top-headlines';

  // Currents API (フォールバック1) - 600リクエスト/日
  static final String _currentsApiKey = dotenv.env['CURRENTS_API_KEY'] ?? '';
  static const String _currentsBaseUrl =
      'https://api.currentsapi.services/v1/latest-news';

  // MediaStack (フォールバック2) - 500リクエスト/月
  static final String _mediaStackApiKey =
      dotenv.env['MEDIASTACK_API_KEY'] ?? '';
  static const String _mediaStackBaseUrl = 'http://api.mediastack.com/v1/news';

  // APIキー不要フォールバック（暫定）
  static const String _redditWorldNewsBaseUrl =
      'https://www.reddit.com/r/worldnews/hot.json';

  static const int pageSize = 20;
  // レート制限管理
  static final Map<String, DateTime> _rateLimitedUntil = {};
  static final Map<String, DateTime> _lastLogTime = {};
  static const Duration _rateLimitSilence = Duration(minutes: 10);
  static const Duration _logThrottle = Duration(seconds: 30);
  static List<Article> _lastTrendingCache = const [];
  static final Map<String, List<Article>> _lastCountryCache = {};

  static bool _isRateLimited(String provider) {
    final until = _rateLimitedUntil[provider];
    return until != null && DateTime.now().isBefore(until);
  }

  static void _markRateLimited(String provider) {
    _rateLimitedUntil[provider] = DateTime.now().add(_rateLimitSilence);
  }

  static void _logOnce(String provider, String message) {
    final now = DateTime.now();
    final last = _lastLogTime[provider];
    if (last == null || now.difference(last) > _logThrottle) {
      print(message); // 一時的デバッグログ（後で削除可）
      _lastLogTime[provider] = now;
    }
  }

  static Future<List<Article>> fetchArticlesByCountry(String countryCode,
      {int page = 1}) async {
    // 優先順で試行（レート制限中はスキップ）
    if (_newsApiOrgKey.isNotEmpty && !_isRateLimited('newsapi')) {
      try {
        return await _fetchFromNewsApiOrg(countryCode, page);
      } catch (e) {
        _logOnce('newsapi', 'NewsAPI.org failed: $e');
      }
    }
    if (_gNewsApiKey.isNotEmpty && !_isRateLimited('gnews')) {
      try {
        return await _fetchFromGNews(countryCode, page);
      } catch (e) {
        _logOnce('gnews', 'GNews API failed: $e');
      }
    }
    if (_currentsApiKey.isNotEmpty && !_isRateLimited('currents')) {
      try {
        return await _fetchFromCurrents(countryCode, page);
      } catch (e) {
        _logOnce('currents', 'Currents API failed: $e');
      }
    }
    if (_mediaStackApiKey.isNotEmpty && !_isRateLimited('mediastack')) {
      try {
        return await _fetchFromMediaStack(countryCode, page);
      } catch (e) {
        _logOnce('mediastack', 'MediaStack API failed: $e');
      }
    }

    // キー不要フォールバック（国別は未対応のため汎用ワールドニュース）
    try {
      final list = await _fetchFromRedditWorldNews(page);
      _cacheCountry(countryCode, list);
      _cacheTrending(list);
      return list;
    } catch (e) {
      _logOnce('reddit', 'Reddit worldnews fallback failed: $e');
    }

    if (_isRateLimited('gnews') ||
      _isRateLimited('newsapi') ||
        _isRateLimited('currents') ||
        _isRateLimited('mediastack')) {
      final cached = _lastCountryCache[countryCode.toLowerCase()] ?? const [];
      if (cached.isNotEmpty) {
        _logOnce('country',
            'All providers are rate-limited. Returning cached country news for $countryCode');
        return cached;
      }
      _logOnce('country',
          'All providers are rate-limited and no country cache exists for $countryCode');
      return [];
    }
    final cached = _lastCountryCache[countryCode.toLowerCase()] ?? const [];
    if (cached.isNotEmpty) {
      _logOnce('country',
          'All providers failed. Returning cached country news for $countryCode');
      return cached;
    }
    return [];
  }

  // GNews API からニュース取得
  static Future<List<Article>> _fetchFromNewsApiOrg(
      String countryCode, int page) async {
    final cc = countryCode.toLowerCase();
    final url =
        '$_newsApiOrgTopHeadlinesBaseUrl?country=$cc&apiKey=$_newsApiOrgKey&pageSize=$pageSize&page=$page';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 429) {
      _markRateLimited('newsapi');
      _logOnce('newsapi',
          'NewsAPI.org rate-limited (429) backoff ${_rateLimitSilence.inMinutes}m');
      throw Exception('APIレート制限: NewsAPI.org (429)');
    }
    if (response.statusCode != 200) {
      throw Exception('NewsAPI.org error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['articles'] == null) return [];
    final list = (data['articles'] as List)
        .map((e) => _articleFromNewsApiOrg(e))
        .toList();
    final filtered = _filterArticlesWithImage(list);
    _cacheCountry(countryCode, filtered);
    return filtered;
  }

  // GNews API からニュース取得
  static Future<List<Article>> _fetchFromGNews(
      String countryCode, int page) async {
    final url =
        '$_gNewsBaseUrl?country=$countryCode&apikey=$_gNewsApiKey&max=$pageSize&page=$page&lang=en';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 429) {
      _markRateLimited('gnews');
      _logOnce('gnews',
          'GNews rate-limited (429) backoff ${_rateLimitSilence.inMinutes}m');
      throw Exception('APIレート制限: GNews (429)');
    }
    if (response.statusCode != 200) {
      throw Exception('GNews API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['articles'] == null) return [];
    final list =
        (data['articles'] as List).map((e) => _articleFromGNews(e)).toList();
    final filtered = _filterArticlesWithImage(list);
    _cacheCountry(countryCode, filtered);
    return filtered;
  }

  // Currents API からニュース取得
  static Future<List<Article>> _fetchFromCurrents(
      String countryCode, int page) async {
    final url =
        '$_currentsBaseUrl?country=$countryCode&apiKey=$_currentsApiKey&page_size=$pageSize&page_number=$page&language=en';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 429) {
      _markRateLimited('currents');
      _logOnce('currents',
          'Currents rate-limited (429) backoff ${_rateLimitSilence.inMinutes}m');
      throw Exception('APIレート制限: Currents (429)');
    }
    if (response.statusCode != 200) {
      throw Exception('Currents API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['news'] == null) return [];
    final list =
        (data['news'] as List).map((e) => _articleFromCurrents(e)).toList();
    final filtered = _filterArticlesWithImage(list);
    _cacheCountry(countryCode, filtered);
    return filtered;
  }

  // MediaStack API からニュース取得
  static Future<List<Article>> _fetchFromMediaStack(
      String countryCode, int page) async {
    final offset = (page - 1) * pageSize;
    final url =
        '$_mediaStackBaseUrl?access_key=$_mediaStackApiKey&countries=$countryCode&limit=$pageSize&offset=$offset&languages=en';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 429) {
      _markRateLimited('mediastack');
      _logOnce('mediastack',
          'MediaStack rate-limited (429) backoff ${_rateLimitSilence.inMinutes}m');
      throw Exception('APIレート制限: MediaStack (429)');
    }
    if (response.statusCode != 200) {
      throw Exception('MediaStack API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['data'] == null) return [];
    final list = (data['data'] as List)
        .map((e) => _articleFromMediaStack(e))
        .toList();
    final filtered = _filterArticlesWithImage(list);
    _cacheCountry(countryCode, filtered);
    return filtered;
  }

  static void _cacheCountry(String countryCode, List<Article> list) {
    if (list.isNotEmpty) {
      _lastCountryCache[countryCode.toLowerCase()] = List<Article>.from(list);
    }
  }

  static void _cacheTrending(List<Article> list) {
    if (list.isNotEmpty) {
      _lastTrendingCache = List<Article>.from(list);
    }
  }

  static bool _hasUsableImage(Article article) {
    final imageUrl = (article.urlToImage ?? '').trim();
    if (imageUrl.isEmpty) return false;
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  static List<Article> _filterArticlesWithImage(List<Article> list) {
    return list.where(_hasUsableImage).toList();
  }

  // GNews レスポンスから Article に変換
  static Article _articleFromNewsApiOrg(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
    );
  }

  // GNews レスポンスから Article に変換
  static Article _articleFromGNews(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['image'],
    );
  }

  // Currents レスポンスから Article に変換
  static Article _articleFromCurrents(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['image'] ?? 'none',
    );
  }

  // MediaStack レスポンスから Article に変換
  static Article _articleFromMediaStack(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['image'],
    );
  }

  // countryCode を渡すとその国のトップヘッドライン（category=general）を取得します。
  // null の場合は country を指定せず取得します（API のデフォルト動作に委ねる）。
  static Future<List<Article>> fetchTrendingArticles(
      [String? countryCode, int page = 1]) async {
    // countryCode が null の場合はグローバル扱い (GNews は country 必須なのでフォールバック利用)
    if (_newsApiOrgKey.isNotEmpty && !_isRateLimited('newsapi')) {
      try {
        final cc = countryCode ?? 'us';
        final list = await _fetchFromNewsApiOrg(cc, page);
        _cacheTrending(list);
        return list;
      } catch (e) {
        _logOnce('newsapi_trending', 'Trending NewsAPI.org failed: $e');
      }
    }
    if (_gNewsApiKey.isNotEmpty && !_isRateLimited('gnews')) {
      try {
        final cc = countryCode ?? 'us'; // デフォルト米国
        final list = await _fetchFromGNews(cc, page);
        _cacheTrending(list);
        return list;
      } catch (e) {
        _logOnce('gnews_trending', 'Trending GNews failed: $e');
        if (e.toString().contains('レート制限')) {
          // レート制限時は即座に他APIへフォールバック
        }
      }
    }
    if (_currentsApiKey.isNotEmpty && !_isRateLimited('currents')) {
      try {
        final cc = countryCode ?? 'us';
        final list = await _fetchFromCurrents(cc, page);
        _cacheTrending(list);
        return list;
      } catch (e) {
        _logOnce('currents_trending', 'Trending Currents failed: $e');
      }
    }
    if (_mediaStackApiKey.isNotEmpty && !_isRateLimited('mediastack')) {
      try {
        final cc = countryCode ?? 'us';
        final list = await _fetchFromMediaStack(cc, page);
        _cacheTrending(list);
        return list;
      } catch (e) {
        _logOnce('mediastack_trending', 'Trending MediaStack failed: $e');
      }
    }

    // APIキー不要フォールバック
    try {
      final list = await _fetchFromRedditWorldNews(page);
      _cacheTrending(list);
      return list;
    } catch (e) {
      _logOnce('reddit_trending', 'Trending Reddit fallback failed: $e');
    }

    if (_isRateLimited('gnews') ||
      _isRateLimited('newsapi') ||
        _isRateLimited('currents') ||
        _isRateLimited('mediastack')) {
      if (_lastTrendingCache.isNotEmpty) {
        _logOnce('trending',
            'All providers are rate-limited. Returning cached trending news');
        return _lastTrendingCache;
      }
      _logOnce('trending',
          'All providers are rate-limited and no trending cache exists');
      return [];
    }
    if (_lastTrendingCache.isNotEmpty) {
      _logOnce('trending', 'All providers failed. Returning cached trending');
      return _lastTrendingCache;
    }
    return [];
  }

  /// APIキー設定状況を確認する簡易メソッド（UIでの診断用）
  static Map<String, bool> configStatus() {
    return {
      'newsapi': _newsApiOrgKey.isNotEmpty,
      'gnews': _gNewsApiKey.isNotEmpty,
      'currents': _currentsApiKey.isNotEmpty,
      'mediastack': _mediaStackApiKey.isNotEmpty,
    };
  }

  static Map<String, Duration> rateLimitRemaining() {
    final now = DateTime.now();
    final m = <String, Duration>{};
    _rateLimitedUntil.forEach((key, until) {
      final diff = until.difference(now);
      if (diff.inMilliseconds > 0) m[key] = diff;
    });
    return m;
  }

  // keyword search across headlines (q parameter)
  static Future<List<Article>> searchArticles(String query) async {
    if (_newsApiOrgKey.isNotEmpty && !_isRateLimited('newsapi')) {
      try {
        final url =
            '$_newsApiOrgEverythingBaseUrl?q=${Uri.encodeQueryComponent(query)}&apiKey=$_newsApiOrgKey&pageSize=$pageSize&sortBy=publishedAt&language=en';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 429) {
          _markRateLimited('newsapi');
          _logOnce('newsapi_search',
              'NewsAPI.org search rate-limited (429) backoff ${_rateLimitSilence.inMinutes}m');
        } else if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['articles'] != null) {
            final list = (data['articles'] as List)
                .map((e) => _articleFromNewsApiOrg(e))
                .toList();
            return _filterArticlesWithImage(list);
          }
        }
      } catch (_) {}
    }

    // GNews search endpoint
    if (_gNewsApiKey.isNotEmpty) {
      try {
        final url =
            '$_gNewsBaseUrl?q=${Uri.encodeQueryComponent(query)}&apikey=$_gNewsApiKey&max=$pageSize&lang=en';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['articles'] != null) {
            final list = (data['articles'] as List)
                .map((e) => _articleFromGNews(e))
                .toList();
            return _filterArticlesWithImage(list);
          }
        }
      } catch (_) {}
    }
    return [];
  }

  // 重要なトップニュースを取得
  static Future<List<Article>> getTopHeadlines() async {
    // 優先順位: GNews -> Currents -> MediaStack
    for (final attempt in ['n', 'g', 'c', 'm', 'r']) {
      try {
        List<Article> arts = [];
        if (attempt == 'n' && _newsApiOrgKey.isNotEmpty) {
          arts = await _fetchFromNewsApiOrg('us', 1);
        } else if (attempt == 'g' && _gNewsApiKey.isNotEmpty) {
          arts = await _fetchFromGNews('us', 1);
        } else if (attempt == 'c' && _currentsApiKey.isNotEmpty) {
          arts = await _fetchFromCurrents('us', 1);
        } else if (attempt == 'm' && _mediaStackApiKey.isNotEmpty) {
          arts = await _fetchFromMediaStack('us', 1);
        } else if (attempt == 'r') {
          arts = await _fetchFromRedditWorldNews(1);
        }
        if (arts.isNotEmpty) {
          arts.sort(
              (a, b) => (b.importance ?? 0.5).compareTo(a.importance ?? 0.5));
          return arts.take(10).toList();
        }
      } catch (e) {
        print('getTopHeadlines attempt $attempt failed: $e');
      }
    }
    return [];
  }

  // Reddit worldnews から取得（キー不要）
  static Future<List<Article>> _fetchFromRedditWorldNews(int page) async {
    // after 方式よりも、まずは安定して同一ページ先頭を返す簡易実装
    final url = '$_redditWorldNewsBaseUrl?raw_json=1&limit=$pageSize';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'world-news-translator/1.0'
    });
    if (response.statusCode == 429) {
      _logOnce('reddit', 'Reddit rate-limited (429)');
      throw Exception('APIレート制限: Reddit (429)');
    }
    if (response.statusCode != 200) {
      throw Exception('Reddit API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final children =
        (((data['data'] ?? const {}) as Map<String, dynamic>)['children']
                as List?) ??
            const [];

    final articles = <Article>[];
    for (final item in children) {
      final d = ((item as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final title = (d['title'] ?? '').toString();
      final permalink = (d['permalink'] ?? '').toString();
      final externalUrl = (d['url'] ?? '').toString();
      final thumb = (d['thumbnail'] ?? '').toString();

      if (title.isEmpty) continue;
      final url = externalUrl.isNotEmpty
          ? externalUrl
          : 'https://www.reddit.com$permalink';
      final image = thumb.startsWith('http') ? thumb : null;

      articles.add(Article(
        title: title,
        description: (d['selftext'] ?? '').toString(),
        url: url,
        urlToImage: image,
      ));
    }
    return _filterArticlesWithImage(articles);
  }
}
