import 'package:flutter/material.dart';

class FxTicker extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FxTicker(
      {super.key,
      required this.child,
      this.duration = const Duration(seconds: 10)});

  @override
  State<FxTicker> createState() => _FxTickerState();
}

class _FxTickerState extends State<FxTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // 左(-width) → 右(+width)へ往復ではなく、無限に流す
            final dx = -width + (2 * width) * _controller.value;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: SizedBox(
                  width: width * 2,
                  child: Align(
                      alignment: Alignment.centerLeft, child: widget.child)),
            );
          },
        );
      },
    );
  }
}
