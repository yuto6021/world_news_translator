import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/article.dart';

class NewsApiService {
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

  static const int pageSize = 20;

  static Future<List<Article>> fetchArticlesByCountry(String countryCode,
      {int page = 1}) async {
    // GNews API を優先
    if (_gNewsApiKey.isNotEmpty) {
      try {
        return await _fetchFromGNews(countryCode, page);
      } catch (e) {
        print('GNews API failed: $e, trying Currents...');
      }
    }

    // Currents API へフォールバック
    if (_currentsApiKey.isNotEmpty) {
      try {
        return await _fetchFromCurrents(countryCode, page);
      } catch (e) {
        print('Currents API failed: $e, trying MediaStack...');
      }
    }

    // MediaStack API へフォールバック
    if (_mediaStackApiKey.isNotEmpty) {
      try {
        return await _fetchFromMediaStack(countryCode, page);
      } catch (e) {
        print('MediaStack API failed: $e');
      }
    }

    throw Exception('All news APIs failed or no API keys configured');
  }

  // GNews API からニュース取得
  static Future<List<Article>> _fetchFromGNews(
      String countryCode, int page) async {
    final url =
        '$_gNewsBaseUrl?country=$countryCode&apikey=$_gNewsApiKey&max=$pageSize&page=$page&lang=en';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('GNews API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['articles'] == null) return [];
    return (data['articles'] as List).map((e) => _articleFromGNews(e)).toList();
  }

  // Currents API からニュース取得
  static Future<List<Article>> _fetchFromCurrents(
      String countryCode, int page) async {
    final url =
        '$_currentsBaseUrl?country=$countryCode&apiKey=$_currentsApiKey&page_size=$pageSize&page_number=$page&language=en';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Currents API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['news'] == null) return [];
    return (data['news'] as List).map((e) => _articleFromCurrents(e)).toList();
  }

  // MediaStack API からニュース取得
  static Future<List<Article>> _fetchFromMediaStack(
      String countryCode, int page) async {
    final offset = (page - 1) * pageSize;
    final url =
        '$_mediaStackBaseUrl?access_key=$_mediaStackApiKey&countries=$countryCode&limit=$pageSize&offset=$offset&languages=en';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('MediaStack API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['data'] == null) return [];
    return (data['data'] as List)
        .map((e) => _articleFromMediaStack(e))
        .toList();
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
    if (_gNewsApiKey.isNotEmpty) {
      try {
        final cc = countryCode ?? 'us'; // デフォルト米国
        return await _fetchFromGNews(cc, page);
      } catch (e) {
        print('Trending GNews failed: $e');
      }
    }
    if (_currentsApiKey.isNotEmpty) {
      try {
        final cc = countryCode ?? 'us';
        return await _fetchFromCurrents(cc, page);
      } catch (e) {
        print('Trending Currents failed: $e');
      }
    }
    if (_mediaStackApiKey.isNotEmpty) {
      try {
        final cc = countryCode ?? 'us';
        return await _fetchFromMediaStack(cc, page);
      } catch (e) {
        print('Trending MediaStack failed: $e');
      }
    }
    return [];
  }

  // keyword search across headlines (q parameter)
  static Future<List<Article>> searchArticles(String query) async {
    // GNews search endpoint
    if (_gNewsApiKey.isNotEmpty) {
      try {
        final url =
            '$_gNewsBaseUrl?q=${Uri.encodeQueryComponent(query)}&apikey=$_gNewsApiKey&max=$pageSize&lang=en';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['articles'] != null) {
            return (data['articles'] as List)
                .map((e) => _articleFromGNews(e))
                .toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  // 重要なトップニュースを取得
  static Future<List<Article>> getTopHeadlines() async {
    // 優先順位: GNews -> Currents -> MediaStack
    for (final attempt in ['g', 'c', 'm']) {
      try {
        List<Article> arts = [];
        if (attempt == 'g' && _gNewsApiKey.isNotEmpty) {
          arts = await _fetchFromGNews('us', 1);
        } else if (attempt == 'c' && _currentsApiKey.isNotEmpty) {
          arts = await _fetchFromCurrents('us', 1);
        } else if (attempt == 'm' && _mediaStackApiKey.isNotEmpty) {
          arts = await _fetchFromMediaStack('us', 1);
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
}
