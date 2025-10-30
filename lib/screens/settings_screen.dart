import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('テーマ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: ThemeService.instance.themeMode,
              builder: (context, mode, _) {
                return Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ThemeService.instance.themeMode.value = ThemeMode.light;
                      },
                      icon: const Icon(Icons.wb_sunny),
                      label: const Text('ライト'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        ThemeService.instance.themeMode.value = ThemeMode.dark;
                      },
                      icon: const Icon(Icons.dark_mode),
                      label: const Text('ダーク'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        ThemeService.instance.themeMode.value =
                            ThemeMode.system;
                      },
                      icon: const Icon(Icons.phone_iphone),
                      label: const Text('システム'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
