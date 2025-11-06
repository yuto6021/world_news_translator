import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._private();
  static final AppSettingsService instance = AppSettingsService._private();

  static const _keyAutoTranslate = 'settings_auto_translate_v1';
  static const _keyPreferDeepl = 'settings_prefer_deepl_v1';

  final ValueNotifier<bool> autoTranslate = ValueNotifier<bool>(true);
  final ValueNotifier<bool> preferDeepl = ValueNotifier<bool>(true);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      autoTranslate.value = prefs.getBool(_keyAutoTranslate) ?? true;
      preferDeepl.value = prefs.getBool(_keyPreferDeepl) ?? true;
    } catch (_) {}
  }

  Future<void> setAutoTranslate(bool v) async {
    autoTranslate.value = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoTranslate, v);
    } catch (_) {}
  }

  Future<void> setPreferDeepl(bool v) async {
    preferDeepl.value = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPreferDeepl, v);
    } catch (_) {}
  }
}
