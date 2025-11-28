import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/achievement.dart';

/// 実績解除時の派手なアニメーション通知
class AchievementUnlockedAnimation extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onComplete;

  const AchievementUnlockedAnimation({
    super.key,
    required this.achievement,
    this.onComplete,
  });

  @override
  State<AchievementUnlockedAnimation> createState() =>
      _AchievementUnlockedAnimationState();
}

class _AchievementUnlockedAnimationState
    extends State<AchievementUnlockedAnimation> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    final rarity = widget.achievement.rarity;

    // レア度に応じたアニメーション強度
    final scaleDuration = rarity == AchievementRarity.legendary
        ? 800
        : rarity == AchievementRarity.epic
            ? 700
            : rarity == AchievementRarity.rare
                ? 600
                : 500;

    // スケールアニメーション（飛び出す感じ）
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: scaleDuration),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: rarity == AchievementRarity.legendary
          ? Curves.elasticOut
          : rarity == AchievementRarity.epic
              ? Curves.easeOutBack
              : Curves.easeOut,
    );

    // 回転アニメーション（レア度が高いほど回転が大きい）
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final rotateAmount = rarity == AchievementRarity.legendary
        ? 0.3
        : rarity == AchievementRarity.epic
            ? 0.2
            : rarity == AchievementRarity.rare
                ? 0.1
                : 0.05;
    _rotateAnimation =
        Tween<double>(begin: -rotateAmount, end: rotateAmount).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    // パーティクル（紙吹雪）アニメーション
    _particleController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: rarity == AchievementRarity.legendary ? 2000 : 1500),
    );
    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );

    // グロー（光の脈動）アニメーション
    _glowController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: rarity == AchievementRarity.legendary ? 600 : 800),
    );
    final glowIntensity = rarity == AchievementRarity.legendary
        ? Tween<double>(begin: 0.3, end: 1.0)
        : rarity == AchievementRarity.epic
            ? Tween<double>(begin: 0.4, end: 1.0)
            : rarity == AchievementRarity.rare
                ? Tween<double>(begin: 0.5, end: 0.9)
                : Tween<double>(begin: 0.6, end: 0.8);
    _glowAnimation = glowIntensity.animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // アニメーション開始
    _scaleController.forward();
    if (rarity != AchievementRarity.common) {
      _rotateController.repeat(reverse: true);
    }
    _particleController.forward();
    if (rarity == AchievementRarity.legendary ||
        rarity == AchievementRarity.epic) {
      _glowController.repeat(reverse: true);
    }

    // レア度に応じた表示時間
    final displayDuration = rarity == AchievementRarity.legendary
        ? 4
        : rarity == AchievementRarity.epic
            ? 3
            : 2;
    Future.delayed(Duration(seconds: displayDuration), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color _getRarityColor() {
    switch (widget.achievement.rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  String _getRarityLabel() {
    switch (widget.achievement.rarity) {
      case AchievementRarity.common:
        return 'コモン';
      case AchievementRarity.rare:
        return 'レア';
      case AchievementRarity.epic:
        return 'エピック';
      case AchievementRarity.legendary:
        return 'レジェンダリー';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor();

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // パーティクル（紙吹雪）
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  progress: _particleAnimation.value,
                  color: rarityColor,
                ),
              );
            },
          ),

          // メインカード
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _scaleAnimation,
                _rotateAnimation,
                _glowAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * 0.1,
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rarityColor.withOpacity(0.9),
                            rarityColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: rarityColor
                                .withOpacity(_glowAnimation.value * 0.6),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 10 * _glowAnimation.value,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // レア度ラベル
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRarityLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // アイコン
                          Text(
                            widget.achievement.icon,
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 16),

                          // 「実績解除！」
                          const Text(
                            '🎉 実績解除！ 🎉',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // タイトル
                          Text(
                            widget.achievement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // 説明
                          Text(
                            widget.achievement.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // タップで閉じる
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                onPressed: () => widget.onComplete?.call(),
                child: const Text(
                  'タップして閉じる',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// パーティクル（紙吹雪）描画
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final math.Random _random = math.Random(42);

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // レア度に応じたパーティクル数（後で外部から指定する想定だが、今は固定）
    final particleCount = 100;
    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final startY = _random.nextDouble() * size.height * 0.3;
      final endY = size.height;
      final currentY = startY + (endY - startY) * progress;

      // 画面外に出たら描画しない
      if (currentY > size.height) continue;

      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = _getParticleColor(i).withOpacity(opacity);

      // 回転しながら落ちる
      final rotation = progress * math.pi * 4 + i;
      canvas.save();
      canvas.translate(x, currentY);
      canvas.rotate(rotation);

      // 小さな四角形や円
      if (i % 2 == 0) {
        canvas.drawRect(
          const Rect.fromLTWH(-4, -4, 8, 8),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 4, paint);
      }

      canvas.restore();
    }
  }

  Color _getParticleColor(int index) {
    final colors = [
      color,
      color.withBlue(255),
      Colors.yellow,
      Colors.white,
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// ゲームスコア演出（ハイスコア更新時）
class HighScoreAnimation extends StatefulWidget {
  final String gameName;
  final int score;
  final int? previousBest;
  final VoidCallback? onComplete;

  const HighScoreAnimation({
    super.key,
    required this.gameName,
    required this.score,
    this.previousBest,
    this.onComplete,
  });

  @override
  State<HighScoreAnimation> createState() => _HighScoreAnimationState();
}

class _HighScoreAnimationState extends State<HighScoreAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _numberAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _numberAnimation = Tween<double>(
      begin: widget.previousBest?.toDouble() ?? 0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.7),
                      blurRadius: 40,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎊 NEW RECORD! 🎊',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.gameName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _numberAnimation.value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.previousBest != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '前回: ${widget.previousBest}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ゲーム結果演出（スコアに応じた派手さ）
class GameResultAnimation extends StatefulWidget {
  final String gameName;
  final int score;
  final int? bestScore;
  final String? message;
  final VoidCallback? onComplete;
  final GameResultLevel level;

  const GameResultAnimation({
    super.key,
    required this.gameName,
    required this.score,
    this.bestScore,
    this.message,
    this.onComplete,
    this.level = GameResultLevel.normal,
  });

  @override
  State<GameResultAnimation> createState() => _GameResultAnimationState();
}

enum GameResultLevel {
  perfect, // 満点・最高クラス（金色、超派手）
  excellent, // 優秀（紫色、派手）
  good, // 良い（青色、やや派手）
  normal, // 普通（灰色、シンプル）
}

class _GameResultAnimationState extends State<GameResultAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    final duration = widget.level == GameResultLevel.perfect
        ? 1000
        : widget.level == GameResultLevel.excellent
            ? 800
            : 600;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.level == GameResultLevel.perfect
          ? Curves.elasticOut
          : Curves.easeOutBack,
    );

    _controller.forward();

    final displayDuration = widget.level == GameResultLevel.perfect ||
            widget.level == GameResultLevel.excellent
        ? 3
        : 2;
    Future.delayed(Duration(seconds: displayDuration), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getLevelColor() {
    switch (widget.level) {
      case GameResultLevel.perfect:
        return Colors.amber;
      case GameResultLevel.excellent:
        return Colors.purple;
      case GameResultLevel.good:
        return Colors.blue;
      case GameResultLevel.normal:
        return Colors.grey;
    }
  }

  String _getLevelEmoji() {
    switch (widget.level) {
      case GameResultLevel.perfect:
        return '🏆';
      case GameResultLevel.excellent:
        return '🎉';
      case GameResultLevel.good:
        return '👍';
      case GameResultLevel.normal:
        return '✅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor();
    final emoji = _getLevelEmoji();

    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // パーティクル（perfect と excellent のみ）
          if (widget.level == GameResultLevel.perfect ||
              widget.level == GameResultLevel.excellent)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ParticlePainter(
                    progress: _controller.value,
                    color: color,
                  ),
                );
              },
            ),

          // 結果カード
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.gameName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.message != null) ...[
                          Text(
                            widget.message!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'スコア: ${widget.score}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.bestScore != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'ベスト: ${widget.bestScore}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // タップで閉じる
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => widget.onComplete?.call(),
              child: const Center(
                child: Text(
                  'タップして閉じる',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 実績解除通知を表示するヘルパー
class AchievementNotifier {
  static OverlayEntry? _currentOverlay;
  static List<Achievement> _pendingAchievements = [];
  static bool _isShowing = false;

  static void show(BuildContext context, Achievement achievement) {
    // 連続解除の場合はキューに追加
    if (_isShowing) {
      _pendingAchievements.add(achievement);
      return;
    }

    _showSingle(context, achievement);
  }

  static void _showSingle(BuildContext context, Achievement achievement) {
    _isShowing = true;
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => AchievementUnlockedAnimation(
        achievement: achievement,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          _isShowing = false;

          // 保留中の実績があればコンボ演出で表示
          if (_pendingAchievements.isNotEmpty) {
            final combo = [..._pendingAchievements];
            _pendingAchievements.clear();
            _showCombo(context, combo);
          }
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void _showCombo(BuildContext context, List<Achievement> achievements) {
    _isShowing = true;
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => ComboAchievementAnimation(
        achievements: achievements,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          _isShowing = false;
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void showHighScore(
    BuildContext context, {
    required String gameName,
    required int score,
    int? previousBest,
  }) {
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => HighScoreAnimation(
        gameName: gameName,
        score: score,
        previousBest: previousBest,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void showGameResult(
    BuildContext context, {
    required String gameName,
    required int score,
    int? bestScore,
    String? message,
    required GameResultLevel level,
  }) {
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => GameResultAnimation(
        gameName: gameName,
        score: score,
        bestScore: bestScore,
        message: message,
        level: level,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }
}

/// コンボ実績解除演出（複数実績を一度に表示）
class ComboAchievementAnimation extends StatefulWidget {
  final List<Achievement> achievements;
  final VoidCallback? onComplete;

  const ComboAchievementAnimation({
    super.key,
    required this.achievements,
    this.onComplete,
  });

  @override
  State<ComboAchievementAnimation> createState() =>
      _ComboAchievementAnimationState();
}

class _ComboAchievementAnimationState extends State<ComboAchievementAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _comboController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _comboAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _comboController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _comboAnimation = CurvedAnimation(
      parent: _comboController,
      curve: Curves.easeOut,
    );

    _scaleController.forward();
    _comboController.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _comboController.dispose();
    super.dispose();
  }

  Color _getComboColor() {
    final count = widget.achievements.length;
    if (count >= 5) return Colors.red;
    if (count >= 3) return Colors.purple;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final comboColor = _getComboColor();
    final count = widget.achievements.length;

    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          // 大量パーティクル
          AnimatedBuilder(
            animation: _comboAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  progress: _comboAnimation.value,
                  color: comboColor,
                ),
              );
            },
          ),

          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [comboColor, comboColor.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: comboColor.withOpacity(0.8),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⚡ $count COMBO! ⚡',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '連続実績解除！',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: SingleChildScrollView(
                            child: Column(
                              children: widget.achievements.map((ach) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Text(
                                        ach.icon,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ach.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ach.description,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => widget.onComplete?.call(),
              child: const Center(
                child: Text(
                  'タップして閉じる',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
