import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/ui_service.dart';
import '../services/favorites_service.dart';
import '../services/translation_service.dart';
import '../services/app_settings_service.dart';
import 'guide_screen.dart';
import 'wikipedia_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 非同期で設定をロード（軽量なので unawaited）
    AppSettingsService.instance.load();

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
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ThemeService.instance.themeMode.value ==
                                    ThemeMode.light
                                ? Colors.indigo
                                : null,
                        foregroundColor:
                            ThemeService.instance.themeMode.value ==
                                    ThemeMode.light
                                ? Colors.white
                                : null,
                      ),
                      onPressed: () {
                        ThemeService.instance.setThemeMode(ThemeMode.light);
                      },
                      icon: const Icon(Icons.wb_sunny),
                      label: const Text('ライト'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ThemeService.instance.themeMode.value ==
                                    ThemeMode.dark
                                ? Colors.indigo
                                : null,
                        foregroundColor:
                            ThemeService.instance.themeMode.value ==
                                    ThemeMode.dark
                                ? Colors.white
                                : null,
                      ),
                      onPressed: () {
                        ThemeService.instance.setThemeMode(ThemeMode.dark);
                      },
                      icon: const Icon(Icons.dark_mode),
                      label: const Text('ダーク'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ThemeService.instance.themeMode.value ==
                                    ThemeMode.system
                                ? Colors.indigo
                                : null,
                        foregroundColor:
                            ThemeService.instance.themeMode.value ==
                                    ThemeMode.system
                                ? Colors.white
                                : null,
                      ),
                      onPressed: () {
                        ThemeService.instance.setThemeMode(ThemeMode.system);
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

            // 自動翻訳トグル
            ValueListenableBuilder<bool>(
              valueListenable: AppSettingsService.instance.autoTranslate,
              builder: (context, enabled, _) {
                return SwitchListTile(
                  title: const Text('自動翻訳を有効にする'),
                  subtitle: const Text('記事詳細で自動的に日本語翻訳を取得します'),
                  value: enabled,
                  onChanged: (v) =>
                      AppSettingsService.instance.setAutoTranslate(v),
                );
              },
            ),

            // DeepL優先トグル
            ValueListenableBuilder<bool>(
              valueListenable: AppSettingsService.instance.preferDeepl,
              builder: (context, prefer, _) {
                return SwitchListTile(
                  title: const Text('DeepL を優先して使用する'),
                  subtitle: const Text('DeepL 利用を優先します（利用不可時は簡易翻訳にフォールバック）'),
                  value: prefer,
                  onChanged: (v) =>
                      AppSettingsService.instance.setPreferDeepl(v),
                );
              },
            ),

            const SizedBox(height: 12),

            // カード表示モード
            ValueListenableBuilder<String>(
              valueListenable: UIService.instance.cardMode,
              builder: (context, mode, _) {
                return Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mode == 'list' ? Colors.indigo : null,
                        foregroundColor: mode == 'list' ? Colors.white : null,
                      ),
                      onPressed: () =>
                          UIService.instance.cardMode.value = 'list',
                      child: const Text('リスト表示'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            mode == 'overlay' ? Colors.indigo : null,
                        foregroundColor:
                            mode == 'overlay' ? Colors.white : null,
                      ),
                      onPressed: () =>
                          UIService.instance.cardMode.value = 'overlay',
                      child: const Text('画像オーバーレイ'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // ヒットターゲット拡大トグル
            ValueListenableBuilder<bool>(
              valueListenable: UIService.instance.expandHitTargets,
              builder: (context, expand, _) {
                return SwitchListTile(
                  title: const Text('操作領域を広げる'),
                  subtitle: const Text('アイコンのタップ領域を広げて操作しやすくします'),
                  value: expand,
                  onChanged: (v) =>
                      UIService.instance.expandHitTargets.value = v,
                );
              },
            ),

            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('使い方ガイド'),
              subtitle: const Text('アプリの各機能の簡単な説明を見る'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GuideScreen())),
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Wikipedia検索履歴'),
              subtitle: const Text('過去に検索した単語を確認・再検索'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WikipediaHistoryScreen())),
            ),

            const SizedBox(height: 8),

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
