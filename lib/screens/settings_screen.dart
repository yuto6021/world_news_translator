import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/ui_service.dart';
import '../services/favorites_service.dart';
import '../services/translation_service.dart';

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

            const SizedBox(height: 16),

            // ホバー効果の設定
            ValueListenableBuilder<bool>(
              valueListenable: UIService.instance.hoverEnabled,
              builder: (context, enabled, _) {
                return SwitchListTile(
                  title: const Text('ホバーエフェクトを有効にする'),
                  subtitle: const Text('マウスを乗せたときにカードが浮き上がります（Web/デスクトップ向け）'),
                  value: enabled,
                  onChanged: (v) => UIService.instance.hoverEnabled.value = v,
                );
              },
            ),

            const SizedBox(height: 12),

            // お気に入りのクリア
            ElevatedButton.icon(
              onPressed: () async {
                final doClear = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('確認'),
                    content: const Text('本当に全てのお気に入りを削除しますか？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('キャンセル')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('削除')),
                    ],
                  ),
                );
                if (doClear == true) {
                  FavoritesService.instance.favorites.value = {};
                }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('お気に入りをクリア'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final doClear = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('確認'),
                    content: const Text('翻訳キャッシュをクリアしますか？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('キャンセル')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('クリア')),
                    ],
                  ),
                );
                if (doClear == true) {
                  // clear in-memory translation cache
                  TranslationService.clearCache();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('翻訳キャッシュをクリアしました')));
                }
              },
              icon: const Icon(Icons.cleaning_services),
              label: const Text('翻訳キャッシュをクリア'),
            ),
          ],
        ),
      ),
    );
  }
}
