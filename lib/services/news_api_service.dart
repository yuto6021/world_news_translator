import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsApiService {
  static const String apiKey = '09e3b347c2194cdb9899963e334e7528';
  static const String baseUrl = 'https://newsapi.org/v2/top-headlines';

  static Future<List<Article>> fetchArticlesByCountry(
      String countryCode) async {
    final response = await http
        .get(Uri.parse('$baseUrl?country=$countryCode&apiKey=$apiKey'));
    final data = jsonDecode(response.body);
    return (data['articles'] as List).map((e) => Article.fromJson(e)).toList();
  }

  // countryCode を渡すとその国のトップヘッドライン（category=general）を取得します。
  // null の場合は country を指定せず取得します（API のデフォルト動作に委ねる）。
  static Future<List<Article>> fetchTrendingArticles(
      [String? countryCode]) async {
    // デフォルトは Global（country パラメータを送らない）
    final uriStr = (countryCode != null && countryCode.isNotEmpty)
        ? '$baseUrl?category=general&country=$countryCode&apiKey=$apiKey'
        : '$baseUrl?category=general&apiKey=$apiKey';
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
}
