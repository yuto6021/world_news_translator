import 'package:flutter/material.dart';

/// ポップアップパネル
/// サイズ: 800×600px相当（モーダル表示）
/// 機能: 進化・イベント通知などの重要メッセージ表示
class PanelPopup extends StatefulWidget {
  final String title;
  final Widget content;
  final List<PopupButton> buttons;
  final String emblemEmoji;

  const PanelPopup({
    Key? key,
    required this.title,
    required this.content,
    this.buttons = const [],
    this.emblemEmoji = '🏆',
  }) : super(key: key);

  @override
  State<PanelPopup> createState() => _PanelPopupState();

  /// ダイアログとして表示
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<PopupButton> buttons = const [],
    String emblemEmoji = '🏆',
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => PanelPopup(
        title: title,
        content: content,
        buttons: buttons,
        emblemEmoji: emblemEmoji,
      ),
    );
  }
}

class _PanelPopupState extends State<PanelPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _twinkleController;
  late Animation<double> _twinkleAnimation;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _twinkleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _twinkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.95),
              const Color(0xFFC8E6FF).withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFFFC107),
            width: 4,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(child: _buildContent()),
                _buildFooter(),
              ],
            ),
            // 上部エンブレム
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.emblemEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ヘッダー部分
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007BFF), Color(0xFF8A2BE2)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white, width: 4),
        ),
      ),
      child: Stack(
        children: [
          // 左側のキラキラ
          Positioned(
            top: 8,
            left: 16,
            child: AnimatedBuilder(
              animation: _twinkleAnimation,
              builder: (context, child) => Opacity(
                opacity: _twinkleAnimation.value,
                child: Transform.scale(
                  scale: 1.0 + (_twinkleAnimation.value - 0.8) * 0.5,
                  child: const Text('✨', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
          // 右側のキラキラ
          Positioned(
            top: 8,
            right: 16,
            child: AnimatedBuilder(
              animation: _twinkleAnimation,
              builder: (context, child) => Opacity(
                opacity: _twinkleAnimation.value,
                child: Transform.scale(
                  scale: 1.0 + (_twinkleAnimation.value - 0.8) * 0.5,
                  child: const Text('✨', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
          // タイトル
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// コンテンツエリア
  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: widget.content,
        ),
      ),
    );
  }

  /// フッター（ボタンエリア）
  Widget _buildFooter() {
    if (widget.buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFFFC107), width: 4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.buttons.map((btn) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              onPressed: () {
                if (btn.onPressed != null) {
                  btn.onPressed!();
                }
                if (btn.closeOnPressed) {
                  Navigator.of(context).pop(btn.result);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: btn.isPrimary
                    ? const Color(0xFF007BFF)
                    : const Color(0xFFE0E0E0),
                foregroundColor: btn.isPrimary ? Colors.white : Colors.black87,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: Text(
                btn.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ポップアップボタンの設定
class PopupButton {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool closeOnPressed;
  final dynamic result; // Navigator.popで返す値

  const PopupButton({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.closeOnPressed = true,
    this.result,
  });
}
