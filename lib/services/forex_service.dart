import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForexService {
  // Alpha Vantage (キー必要) → Twelve Data (キー必要) → exchangerate.host (キー不要) のフォールバック
  static Future<double?> getUsdJpy() async {
    final alphaKey = dotenv.env['ALPHAVANTAGE_KEY'];
    final twelveKey = dotenv.env['TWELVEDATA_KEY'];

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

    // 3. exchangerate.host（最終フォールバック）
    try {
      final uri = Uri.parse(
          'https://api.exchangerate.host/latest?base=USD&symbols=JPY');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final jpy = (rates['JPY'] as num?)?.toDouble();
        return jpy;
      }
    } catch (_) {}
    return null;
  }
}
