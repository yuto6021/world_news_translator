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
  final Map<String, double> _prev = {};

  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration refreshInterval = const Duration(minutes: 2);

  /// ティッカー表示用文字列の取得。
  /// 一定間隔内ならキャッシュ値のみで再構築（API叩きすぎ防止）。
  Future<List<String>> fetchTickerItems({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final bool shouldRefresh =
        forceRefresh || now.difference(_lastFetch) > refreshInterval;
    final List<String> items = [];

    // USD/JPY (唯一のリアル取得実装)
    if (shouldRefresh) {
      final usdJpy = await ForexService.getUsdJpy();
      if (usdJpy != null) {
        _prev['USD/JPY'] = _cache['USD/JPY'] ?? usdJpy;
        _cache['USD/JPY'] = usdJpy;
        _lastFetch = now;
      }
    }
    if (_cache.containsKey('USD/JPY')) {
      items.add(_withArrow('USD/JPY', _cache['USD/JPY']!, fraction: 3));
    } else {
      items.add('USD/JPY 取得失敗');
    }

    // 擬似: EUR/JPY, GBP/JPY （USD/JPY を基に適当係数で近似。後で本実装に置換）
    // 係数は実勢レートに大きく乖離しない範囲の簡易近似
    if (_cache.containsKey('USD/JPY')) {
      final usd = _cache['USD/JPY']!;
      final eur = usd * 0.92; // 仮係数
      final gbp = usd * 1.16; // 仮係数
      _prev['EUR/JPY'] = _cache['EUR/JPY'] ?? eur;
      _prev['GBP/JPY'] = _cache['GBP/JPY'] ?? gbp;
      _cache['EUR/JPY'] = eur;
      _cache['GBP/JPY'] = gbp;
    }
    items.add(_cache.containsKey('EUR/JPY')
        ? _withArrow('EUR/JPY', _cache['EUR/JPY']!, fraction: 3)
        : 'EUR/JPY 未取得');
    items.add(_cache.containsKey('GBP/JPY')
        ? _withArrow('GBP/JPY', _cache['GBP/JPY']!, fraction: 3)
        : 'GBP/JPY 未取得');

    // 暗号資産 (BTC, ETH)
    if (shouldRefresh) {
      final btc = await CryptoService.getBitcoinPrice();
      final btcJpy = btc?['JPY'];
      if (btcJpy != null) {
        _prev['BTC/JPY'] = _cache['BTC/JPY'] ?? btcJpy;
        _cache['BTC/JPY'] = btcJpy;
      }

      final eth = await CryptoService.getEthPrice();
      final ethJpy = eth?['JPY'];
      if (ethJpy != null) {
        _prev['ETH/JPY'] = _cache['ETH/JPY'] ?? ethJpy;
        _cache['ETH/JPY'] = ethJpy;
      }
    }
    items.add(_cache.containsKey('BTC/JPY')
        ? _withArrow('BTC/JPY', _cache['BTC/JPY']!, round: true)
        : 'BTC/JPY 取得失敗');
    items.add(_cache.containsKey('ETH/JPY')
        ? _withArrow('ETH/JPY', _cache['ETH/JPY']!, fraction: 0, round: true)
        : 'ETH/JPY 取得失敗');

    return items;
  }

  /// 数値マップで最新値を取得（チャート等向け）
  Future<Map<String, double>> fetchLatest({bool forceRefresh = false}) async {
    await fetchTickerItems(forceRefresh: forceRefresh);
    return Map<String, double>.from(_cache);
  }

  String _fmt(String symbol, double value,
      {int fraction = 2, bool round = false}) {
    return round
        ? '$symbol ${value.round()}'
        : '$symbol ${value.toStringAsFixed(fraction)}';
  }

  String _withArrow(String symbol, double value,
      {int fraction = 2, bool round = false}) {
    final base = _fmt(symbol, value, fraction: fraction, round: round);
    final prev = _prev[symbol];
    if (prev == null) return base;
    if (value > prev) return '$base ▲';
    if (value < prev) return '$base ▼';
    return '$base →';
  }
}
