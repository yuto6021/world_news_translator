import 'package:flutter/material.dart';
import 'country_news_screen.dart';
import '../services/news_api_service.dart';
import '../services/availability_service.dart';
import '../services/achievement_service.dart';

/// 地図ニュースタブ: 世界の主要国カード + ニュース件数バッジ (1分キャッシュ)
class MapNewsScreen extends StatefulWidget {
  const MapNewsScreen({super.key});

  @override
  State<MapNewsScreen> createState() => _MapNewsScreenState();
}

class _MapNewsScreenState extends State<MapNewsScreen> {
  // 利用可能国をロードした後に使う動的リスト
  late List<_Region> _regions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailable();
  }

  Future<void> _loadAvailable() async {
    final codes =
        await AvailabilityService.getAvailableCountryCodes(includeJapan: true);
    // 緯度経度 + pixelOffset テンプレート
    final Map<String, _Region> template = {
      // 北米
      'us':
          _Region('アメリカ', 'us', 38.0, -97.0, pixelOffset: const Offset(8, -6)),
      'ca':
          _Region('カナダ', 'ca', 56.0, -96.0, pixelOffset: const Offset(10, -10)),
      'mx':
          _Region('メキシコ', 'mx', 23.0, -102.0, pixelOffset: const Offset(-8, 6)),
      // 中南米
      'br': _Region('ブラジル', 'br', -10.0, -55.0,
          pixelOffset: const Offset(12, 14)),
      // 欧州
      'gb': _Region('イギリス', 'gb', 55.0, -3.0, pixelOffset: const Offset(0, -6)),
      'fr': _Region('フランス', 'fr', 46.0, 2.0, pixelOffset: const Offset(8, -2)),
      'de': _Region('ドイツ', 'de', 51.0, 10.0, pixelOffset: const Offset(10, -8)),
      'es': _Region('スペイン', 'es', 40.0, -4.0, pixelOffset: const Offset(-4, 0)),
      'ru': _Region('ロシア', 'ru', 60.0, 100.0, pixelOffset: const Offset(0, -8)),
      // 中東
      'eg': _Region('エジプト', 'eg', 26.0, 30.0, pixelOffset: const Offset(6, -4)),
      'ae': _Region('UAE', 'ae', 24.0, 54.0, pixelOffset: const Offset(-6, -2)),
      'sa': _Region('サウジアラビア', 'sa', 24.0, 45.0,
          pixelOffset: const Offset(2, -2)),
      // アフリカ
      'za':
          _Region('南アフリカ', 'za', -30.0, 25.0, pixelOffset: const Offset(0, 6)),
      // アジア
      'in': _Region('インド', 'in', 21.0, 78.0, pixelOffset: const Offset(-6, -4)),
      'cn': _Region('中国', 'cn', 35.0, 103.0, pixelOffset: const Offset(-6, -6)),
      'kr':
          _Region('韓国', 'kr', 36.0, 128.0, pixelOffset: const Offset(-10, -6)),
      'jp':
          _Region('日本', 'jp', 20.0, -20, pixelOffset: const Offset(-12, -6)),
      'id':
          _Region('インドネシア', 'id', -2.0, 118.0, pixelOffset: const Offset(0, 4)),
      // オセアニア
      'au': _Region('オーストラリア', 'au', -25.0, 133.0,
          pixelOffset: const Offset(8, -6)),
    };
    _regions =
        codes.where(template.containsKey).map((c) => template[c]!).toList();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
        final mapW = w * 0.8; // 画像を少し小さく (80%)
        final mapH = mapW / 2; // 2:1 比率維持
        final leftOffset = (w - mapW) / 2;
        final topOffset = 32.0; // 上余白固定
        return Stack(
          children: [
            // 提供された世界地図画像があればそれを背景に。なければシルエットへフォールバック。
            Positioned(
              left: leftOffset,
              top: topOffset,
              width: mapW,
              height: mapH,
              child: Image.asset(
                'assets/images/world_map.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CustomPaint(
                  painter: _WorldMapSilhouettePainter(isDark: widget.isDark),
                ),
              ),
            ),
            ...widget.regions.map((r) {
              final pos = _projectLatLon(r.lat, r.lon, mapW, mapH) +
                  (r.pixelOffset ?? Offset.zero);
              final count = _counts[r.code];
              return Positioned(
                left: leftOffset + pos.dx - 46,
                top: topOffset + pos.dy - 22,
                width: 100,
                height: 44,
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
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border:
                            Border.all(color: Colors.indigo.withOpacity(0.45)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            r.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          if (count != null)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
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
            // 🔒 秘密ボタン（右下の小さな隠しボタン）
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: () async {
                  await AchievementService.unlockSecretButton();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('🧙 隠者バッジ解除！秘密を見つけた！'),
                          ],
                        ),
                        backgroundColor: Colors.deepPurple,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Opacity(
                  opacity: 0.5, // 0.3から0.5に変更して少し見やすく
                  child: Container(
                    width: 32, // 24から32に拡大
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.amber, width: 2), // 境界線も太く
                    ),
                    child: const Icon(
                      Icons.question_mark,
                      color: Colors.amber,
                      size: 18, // 14から18に拡大
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Region {
  final String name;
  final String code;
  final double lat; // 緯度 -90..90
  final double lon; // 経度 -180..180
  final Offset? pixelOffset; // 画像と重ならないよう微調整
  const _Region(this.name, this.code, this.lat, this.lon, {this.pixelOffset});

  @override
  String toString() => '_Region($name,$code,$lat,$lon)';
}

class _WorldMapSilhouettePainter extends CustomPainter {
  final bool isDark;
  _WorldMapSilhouettePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 背景を濃いグラデーションで塗る（海を表現）
    final bgGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                Colors.indigo.shade900.withOpacity(0.35),
                Colors.blue.shade900.withOpacity(0.25)
              ]
            : [
                Colors.blue.shade100.withOpacity(0.60),
                Colors.indigo.shade200.withOpacity(0.50)
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgGradient);

    // 大陸の色（濃く）
    final landColor = Paint()
      ..color = (isDark ? Colors.indigo.shade300 : Colors.indigo.shade500)
          .withOpacity(isDark ? 0.50 : 0.55);

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
      canvas.drawRRect(rrect, landColor);
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
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.15)
      ..strokeWidth = 2.0;
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

/// equirectangular（等距円筒）投影で緯度経度を画面座標に変換
Offset _projectLatLon(double lat, double lon, double width, double height) {
  // 正常化した 0..1 の座標へ
  final xNorm = (lon + 180.0) / 360.0;
  final yNorm = (90.0 - lat) / 180.0;
  return Offset(xNorm * width, yNorm * height);
}
