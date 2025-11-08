import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String apiKey = 'a4f0ce3d4fa1a985375cb6c97c2ef596';
  static const String baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static const _cities = [
    {'name': '東京', 'id': '1850147'},
    {'name': 'ニューヨーク', 'id': '5128581'},
    {'name': 'ロンドン', 'id': '2643743'},
    {'name': 'パリ', 'id': '2968815'},
    {'name': 'ベルリン', 'id': '2950159'},
    {'name': '北京', 'id': '1816670'},
    {'name': 'ソウル', 'id': '1835848'},
    {'name': 'シドニー', 'id': '2147714'},
    {'name': 'モスクワ', 'id': '524901'},
    {'name': 'サンパウロ', 'id': '3448439'},
  ];

  Future<List<CityWeather>> getWeatherForMajorCities() async {
    final weatherList = <CityWeather>[];

    for (final city in _cities) {
      try {
        final response = await http.get(Uri.parse(
            '$baseUrl?id=${city['id']}&appid=$apiKey&units=metric&lang=ja'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          weatherList.add(CityWeather(
            cityName: city['name']!,
            description: data['weather'][0]['description'],
            temperature: data['main']['temp'].toDouble(),
            humidity: data['main']['humidity'],
            windSpeed: data['wind']['speed'].toDouble(),
            pressure: data['main']['pressure'],
            condition: data['weather'][0]['main'],
          ));
        }
      } catch (e) {
        print('Error fetching weather for ${city['name']}: $e');
      }
    }

    return weatherList;
  }

  static Future<Map<String, dynamic>?> getWeatherByCity(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?q=$city&units=metric&lang=ja&appid=$apiKey'),
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
            'http://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apiKey'),
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
