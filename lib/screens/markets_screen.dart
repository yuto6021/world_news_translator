import 'dart:async';
import 'package:flutter/material.dart';
import '../services/market_data_service.dart';
import 'dart:math' as math;

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = MarketDataService.instance;
  final Map<String, List<double>> _history = {};
  Timer? _timer;
  bool _loading = true;
  bool _isRefreshing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fetch(refresh: true);
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (refresh && mounted) {
      setState(() => _isRefreshing = true);
    }
    final map = await _svc.fetchLatest(forceRefresh: refresh);
    for (final e in map.entries) {
      final list = _history.putIfAbsent(e.key, () => <double>[]);
      list.add(e.value);
      if (list.length > 60) list.removeAt(0);
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _isRefreshing = false;
      });
      if (refresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('データを更新しました'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'マーケットデータ読み込み中...',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        // 背景画像
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [Colors.grey.shade900, Colors.black]
                        : [Colors.blueGrey.shade50, Colors.grey.shade100],
                  ),
                ),
              );
            },
          ),
        ),
        // オーバーレイ（視認性向上）
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withOpacity(0.65),
                        Colors.black.withOpacity(0.8),
                      ]
                    : [
                        Colors.white.withOpacity(0.88),
                        Colors.white.withOpacity(0.78),
                      ],
              ),
            ),
          ),
        ),
        // コンテンツ
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
          children: _svc.symbols.asMap().entries.map((entry) {
            final idx = entry.key;
            final sym = entry.value;
            final data = _history[sym] ?? const <double>[];
            final latest = data.isNotEmpty ? data.last : null;
            final prev = data.length >= 2 ? data[data.length - 2] : null;
            final diff = (latest != null && prev != null) ? latest - prev : 0.0;
            final pctChange =
                (latest != null && prev != null && prev.abs() > 1e-9)
                    ? ((diff / prev) * 100)
                    : 0.0;
            final isPositive = diff > 0;
            final isNegative = diff < 0;

            // 高値/安値
            final high =
                data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : latest;
            final low =
                data.isNotEmpty ? data.reduce((a, b) => a < b ? a : b) : latest;

            // カラーテーマ - より鮮やかなグラデーション
            final cardGradientColors = isDark
                ? [
                    const Color(0xFF1a1f2e),
                    const Color(0xFF0f1419),
                  ]
                : [
                    const Color(0xFFffffff),
                    const Color(0xFFf8f9ff),
                  ];

            final accentColor = isPositive
                ? Colors.green.shade600
                : (isNegative ? Colors.red.shade600 : Colors.blueGrey.shade600);

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + idx * 50),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                elevation: 8,
                shadowColor: accentColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cardGradientColors,
                      stops: const [0.0, 1.0],
                    ),
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // 装飾的な背景パターン
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MarketPatternPainter(
                              color: accentColor,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        // メインコンテンツ
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // トップ行: シンボル + 変化アイコン
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accentColor.withOpacity(0.25),
                                              accentColor.withOpacity(0.15),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color:
                                                  accentColor.withOpacity(0.6),
                                              width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  accentColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          sym,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: accentColor,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      if (diff != 0) ...[
                                        const SizedBox(width: 16),
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: accentColor
                                                    .withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Transform.scale(
                                                scale: 1.0 +
                                                    (_pulseController.value *
                                                        0.15),
                                                child: Icon(
                                                  isPositive
                                                      ? Icons
                                                          .trending_up_rounded
                                                      : Icons
                                                          .trending_down_rounded,
                                                  color: accentColor,
                                                  size: 32,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                  // 変化率チップ
                                  if (diff != 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accentColor.withOpacity(0.25),
                                            accentColor.withOpacity(0.3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accentColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${pctChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // 現在価格（大きく表示）
                              if (latest != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              Colors.white.withOpacity(0.05),
                                              Colors.white.withOpacity(0.02),
                                            ]
                                          : [
                                              accentColor.withOpacity(0.05),
                                              accentColor.withOpacity(0.02),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : accentColor.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _fmtValue(sym, latest),
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          letterSpacing: -1.0,
                                          shadows: [
                                            Shadow(
                                              color:
                                                  accentColor.withOpacity(0.3),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (diff != 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                accentColor.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(sym.contains('JPY') ? 3 : 2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: accentColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              // 高値・安値ステータス
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                        '高値',
                                        high,
                                        sym,
                                        Colors.green.shade600,
                                        isDark,
                                        Icons.arrow_upward_rounded),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                        '安値',
                                        low,
                                        sym,
                                        Colors.red.shade600,
                                        isDark,
                                        Icons.arrow_downward_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // チャート見出し
                              Row(
                                children: [
                                  Icon(Icons.show_chart_rounded,
                                      color: accentColor, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'トレンド推移 (${data.length}pt)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // リッチなスパークライン
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: CustomPaint(
                                  painter: _EnhancedSparklinePainter(
                                    data: data,
                                    color: accentColor,
                                    isDark: isDark,
                                  ),
                                  size: const Size(double.infinity, 120),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // フッター: 更新ボタン
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _isRefreshing
                                      ? null
                                      : () => _fetch(refresh: true),
                                  icon: _isRefreshing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.refresh_rounded,
                                          size: 18),
                                  label:
                                      Text(_isRefreshing ? '更新中...' : '手動更新'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        accentColor.withOpacity(0.15),
                                    foregroundColor: accentColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: accentColor.withOpacity(0.3)),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, double? value, String sym, Color color,
      bool isDark, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ]
              : [
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (value != null)
            Text(
              _fmtValue(sym, value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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

/// 強化版スパークラインペインター: グリッド、グラデーション塗り、移動平均線、エンドポイント
class _EnhancedSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isDark;

  _EnhancedSparklinePainter({
    required this.data,
    required this.color,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final dx = size.width / (data.length - 1);

    // 背景グリッド（横5本、縦5本）
    final gridPaint = Paint()
      ..color = (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
          .withOpacity(0.25)
      ..strokeWidth = 0.8;

    // 横グリッド
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // 縦グリッド
    for (int i = 0; i <= 4; i++) {
      final x = (size.width / 4) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // メインパス構築
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

    // グラデーション塗りつぶし（下方向へ）
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final shader = LinearGradient(
      colors: [
        color.withOpacity(0.4),
        color.withOpacity(0.1),
        color.withOpacity(0.02),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final fillPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // メインライン（太く、影付き）
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 移動平均線（7期間）を薄く表示
    if (data.length >= 7) {
      final maPath = Path();
      for (int i = 6; i < data.length; i++) {
        final sum = data.sublist(i - 6, i + 1).reduce((a, b) => a + b);
        final ma = sum / 7;
        final x = dx * i;
        final y = size.height - ((ma - minV) / range) * size.height;
        if (i == 6) {
          maPath.moveTo(x, y);
        } else {
          maPath.lineTo(x, y);
        }
      }
      final maPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(maPath, maPaint);
    }

    // エンドポイントマーカー（大きめの丸＋リング）
    if (data.isNotEmpty) {
      final lastX = dx * (data.length - 1);
      final lastY = size.height - ((data.last - minV) / range) * size.height;

      // 外側リング（光彩効果）
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 8, glowPaint);

      // メイン丸
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 5, dotPaint);

      // 白枠
      final dotBorder = Paint()
        ..color = isDark ? Colors.grey.shade900 : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(lastX, lastY), 5, dotBorder);
    }

    // 開始ポイントマーカー（小さめ）
    if (data.isNotEmpty) {
      final firstY = size.height - ((data.first - minV) / range) * size.height;
      final startDot = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(0, firstY), 3, startDot);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedSparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

/// 市場カード用の装飾的な背景パターンペインター
class _MarketPatternPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _MarketPatternPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(isDark ? 0.03 : 0.05)
      ..style = PaintingStyle.fill;

    // 右上の大きな円
    canvas.drawCircle(
      Offset(size.width * 0.85, -size.height * 0.15),
      size.width * 0.4,
      paint,
    );

    // 左下の中くらいの円
    canvas.drawCircle(
      Offset(-size.width * 0.1, size.height * 0.75),
      size.width * 0.3,
      paint,
    );

    // 微細なドットパターン（グリッド）
    final dotPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.02 : 0.03)
      ..style = PaintingStyle.fill;

    for (double x = 20; x < size.width; x += 40) {
      for (double y = 20; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // 右下の小さい円
    canvas.drawCircle(
      Offset(size.width * 1.1, size.height * 1.05),
      size.width * 0.25,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MarketPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
