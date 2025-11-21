import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ペット育成用のゲージウィジェット（Flutter製）
class PetGaugeWidget extends StatelessWidget {
  final String label; // "お腹", "機嫌", "汚れ", "体力"
  final int currentValue; // 0-100
  final int maxValue; // 通常100
  final Color gaugeColor;
  final IconData? icon;
  final bool showPercentage;

  const PetGaugeWidget({
    Key? key,
    required this.label,
    required this.currentValue,
    this.maxValue = 100,
    required this.gaugeColor,
    this.icon,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (currentValue / maxValue * 100).clamp(0, 100).toInt();
    final widthFactor = (currentValue / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ラベル行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: gaugeColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (showPercentage)
                Text(
                  '$currentValue / $maxValue',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // ゲージバー
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                children: [
                  // 背景グラデーション
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade300,
                        ],
                      ),
                    ),
                  ),
                  // ゲージ本体
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gaugeColor,
                            gaugeColor.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gaugeColor.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 光沢エフェクト
                  Positioned(
                    top: 2,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4つのゲージをまとめて表示するウィジェット
class PetGaugesPanel extends StatelessWidget {
  final int hunger; // お腹ゲージ
  final int mood; // 機嫌ゲージ
  final int dirty; // 汚れゲージ
  final int stamina; // 体力ゲージ

  const PetGaugesPanel({
    Key? key,
    required this.hunger,
    required this.mood,
    required this.dirty,
    required this.stamina,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          PetGaugeWidget(
            label: 'お腹',
            currentValue: hunger,
            gaugeColor: Colors.orange.shade600,
            icon: Icons.restaurant,
          ),
          PetGaugeWidget(
            label: '機嫌',
            currentValue: mood,
            gaugeColor: Colors.yellow.shade700,
            icon: Icons.sentiment_satisfied,
          ),
          PetGaugeWidget(
            label: '汚れ',
            currentValue: dirty,
            gaugeColor: Colors.brown.shade500,
            icon: Icons.cleaning_services,
          ),
          PetGaugeWidget(
            label: '体力',
            currentValue: stamina,
            gaugeColor: Colors.red.shade600,
            icon: Icons.favorite,
          ),
        ],
      ),
    );
  }
}

/// 経験値バー専用（レベルアップ演出付き）
class ExpGaugeWidget extends StatelessWidget {
  final int currentExp;
  final int expToNextLevel;
  final int level;

  const ExpGaugeWidget({
    Key? key,
    required this.currentExp,
    required this.expToNextLevel,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widthFactor = (currentExp / expToNextLevel).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade700,
            Colors.purple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    '経験値',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentExp / $expToNextLevel',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // キラキラエフェクト
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SparklesPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// キラキラエフェクト描画
class _SparklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // ランダムな位置に小さな星を描画
    final random = [0.2, 0.5, 0.8];
    for (var x in random) {
      _drawStar(canvas, Offset(size.width * x, size.height / 2), 3, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final x = center.dx + radius * (i % 2 == 0 ? 1 : 0.5) * math.cos(angle);
      final y = center.dy + radius * (i % 2 == 0 ? 1 : 0.5) * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
