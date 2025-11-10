import 'dart:async';
import '../models/country.dart';
import '../services/news_api_service.dart';

/// セッション中に「記事を取得できた国」だけを共有する簡易サービス
class AvailabilityService {
  static final Map<String, String> _jpNames = {
    'jp': '日本',
    'us': 'アメリカ',
    'gb': 'イギリス',
    'fr': 'フランス',
    'de': 'ドイツ',
    'kr': '韓国',
    'cn': '中国',
    'in': 'インド',
    'br': 'ブラジル',
    'mx': 'メキシコ',
    'ca': 'カナダ',
    'ae': 'UAE',
    'sa': 'サウジアラビア',
    'eg': 'エジプト',
    'za': '南アフリカ',
    'au': 'オーストラリア',
    'es': 'スペイン',
    'ru': 'ロシア',
    'id': 'インドネシア',
  };

  static final List<String> _candidates = [
    'jp',
    'us',
    'gb',
    'fr',
    'de',
    'kr',
    'cn',
    'in',
    'br',
    'mx',
    'ca',
    'ae',
    'sa',
    'eg',
    'za',
    'au',
    'es',
    'ru',
    'id'
  ];

  static List<String>? _cachedCodes;
  static DateTime? _lastChecked;
  static const _ttl = Duration(minutes: 10);

  /// 利用可能な国コード一覧を返す（日本は常に含める）。結果はメモリに10分キャッシュ。
  static Future<List<String>> getAvailableCountryCodes(
      {bool includeJapan = true}) async {
    final now = DateTime.now();
    if (_cachedCodes != null &&
        _lastChecked != null &&
        now.difference(_lastChecked!) < _ttl) {
      final list = List<String>.from(_cachedCodes!);
      if (includeJapan && !list.contains('jp')) list.insert(0, 'jp');
      return list;
    }

    final results = <String>[];
    // 並列で叩く。失敗や0件はスキップ。
    try {
      await Future.wait(_candidates.map((code) async {
        try {
          final articles =
              await NewsApiService.fetchArticlesByCountry(code, page: 1);
          if (articles.isNotEmpty) {
            results.add(code);
          }
        } catch (_) {
          // ignore individual failures
        }
      })).timeout(const Duration(seconds: 10));
    } catch (_) {
      // タイムアウトまたは全体的な失敗時は全候補を返す
      results.addAll(_candidates);
    }

    // 結果が少なすぎる場合（3カ国以下）は全候補を返す
    if (results.length <= 3) {
      results.clear();
      results.addAll(_candidates);
    }

    // 日本を必ず含める
    if (includeJapan && !results.contains('jp')) results.insert(0, 'jp');

    // キャッシュ
    _cachedCodes = List<String>.from(results);
    _lastChecked = DateTime.now();
    return results;
  }

  /// Countryモデルのリストを返す（日本語名付与）
  static Future<List<Country>> getAvailableCountries(
      {bool includeJapan = true}) async {
    final codes = await getAvailableCountryCodes(includeJapan: includeJapan);
    return codes
        .where((c) => _jpNames.containsKey(c))
        .map((c) => Country(name: _jpNames[c]!, code: c))
        .toList(growable: false);
  }
}
