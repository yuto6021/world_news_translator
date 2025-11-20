import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingModeService {
  ReadingModeService._();
  static final ReadingModeService instance = ReadingModeService._();

  // ValueNotifiers for reactive updates
  final ValueNotifier<bool> enabled = ValueNotifier(false);
  final ValueNotifier<double> fontScale = ValueNotifier(1.0); // 1.0 = base
  final ValueNotifier<double> lineHeight = ValueNotifier(1.3); // multiplier
  final ValueNotifier<bool> highContrast = ValueNotifier(false);
  final ValueNotifier<bool> dyslexicFont = ValueNotifier(false);

  static const _keyEnabled = 'reading_enabled';
  static const _keyFontScale = 'reading_font_scale';
  static const _keyLineHeight = 'reading_line_height';
  static const _keyHighContrast = 'reading_high_contrast';
  static const _keyDyslexicFont = 'reading_dyslexic_font';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_keyEnabled) ?? false;
    fontScale.value = prefs.getDouble(_keyFontScale) ?? 1.0;
    lineHeight.value = prefs.getDouble(_keyLineHeight) ?? 1.3;
    highContrast.value = prefs.getBool(_keyHighContrast) ?? false;
    dyslexicFont.value = prefs.getBool(_keyDyslexicFont) ?? false;
  }

  Future<void> setEnabled(bool v) async {
    enabled.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, v);
  }

  Future<void> setFontScale(double v) async {
    fontScale.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, v);
  }

  Future<void> setLineHeight(double v) async {
    lineHeight.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLineHeight, v);
  }

  Future<void> setHighContrast(bool v) async {
    highContrast.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, v);
  }

  Future<void> setDyslexicFont(bool v) async {
    dyslexicFont.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDyslexicFont, v);
  }
}
