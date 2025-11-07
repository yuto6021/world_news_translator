import 'dart:convert';
import 'package:http/http.dart' as http;

class TrendsService {
  // Google Trendsの非公式APIエンドポイント（制限あり）
  static const String baseUrl =
      'https://trends.google.com/trends/api/dailytrends';

  static Future<List<Map<String, dynamic>>> getTrends() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?hl=ja&geo=JP&ns=15'),
      );

      if (response.statusCode == 200) {
        // Google Trendsの応答は ")]}'" で始まるため、それを削除
        final jsonStr = response.body.replaceFirst(")]}'", '');
        final data = json.decode(jsonStr);

        final List trendingSearches =
            data['default']['trendingSearchesDays'][0]['trendingSearches'];
        return trendingSearches
            .map((trend) {
              return {
                'title': trend['title']['query'],
                'traffic': trend['formattedTraffic'],
                'articles': (trend['articles'] as List).map((article) {
                  return {
                    'title': article['title'],
                    'url': article['url'],
                  };
                }).toList(),
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Trends API error: $e');
    }
    return [];
  }

  // 特定のキーワードの関連トピックを取得
  static Future<List<String>> getRelatedTopics(String keyword) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final response = await http.get(
        Uri.parse(
            'https://trends.google.com/trends/api/explore?hl=ja&q=$encodedKeyword&geo=JP'),
      );

      if (response.statusCode == 200) {
        final jsonStr = response.body.replaceFirst(")]}'", '');
        final data = json.decode(jsonStr);

        // 関連トピックを抽出（実際のAPIでは構造が異なる可能性があります）
        if (data.containsKey('related_topics')) {
          return (data['related_topics'] as List)
              .map((topic) => topic['title'].toString())
              .toList();
        }
      }
    } catch (e) {
      print('Related topics API error: $e');
    }
    return [];
  }
}
