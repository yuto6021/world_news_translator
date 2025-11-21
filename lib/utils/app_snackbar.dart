import 'package:flutter/material.dart';

/// 統一されたSnackBar表示ヘルパー
class AppSnackBar {
  /// 成功メッセージ（緑）
  static void success(BuildContext context, String message,
      {VoidCallback? onAction, String? actionLabel}) {
    _show(
      context,
      message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// エラーメッセージ（赤）
  static void error(BuildContext context, String message,
      {VoidCallback? onAction, String? actionLabel}) {
    _show(
      context,
      message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// 警告メッセージ（オレンジ）
  static void warning(BuildContext context, String message,
      {VoidCallback? onAction, String? actionLabel}) {
    _show(
      context,
      message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// 情報メッセージ（青）
  static void info(BuildContext context, String message,
      {VoidCallback? onAction, String? actionLabel}) {
    _show(
      context,
      message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
