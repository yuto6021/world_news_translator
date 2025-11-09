import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/weather_service.dart';
import '../models/weather.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _weatherService = WeatherService();
  bool _loading = true;
  List<CityWeather> _weatherData = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _weatherData = await _weatherService.getWeatherForMajorCities();
    } catch (e) {
      _error = '天気データの取得に失敗しました: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildWeatherCard(CityWeather weather) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getGradientForWeather(weather.description, isDark);
    final patternType = _getPatternType(weather.description);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 天候に応じた背景パターン
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WeatherPatternPainter(
                    type: patternType,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            // 汎用の柔らかい円形装飾（控えめ）
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weather.cityName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weather.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        weather.getWeatherIcon(),
                        size: 64,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature}',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          '°C',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _compactInfoRow(Icons.opacity, '${weather.humidity}%',
                              Colors.white),
                          const SizedBox(height: 6),
                          _compactInfoRow(Icons.air, '${weather.windSpeed}m/s',
                              Colors.white),
                          const SizedBox(height: 6),
                          _compactInfoRow(Icons.speed, '${weather.pressure}hPa',
                              Colors.white),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactInfoRow(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.9)),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: color.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientForWeather(String description, bool isDark) {
    final desc = description.toLowerCase();
    if (desc.contains('clear') ||
        desc.contains('sunny') ||
        desc.contains('晴')) {
      return isDark
          ? [const Color(0xFF1e3a8a), const Color(0xFF3b82f6)]
          : [const Color(0xFF60a5fa), const Color(0xFF3b82f6)];
    } else if (desc.contains('cloud') || desc.contains('曇')) {
      return isDark
          ? [const Color(0xFF374151), const Color(0xFF6b7280)]
          : [const Color(0xFF9ca3af), const Color(0xFF6b7280)];
    } else if (desc.contains('rain') ||
        desc.contains('雨') ||
        desc.contains('drizzle')) {
      return isDark
          ? [const Color(0xFF1e40af), const Color(0xFF475569)]
          : [const Color(0xFF64748b), const Color(0xFF475569)];
    } else if (desc.contains('snow') || desc.contains('雪')) {
      return isDark
          ? [const Color(0xFF334155), const Color(0xFF64748b)]
          : [const Color(0xFFbfdbfe), const Color(0xFF93c5fd)];
    } else if (desc.contains('storm') || desc.contains('thunder')) {
      return isDark
          ? [const Color(0xFF0f172a), const Color(0xFF334155)]
          : [const Color(0xFF475569), const Color(0xFF334155)];
    }
    return isDark
        ? [const Color(0xFF312e81), const Color(0xFF4c1d95)]
        : [const Color(0xFF818cf8), const Color(0xFF6366f1)];
  }

  Widget _weatherInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // --- 背景パターン関連 ---
  _PatternType _getPatternType(String description) {
    final d = description.toLowerCase();
    if (d.contains('storm') || d.contains('thunder') || d.contains('雷'))
      return _PatternType.storm;
    if (d.contains('snow') || d.contains('雪')) return _PatternType.snow;
    if (d.contains('rain') || d.contains('雨') || d.contains('drizzle'))
      return _PatternType.rain;
    if (d.contains('cloud') || d.contains('曇')) return _PatternType.cloud;
    if (d.contains('clear') || d.contains('sunny') || d.contains('晴'))
      return _PatternType.clear;
    return _PatternType.other;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeatherData,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWeatherData,
      child: ListView.builder(
        itemCount: _weatherData.length,
        itemBuilder: (context, index) => _buildWeatherCard(_weatherData[index]),
      ),
    );
  }
}

enum _PatternType { clear, cloud, rain, snow, storm, other }

class _WeatherPatternPainter extends CustomPainter {
  final _PatternType type;
  final bool isDark;

  _WeatherPatternPainter({required this.type, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 統一した薄いホワイト系カラー
    final baseColor =
        (isDark ? Colors.white70 : Colors.white).withOpacity(0.18);
    final p = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (type) {
      case _PatternType.clear:
        _paintClear(canvas, size, p);
        break;
      case _PatternType.cloud:
        _paintCloud(canvas, size, p..strokeWidth = 3);
        break;
      case _PatternType.rain:
        _paintRain(canvas, size, p..strokeWidth = 2);
        break;
      case _PatternType.snow:
        _paintSnow(canvas, size, p..strokeWidth = 1.6);
        break;
      case _PatternType.storm:
        _paintStorm(canvas, size, p..strokeWidth = 2.4);
        break;
      case _PatternType.other:
        _paintSubtleWaves(canvas, size, p..strokeWidth = 1.8);
        break;
    }
  }

  void _paintClear(Canvas canvas, Size size, Paint p) {
    // 右上に緩やかな同心円（晴れの雰囲気）
    final center = Offset(size.width * 0.8, size.height * 0.25);
    for (var r = 30.0; r <= 110; r += 20) {
      canvas.drawCircle(center, r, p);
    }
  }

  void _paintCloud(Canvas canvas, Size size, Paint p) {
    // 右上に雲っぽい重なり円弧
    final baseY = size.height * 0.28;
    final xs = [
      size.width * 0.6,
      size.width * 0.7,
      size.width * 0.8,
      size.width * 0.68
    ];
    final rs = [28.0, 36.0, 30.0, 24.0];
    for (var i = 0; i < xs.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(xs[i], baseY), radius: rs[i]),
        math.pi,
        math.pi,
        false,
        p,
      );
    }
  }

  void _paintRain(Canvas canvas, Size size, Paint p) {
    // 斜めの雨線
    final gap = 16.0;
    for (double x = -size.height; x < size.width; x += gap) {
      final start = Offset(x, 0);
      final end = Offset(x + size.height * 0.5, size.height);
      canvas.drawLine(start, end, p);
    }
  }

  void _paintSnow(Canvas canvas, Size size, Paint p) {
    // 小さな結晶（十字）を散りばめる
    final rnd = math.Random(0x53);
    final count = 18;
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final len = 5 + rnd.nextDouble() * 6;
      canvas.drawLine(Offset(x - len, y), Offset(x + len, y), p);
      canvas.drawLine(Offset(x, y - len), Offset(x, y + len), p);
    }
  }

  void _paintStorm(Canvas canvas, Size size, Paint p) {
    // 稲妻のジグザグ + 雨線少し
    final lightning = Path();
    lightning.moveTo(size.width * 0.15, size.height * 0.2);
    lightning.lineTo(size.width * 0.35, size.height * 0.35);
    lightning.lineTo(size.width * 0.25, size.height * 0.35);
    lightning.lineTo(size.width * 0.45, size.height * 0.55);
    lightning.lineTo(size.width * 0.3, size.height * 0.52);
    canvas.drawPath(lightning, p);

    final rp = Paint()
      ..color = p.color.withOpacity(0.7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(
          Offset(x, size.height * 0.6), Offset(x + 14, size.height), rp);
    }
  }

  void _paintSubtleWaves(Canvas canvas, Size size, Paint p) {
    // ゆるい波線
    final path = Path();
    final h = size.height * 0.65;
    path.moveTo(0, h);
    for (double x = 0; x <= size.width; x += 24) {
      path.quadraticBezierTo(x + 12, h - 6, x + 24, h);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _WeatherPatternPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.isDark != isDark;
  }
}
