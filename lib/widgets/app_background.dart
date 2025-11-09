import 'package:flutter/material.dart';
import 'dart:ui';

/// 共通背景レイヤー（画像 + グラデ + ブラー + 緩やかなグラデ方向アニメーション）
class AppBackground extends StatefulWidget {
  final bool dark;
  final double blurSigma;
  final Widget? child;
  final Duration period; // グラデ方向の往復周期
  const AppBackground({
    super.key,
    required this.dark,
    this.blurSigma = 4,
    this.child,
    this.period = const Duration(seconds: 10),
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        // -0.2〜0.2 の範囲で緩やかにグラデーション方向を揺らす
        final shift = (0.2 * (2 * _anim.value - 1));
        final begin = Alignment(-0.8 + shift, -1.0);
        final end = Alignment(0.8 - shift, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: begin,
                    end: end,
                    colors: widget.dark
                        ? const [Color(0xFF0B1020), Color(0xFF101a3a)]
                        : const [Color(0xFFE8ECFF), Color(0xFFDDE7FF)],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: widget.dark
                      ? [
                          Colors.black.withOpacity(0.62),
                          Colors.black.withOpacity(0.44),
                          Colors.black.withOpacity(0.54),
                        ]
                      : [
                          Colors.white.withOpacity(0.75),
                          Colors.white.withOpacity(0.55),
                          Colors.white.withOpacity(0.65),
                        ],
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
              child: const SizedBox.expand(),
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}
