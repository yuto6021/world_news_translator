import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/achievement_service.dart';

/// コナミコマンド検出ウィジェット
/// ↑↑↓↓←→←→BA を検出して実績解除
class KonamiCodeDetector extends StatefulWidget {
  final Widget child;

  const KonamiCodeDetector({super.key, required this.child});

  @override
  State<KonamiCodeDetector> createState() => _KonamiCodeDetectorState();
}

class _KonamiCodeDetectorState extends State<KonamiCodeDetector> {
  static const _konamiSequence = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];

  final List<LogicalKeyboardKey> _inputSequence = [];
  DateTime? _lastInputTime;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final now = DateTime.now();

    // 前回の入力から3秒以上経過したらリセット
    if (_lastInputTime != null &&
        now.difference(_lastInputTime!).inSeconds > 3) {
      _inputSequence.clear();
    }
    _lastInputTime = now;

    // 入力を追加
    _inputSequence.add(event.logicalKey);

    // シーケンスが長すぎたら古いものを削除
    if (_inputSequence.length > _konamiSequence.length) {
      _inputSequence.removeAt(0);
    }

    // コナミコマンドチェック
    if (_inputSequence.length == _konamiSequence.length) {
      bool matched = true;
      for (int i = 0; i < _konamiSequence.length; i++) {
        if (_inputSequence[i] != _konamiSequence[i]) {
          matched = false;
          break;
        }
      }

      if (matched) {
        _onKonamiCodeSuccess();
        _inputSequence.clear();
      }
    }
  }

  void _onKonamiCodeSuccess() async {
    await AchievementService.unlockKonamiCode();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎮 実績「コナミコマンド」を解除しました！'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }
}
