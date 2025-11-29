import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/awakening_service.dart';
import '../services/pet_service.dart';

/// 覚醒画面 - 覚醒条件確認と実行
class AwakeningScreen extends StatefulWidget {
  final PetModel pet;

  const AwakeningScreen({super.key, required this.pet});

  @override
  State<AwakeningScreen> createState() => _AwakeningScreenState();
}

class _AwakeningScreenState extends State<AwakeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isAwakening = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAwaken = AwakeningService.canAwaken(widget.pet);
    final progress = AwakeningService.getAwakeningProgress(widget.pet);
    final status = AwakeningService.getAwakeningStatus(widget.pet);

    return Scaffold(
      appBar: AppBar(
        title: const Text('覚醒'),
        backgroundColor: Colors.purple.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.indigo.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // タイトルカード
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade700, Colors.indigo.shade700],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple
                                      .withOpacity(_glowController.value * 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 80,
                              color: Colors.amber.shade300,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '究極の覚醒',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.pet.nickname}の真の力を解放',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (status['isAwakened'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '既に覚醒済み',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 覚醒条件カード
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '覚醒条件',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRequirementRow(
                        '段階',
                        '究極体',
                        widget.pet.stage == 'ultimate',
                        Icons.pets,
                        Colors.purple,
                      ),
                      _buildRequirementRow(
                        'レベル',
                        '${widget.pet.level} / 50',
                        widget.pet.level >= 50,
                        Icons.trending_up,
                        Colors.orange,
                      ),
                      _buildRequirementRow(
                        '親密度',
                        '${widget.pet.intimacy} / 80',
                        widget.pet.intimacy >= 80,
                        Icons.favorite,
                        Colors.pink,
                      ),
                      _buildRequirementRow(
                        '勝利数',
                        '${widget.pet.wins} / 50',
                        widget.pet.wins >= 50,
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 100 ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '達成度: ${progress.toInt()}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: progress >= 100
                                ? Colors.green
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 効果説明カード
              Card(
                elevation: 4,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star,
                              color: Colors.amber.shade700, size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            '覚醒の効果',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildEffectRow(
                          '全ステータス 1.5倍', Icons.flash_on, Colors.red),
                      _buildEffectRow(
                          '種族名に「覚醒」の称号', Icons.auto_awesome, Colors.purple),
                      _buildEffectRow(
                          '究極体を超えた姿', Icons.emoji_events, Colors.amber),
                      _buildEffectRow(
                          '永久的な効果', Icons.all_inclusive, Colors.green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 覚醒ボタン
              if (!status['isAwakened'])
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        canAwaken && !_isAwakening ? _executeAwakening : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canAwaken ? Colors.purple.shade600 : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: canAwaken ? 8 : 2,
                    ),
                    child: _isAwakening
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, size: 32),
                              const SizedBox(width: 12),
                              Text(
                                canAwaken ? '覚醒する' : '条件未達成',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(
    String label,
    String value,
    bool isMet,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildEffectRow(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAwakening() async {
    setState(() => _isAwakening = true);

    // 演出用のディレイ
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // 覚醒演出ダイアログ
    await _showAwakeningAnimation();

    // 覚醒実行
    await AwakeningService.executeAwakening(widget.pet);

    // ペット更新
    await PetService.updatePetStats(
      widget.pet.id,
      attack: widget.pet.attack,
      defense: widget.pet.defense,
      speed: widget.pet.speed,
    );

    if (!mounted) return;

    setState(() => _isAwakening = false);

    // 完了ダイアログ
    await _showCompletionDialog();

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _showAwakeningAnimation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.purple.shade900,
                  Colors.black,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 3),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Opacity(
                        opacity: value,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 120,
                          color: Colors.amber.shade300,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 3),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: const Text(
                        '覚醒中...',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCompletionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.amber.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '覚醒完了！',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.pet.species,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '全ステータスが 1.5倍 に強化されました！',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBonus('攻撃', widget.pet.attack, Colors.red),
                _buildStatBonus('防御', widget.pet.defense, Colors.blue),
                _buildStatBonus('速度', widget.pet.speed, Colors.green),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('最高だ！', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBonus(String label, int value, Color color) {
    return Column(
      children: [
        Icon(
          label == '攻撃'
              ? Icons.flash_on
              : label == '防御'
                  ? Icons.shield
                  : Icons.speed,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
