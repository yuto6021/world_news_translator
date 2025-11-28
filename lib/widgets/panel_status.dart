import 'package:flutter/material.dart';

/// ステータスパネル
/// サイズ: 600×200px相当（レスポンシブ対応）
/// 機能: ペットの4つのゲージ（お腹/機嫌/清潔/体力）を表示
class PanelStatus extends StatelessWidget {
  final String petName;
  final int level;
  final int rarity; // 1-5 (星の数)
  final String iconEmoji;
  final double hunger; // 0.0-1.0
  final double happiness; // 0.0-1.0
  final double cleanliness; // 0.0-1.0
  final double health; // 0.0-1.0

  const PanelStatus({
    Key? key,
    required this.petName,
    required this.level,
    this.rarity = 3,
    this.iconEmoji = '🐉',
    required this.hunger,
    required this.happiness,
    required this.cleanliness,
    required this.health,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600, minHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _GradientBorderPainter(
          gradient: const LinearGradient(
            colors: [Color(0xFF007BFF), Color(0xFF00C7FF)],
          ),
          strokeWidth: 2.0,
          radius: 12.0,
        ),
        child: Stack(
          children: [
            // 角の回路パターン装飾
            ..._buildCornerCircuits(),
            // コンテンツ
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildStatusBars(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 4隅の回路パターン装飾
  List<Widget> _buildCornerCircuits() {
    return [
      // 左上
      Positioned(
        top: 6,
        left: 6,
        child: _CircuitCorner(position: CornerPosition.topLeft),
      ),
      // 右上
      Positioned(
        top: 6,
        right: 6,
        child: _CircuitCorner(position: CornerPosition.topRight),
      ),
      // 左下
      Positioned(
        bottom: 6,
        left: 6,
        child: _CircuitCorner(position: CornerPosition.bottomLeft),
      ),
      // 右下
      Positioned(
        bottom: 6,
        right: 6,
        child: _CircuitCorner(position: CornerPosition.bottomRight),
      ),
    ];
  }

  /// ヘッダー部分（ペット名・レベル・レア度）
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            iconEmoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      petName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lv.$level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // レア度表示（星）
          Row(
            children: List.generate(
              rarity,
              (index) => const Text(
                '⭐',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ステータスバー4本
  Widget _buildStatusBars() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(
            label: '🍖 お腹',
            value: hunger,
            color: _getGaugeColor(hunger),
          ),
          const SizedBox(height: 8),
          _StatusBar(
            label: '😊 機嫌',
            value: happiness,
            color: _getGaugeColor(happiness),
          ),
          const SizedBox(height: 8),
          _StatusBar(
            label: '🧹 清潔',
            value: cleanliness,
            color: _getGaugeColor(cleanliness),
          ),
          const SizedBox(height: 8),
          _StatusBar(
            label: '❤️ 体力',
            value: health,
            color: _getGaugeColor(health),
          ),
        ],
      ),
    );
  }

  /// ゲージの色を値に応じて決定
  LinearGradient _getGaugeColor(double value) {
    if (value >= 0.8) {
      return const LinearGradient(
        colors: [Color(0xFF4ADE80), Color(0xFF10B981)],
      );
    } else if (value >= 0.4) {
      return const LinearGradient(
        colors: [Color(0xFFFACC15), Color(0xFFF59E0B)],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFF87171), Color(0xFFEF4444)],
      );
    }
  }
}

/// ステータスバー（1本分）
class _StatusBar extends StatelessWidget {
  final String label;
  final double value; // 0.0-1.0
  final LinearGradient color;

  const _StatusBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: color,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toInt()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// 角の回路パターン装飾
enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _CircuitCorner extends StatelessWidget {
  final CornerPosition position;

  const _CircuitCorner({required this.position});

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius;
    switch (position) {
      case CornerPosition.topLeft:
        borderRadius = const BorderRadius.only(topLeft: Radius.circular(2));
        break;
      case CornerPosition.topRight:
        borderRadius = const BorderRadius.only(topRight: Radius.circular(2));
        break;
      case CornerPosition.bottomLeft:
        borderRadius = const BorderRadius.only(bottomLeft: Radius.circular(2));
        break;
      case CornerPosition.bottomRight:
        borderRadius = const BorderRadius.only(bottomRight: Radius.circular(2));
        break;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00C7FF), width: 1),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// グラデーション枠線を描画するCustomPainter
class _GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;
  final double radius;

  _GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
