import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_settings_service.dart';

class TranslationService {
  static const String deeplKey = '0d528a61-d312-4a5e-9096-cbbddbb17eb0:fx';
  static const String deeplUrl = 'https://api-free.deepl.com/v2/translate';

  // simple in-memory cache to avoid duplicate DeepL calls within a session
  static final Map<String, String> _cache = {};

  // small dictionary for a simple local fallback translation (English -> Japanese)
  static final Map<String, String> _tinyDict = {
    'president': '大統領',
    'election': '選挙',
    'economy': '経済',
    'market': '市場',
    'stock': '株価',
    'attack': '攻撃',
    'crash': '墜落',
    'earthquake': '地震',
    'death': '死亡',
    'dies': '死亡',
    'dead': '死亡',
    'protest': '抗議',
    'conflict': '紛争',
    'covid': 'コロナ',
    'pandemic': 'パンデミック',
    'report': '報告',
    'breaking': '速報',
    'investigation': '捜査',
    'government': '政府',
    'inflation': 'インフレ',
    'rate': '金利',
    'unemployment': '失業率',
    'hospital': '病院',
    'health': '医療',
    'fire': '火災',
    'police': '警察',
    'law': '法律',
    'court': '裁判所',
    'deal': '合意',
    'trade': '貿易',
    'climate': '気候',
    'change': '変化',
    'minister': '大臣',
    'ministerial': '閣僚の',
  };

  static Future<String> translateToJapanese(String text) async {
    if (text.trim().isEmpty) return '（本文なし）';
    if (_cache.containsKey(text)) return _cache[text]!;
    // ユーザーが DeepL を優先しない設定の場合、簡易翻訳をすぐ返す
    debugPrint(
        '[TranslationService] translateToJapanese: text="${text.length > 120 ? text.substring(0, 120) + '...' : text}"');
    if (!AppSettingsService.instance.preferDeepl.value) {
      debugPrint(
          '[TranslationService] preferDeepl is false: using pseudo-translation');
      final fallback = _pseudoTranslate(text);
      _cache[text] = fallback;
      return fallback;
    }

    try {
      debugPrint('[TranslationService] Calling DeepL API...');
      final response = await http.post(
        Uri.parse(deeplUrl),
        body: {
          'auth_key': deeplKey,
          'text': text,
          'target_lang': 'JA',
        },
      );

      debugPrint(
          '[TranslationService] DeepL response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result =
            (data['translations'] != null && data['translations'].isNotEmpty)
                ? data['translations'][0]['text']
                : '（翻訳結果なし）';
        debugPrint(
            '[TranslationService] DeepL returned text length=${result.length}');
        _cache[text] = result;
        return result;
      }

      // DeepLが制限に達したり認証エラーの時はローカルフォールバックを使う
      if (response.statusCode == 429 || response.statusCode == 403) {
        debugPrint(
            '[TranslationService] DeepL rate/auth error, falling back to pseudo-translation. body=${response.body}');
        final fallback = _pseudoTranslate(text);
        _cache[text] = fallback;
        return fallback;
      }

      debugPrint(
          '[TranslationService] DeepL returned unexpected status ${response.statusCode}, body=${response.body}');
      return '（翻訳サービスエラー:${response.statusCode}）';
    } catch (e) {
      debugPrint('[TranslationService] Exception while calling DeepL: $e');
      final fallback = _pseudoTranslate(text);
      _cache[text] = fallback;
      return fallback;
    }
  }

  // 超軽量の疑似翻訳: 既知語を置換してユーザーに意味の手がかりを与える
  static String _pseudoTranslate(String text) {
    var result = text;
    // 単語ごとに置換（長い文章でも安全）。記号・括弧付きの語や複数形にも対応する。
    _tinyDict.forEach((eng, jp) {
      // 単語境界にマッチするが、末尾のピリオドやカンマに続く場合も考慮
      result = result.replaceAll(
          RegExp('\\b' + RegExp.escape(eng) + '\\b', caseSensitive: false), jp);
      // 複数形の's'に対応（books -> book -> 辞書にbookがあれば置換される）
      result = result.replaceAll(
          RegExp('\\b' + RegExp.escape(eng) + 's\\b', caseSensitive: false),
          jp);
    });

    // それでも置換が無い場合はトークン分割して既知語だけを置換する試みを行う
    if (result == text) {
      final tokens = text.split(RegExp(r'[^A-Za-z]+'));
      var worked = false;
      var out = text;
      for (final t in tokens) {
        if (t.trim().isEmpty) continue;
        final key = t.toLowerCase().replaceAll(RegExp(r"[^a-z]"), '');
        if (_tinyDict.containsKey(key)) {
          out = out.replaceAll(RegExp(RegExp.escape(t)), _tinyDict[key]!);
          worked = true;
        } else if (key.endsWith('s') &&
            _tinyDict.containsKey(key.substring(0, key.length - 1))) {
          out = out.replaceAll(RegExp(RegExp.escape(t)),
              _tinyDict[key.substring(0, key.length - 1)]!);
          worked = true;
        }
      }
      if (worked) {
        _cache[text] = out + '（簡易翻訳）';
        return out + '（簡易翻訳）';
      }

      // 本当に置換ができない場合、長い文は先頭だけ切って注記を付与
      if (text.length > 160) {
        return '${text.substring(0, 157)}...（原文/簡易表示）';
      }
      return '$text（未翻訳・簡易表示）';
    }

    return '$result（簡易翻訳）';
  }

  static void clearCache() {
    _cache.clear();
  }
}
