import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._private() {
    // 非同期で保存値を読み込む（呼び出し元は ValueListenable を監視する）
    _load();
  }

  static final ThemeService instance = ThemeService._private();

  static const _keyThemeMode = 'settings_theme_mode_v1';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt(_keyThemeMode);
      if (idx != null && idx >= 0 && idx < ThemeMode.values.length) {
        themeMode.value = ThemeMode.values[idx];
      }
    } catch (_) {
      // ignore load errors
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, mode.index);
    } catch (_) {}
  }

  void toggleDarkMode() {
    themeMode.value =
        (themeMode.value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }
}
