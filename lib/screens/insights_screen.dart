import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/trends_service.dart';
import '../models/article.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InsightsScreen extends StatefulWidget {
  final Article? article;

  const InsightsScreen({this.article, super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Map<String, dynamic>? _weather;
  List<Map<String, dynamic>> _trends = [];
  List<String> _relatedTopics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _loading = true);

    // 記事の地域から天気を取得（例：東京）
    final weather = await WeatherService.getWeatherByCity('Tokyo');
    if (mounted) setState(() => _weather = weather);

    // トレンドを取得
    final trends = await TrendsService.getTrends();
    if (mounted) setState(() => _trends = trends);

    // 記事があれば、その内容に関連するトピックを取得
    if (widget.article != null) {
      final topics =
          await TrendsService.getRelatedTopics(widget.article!.title);
      if (mounted) setState(() => _relatedTopics = topics);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInsights,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 天気情報
          if (_weather != null) _buildWeatherCard(),
          const SizedBox(height: 16),

          // トレンド情報
          _buildTrendsCard(),
          const SizedBox(height: 16),

          // 関連トピック（記事がある場合）
          if (_relatedTopics.isNotEmpty) _buildRelatedTopicsCard(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '現在の天気',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_weather?['icon'] != null)
                  CachedNetworkImage(
                    imageUrl:
                        WeatherService.getWeatherIconUrl(_weather!['icon']),
                    width: 50,
                    height: 50,
                  ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weather?['temp']}°C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _weather?['description'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '注目のトレンド',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._trends.take(5).map((trend) => ListTile(
                  title: Text(trend['title']),
                  subtitle: Text('検索数: ${trend['traffic']}'),
                  trailing: const Icon(Icons.trending_up),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedTopicsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '関連トピック',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._relatedTopics.map((topic) => ListTile(
                  title: Text(topic),
                  leading: const Icon(Icons.label_outline),
                )),
          ],
        ),
      ),
    );
  }
}
