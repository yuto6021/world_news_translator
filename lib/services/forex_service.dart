import 'dart:convert';
import 'package:http/http.dart' as http;

class ForexService {
  // 無料API（CORSの都合でWebでは失敗する可能性あり）。失敗時はnullを返す。
  static Future<double?> getUsdJpy() async {
    try {
      final uri = Uri.parse('https://api.exchangerate.host/latest?base=USD&symbols=JPY');
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
