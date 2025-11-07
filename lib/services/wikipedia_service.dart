import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaService {
  static const String baseUrl = 'https://ja.wikipedia.org/api/rest_v1';

  // キーワードに関連する Wikipedia の要約を取得
  static Future<String?> getSummary(String keyword) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final response = await http.get(
        Uri.parse('$baseUrl/page/summary/$encodedKeyword'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['extract'] as String?;
      }
    } catch (e) {
      print('Wikipedia API error: $e');
    }
    return null;
  }

  // キーワードに関連する記事を検索
  static Future<List<String>> searchArticles(String keyword) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final response = await http.get(
        Uri.parse(
          'https://ja.wikipedia.org/w/api.php?action=opensearch&format=json&search=$encodedKeyword&limit=5',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data[1] as List).cast<String>();
      }
    } catch (e) {
      print('Wikipedia search error: $e');
    }
    return [];
  }

  // エンティティ（人物、場所、組織など）を抽出してWikipedia情報を取得
  static Future<Map<String, String>> extractEntities(String text) async {
    final Map<String, String> entities = {};

    // 簡易的なエンティティ抽出（実際はもっと洗練された方法を使用）
    final candidates = text
        .split(' ')
        .where((word) => word.length > 1 && word[0].toUpperCase() == word[0])
        .toSet();

    for (final candidate in candidates) {
      final summary = await getSummary(candidate);
      if (summary != null) {
        entities[candidate] = summary;
      }
    }

    return entities;
  }
}
