import 'package:flutter/material.dart';
import 'dart:async';
import '../services/training_service.dart';
import '../models/pet.dart';

class TrainingScreen extends StatefulWidget {
  final PetModel pet;

  const TrainingScreen({super.key, required this.pet});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String? _selectedTraining;
  int _todayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayCount();
  }

  Future<void> _loadTodayCount() async {
    final count = await TrainingService.getTodayTrainingCount(widget.pet.id);
    setState(() => _todayCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('特訓'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('今日: $_todayCount/3回',
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFFfff3e0), const Color(0xFFffe0b2)],
          ),
        ),
        child:
            _selectedTraining == null ? _buildTrainingMenu() : _buildMiniGame(),
      ),
    );
  }

  Widget _buildTrainingMenu() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.fitness_center,
                    size: 60, color: Colors.orange),
                const SizedBox(height: 12),
                const Text('特訓でステータスを強化！',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'ミニゲームの成績でステータス上昇量が変わります',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (_todayCount >= 3)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text('本日の特訓回数上限に達しました',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...TrainingService.trainingTypes.entries.map((entry) {
          final config = entry.value;
          return _buildTrainingCard(
            type: entry.key,
            name: config['name'] as String,
            description: config['description'] as String,
            icon: config['icon'] as String,
            cost: config['cost'] as int,
          );
        }),
      ],
    );
  }

  Widget _buildTrainingCard({
    required String type,
    required String name,
    required String description,
    required String icon,
    required int cost,
  }) {
    final isDisabled = _todayCount >= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                setState(() => _selectedTraining = type);
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('$cost',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isDisabled ? Icons.lock : Icons.arrow_forward_ios,
                color: isDisabled ? Colors.grey : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniGame() {
    switch (_selectedTraining) {
      case 'attack':
        return _TimingMiniGame(
          onComplete: _onMiniGameComplete,
          onCancel: () => setState(() => _selectedTraining = null),
        );
      case 'defense':
        return _TapMiniGame(
          onComplete: _onMiniGameComplete,
          onCancel: () => setState(() => _selectedTraining = null),
        );
      case 'speed':
        return _ReflexMiniGame(
          onComplete: _onMiniGameComplete,
          onCancel: () => setState(() => _selectedTraining = null),
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _onMiniGameComplete(int score) async {
    if (_selectedTraining == null) return;

    try {
      final result = await TrainingService.executeTrain(
        petId: widget.pet.id,
        trainingType: _selectedTraining!,
        miniGameScore: score,
      );

      await TrainingService.incrementTodayTrainingCount(widget.pet.id);

      if (!mounted) return;

      _showResultDialog(result);
      _loadTodayCount();
      setState(() => _selectedTraining = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
      setState(() => _selectedTraining = null);
    }
  }

  void _showResultDialog(TrainingResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isPerfect ? Icons.star : Icons.trending_up,
              color: result.isPerfect ? Colors.amber : Colors.green,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(result.isPerfect ? 'パーフェクト!' : '特訓完了!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('スコア: ${result.score}点',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('${result.typeName} +${result.statGain}',
                style: const TextStyle(fontSize: 24, color: Colors.green)),
            if (result.isPerfect)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('ボーナス +2',
                    style: TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            if (result.trainingStreak > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '連続${result.trainingStreak}日',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    if (result.trainingStreak >= 5)
                      const Text(' (×2.0倍!)',
                          style: TextStyle(fontSize: 14, color: Colors.orange))
                    else if (result.trainingStreak >= 3)
                      const Text(' (×1.5倍!)',
                          style: TextStyle(fontSize: 14, color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// === タイミングミニゲーム（攻撃訓練） ===
class _TimingMiniGame extends StatefulWidget {
  final Function(int) onComplete;
  final VoidCallback onCancel;

  const _TimingMiniGame({required this.onComplete, required this.onCancel});

  @override
  State<_TimingMiniGame> createState() => _TimingMiniGameState();
}

class _TimingMiniGameState extends State<_TimingMiniGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _started = false;
  double? _targetTime;
  int? _score;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _targetTime = TrainingService.generateTimingTarget();
    });
  }

  void _tap() {
    if (!_started || _score != null) return;

    final actualTime = _controller.value * 2.0;
    final score =
        TrainingService.calculateTimingScore(_targetTime!, actualTime);

    setState(() => _score = score);

    Future.delayed(const Duration(seconds: 2), () {
      widget.onComplete(score);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚔️ タイミング攻撃 ⚔️',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('バーが中央に来たタイミングでタップ！', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 48),
          if (_started) ...[
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // ターゲットゾーン
                          if (_targetTime != null)
                            Positioned(
                              left: _targetTime! *
                                  MediaQuery.of(context).size.width *
                                  0.8,
                              child: Container(
                                width: 40,
                                height: 60,
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                          // 移動バー
                          Positioned(
                            left: _controller.value *
                                MediaQuery.of(context).size.width *
                                0.8,
                            child: Container(
                              width: 8,
                              height: 60,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_score == null)
                      ElevatedButton(
                        onPressed: _tap,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 24),
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('タップ！',
                            style:
                                TextStyle(fontSize: 24, color: Colors.white)),
                      )
                    else
                      Column(
                        children: [
                          Icon(
                            _score! >= 90 ? Icons.star : Icons.check_circle,
                            size: 80,
                            color: _score! >= 90 ? Colors.amber : Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text('スコア: $_score点',
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                );
              },
            ),
          ] else
            ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              ),
              child: const Text('スタート', style: TextStyle(fontSize: 24)),
            ),
          const Spacer(),
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}

// === 連打ミニゲーム（防御訓練） ===
class _TapMiniGame extends StatefulWidget {
  final Function(int) onComplete;
  final VoidCallback onCancel;

  const _TapMiniGame({required this.onComplete, required this.onCancel});

  @override
  State<_TapMiniGame> createState() => _TapMiniGameState();
}

class _TapMiniGameState extends State<_TapMiniGame> {
  bool _started = false;
  int _tapCount = 0;
  int _timeLeft = 5;
  Timer? _timer;

  void _start() {
    setState(() {
      _started = true;
      _tapCount = 0;
      _timeLeft = 5;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        timer.cancel();
        final score = TrainingService.calculateTapScore(_tapCount, 5);
        Future.delayed(const Duration(seconds: 1), () {
          widget.onComplete(score);
        });
      }
    });
  }

  void _tap() {
    if (_started && _timeLeft > 0) {
      setState(() => _tapCount++);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛡️ 防御連打 🛡️',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('5秒間できるだけたくさんタップ！', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 48),
          if (_started) ...[
            Text('$_timeLeft',
                style:
                    const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('タップ数: $_tapCount',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            if (_timeLeft > 0)
              GestureDetector(
                onTap: _tap,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('TAP!',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ),
          ] else
            ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              ),
              child: const Text('スタート', style: TextStyle(fontSize: 24)),
            ),
          const Spacer(),
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}

// === 反射ミニゲーム（俊敏訓練） ===
class _ReflexMiniGame extends StatefulWidget {
  final Function(int) onComplete;
  final VoidCallback onCancel;

  const _ReflexMiniGame({required this.onComplete, required this.onCancel});

  @override
  State<_ReflexMiniGame> createState() => _ReflexMiniGameState();
}

class _ReflexMiniGameState extends State<_ReflexMiniGame> {
  bool _started = false;
  bool _targetVisible = false;
  int _round = 0;
  final List<int> _reactionTimes = [];
  DateTime? _targetShowTime;

  void _start() {
    setState(() {
      _started = true;
      _round = 0;
      _reactionTimes.clear();
    });
    _nextRound();
  }

  void _nextRound() {
    if (_round >= 5) {
      final score = TrainingService.calculateReflexScore(_reactionTimes);
      Future.delayed(const Duration(seconds: 1), () {
        widget.onComplete(score);
      });
      return;
    }

    setState(() {
      _targetVisible = false;
      _round++;
    });

    final delay = Duration(
        milliseconds: 1000 + (DateTime.now().millisecondsSinceEpoch % 1000));
    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() {
        _targetVisible = true;
        _targetShowTime = DateTime.now();
      });
    });
  }

  void _tap() {
    if (!_targetVisible) return;

    final reactionTime =
        DateTime.now().difference(_targetShowTime!).inMilliseconds;
    _reactionTimes.add(reactionTime);

    _nextRound();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚡ 反射神経 ⚡',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('的が表示されたら素早くタップ！（5回）', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 48),
          if (_started) ...[
            Text('${_round}/5',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _tap,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _targetVisible
                      ? Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const Text('待機中...',
                          style: TextStyle(fontSize: 24, color: Colors.grey)),
                ),
              ),
            ),
          ] else
            ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              ),
              child: const Text('スタート', style: TextStyle(fontSize: 24)),
            ),
          const Spacer(),
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}
