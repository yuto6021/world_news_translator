import 'package:flutter/material.dart';

class ThemeService {
  ThemeService._private();
  static final ThemeService instance = ThemeService._private();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  void toggleDarkMode() {
    themeMode.value =
        (themeMode.value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }
}
