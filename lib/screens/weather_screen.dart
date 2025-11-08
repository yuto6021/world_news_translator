import 'package:flutter/material.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  weather.cityName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${weather.temperature}°C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  weather.getWeatherIcon(),
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  weather.description,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _weatherInfoItem('湿度', '${weather.humidity}%'),
                _weatherInfoItem('風速', '${weather.windSpeed}m/s'),
                _weatherInfoItem('気圧', '${weather.pressure}hPa'),
              ],
            ),
          ],
        ),
      ),
    );
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
