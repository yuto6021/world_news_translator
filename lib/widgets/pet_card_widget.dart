import 'package:flutter/material.dart';
import 'dart:math' as math;

/// LED風発光アニメ付きラッパー
class GlowingPetCard extends StatefulWidget {
  final PetModelLike pet; // 必要最低限のフィールドを持つインターフェース
  final String imagePath;
  const GlowingPetCard({super.key, required this.pet, required this.imagePath});

  @override
  State<GlowingPetCard> createState() => _GlowingPetCardState();
}

/// 最低限必要なPet互換インターフェース（直接PetModelを参照しないため）
abstract class PetModelLike {
  String get name;
  int get level;
  String get species;
  String get stage;
  int get hp;
  int get attack;
  int get defense;
  int? get rarity;
}

class _GlowingPetCardState extends State<GlowingPetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _elementOfSpecies(String s) {
    const map = {
      'agumon': 'fire',
      'greymon': 'fire',
      'wargreymon': 'fire',
      'gabumon': 'water',
      'garurumon': 'water',
      'metalgarurumon': 'water',
      'patamon': 'light',
      'angemon': 'light',
      'devimon': 'dark',
      'palmon': 'grass',
      'tentomon': 'electric',
    };
    return map[s] ?? 'normal';
  }

  Color _elementColor(String e) {
    switch (e) {
      case 'fire':
        return Colors.deepOrange;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'ice':
        return Colors.cyan;
      case 'dark':
        return Colors.purple;
      case 'light':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _elementEmoji(String e) {
    switch (e) {
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'grass':
        return '🌿';
      case 'electric':
        return '⚡';
      case 'ice':
        return '❄️';
      case 'dark':
        return '🌑';
      case 'light':
        return '✨';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final element = _elementOfSpecies(widget.pet.species);
    final elementColor = _elementColor(element);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // 虹っぽいグラデーションを枠に流す
        final gradient = SweepGradient(
          colors: [
            elementColor,
            elementColor.withOpacity(0.7),
            Colors.white,
            elementColor,
          ],
          startAngle: 0,
          endAngle: 3.14 * 2,
          transform: GradientRotation(t * 3.14 * 2),
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            // 発光する外枠
            Container(
              width: 300,
              height: 430,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        elementColor.withOpacity(0.4 + math.sin(t * 6) * 0.2),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _AnimatedBorderPainter(gradient, t),
              ),
            ),
            // 元カード
            PetCardWidget(
              petImagePath: widget.imagePath,
              petName: widget.pet.name,
              level: widget.pet.level,
              species: widget.pet.species,
              stage: widget.pet.stage,
              hp: widget.pet.hp,
              attack: widget.pet.attack,
              defense: widget.pet.defense,
              rarity: widget.pet.rarity,
              showFrameCorners: true,
            ),
            // 属性バッジ
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [elementColor, elementColor.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: elementColor.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_elementEmoji(element),
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      element.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double progress;
  _AnimatedBorderPainter(this.gradient, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = gradient.createShader(rect);

    // 角丸矩形枠
    final rrect =
        RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(20));
    canvas.drawRRect(rrect, paint);

    // LED風点滅ドット（簡易）
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.8);
    const dotCount = 24;
    for (int i = 0; i < dotCount; i++) {
      final p = (i / dotCount + progress) % 1.0;
      final angle = p * 3.1415926 * 2;
      final cx = rect.center.dx + (rect.width / 2 - 10) * math.cos(angle);
      final cy = rect.center.dy + (rect.height / 2 - 10) * math.sin(angle);
      canvas.drawCircle(Offset(cx, cy), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter oldDelegate) => true;
}

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
  final int? rarity; // 1-5 で想定。nullなら未設定
  final Color? cardColor; // カードの背景色（レア度で変える）

  // デコレーション（星）のカスタマイズパラメータ
  final double? sparkleWidth; // 星の幅（デフォルト: 80）
  final double? sparkleHeight; // 星の高さ（デフォルト: 80）
  final double? sparkleTop; // 上からの位置（デフォルト: 10）
  final double? sparkleRight; // 右からの位置（デフォルト: 10）
  final BoxFit? sparkleFit; // 星の表示モード（デフォルト: BoxFit.contain）

  // カード枚線のカスタマイズパラメータ
  final Color? borderColor; // 枚線の色（デフォルト: レア度による）
  final double? borderWidth; // 枚線の太さ（デフォルト: レア度による）

  // フレームコーナーのカスタマイズパラメータ
  final double? frameCornerSize; // フレーム角の大きさ（デフォルト: 40）
  final bool showFrameCorners; // フレーム角を表示するか（デフォルト: レア度3以上でtrue）
  final Color? frameCornerColor; // フレーム角の色（デフォルト: 枠線色）

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
    this.rarity,
    this.cardColor,
    this.sparkleWidth,
    this.sparkleHeight,
    this.sparkleTop,
    this.sparkleRight,
    this.sparkleFit,
    this.borderColor,
    this.borderWidth,
    this.frameCornerSize,
    this.showFrameCorners = false,
    this.frameCornerColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveCardColor = cardColor ?? _getStageColor(stage, isDark);

    // 枚線の色と太さを決定
    final effectiveBorderColor = borderColor ?? _getRarityBorderColor();
    final effectiveBorderWidth = borderWidth ?? _getRarityBorderWidth();

    return Container(
      width: 280,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: effectiveBorderWidth > 0
            ? Border.all(
                color: effectiveBorderColor, width: effectiveBorderWidth)
            : null,
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
          // レア度スパークル（高レアほど強め）
          if (rarity != null) _buildRaritySparkle(rarity!),
          // フレームコーナー装飾（レア度3以上またはshowFrameCornersがtrue）
          if (showFrameCorners || (rarity != null && rarity! >= 3))
            ..._buildFrameCorners(),
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

  /// レア度スパークルオーバーレイ
  Widget _buildRaritySparkle(int rarity) {
    final opacity = (0.1 + (rarity.clamp(1, 5) - 1) * 0.12).clamp(0.1, 0.6);
    final width = sparkleWidth ?? 80.0;
    final height = sparkleHeight ?? 80.0;
    final top = sparkleTop ?? 10.0;
    final right = sparkleRight ?? 10.0;
    final fit = sparkleFit ?? BoxFit.contain;

    return Positioned(
      top: top,
      right: right,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Image.asset(
          'assets/ui/decorations/ui_sparkle_rarity.png',
          fit: fit,
          color: Colors.white.withOpacity(opacity.toDouble()),
          colorBlendMode: BlendMode.screen,
        ),
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
            // ステージに応じた背景画像
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  _getStageBgImage(stage),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 背景画像がない場合はグラデーション
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade200,
                          ],
                        ),
                      ),
                    );
                  },
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

  /// 進化段階に応じたバトル背景画像パスを返す
  String _getStageBgImage(String stage) {
    switch (stage) {
      case 'egg':
        return 'assets/ui/backgrounds/bg_battle_field.png';
      case 'baby':
        return 'assets/ui/backgrounds/bg_battle_forest.png';
      case 'child':
        return 'assets/ui/backgrounds/bg_battle_sky.png';
      case 'adult':
        return 'assets/ui/backgrounds/bg_battle_ocean.png';
      case 'ultimate':
        return 'assets/ui/backgrounds/bg_battle_ruins.png';
      default:
        return 'assets/ui/backgrounds/bg_battle_field.png';
    }
  }

  /// レアリティに応じた枠線の色
  Color _getRarityBorderColor() {
    if (rarity == null) return Colors.transparent;

    switch (rarity!) {
      case 1: // コモン
        return Colors.grey.shade400;
      case 2: // アンコモン
        return Colors.green.shade600;
      case 3: // レア
        return Colors.blue.shade600;
      case 4: // エピック
        return Colors.purple.shade600;
      case 5: // レジェンダリー
        return Colors.amber.shade600;
      default:
        return Colors.grey;
    }
  }

  /// レアリティに応じた枠線の太さ
  double _getRarityBorderWidth() {
    if (rarity == null) return 0;

    // レア度3以上は太い枠線
    return rarity! >= 3 ? 4.0 : 2.0;
  }

  /// フレームコーナー装飾（4隅）
  List<Widget> _buildFrameCorners() {
    final size = frameCornerSize ?? 40.0;
    final color = frameCornerColor ?? _getRarityBorderColor();

    return [
      // 左上
      Positioned(
        top: 0,
        left: 0,
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FrameCornerPainter(color, CornerPosition.topLeft),
        ),
      ),
      // 右上
      Positioned(
        top: 0,
        right: 0,
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FrameCornerPainter(color, CornerPosition.topRight),
        ),
      ),
      // 左下
      Positioned(
        bottom: 0,
        left: 0,
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FrameCornerPainter(color, CornerPosition.bottomLeft),
        ),
      ),
      // 右下
      Positioned(
        bottom: 0,
        right: 0,
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FrameCornerPainter(color, CornerPosition.bottomRight),
        ),
      ),
    ];
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

/// フレームコーナーの位置
enum CornerPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// フレームコーナー装飾描画
class _FrameCornerPainter extends CustomPainter {
  final Color color;
  final CornerPosition position;

  _FrameCornerPainter(this.color, this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final length = size.width * 0.6; // コーナーの長さ

    // 位置に応じて回転と配置を調整
    canvas.save();

    switch (position) {
      case CornerPosition.topLeft:
        // そのまま
        break;
      case CornerPosition.topRight:
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
        break;
      case CornerPosition.bottomLeft:
        canvas.translate(0, size.height);
        canvas.scale(1, -1);
        break;
      case CornerPosition.bottomRight:
        canvas.translate(size.width, size.height);
        canvas.scale(-1, -1);
        break;
    }

    // L字型の装飾を描画
    final path = Path()
      ..moveTo(0, length)
      ..lineTo(0, 8)
      ..quadraticBezierTo(0, 0, 8, 0)
      ..lineTo(length, 0);

    // 塗りつぶし（薄く）
    final fillPath = Path()
      ..moveTo(0, length)
      ..lineTo(0, 6)
      ..quadraticBezierTo(0, 0, 6, 0)
      ..lineTo(length, 0)
      ..lineTo(length - 4, 4)
      ..lineTo(6, 4)
      ..lineTo(4, 6)
      ..lineTo(4, length - 4)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // 角に小さな装飾円
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(8, 8), 2, circlePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
