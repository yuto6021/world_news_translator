import 'dart:async';
import 'forex_service.dart';
import 'crypto_service.dart';

class MarketDataService {
  static final MarketDataService instance = MarketDataService._();
  MarketDataService._();

  // 拡張: FX + 主要暗号資産
  // 通貨ペアは ForexService で個別メソッド未実装なので USD/JPY 以外は簡易的に null 扱い（将来拡張）
  final List<String> symbols = [
    'USD/JPY',
    'EUR/JPY',
    'GBP/JPY',
    'BTC/JPY',
    'ETH/JPY',
  ];

  // 最新値キャッシュ
  final Map<String, double> _cache = {};

  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration refreshInterval = const Duration(minutes: 2);

  /// ティッカー表示用文字列の取得。
  /// 一定間隔内ならキャッシュ値のみで再構築（API叩きすぎ防止）。
  Future<List<String>> fetchTickerItems({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final bool shouldRefresh = forceRefresh || now.difference(_lastFetch) > refreshInterval;
    final List<String> items = [];

    // USD/JPY (唯一のリアル取得実装)
    if (shouldRefresh) {
      final usdJpy = await ForexService.getUsdJpy();
      if (usdJpy != null) {
        _cache['USD/JPY'] = usdJpy;
        _lastFetch = now;
      }
    }
    if (_cache.containsKey('USD/JPY')) {
      items.add(_fmt('USD/JPY', _cache['USD/JPY']!, fraction: 3));
    } else {
      items.add('USD/JPY 取得失敗');
    }

    // 擬似: EUR/JPY, GBP/JPY （USD/JPY を基に適当係数で近似。後で本実装に置換）
    // 係数は実勢レートに大きく乖離しない範囲の簡易近似
    if (_cache.containsKey('USD/JPY')) {
      final usd = _cache['USD/JPY']!;
      _cache['EUR/JPY'] = usd * 0.92; // 仮係数
      _cache['GBP/JPY'] = usd * 1.16; // 仮係数
    }
    items.add(_cache.containsKey('EUR/JPY')
        ? _fmt('EUR/JPY', _cache['EUR/JPY']!, fraction: 3)
        : 'EUR/JPY 未取得');
    items.add(_cache.containsKey('GBP/JPY')
        ? _fmt('GBP/JPY', _cache['GBP/JPY']!, fraction: 3)
        : 'GBP/JPY 未取得');

    // 暗号資産 (BTC, ETH)
    if (shouldRefresh) {
      final btc = await CryptoService.getBitcoinPrice();
      final btcJpy = btc?['JPY'];
      if (btcJpy != null) _cache['BTC/JPY'] = btcJpy;

      final eth = await CryptoService.getEthPrice();
      final ethJpy = eth?['JPY'];
      if (ethJpy != null) _cache['ETH/JPY'] = ethJpy;
    }
    items.add(_cache.containsKey('BTC/JPY')
        ? _fmt('BTC/JPY', _cache['BTC/JPY']!, round: true)
        : 'BTC/JPY 取得失敗');
    items.add(_cache.containsKey('ETH/JPY')
        ? _fmt('ETH/JPY', _cache['ETH/JPY']!, fraction: 0, round: true)
        : 'ETH/JPY 取得失敗');

    return items;
  }

  String _fmt(String symbol, double value, {int fraction = 2, bool round = false}) {
    return round
        ? '$symbol ${value.round()}'
        : '$symbol ${value.toStringAsFixed(fraction)}';
  }
}
