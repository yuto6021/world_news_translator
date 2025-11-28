import 'package:flutter/material.dart';

/// カード枠パネル
/// サイズ: 280×400px
/// 機能: ポケモンカード風のペット表示フレーム
class PanelCardFrame extends StatelessWidget {
  final String petName;
  final int level;
  final int rarity; // 1-5
  final String elementEmoji; // 属性アイコン（⚡🔥💧🌿）
  final String speciesName;
  final Widget petImage;
  final double atk; // 0.0-1.0
  final double def; // 0.0-1.0
  final double spd; // 0.0-1.0
  final Color backgroundColor;
  final VoidCallback? onTap;

  const PanelCardFrame({
    Key? key,
    required this.petName,
    required this.level,
    this.rarity = 3,
    this.elementEmoji = '⚡',
    required this.speciesName,
    required this.petImage,
    required this.atk,
    required this.def,
    required this.spd,
    this.backgroundColor = const Color(0xFF0F172A),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 虹色ホログラム枠線
            Positioned.fill(
              child: CustomPaint(
                painter: _RainbowBorderPainter(radius: 16.0),
              ),
            ),
            // 角の回路装飾
            ..._buildCornerCircuits(),
            // コンテンツ
            Column(
              children: [
                _buildHeader(),
                _buildImageArea(),
                _buildFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 4隅の回路パターン装飾
  List<Widget> _buildCornerCircuits() {
    const color = Color(0xFF00FFFF);
    return [
      Positioned(
        top: 8,
        left: 8,
        child: _CircuitCorner(color: color, position: CornerPosition.topLeft),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: _CircuitCorner(color: color, position: CornerPosition.topRight),
      ),
      Positioned(
        bottom: 8,
        left: 8,
        child:
            _CircuitCorner(color: color, position: CornerPosition.bottomLeft),
      ),
      Positioned(
        bottom: 8,
        right: 8,
        child:
            _CircuitCorner(color: color, position: CornerPosition.bottomRight),
      ),
    ];
  }

  /// ヘッダー部分（名前・レベル・属性）
  Widget _buildHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        border: const Border(
          bottom: BorderSide(color: Colors.white, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 属性アイコン
          Text(
            elementEmoji,
            style: const TextStyle(fontSize: 28),
          ),
          const Spacer(),
          // 名前・レベル
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                petName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'Lv.$level',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // レア度星
          Text(
            '⭐' * rarity,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  /// 画像エリア
  Widget _buildImageArea() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
          color: Colors.grey[700],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: petImage,
        ),
      ),
    );
  }

  /// フッター部分（種族名・ステータスゲージ）
  Widget _buildFooter() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: const Border(
          top: BorderSide(color: Colors.white, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          Text(
            '種族名: $speciesName',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatGauge(label: 'ATK', value: atk, color: Colors.red[300]!),
              _StatGauge(label: 'DEF', value: def, color: Colors.blue[300]!),
              _StatGauge(label: 'SPD', value: spd, color: Colors.green[300]!),
            ],
          ),
        ],
      ),
    );
  }
}

/// ステータスゲージ（ATK/DEF/SPD）
class _StatGauge extends StatelessWidget {
  final String label;
  final double value; // 0.0-1.0
  final Color color;

  const _StatGauge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 角の回路パターン装飾
enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _CircuitCorner extends StatelessWidget {
  final Color color;
  final CornerPosition position;

  const _CircuitCorner({required this.color, required this.position});

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
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// 虹色ホログラムボーダーを描画するCustomPainter
class _RainbowBorderPainter extends CustomPainter {
  final double radius;

  _RainbowBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF00FF), // Magenta
          Color(0xFF00FFFF), // Cyan
          Color(0xFFFFFF00), // Yellow
          Color(0xFFFF4500), // OrangeRed
        ],
      ).createShader(rect)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
