import 'package:flutter/material.dart';
import '../services/gacha_service.dart';
import '../models/achievement.dart';
import '../widgets/achievement_animation.dart';

/// 実績ガチャ画面
class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen>
    with SingleTickerProviderStateMixin {
  bool _canDraw = false;
  Achievement? _activeChallenge;
  int _totalGachas = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    // 初期表示時にアニメーションを開始し、ScaleTransitionが0で非表示にならないようにする
    _controller.forward();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final canDraw = await GachaService.canGachaToday();
    final activeChallenge = await GachaService.getActiveChallenge();
    final totalGachas = await GachaService.getTotalGachaCount();

    setState(() {
      _canDraw = canDraw;
      _activeChallenge = activeChallenge;
      _totalGachas = totalGachas;
    });
  }

  Future<void> _drawGacha() async {
    // デバッグ用：制限チェックを無効化
    // if (!_canDraw) return;

    // ガチャ演出
    _controller.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 500));
    final challenge = await GachaService.drawGacha();

    setState(() {
      _canDraw = false;
      _activeChallenge = challenge;
      _totalGachas++;
    });

    // チャレンジ表示
    if (mounted) {
      AchievementNotifier.show(context, challenge);

      // デバッグ用：スナックバーでも表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${challenge.icon} ${challenge.title}\n${challenge.description}'),
          duration: const Duration(seconds: 3),
          backgroundColor: _getRarityColor(challenge.rarity),
        ),
      );
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
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

  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
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
    // isDark 未使用のため削除（テーマ依存表示が必要になれば再導入）

    return Scaffold(
      appBar: AppBar(
        title: const Text('実績ガチャ 🎰'),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/ui/backgrounds/gacha_bg.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade900.withOpacity(0.6),
              Colors.purple.shade700.withOpacity(0.6),
              Colors.pink.shade700.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 総ガチャ回数
                Card(
                  color: Colors.white.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.casino, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          '総ガチャ回数: $_totalGachas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ガチャボタン
                Center(
                  child: ScaleTransition(
                    scale: _animation,
                    child: GestureDetector(
                      onTap: _drawGacha, // デバッグ用：常に引けるように
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _canDraw
                                ? [Colors.yellow, Colors.orange, Colors.red]
                                : [
                                    Colors.cyan.shade300,
                                    Colors.blue.shade400,
                                    Colors.purple.shade500
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _canDraw
                                  ? Colors.orange.withOpacity(0.8)
                                  : Colors.cyan.withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _canDraw ? '🎰' : '🎲',
                                style: const TextStyle(fontSize: 64),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _canDraw ? 'ガチャを引く' : 'タップして引く',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // アクティブチャレンジ
                if (_activeChallenge != null) ...[
                  const Text(
                    '📋 現在のチャレンジ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white.withOpacity(0.15),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: _getRarityColor(_activeChallenge!.rarity),
                        width: 3,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                _activeChallenge!.icon,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _activeChallenge!.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRarityColor(
                                                _activeChallenge!.rarity),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getRarityLabel(
                                                _activeChallenge!.rarity),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _activeChallenge!.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: (_activeChallenge!.progress /
                                    _activeChallenge!.target)
                                .clamp(0.0, 1.0),
                            backgroundColor: Colors.white24,
                            color: _getRarityColor(_activeChallenge!.rarity),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '進捗: ${_activeChallenge!.progress}/${_activeChallenge!.target}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              if (_activeChallenge!.unlockedAt != null)
                                Text(
                                  '残り${24 - DateTime.now().difference(_activeChallenge!.unlockedAt!).inHours}時間',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                          if (_activeChallenge!.isUnlocked) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 28),
                                  SizedBox(width: 8),
                                  Text(
                                    'チャレンジ達成！',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else if (!_canDraw) ...[
                  const SizedBox(height: 48),
                  const Text(
                    '現在アクティブなチャレンジはありません',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // 説明
                Card(
                  color: Colors.white.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ℹ️ ガチャについて',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('• 1日1回無料でガチャを引けます'),
                        _buildInfoRow('• ランダムでチャレンジ実績が出現'),
                        _buildInfoRow('• レア度が高いほど難しく、報酬も豪華'),
                        _buildInfoRow('• 24時間以内に達成すると報酬獲得'),
                        _buildInfoRow('• 期限切れで失敗しても次のガチャが引けます'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}
