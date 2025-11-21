import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// キーボードショートカットのラッパーウィジェット（デスクトップ/Web向け）
class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSearch;
  final VoidCallback? onRefresh;
  final VoidCallback? onHome;
  final VoidCallback? onSettings;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.onSearch,
    this.onRefresh,
    this.onHome,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Ctrl/Cmd + F で検索
        if (onSearch != null)
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              onSearch!,
        if (onSearch != null)
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): onSearch!,

        // F5 で更新
        if (onRefresh != null)
          const SingleActivator(LogicalKeyboardKey.f5): onRefresh!,

        // Ctrl/Cmd + H でホーム
        if (onHome != null)
          const SingleActivator(LogicalKeyboardKey.keyH, control: true):
              onHome!,
        if (onHome != null)
          const SingleActivator(LogicalKeyboardKey.keyH, meta: true): onHome!,

        // Ctrl/Cmd + , で設定
        if (onSettings != null)
          const SingleActivator(LogicalKeyboardKey.comma, control: true):
              onSettings!,
        if (onSettings != null)
          const SingleActivator(LogicalKeyboardKey.comma, meta: true):
              onSettings!,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
