import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // 無料版の制限付きエンドポイントを使用
  static const String baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static Future<Map<String, dynamic>?> getWeatherByCity(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?q=$city&units=metric&lang=ja'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temp': data['main']['temp'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
        };
      }
    } catch (e) {
      print('Weather API error: $e');
    }
    return null;
  }

  // 天気アイコンのURLを取得（これは認証不要）
  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/w/$iconCode.png';
  }

  // 都市名から位置情報を取得（Geocoding API - 制限付き無料版）
  static Future<Map<String, double>?> getCityCoordinates(String city) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1'),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': data[0]['lat'],
            'lon': data[0]['lon'],
          };
        }
      }
    } catch (e) {
      print('Geocoding API error: $e');
    }
    return null;
  }
}
