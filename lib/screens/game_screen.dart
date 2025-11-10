import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/achievement_service.dart';

/// ミニゲーム画面（暇つぶし用）
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  int _selectedGame = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Text(
              '🎮 ミニゲーム',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ニュース待ちの暇つぶしに',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // ゲーム選択タブ
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _GameTab(
                      label: '記憶ゲーム',
                      icon: Icons.memory,
                      isSelected: _selectedGame == 0,
                      onTap: () => setState(() => _selectedGame = 0),
                    ),
                  ),
                  Expanded(
                    child: _GameTab(
                      label: 'タップチャレンジ',
                      icon: Icons.touch_app,
                      isSelected: _selectedGame == 1,
                      onTap: () => setState(() => _selectedGame = 1),
                    ),
                  ),
                  Expanded(
                    child: _GameTab(
                      label: '数字パズル',
                      icon: Icons.grid_3x3,
                      isSelected: _selectedGame == 2,
                      onTap: () => setState(() => _selectedGame = 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ゲームコンテンツ
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildGameContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    switch (_selectedGame) {
      case 0:
        return const _MemoryGame(key: ValueKey('memory'));
      case 1:
        return const _TapChallengeGame(key: ValueKey('tap'));
      case 2:
        return const _NumberPuzzleGame(key: ValueKey('puzzle'));
      default:
        return const SizedBox();
    }
  }
}

class _GameTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GameTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.indigo[700] : Colors.indigo[400])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 記憶ゲーム（神経衰弱風）
class _MemoryGame extends StatefulWidget {
  const _MemoryGame({super.key});

  @override
  State<_MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<_MemoryGame> {
  static const _emojis = ['🍎', '🍊', '🍋', '🍌', '🍇', '🍓', '🍒', '🍑'];
  List<String> _cards = [];
  List<bool> _revealed = [];
  List<int> _matched = [];
  int? _firstCard;
  int? _secondCard;
  int _moves = 0;
  int _bestScore = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _initGame();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('game_memory_best') ?? 999;
    });
  }

  Future<void> _saveBestScore(int score) async {
    if (score < _bestScore || _bestScore == 999) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_memory_best', score);
      setState(() {
        _bestScore = score;
      });
    }
  }

  void _initGame() {
    _cards = [..._emojis, ..._emojis]..shuffle(Random());
    _revealed = List.filled(16, false);
    _matched = [];
    _firstCard = null;
    _secondCard = null;
    _moves = 0;
  }

  void _onCardTap(int index) {
    if (_isChecking ||
        _revealed[index] ||
        _matched.contains(index) ||
        _firstCard == index) return;

    setState(() {
      _revealed[index] = true;
      if (_firstCard == null) {
        _firstCard = index;
      } else {
        _secondCard = index;
        _moves++;
        _isChecking = true;
      }
    });

    if (_secondCard != null) {
      Timer(const Duration(milliseconds: 600), () {
        _checkMatch();
      });
    }
  }

  void _checkMatch() {
    if (_firstCard == null || _secondCard == null) return;

    if (_cards[_firstCard!] == _cards[_secondCard!]) {
      setState(() {
        _matched.addAll([_firstCard!, _secondCard!]);
      });

      // 全てマッチしたらゲームクリア
      if (_matched.length == 16) {
        _saveBestScore(_moves);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('🎉 クリア！'),
                content: Text('$_moves手でクリアしました！\nベスト: $_bestScore手'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _initGame());
                    },
                    child: const Text('もう一度'),
                  ),
                ],
              ),
            );
          }
        });
      }
    } else {
      setState(() {
        _revealed[_firstCard!] = false;
        _revealed[_secondCard!] = false;
      });
    }

    setState(() {
      _firstCard = null;
      _secondCard = null;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // スコア表示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('手数: $_moves', style: theme.textTheme.titleMedium),
            Text('ベスト: ${_bestScore == 999 ? "-" : _bestScore}手',
                style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),

        // カードグリッド
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            final isRevealed = _revealed[index] || _matched.contains(index);
            return GestureDetector(
              onTap: () => _onCardTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isRevealed
                      ? (isDark ? Colors.indigo[800] : Colors.indigo[100])
                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isRevealed ? _cards[index] : '?',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // リセットボタン
        ElevatedButton.icon(
          onPressed: () => setState(() => _initGame()),
          icon: const Icon(Icons.refresh),
          label: const Text('リセット'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.indigo[700] : Colors.indigo[400],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// タップチャレンジゲーム（高速タップ）
class _TapChallengeGame extends StatefulWidget {
  const _TapChallengeGame({super.key});

  @override
  State<_TapChallengeGame> createState() => _TapChallengeGameState();
}

class _TapChallengeGameState extends State<_TapChallengeGame> {
  int _tapCount = 0;
  int _timeLeft = 10;
  bool _isPlaying = false;
  Timer? _timer;
  int _bestScore = 0;
  int _tapSequence = 0; // 連続タップカウント
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('game_tap_best') ?? 0;
    });
  }

  Future<void> _saveBestScore(int score) async {
    if (score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_tap_best', score);
      setState(() {
        _bestScore = score;
      });
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _tapCount = 0;
      _timeLeft = 10;
      _tapSequence = 0;
      _lastTapTime = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
    });
    _saveBestScore(_tapCount);

    // 高速タッパー実績チェック（10秒で50回以上）
    if (_tapCount >= 50) {
      AchievementService.unlockFastTapper();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ 実績「ゴッドハンド」を解除しました！'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ 終了！'),
        content: Text('$_tapCount回タップしました！\nベスト: $_bestScore回'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onTap() {
    if (!_isPlaying) return;

    final now = DateTime.now();
    if (_lastTapTime != null) {
      final diff = now.difference(_lastTapTime!).inMilliseconds;
      if (diff < 200) {
        _tapSequence++;
      } else {
        _tapSequence = 0;
      }
    }
    _lastTapTime = now;

    setState(() {
      _tapCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          'ルール: 10秒間でできるだけ多くタップ！',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // タイマー＆スコア表示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text('残り時間', style: theme.textTheme.bodySmall),
                Text(
                  '$_timeLeft秒',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: _isPlaying ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text('タップ数', style: theme.textTheme.bodySmall),
                Text(
                  '$_tapCount',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // タップエリア
        GestureDetector(
          onTap: _onTap,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isPlaying
                    ? [Colors.indigo[400]!, Colors.purple[400]!]
                    : [Colors.grey[400]!, Colors.grey[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 64,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPlaying ? 'タップ！' : 'スタートを押してください',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // スタートボタン＆ベストスコア
        Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isPlaying ? null : _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('スタート'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.indigo[700] : Colors.indigo[400],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ベストスコア: $_bestScore回',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 数字パズルゲーム（15パズル風）
class _NumberPuzzleGame extends StatefulWidget {
  const _NumberPuzzleGame({super.key});

  @override
  State<_NumberPuzzleGame> createState() => _NumberPuzzleGameState();
}

class _NumberPuzzleGameState extends State<_NumberPuzzleGame> {
  List<int> _tiles = [];
  int _emptyIndex = 15;
  int _moves = 0;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _initGame();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('game_puzzle_best') ?? 999;
    });
  }

  Future<void> _saveBestScore(int score) async {
    if (score < _bestScore || _bestScore == 999) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_puzzle_best', score);
      setState(() {
        _bestScore = score;
      });
    }
  }

  void _initGame() {
    _tiles = List.generate(16, (i) => i);
    _emptyIndex = 15;
    _moves = 0;

    // シャッフル（解ける配置のみ）
    final random = Random();
    for (int i = 0; i < 100; i++) {
      final neighbors = _getNeighbors(_emptyIndex);
      final randomNeighbor = neighbors[random.nextInt(neighbors.length)];
      _swapTiles(_emptyIndex, randomNeighbor);
    }
  }

  List<int> _getNeighbors(int index) {
    final neighbors = <int>[];
    final row = index ~/ 4;
    final col = index % 4;

    if (row > 0) neighbors.add(index - 4); // 上
    if (row < 3) neighbors.add(index + 4); // 下
    if (col > 0) neighbors.add(index - 1); // 左
    if (col < 3) neighbors.add(index + 1); // 右

    return neighbors;
  }

  void _swapTiles(int a, int b) {
    final temp = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = temp;
    if (_tiles[a] == 0) _emptyIndex = a;
    if (_tiles[b] == 0) _emptyIndex = b;
  }

  bool _isSolved() {
    for (int i = 0; i < 15; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles[15] == 0;
  }

  void _onTileTap(int index) {
    if (!_getNeighbors(_emptyIndex).contains(index)) return;

    setState(() {
      _swapTiles(_emptyIndex, index);
      _moves++;
    });

    if (_isSolved()) {
      _saveBestScore(_moves);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🎉 完成！'),
              content: Text(
                  '$_moves手でクリアしました！\nベスト: ${_bestScore == 999 ? "-" : "$_bestScore手"}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _initGame());
                  },
                  child: const Text('もう一度'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          'ルール: タイルをスライドさせて1-15を順番に並べよう！',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // スコア表示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('手数: $_moves', style: theme.textTheme.titleMedium),
            Text('ベスト: ${_bestScore == 999 ? "-" : "$_bestScore手"}',
                style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),

        // パズルグリッド
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            final value = _tiles[index];
            final isEmpty = value == 0;

            return GestureDetector(
              onTap: () => _onTileTap(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isEmpty
                      ? Colors.transparent
                      : (isDark ? Colors.indigo[700] : Colors.indigo[300]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    isEmpty ? '' : '$value',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // リセットボタン
        ElevatedButton.icon(
          onPressed: () => setState(() => _initGame()),
          icon: const Icon(Icons.refresh),
          label: const Text('シャッフル'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.indigo[700] : Colors.indigo[400],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
