import 'package:flutter/material.dart';
import 'country_news_screen.dart';
import '../services/news_api_service.dart';

/// 地図ニュースタブ: 世界の主要地域カード + ニュース件数バッジ (1分キャッシュ)
class MapNewsScreen extends StatelessWidget {
  const MapNewsScreen({super.key});

  static final List<_Region> _regions = [
    _Region('北米', 'us', const Offset(0.22, 0.35)),
    _Region('欧州', 'gb', const Offset(0.55, 0.30)),
    _Region('アジア', 'jp', const Offset(0.76, 0.34)),
    _Region('中東', 'ae', const Offset(0.63, 0.46)),
    _Region('中南米', 'br', const Offset(0.32, 0.62)),
    _Region('アフリカ', 'za', const Offset(0.55, 0.62)),
    _Region('オセアニア', 'au', const Offset(0.86, 0.72)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _MapNewsBody(isDark: isDark, regions: _regions);
  }
}

class _MapNewsBody extends StatefulWidget {
  final bool isDark;
  final List<_Region> regions;
  const _MapNewsBody({required this.isDark, required this.regions});

  @override
  State<_MapNewsBody> createState() => _MapNewsBodyState();
}

class _MapNewsBodyState extends State<_MapNewsBody> {
  final Map<String, int> _counts = {};
  final Map<String, DateTime> _cacheTime = {};

  @override
  void initState() {
    super.initState();
    _fetchAllCounts();
  }

  Future<void> _fetchAllCounts() async {
    for (final r in widget.regions) {
      await _fetchCount(r.code);
    }
    if (mounted) setState(() {});
  }

  Future<void> _fetchCount(String code) async {
    final now = DateTime.now();
    if (_cacheTime[code] != null &&
        now.difference(_cacheTime[code]!) < const Duration(minutes: 1)) return;
    try {
      final articles = await NewsApiService.fetchArticlesByCountry(code);
      if (!mounted) return;
      setState(() {
        _counts[code] = articles.length;
        _cacheTime[code] = now;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _counts[code] = 0;
        _cacheTime[code] = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WorldMapSilhouettePainter(isDark: widget.isDark),
              ),
            ),
            ...widget.regions.map((r) {
              final pos = Offset(r.anchor.dx * w, r.anchor.dy * h);
              final count = _counts[r.code];
              return Positioned(
                left: pos.dx - 70,
                top: pos.dy - 32,
                width: 140,
                height: 64,
                child: Semantics(
                  label: '${r.name}のニュース',
                  button: true,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CountryNewsScreen(
                          countryName: r.name,
                          countryCode: r.code,
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: (widget.isDark ? Colors.black : Colors.white)
                            .withOpacity(0.55),
                        border:
                            Border.all(color: Colors.indigo.withOpacity(0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            r.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color:
                                  widget.isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (count != null)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _Region {
  final String name;
  final String code;
  final Offset anchor;
  const _Region(this.name, this.code, this.anchor);
}

class _WorldMapSilhouettePainter extends CustomPainter {
  final bool isDark;
  _WorldMapSilhouettePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = (isDark ? Colors.indigo.shade50 : Colors.indigo.shade900)
          .withOpacity(isDark ? 0.06 : 0.05);

    void blob(double cx, double cy, double rw, double rh, [double rot = 0]) {
      canvas.save();
      canvas.translate(cx * size.width, cy * size.height);
      canvas.rotate(rot);
      final rect = Rect.fromCenter(
          center: Offset.zero,
          width: size.width * rw,
          height: size.height * rh);
      final rrect =
          RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.25));
      canvas.drawRRect(rrect, bg);
      canvas.restore();
    }

    // 大陸/地域シルエット風シンプルブロブ
    blob(0.22, 0.35, 0.30, 0.18, -0.15); // 北米
    blob(0.33, 0.65, 0.16, 0.20, 0.15); // 中南米
    blob(0.55, 0.30, 0.14, 0.10, 0.10); // 欧州
    blob(0.55, 0.58, 0.18, 0.22, 0.05); // アフリカ
    blob(0.72, 0.36, 0.30, 0.22, 0.05); // アジア/中東
    blob(0.84, 0.74, 0.16, 0.12, -0.1); // オセアニア

    // グリッド (視覚補助)
    final grid = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 1;
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapSilhouettePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
