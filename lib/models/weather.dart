import 'package:flutter/material.dart';

class CityWeather {
  final String cityName;
  final String description;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final String condition;

  CityWeather({
    required this.cityName,
    required this.description,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.condition,
  });

  IconData getWeatherIcon() {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'partly cloudy':
        return Icons.cloud;
      case 'rain':
      case 'showers':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.cloud;
    }
  }
}
