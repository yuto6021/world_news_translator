import 'package:flutter/material.dart';
import 'dart:ui';

/// 共通背景レイヤー（画像 + グラデ + ブラー）
class AppBackground extends StatelessWidget {
  final bool dark;
  final double blurSigma;
  final Widget? child;
  const AppBackground({super.key, required this.dark, this.blurSigma = 4, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xFF0B1020), Color(0xFF101a3a)]
                    : const [Color(0xFFE8ECFF), Color(0xFFDDE7FF)],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
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
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: const SizedBox.expand(),
        ),
        if (child != null) child!,
      ],
    );
  }
}
