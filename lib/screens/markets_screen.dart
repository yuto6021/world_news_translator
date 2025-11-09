import 'dart:async';
import 'package:flutter/material.dart';
import '../services/market_data_service.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final _svc = MarketDataService.instance;
  final Map<String, List<double>> _history = {};
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch(refresh: true);
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool refresh = false}) async {
    final map = await _svc.fetchLatest(forceRefresh: refresh);
    for (final e in map.entries) {
      final list = _history.putIfAbsent(e.key, () => <double>[]);
      list.add(e.value);
      if (list.length > 60) list.removeAt(0);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.grey.shade900, Colors.black]
              : [Colors.grey.shade50, Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: _svc.symbols.map((sym) {
          final data = _history[sym] ?? const <double>[];
          final latest = data.isNotEmpty ? data.last : null;
          final prev = data.length >= 2 ? data[data.length - 2] : null;
          final diff = (latest != null && prev != null) ? latest - prev : 0.0;
          final pctChange =
              (latest != null && prev != null && prev.abs() > 1e-9)
                  ? ((diff / prev) * 100)
                  : 0.0;
          final color = diff > 0
              ? Colors.green
              : (diff < 0 ? Colors.redAccent : Colors.grey);

          // 簡易的な24h高値/安値（実際は過去データから）
          final high =
              data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : latest;
          final low =
              data.isNotEmpty ? data.reduce((a, b) => a < b ? a : b) : latest;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.grey.shade800,
                          Colors.grey.shade900,
                        ]
                      : [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー行: シンボル + 現在値 + 変化率
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: color.withOpacity(0.4), width: 1.5),
                              ),
                              child: Text(
                                sym,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (latest != null)
                              Text(
                                _fmtValue(sym, latest),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                        // 変化率 + アイコン
                        if (diff != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  diff > 0
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: color,
                                  size: 22,
                                ),
                                Text(
                                  '${pctChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 高値・安値表示
                    Row(
                      children: [
                        _buildStatChip(
                            '高値', high, sym, Colors.green.shade700, isDark),
                        const SizedBox(width: 12),
                        _buildStatChip(
                            '安値', low, sym, Colors.red.shade700, isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // スパークライン
                    SizedBox(
                      height: 80,
                      child: CustomPaint(
                        painter: _SparklinePainter(
                          data: data,
                          color: color,
                          isDark: isDark,
                        ),
                        size: const Size(double.infinity, 80),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // フッター: データポイント数 + 更新ボタン
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'データ数: ${data.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _fetch(refresh: true),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('更新'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatChip(
      String label, double? value, String sym, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          Text(
            value != null ? _fmtValue(sym, value) : '--',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtValue(String sym, double v) {
    if (sym.endsWith('JPY') &&
        !sym.startsWith('ETH') &&
        !sym.startsWith('BTC')) {
      return v.toStringAsFixed(3);
    }
    if (sym.startsWith('BTC')) return v.toStringAsFixed(0);
    if (sym.startsWith('ETH')) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isDark;
  _SparklinePainter({
    required this.data,
    required this.color,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final dx = size.width / (data.length - 1);

    // グリッド線（薄く横3本）
    final gridPaint = Paint()
      ..color = (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
          .withOpacity(0.3)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // パス構築
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = dx * i;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 塗りつぶしグラデーション
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final shader = LinearGradient(
      colors: [color.withOpacity(0.35), color.withOpacity(0.05)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final fillPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // ライン本体（より太く）
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 最後のポイントに丸印
    if (data.isNotEmpty) {
      final lastX = dx * (data.length - 1);
      final lastY = size.height - ((data.last - minV) / range) * size.height;
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 4, dotPaint);
      final dotBorder = Paint()
        ..color = isDark ? Colors.grey.shade800 : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(lastX, lastY), 4, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
