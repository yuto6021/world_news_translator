import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsApiService {
  static const String apiKey = '09e3b347c2194cdb9899963e334e7528';
  static const String baseUrl = 'https://newsapi.org/v2/top-headlines';
  static const int pageSize = 20; // 1ページあたりの記事数

  static Future<List<Article>> fetchArticlesByCountry(String countryCode,
      {int page = 1}) async {
    final response = await http.get(Uri.parse(
        '$baseUrl?country=$countryCode&apiKey=$apiKey&pageSize=$pageSize&page=$page'));
    final data = jsonDecode(response.body);
    return (data['articles'] as List).map((e) => Article.fromJson(e)).toList();
  }

  // countryCode を渡すとその国のトップヘッドライン（category=general）を取得します。
  // null の場合は country を指定せず取得します（API のデフォルト動作に委ねる）。
  static Future<List<Article>> fetchTrendingArticles(
      [String? countryCode, int page = 1]) async {
    // デフォルトは Global（country パラメータを送らない）
    final uriStr = (countryCode != null && countryCode.isNotEmpty)
        ? '$baseUrl?category=general&country=$countryCode&apiKey=$apiKey&pageSize=$pageSize&page=$page'
        : '$baseUrl?category=general&apiKey=$apiKey&pageSize=$pageSize&page=$page';
    final response = await http.get(Uri.parse(uriStr));
    final data = jsonDecode(response.body);
    return (data['articles'] as List).map((e) => Article.fromJson(e)).toList();
  }

  // keyword search across headlines (q parameter)
  static Future<List<Article>> searchArticles(String query) async {
    final uriStr =
        '$baseUrl?q=${Uri.encodeQueryComponent(query)}&apiKey=$apiKey';
    final response = await http.get(Uri.parse(uriStr));
    final data = jsonDecode(response.body);
    if (data == null || data['articles'] == null) return [];
    return (data['articles'] as List).map((e) => Article.fromJson(e)).toList();
  }

  // 重要なトップニュースを取得
  Future<List<Article>> getTopHeadlines() async {
    const uriStr = '$baseUrl?language=en&pageSize=10&apiKey=$apiKey';
    final response = await http.get(Uri.parse(uriStr));
    final data = jsonDecode(response.body);
    if (data == null || data['articles'] == null) return [];
    final articles = (data['articles'] as List)
        .map((e) => Article.fromJson(e))
        .where((article) => article.urlToImage != null) // 画像のある記事のみ
        .toList();
    articles
        .sort((a, b) => (b.importance ?? 0.5).compareTo(a.importance ?? 0.5));
    return articles;
  }
}
