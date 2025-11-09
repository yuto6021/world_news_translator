import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'forex_service.dart';
import 'crypto_service.dart';

class MarketDataService {
  static final MarketDataService instance = MarketDataService._();
  MarketDataService._();

  // 取得対象シンボル（今後拡張しやすく）
  final List<String> symbols = ['USD/JPY', 'BTC/JPY'];

  // 最新値キャッシュ
  final Map<String, double> _cache = {};

  Future<List<String>> fetchTickerItems() async {
    final List<String> list = [];
    // USD/JPY
    final usdJpy = await ForexService.getUsdJpy();
    if (usdJpy != null) {
      _cache['USD/JPY'] = usdJpy;
      list.add('USD/JPY ${usdJpy.toStringAsFixed(3)}');
    } else if (_cache.containsKey('USD/JPY')) {
      list.add('USD/JPY ${_cache['USD/JPY']!.toStringAsFixed(3)}');
    } else {
      list.add('USD/JPY 取得失敗');
    }

    // BTC/JPY
    final btc = await CryptoService.getBitcoinPrice();
    final btcJpy = btc?['JPY'];
    if (btcJpy != null) {
      _cache['BTC/JPY'] = btcJpy;
      list.add('BTC/JPY ${btcJpy.round()}');
    } else if (_cache.containsKey('BTC/JPY')) {
      list.add('BTC/JPY ${_cache['BTC/JPY']!.round()}');
    } else {
      list.add('BTC/JPY 取得失敗');
    }

    return list;
  }
}
