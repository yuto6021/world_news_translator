import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoService {
  // CoinGecko は API キー不要・無料（レート制限あり）
  // 価格は JPY / USD の両方を返す。失敗時は null
  static Future<Map<String, double>?> getBitcoinPrice() async {
    try {
      final uri = Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=jpy,usd');
      final res = await http.get(uri, headers: {
        'accept': 'application/json',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final btc = data['bitcoin'] as Map<String, dynamic>?;
        if (btc == null) return null;
        final jpy = (btc['jpy'] as num?)?.toDouble();
        final usd = (btc['usd'] as num?)?.toDouble();
        if (jpy == null || usd == null) return null;
        return {'JPY': jpy, 'USD': usd};
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, double>?> getEthPrice() async {
    try {
      final uri = Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=jpy,usd');
      final res = await http.get(uri, headers: {
        'accept': 'application/json',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final eth = data['ethereum'] as Map<String, dynamic>?;
        if (eth == null) return null;
        final jpy = (eth['jpy'] as num?)?.toDouble();
        final usd = (eth['usd'] as num?)?.toDouble();
        if (jpy == null || usd == null) return null;
        return {'JPY': jpy, 'USD': usd};
      }
    } catch (_) {}
    return null;
  }
}
