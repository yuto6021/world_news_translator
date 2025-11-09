import 'package:flutter/material.dart';

// シームレスなマーキー（隙間なし）。内部で child を2回並べる。
class FxTicker extends StatefulWidget {
  final Widget child; // 中身（Row など水平連続）
  final Duration duration; // 1サイクルの時間
  final bool pauseOnHover;

  const FxTicker({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 12),
    this.pauseOnHover = false,
  });

  @override
  State<FxTicker> createState() => _FxTickerState();
}

class _FxTickerState extends State<FxTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticker = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final dx = (-_controller.value * width);
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Row(
                children: [
                  SizedBox(width: width, child: widget.child),
                  SizedBox(width: width, child: widget.child),
                ],
              ),
            );
          },
        );
      },
    );

    if (!widget.pauseOnHover) return ClipRect(child: ticker);
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _controller.stop();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _controller.repeat();
      },
      child: ClipRect(child: ticker),
    );
  }
}
