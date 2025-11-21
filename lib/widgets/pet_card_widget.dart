import 'package:flutter/material.dart';

/// ポケモンカード風のペット表示ウィジェット
class PetCardWidget extends StatelessWidget {
  final String petImagePath; // 例: "assets/pets/adult/greymon/normal_idle.png"
  final String petName;
  final int level;
  final String species;
  final String stage; // "egg", "baby", "child", "adult", "ultimate"
  final int hp;
  final int attack;
  final int defense;
  final Color? cardColor; // カードの背景色（レア度で変える）

  const PetCardWidget({
    Key? key,
    required this.petImagePath,
    required this.petName,
    required this.level,
    required this.species,
    required this.stage,
    required this.hp,
    required this.attack,
    required this.defense,
    this.cardColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveCardColor = cardColor ?? _getStageColor(stage, isDark);

    return Container(
      width: 280,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveCardColor.withOpacity(0.9),
            effectiveCardColor.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装飾パターン（カード背景）
          Positioned.fill(
            child: CustomPaint(
              painter: _CardPatternPainter(effectiveCardColor),
            ),
          ),
          // メインコンテンツ
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー（名前＋レベル）
                _buildHeader(),
                const SizedBox(height: 8),
                // ペット画像エリア
                _buildImageArea(),
                const SizedBox(height: 12),
                // ステータスバー
                _buildStatsArea(),
                const Spacer(),
                // フッター（種族名）
                _buildFooter(),
              ],
            ),
          ),
          // ホログラム風エフェクト（究極体のみ）
          if (stage == 'ultimate') _buildHologramEffect(),
        ],
      ),
    );
  }

  /// ヘッダー（名前＋レベル）
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              petName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lv.$level',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ペット画像エリア
  Widget _buildImageArea() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            // 背景グラデーション
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade200,
                  ],
                ),
              ),
            ),
            // ペット画像
            Center(
              child: Image.asset(
                petImagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // 画像が無い場合のプレースホルダー
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStageIcon(stage),
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        species.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ステータスバー（HP/攻撃/防御）
  Widget _buildStatsArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildStatRow('HP', hp, Colors.red),
          const SizedBox(height: 6),
          _buildStatRow('攻撃', attack, Colors.orange),
          const SizedBox(height: 6),
          _buildStatRow('防御', defense, Colors.blue),
        ],
      ),
    );
  }

  /// ステータス行
  Widget _buildStatRow(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (value / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// フッター（種族名＋進化段階）
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            species.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStageColor(stage, false),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStageName(stage),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ホログラム風エフェクト（究極体専用）
  Widget _buildHologramEffect() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.transparent,
                Colors.purple.withOpacity(0.2),
                Colors.transparent,
                Colors.cyan.withOpacity(0.3),
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  /// 進化段階に応じた色
  Color _getStageColor(String stage, bool isDark) {
    switch (stage) {
      case 'egg':
        return Colors.grey.shade300;
      case 'baby':
        return Colors.green.shade400;
      case 'child':
        return Colors.blue.shade500;
      case 'adult':
        return Colors.purple.shade600;
      case 'ultimate':
        return Colors.deepOrange.shade700;
      default:
        return Colors.grey;
    }
  }

  /// 進化段階名
  String _getStageName(String stage) {
    switch (stage) {
      case 'egg':
        return 'たまご';
      case 'baby':
        return '幼年期';
      case 'child':
        return '成長期';
      case 'adult':
        return '成熟期';
      case 'ultimate':
        return '究極体';
      default:
        return '不明';
    }
  }

  /// 進化段階アイコン
  IconData _getStageIcon(String stage) {
    switch (stage) {
      case 'egg':
        return Icons.egg;
      case 'baby':
        return Icons.child_care;
      case 'child':
        return Icons.face;
      case 'adult':
        return Icons.flash_on;
      case 'ultimate':
        return Icons.star;
      default:
        return Icons.help;
    }
  }
}

/// カード背景パターン描画
class _CardPatternPainter extends CustomPainter {
  final Color baseColor;

  _CardPatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 斜め線パターン
    for (double i = -size.height; i < size.width + size.height; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // 中央の円パターン
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.4),
      80,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
