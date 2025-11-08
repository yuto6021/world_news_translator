import 'package:flutter/material.dart';

/// オフライン状態を表示するバナーウィジェット
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;

  const OfflineBanner({
    super.key,
    this.onRetry,
    this.message = 'オフラインモード - キャッシュされた記事を表示中',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('再試行', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 接続状態を監視してオフラインバナーを表示するウィジェット
class NetworkAwareWidget extends StatefulWidget {
  final Widget child;
  final bool showOfflineBanner;
  final VoidCallback? onRetry;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.showOfflineBanner = true,
    this.onRetry,
  });

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  bool _isOffline = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline && widget.showOfflineBanner)
          OfflineBanner(onRetry: widget.onRetry),
        Expanded(child: widget.child),
      ],
    );
  }

  void setOffline(bool offline) {
    if (_isOffline != offline) {
      setState(() {
        _isOffline = offline;
      });
    }
  }
}
