import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String deeplKey = '0d528a61-d312-4a5e-9096-cbbddbb17eb0:fx';
  static const String deeplUrl = 'https://api-free.deepl.com/v2/translate';

  // simple in-memory cache to avoid duplicate DeepL calls within a session
  static final Map<String, String> _cache = {};

  static Future<String> translateToJapanese(String text) async {
    // 早期リターン: 空文字は翻訳リクエスト不要
    if (text.trim().isEmpty) return '（本文なし）';

    // return cached translation when available
    if (_cache.containsKey(text)) return _cache[text]!;

    try {
      final response = await http.post(
        Uri.parse(deeplUrl),
        body: {
          'auth_key': deeplKey,
          'text': text,
          'target_lang': 'JA',
        },
      );
      if (response.statusCode != 200) {
        // ステータスコードに応じた説明を返す
        if (response.statusCode == 429) return '（翻訳制限に達しました。しばらくして再試行してください）';
        if (response.statusCode == 403) return '（翻訳サービス認証エラー：APIキーを確認してください）';
        return '（翻訳サービスエラー:${response.statusCode}）';
      }
      final data = jsonDecode(response.body);
      final result =
          (data['translations'] != null && data['translations'].isNotEmpty)
              ? data['translations'][0]['text']
              : '（翻訳結果なし）';
      _cache[text] = result;
      return result;
    } catch (e) {
      // ネットワークや解析エラーを吸収して UI を壊さない
      return '（翻訳できません）';
    }
  }

  static void clearCache() {
    _cache.clear();
  }
}
