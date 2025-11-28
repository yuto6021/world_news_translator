import 'dart:math';

/// 天候・時間帯管理サービス
class WeatherCycleService {
  static Weather getCurrentWeather() {
    final hour = DateTime.now().hour;
    final random = Random(DateTime.now().day);
    final weatherRoll = random.nextInt(100);

    // 時間帯による天候の傾向
    if (hour >= 22 || hour < 5) {
      // 夜間: 晴れまたは晴天
      return weatherRoll < 80 ? Weather.clear : Weather.starry;
    } else if (hour >= 5 && hour < 12) {
      // 午前: 晴れが多い
      if (weatherRoll < 60) return Weather.sunny;
      if (weatherRoll < 80) return Weather.cloudy;
      if (weatherRoll < 95) return Weather.rainy;
      return Weather.stormy;
    } else if (hour >= 12 && hour < 18) {
      // 午後: 晴れ or 曇り
      if (weatherRoll < 50) return Weather.sunny;
      if (weatherRoll < 85) return Weather.cloudy;
      if (weatherRoll < 95) return Weather.rainy;
      return Weather.stormy;
    } else {
      // 夕方: 夕焼けチャンス
      if (weatherRoll < 30) return Weather.sunset;
      if (weatherRoll < 60) return Weather.cloudy;
      if (weatherRoll < 90) return Weather.clear;
      return Weather.rainy;
    }
  }

  static TimeOfDay getTimeOfDay() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 8) return TimeOfDay.dawn;
    if (hour >= 8 && hour < 12) return TimeOfDay.morning;
    if (hour >= 12 && hour < 17) return TimeOfDay.afternoon;
    if (hour >= 17 && hour < 19) return TimeOfDay.evening;
    if (hour >= 19 && hour < 22) return TimeOfDay.night;
    return TimeOfDay.midnight;
  }

  /// 天候によるステータス補正を計算
  static Map<String, double> getWeatherStatBonus(Weather weather) {
    switch (weather) {
      case Weather.sunny:
        return {'attack': 1.1, 'speed': 1.1}; // 攻撃・速度+10%
      case Weather.rainy:
        return {'defense': 1.15, 'hp': 1.1}; // 防御+15%, HP+10%
      case Weather.cloudy:
        return {'exp': 1.05}; // 経験値+5%
      case Weather.stormy:
        return {'attack': 1.2, 'critRate': 1.3}; // 攻撃+20%, クリティカル+30%
      case Weather.clear:
        return {'dropRate': 1.15}; // ドロップ率+15%
      case Weather.sunset:
        return {'intimacy': 1.2, 'mood': 1.1}; // 親密度+20%, 機嫌+10%
      case Weather.starry:
        return {'luck': 1.3, 'shiny': 1.5}; // 運+30%, レア率+50%
    }
  }

  /// 時間帯によるステータス補正を計算
  static Map<String, double> getTimeStatBonus(TimeOfDay time) {
    switch (time) {
      case TimeOfDay.dawn:
        return {'stamina': 1.1, 'healing': 1.2}; // 体力+10%, 回復+20%
      case TimeOfDay.morning:
        return {'exp': 1.1, 'mood': 1.1}; // 経験値+10%, 機嫌+10%
      case TimeOfDay.afternoon:
        return {'coins': 1.1}; // コイン+10%
      case TimeOfDay.evening:
        return {'intimacy': 1.15}; // 親密度+15%
      case TimeOfDay.night:
        return {'defense': 1.1, 'evasion': 1.2}; // 防御+10%, 回避+20%
      case TimeOfDay.midnight:
        return {'darkPower': 1.3, 'rareEnemy': 1.5}; // 闇属性+30%, レア敵+50%
    }
  }

  /// 総合ボーナスを計算
  static Map<String, double> getTotalBonus() {
    final weather = getCurrentWeather();
    final time = getTimeOfDay();

    final Map<String, double> total = {};

    // 天候ボーナス
    getWeatherStatBonus(weather).forEach((key, value) {
      total[key] = (total[key] ?? 1.0) * value;
    });

    // 時間帯ボーナス
    getTimeStatBonus(time).forEach((key, value) {
      total[key] = (total[key] ?? 1.0) * value;
    });

    return total;
  }

  /// 天候の説明
  static String getWeatherDescription(Weather weather) {
    switch (weather) {
      case Weather.sunny:
        return '☀️ 快晴 - 攻撃・速度UP';
      case Weather.rainy:
        return '☔ 雨 - 防御・HP UP';
      case Weather.cloudy:
        return '☁️ 曇り - 経験値UP';
      case Weather.stormy:
        return '⚡ 嵐 - 攻撃・クリティカルUP';
      case Weather.clear:
        return '🌤️ 晴れ - ドロップ率UP';
      case Weather.sunset:
        return '🌅 夕焼け - 親密度・機嫌UP';
      case Weather.starry:
        return '🌟 星空 - 運・レア率大幅UP';
    }
  }

  /// 時間帯の説明
  static String getTimeDescription(TimeOfDay time) {
    switch (time) {
      case TimeOfDay.dawn:
        return '🌄 夜明け - 回復効果UP';
      case TimeOfDay.morning:
        return '🌞 朝 - 経験値・機嫌UP';
      case TimeOfDay.afternoon:
        return '☀️ 昼 - コイン報酬UP';
      case TimeOfDay.evening:
        return '🌆 夕方 - 親密度UP';
      case TimeOfDay.night:
        return '🌙 夜 - 防御・回避UP';
      case TimeOfDay.midnight:
        return '🌑 深夜 - レア敵出現率UP';
    }
  }

  /// 現在の環境情報
  static Map<String, String> getCurrentEnvironment() {
    final weather = getCurrentWeather();
    final time = getTimeOfDay();

    return {
      'weather': getWeatherDescription(weather),
      'time': getTimeDescription(time),
      'weatherName': weather.name,
      'timeName': time.name,
    };
  }
}

enum Weather {
  sunny, // 快晴
  rainy, // 雨
  cloudy, // 曇り
  stormy, // 嵐
  clear, // 晴れ
  sunset, // 夕焼け
  starry, // 星空
}

enum TimeOfDay {
  dawn, // 5-8時
  morning, // 8-12時
  afternoon, // 12-17時
  evening, // 17-19時
  night, // 19-22時
  midnight, // 22-5時
}
