import 'package:shared_preferences/shared_preferences.dart';

/// 実績管理サービス
class AchievementService {
  static const String _secretButtonKey = 'achievement_secret_button';
  static const String _konamiCodeKey = 'achievement_konami_code';
  static const String _fastTapperKey = 'achievement_fast_tapper';
  static const String _nightOwlSecretKey = 'achievement_night_owl_secret';

  /// 秘密ボタン実績を解除
  static Future<void> unlockSecretButton() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_secretButtonKey, true);
  }

  /// 秘密ボタン実績が解除されているか確認
  static Future<bool> isSecretButtonUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_secretButtonKey) ?? false;
  }

  /// コナミコマンド実績を解除
  static Future<void> unlockKonamiCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_konamiCodeKey, true);
  }

  /// コナミコマンド実績が解除されているか確認
  static Future<bool> isKonamiCodeUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_konamiCodeKey) ?? false;
  }

  /// 高速タッパー実績を解除
  static Future<void> unlockFastTapper() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fastTapperKey, true);
  }

  /// 高速タッパー実績が解除されているか確認
  static Future<bool> isFastTapperUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fastTapperKey) ?? false;
  }

  /// 深夜の秘密実績を解除（深夜3時に特定操作）
  static Future<void> unlockNightOwlSecret() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nightOwlSecretKey, true);
  }

  /// 深夜の秘密実績が解除されているか確認
  static Future<bool> isNightOwlSecretUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_nightOwlSecretKey) ?? false;
  }
}
