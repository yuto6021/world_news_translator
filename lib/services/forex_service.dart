import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForexService {
  // Alpha Vantage (キー必要) → Twelve Data (キー必要) → exchangerate.host (キー不要) のフォールバック
  static Future<double?> getUsdJpy() async {
    final alphaKey = dotenv.env['ALPHAVANTAGE_KEY'];
    final twelveKey = dotenv.env['TWELVEDATA_KEY'];
    double? lastOk;
    try {
      final prefs = await SharedPreferences.getInstance();
      lastOk = prefs.getDouble('last_usd_jpy');
    } catch (_) {}

    // 1. Alpha Vantage (FX_INTRADAY は1分足; ここでは CURRENCY_EXCHANGE_RATE を簡易利用)
    if (alphaKey != null && alphaKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
            'https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=JPY&apikey=$alphaKey');
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final rateObj =
              data['Realtime Currency Exchange Rate'] as Map<String, dynamic>?;
          final rateStr = rateObj?['5. Exchange Rate'] as String?;
          final rate = double.tryParse(rateStr ?? '');
          if (rate != null) return rate;
        }
      } catch (_) {}
    }

    // 2. Twelve Data
    if (twelveKey != null && twelveKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
            'https://api.twelvedata.com/price?symbol=USD/JPY&apikey=$twelveKey');
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final priceStr = data['price'] as String?;
          final price = double.tryParse(priceStr ?? '');
          if (price != null) return price;
        }
      } catch (_) {}
    }

    // 3. exchangerate.host（最終フォールバック1）
    try {
      final uri = Uri.parse(
          'https://api.exchangerate.host/latest?base=USD&symbols=JPY');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final jpy = (rates['JPY'] as num?)?.toDouble();
        if (jpy != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('last_usd_jpy', jpy);
          } catch (_) {}
          return jpy;
        }
      }
    } catch (_) {}

    // 4. open.er-api.com（CORS 対応の無料API）
    try {
      final uri = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        final jpy = (rates?['JPY'] as num?)?.toDouble();
        if (jpy != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('last_usd_jpy', jpy);
          } catch (_) {}
          return jpy;
        }
      }
    } catch (_) {}

    // 失敗時は最後に成功した値を返して UI の『取得失敗』を回避
    if (lastOk != null) return lastOk;
    return null;
  }
}
