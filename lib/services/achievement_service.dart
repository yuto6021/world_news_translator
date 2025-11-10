import 'package:shared_preferences/shared_preferences.dart';

/// 実績管理サービス
class AchievementService {
  static const String _secretButtonKey = 'achievement_secret_button';
  static const String _konamiCodeKey = 'achievement_konami_code';
  static const String _konamiDoubleKey = 'achievement_konami_double';
  static const String _konamiCountKey = 'konami_input_count';

  static const String _fastTapperKey = 'achievement_fast_tapper'; // 50回
  static const String _fastTapGodKey = 'achievement_fast_tap_god'; // 80回

  static const String _nightOwlSecretKey = 'achievement_night_owl_secret';

  static const String _memoryMasterKey = 'achievement_memory_master';

  static const String _petLevel5Key = 'achievement_pet_lv5';
  static const String _petLevel10Key = 'achievement_pet_lv10';
  static const String _petHappy100Key = 'achievement_pet_happy_100';

  // ゲーム共通: 遊び時間
  static const String _gamePlayTime30Key = 'achievement_play_30min';
  static const String _gamePlayTime60Key = 'achievement_play_60min';
  static const String _gamePlayTime180Key = 'achievement_play_180min';

  // 記憶ゲーム: ノーミス
  static const String _memoryPerfectKey = 'achievement_memory_perfect';

  // 育成ギミック
  static const String _petOverfeedKey = 'achievement_pet_overfeed'; // 連続ごはん3回
  static const String _petOverplayKey = 'achievement_pet_overplay'; // 連続あそぶ5回

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

  /// コナミコマンド2連続を登録（2回で達成）
  static Future<bool> registerKonamiInput() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_konamiCountKey) ?? 0;
    count += 1;
    await prefs.setInt(_konamiCountKey, count);
    if (count >= 2) {
      await prefs.setBool(_konamiDoubleKey, true);
      await prefs.setInt(_konamiCountKey, 0); // リセット
      return true;
    }
    return false;
  }

  static Future<bool> isKonamiCodeUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_konamiCodeKey) ?? false;
  }

  static Future<bool> isKonamiDoubleUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_konamiDoubleKey) ?? false;
  }

  /// 高速タッパー実績を解除（50）
  static Future<void> unlockFastTapper() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fastTapperKey, true);
  }

  static Future<bool> isFastTapperUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fastTapperKey) ?? false;
  }

  /// 早撃ち神（80）
  static Future<void> unlockFastTapGod() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fastTapGodKey, true);
  }

  static Future<bool> isFastTapGodUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fastTapGodKey) ?? false;
  }

  /// 記憶王（メモリゲームの好成績）
  static Future<void> unlockMemoryMaster() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_memoryMasterKey, true);
  }

  static Future<bool> isMemoryMasterUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_memoryMasterKey) ?? false;
  }

  /// 深夜の秘密実績を解除（深夜3時に特定操作）
  static Future<void> unlockNightOwlSecret() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nightOwlSecretKey, true);
  }

  static Future<bool> isNightOwlSecretUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_nightOwlSecretKey) ?? false;
  }

  /// ペット育成系
  static Future<void> unlockPetLevel5() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_petLevel5Key, true);
  }

  static Future<bool> isPetLevel5Unlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_petLevel5Key) ?? false;
  }

  static Future<void> unlockPetLevel10() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_petLevel10Key, true);
  }

  static Future<bool> isPetLevel10Unlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_petLevel10Key) ?? false;
  }

  static Future<void> unlockPetHappy100() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_petHappy100Key, true);
  }

  static Future<bool> isPetHappy100Unlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_petHappy100Key) ?? false;
  }

  // ゲーム共通: プレイ時間管理
  static Future<void> addGamePlayTime(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    int total = prefs.getInt('game_total_play_time_seconds') ?? 0;
    total += seconds;
    await prefs.setInt('game_total_play_time_seconds', total);

    // 実績チェック (30分=1800秒, 1時間=3600秒, 3時間=10800秒)
    if (total >= 1800 && !(await isPlayTime30Unlocked())) {
      await prefs.setBool(_gamePlayTime30Key, true);
    }
    if (total >= 3600 && !(await isPlayTime60Unlocked())) {
      await prefs.setBool(_gamePlayTime60Key, true);
    }
    if (total >= 10800 && !(await isPlayTime180Unlocked())) {
      await prefs.setBool(_gamePlayTime180Key, true);
    }
  }

  static Future<bool> isPlayTime30Unlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gamePlayTime30Key) ?? false;
  }

  static Future<bool> isPlayTime60Unlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gamePlayTime60Key) ?? false;
  }

  static Future<bool> isPlayTime180Unlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gamePlayTime180Key) ?? false;
  }

  // 記憶ゲーム: ノーミス（めくり戻し0）
  static Future<void> unlockMemoryPerfect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_memoryPerfectKey, true);
  }

  static Future<bool> isMemoryPerfectUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_memoryPerfectKey) ?? false;
  }

  // 育成ギミック
  static Future<void> unlockPetOverfeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_petOverfeedKey, true);
  }

  static Future<bool> isPetOverfeedUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_petOverfeedKey) ?? false;
  }

  static Future<void> unlockPetOverplay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_petOverplayKey, true);
  }

  static Future<bool> isPetOverplayUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_petOverplayKey) ?? false;
  }
}
