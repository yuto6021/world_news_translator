import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/achievement_service.dart';
import '../services/news_api_service.dart';
import '../models/article.dart';
import '../widgets/achievement_animation.dart';

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

            // ゲーム選択タブ（横スクロール）
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _GameTab(
                      label: '神経衰弱(国旗)',
                      icon: Icons.flag,
                      isSelected: _selectedGame == 0,
                      onTap: () => setState(() => _selectedGame = 0),
                    ),
                    _GameTab(
                      label: 'タップ',
                      icon: Icons.touch_app,
                      isSelected: _selectedGame == 1,
                      onTap: () => setState(() => _selectedGame = 1),
                    ),
                    _GameTab(
                      label: '育成',
                      icon: Icons.pets,
                      isSelected: _selectedGame == 2,
                      onTap: () => setState(() => _selectedGame = 2),
                    ),
                    _GameTab(
                      label: '数当て',
                      icon: Icons.casino,
                      isSelected: _selectedGame == 3,
                      onTap: () => setState(() => _selectedGame = 3),
                    ),
                    _GameTab(
                      label: 'ニュースクイズ',
                      icon: Icons.quiz,
                      isSelected: _selectedGame == 4,
                      onTap: () => setState(() => _selectedGame = 4),
                    ),
                    _GameTab(
                      label: 'スネーク',
                      icon: Icons.android,
                      isSelected: _selectedGame == 5,
                      onTap: () => setState(() => _selectedGame = 5),
                    ),
                    _GameTab(
                      label: '2048',
                      icon: Icons.grid_4x4,
                      isSelected: _selectedGame == 6,
                      onTap: () => setState(() => _selectedGame = 6),
                    ),
                  ]
                      .map((w) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: w))
                      .toList(),
                ),
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
        return const _FlagMemoryGame(key: ValueKey('memory'));
      case 1:
        return const _TapChallengeGame(key: ValueKey('tap'));
      case 2:
        return const _PetRaisingGame(key: ValueKey('pet'));
      case 3:
        return const _NumberGuessGame(key: ValueKey('guess'));
      case 4:
        return const _NewsQuizGame(key: ValueKey('quiz'));
      case 5:
        return const _SnakeGame(key: ValueKey('snake'));
      case 6:
        return const _Game2048(key: ValueKey('2048'));
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

// 国旗神経衰弱
class _FlagMemoryGame extends StatefulWidget {
  const _FlagMemoryGame({super.key});

  @override
  State<_FlagMemoryGame> createState() => _FlagMemoryGameState();
}

class _FlagMemoryGameState extends State<_FlagMemoryGame> {
  static const _flagCodes = [
    'us',
    'gb',
    'jp',
    'fr',
    'de',
    'cn',
    'kr',
    'in',
    'br',
    'au',
    'ca',
    'es',
    'mx',
    'ru',
    'sa',
    'eg',
    'za',
    'id',
    'ae'
  ];
  List<String> _cards = [];
  List<bool> _revealed = [];
  List<int> _matched = [];
  int? _firstCard;
  int? _secondCard;
  int _moves = 0;
  int _bestScore = 0;
  bool _isChecking = false;
  int _mismatches = 0; // めくり戻し回数（ノーミス判定用）
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _initGame();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('game_flag_memory_best') ?? 999;
    });
  }

  Future<void> _saveBestScore(int score) async {
    if (score < _bestScore || _bestScore == 999) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_flag_memory_best', score);
      setState(() {
        _bestScore = score;
      });
    }
  }

  void _initGame() {
    final rng = Random();
    final pool = [..._flagCodes]..shuffle(rng);
    final pick = pool.take(8).toList();
    _cards = [...pick, ...pick]..shuffle(rng);
    _revealed = List.filled(16, false);
    _matched = [];
    _firstCard = null;
    _secondCard = null;
    _moves = 0;
    _mismatches = 0;
    _gameStartTime = DateTime.now();
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
        // プレイ時間記録
        if (_gameStartTime != null) {
          final elapsed = DateTime.now().difference(_gameStartTime!).inSeconds;
          AchievementService.addGamePlayTime(elapsed);
        }

        _saveBestScore(_moves);
        // 記憶王（12手以内）
        if (_moves <= 12) {
          AchievementService.unlockMemoryMaster();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🧠 実績「記憶王」を解除しました！'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        // ノーミス（めくり戻し0）
        if (_mismatches == 0) {
          AchievementService.unlockMemoryPerfect();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ 実績「完璧主義者」を解除しました！'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
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
      // ミスマッチ時にカウント
      _mismatches++;
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
                  child: isRevealed
                      ? Image.asset(
                          'assets/flags/${_cards[index]}.png',
                          width: 48,
                          height: 32,
                          errorBuilder: (_, __, ___) => const Icon(Icons.flag),
                        )
                      : const Text('?', style: TextStyle(fontSize: 32)),
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
  DateTime? _lastTapTime;
  DateTime? _gameStartTime; // ゲーム開始時刻

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
      _lastTapTime = null;
      _gameStartTime = DateTime.now();
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

    // プレイ時間記録
    if (_gameStartTime != null) {
      final elapsed = DateTime.now().difference(_gameStartTime!).inSeconds;
      AchievementService.addGamePlayTime(elapsed);
    }

    setState(() {
      _isPlaying = false;
    });
    _saveBestScore(_tapCount);

    // 高速タッパー実績チェック（10秒で50回以上 / 80回以上）
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
    if (_tapCount >= 80) {
      AchievementService.unlockFastTapGod();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👑 実績「早撃ち神」を解除しました！'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // スコアに応じた演出レベル決定
    GameResultLevel level;
    String? message;
    if (_tapCount >= 100) {
      level = GameResultLevel.perfect;
      message = '神の領域！';
    } else if (_tapCount >= 80) {
      level = GameResultLevel.excellent;
      message = 'すごい！';
    } else if (_tapCount >= 60) {
      level = GameResultLevel.good;
      message = '良い調子！';
    } else {
      level = GameResultLevel.normal;
      message = null;
    }

    // 派手な演出で結果表示
    if (mounted) {
      AchievementNotifier.showGameResult(
        context,
        gameName: 'タップチャレンジ',
        score: _tapCount,
        bestScore: _bestScore,
        message: message,
        level: level,
      );
    }
  }

  void _onTap() {
    if (!_isPlaying) return;

    final now = DateTime.now();
    if (_lastTapTime != null) {
      final diff = now.difference(_lastTapTime!).inMilliseconds;
      if (diff < 200) {
        // 連続タップ判定（200ms以内）
        _tapCount++;
      } else {
        _tapCount++;
      }
    } else {
      _tapCount++;
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
            height: 150,
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

// 簡易ペット育成ゲーム
class _PetRaisingGame extends StatefulWidget {
  const _PetRaisingGame({super.key});

  @override
  State<_PetRaisingGame> createState() => _PetRaisingGameState();
}

class _PetRaisingGameState extends State<_PetRaisingGame> {
  int _level = 1;
  int _exp = 0;
  int _happiness = 50; // 0-100
  int _energy = 100; // 0-100
  int _bestLevel = 1;
  int _evolutionStage = 0; // 進化段階: 0=卵, 1=ひな, 2=子供, 3=成体
  int _coins = 0; // コイン
  List<String> _ownedItems = []; // 所有アイテム
  String? _equippedItem; // 装備中アイテム
  int _actionCount = 0; // アクション回数
  bool _loading = true;
  Timer? _decayTimer;
  DateTime? _sessionStartTime; // セッション開始時刻
  String _lastAction = ''; // 最後のアクション
  int _consecutiveCount = 0; // 連続同一アクションカウント

  // クールダウンタイマー
  DateTime? _lastFeedTime;
  DateTime? _lastPlayTime;
  DateTime? _lastRestTime;
  static const _cooldownSeconds = 10; // 各アクションのクールダウン時間

  // デイリーログインボーナス
  int _loginStreak = 0; // 連続ログイン日数
  DateTime? _lastLoginDate; // 最後のログイン日

  // 親密度システム
  int _affection = 0; // 親密度 (0-1000)

  // デイリーミッション
  int _dailyFeedCount = 0;
  int _dailyPlayCount = 0;
  int _dailyEventCount = 0;
  DateTime? _lastMissionResetDate;

  // ペットインタラクション
  String _petReaction = ''; // ペットの反応メッセージ
  Timer? _reactionTimer; // 反応メッセージを消すタイマー
  int _petTapCount = 0; // ペットタップ回数

  static const _expPerLevelBase = 50;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _loadState();
    _startDecay();
  }

  @override
  void dispose() {
    // セッション終了時にプレイ時間記録
    if (_sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      AchievementService.addGamePlayTime(elapsed);
    }
    _decayTimer?.cancel();
    _reactionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _level = prefs.getInt('pet_level') ?? 1;
      _exp = prefs.getInt('pet_exp') ?? 0;
      _happiness = prefs.getInt('pet_happiness') ?? 50;
      _energy = prefs.getInt('pet_energy') ?? 100;
      _bestLevel = prefs.getInt('pet_best_level') ?? _level;
      _evolutionStage = prefs.getInt('pet_evolution_stage') ?? 0;
      _coins = prefs.getInt('pet_coins') ?? 0;
      _ownedItems = prefs.getStringList('pet_owned_items') ?? [];
      _equippedItem = prefs.getString('pet_equipped_item');
      _loginStreak = prefs.getInt('pet_login_streak') ?? 0;
      _affection = prefs.getInt('pet_affection') ?? 0;
      _dailyFeedCount = prefs.getInt('pet_daily_feed_count') ?? 0;
      _dailyPlayCount = prefs.getInt('pet_daily_play_count') ?? 0;
      _dailyEventCount = prefs.getInt('pet_daily_event_count') ?? 0;

      // 最後のログイン日をチェック
      final lastLoginStr = prefs.getString('pet_last_login_date');
      if (lastLoginStr != null) {
        _lastLoginDate = DateTime.parse(lastLoginStr);
      }

      // 最後のミッションリセット日をチェック
      final lastMissionResetStr =
          prefs.getString('pet_last_mission_reset_date');
      if (lastMissionResetStr != null) {
        _lastMissionResetDate = DateTime.parse(lastMissionResetStr);
      }

      _loading = false;
    });

    // デイリーミッションリセットチェック
    _checkDailyMissionReset();

    // ログインボーナスチェック
    _checkDailyLogin();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pet_level', _level);
    await prefs.setInt('pet_exp', _exp);
    await prefs.setInt('pet_happiness', _happiness);
    await prefs.setInt('pet_energy', _energy);
    await prefs.setInt('pet_evolution_stage', _evolutionStage);
    await prefs.setInt('pet_coins', _coins);
    await prefs.setStringList('pet_owned_items', _ownedItems);
    await prefs.setInt('pet_login_streak', _loginStreak);
    await prefs.setInt('pet_affection', _affection);
    await prefs.setInt('pet_daily_feed_count', _dailyFeedCount);
    await prefs.setInt('pet_daily_play_count', _dailyPlayCount);
    await prefs.setInt('pet_daily_event_count', _dailyEventCount);
    if (_lastLoginDate != null) {
      await prefs.setString(
          'pet_last_login_date', _lastLoginDate!.toIso8601String());
    }
    if (_lastMissionResetDate != null) {
      await prefs.setString('pet_last_mission_reset_date',
          _lastMissionResetDate!.toIso8601String());
    }
    if (_equippedItem != null) {
      await prefs.setString('pet_equipped_item', _equippedItem!);
    }
    if (_level > _bestLevel) {
      await prefs.setInt('pet_best_level', _level);
      _bestLevel = _level;
    }
  }

  void _checkDailyLogin() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastLoginDate == null) {
      // 初回ログイン
      _showDailyLoginBonus(1, isNewStreak: true);
      setState(() {
        _loginStreak = 1;
        _lastLoginDate = today;
      });
      _saveState();
    } else {
      final lastLogin = DateTime(
          _lastLoginDate!.year, _lastLoginDate!.month, _lastLoginDate!.day);
      final daysDiff = today.difference(lastLogin).inDays;

      if (daysDiff == 1) {
        // 連続ログイン
        setState(() {
          _loginStreak++;
          _lastLoginDate = today;
        });
        _showDailyLoginBonus(_loginStreak, isNewStreak: false);
        _saveState();
      } else if (daysDiff > 1) {
        // ストリーク途切れ
        setState(() {
          _loginStreak = 1;
          _lastLoginDate = today;
        });
        _showDailyLoginBonus(1, isNewStreak: true);
        _saveState();
      }
      // daysDiff == 0 なら今日既にログイン済み（何もしない）
    }
  }

  void _showDailyLoginBonus(int streak, {required bool isNewStreak}) {
    // ボーナス計算（最大7日間の累積ボーナス）
    final dayBonus = (streak <= 7) ? streak : 7;
    final coinBonus = 10 * dayBonus;
    final expBonus = 20 * dayBonus;

    setState(() {
      _coins += coinBonus;
    });
    _gainExp(expBonus);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNewStreak ? '🎁 デイリーログイン！' : '🔥 連続ログイン $streak日目！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNewStreak ? 'ログインボーナスをゲット！' : '連続ログイン中！ボーナスアップ！',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '💰 +$coinBonus コイン\n✨ +$expBonus 経験値',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (streak < 7)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '明日も来るとボーナスが増えるよ！\n（最大7日間）',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('やった！'),
          ),
        ],
      ),
    );
  }

  void _checkDailyMissionReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastMissionResetDate == null) {
      // 初回起動
      setState(() {
        _lastMissionResetDate = today;
      });
      _saveState();
    } else {
      final lastReset = DateTime(_lastMissionResetDate!.year,
          _lastMissionResetDate!.month, _lastMissionResetDate!.day);
      final daysDiff = today.difference(lastReset).inDays;

      if (daysDiff >= 1) {
        // 日付が変わったのでミッションリセット
        setState(() {
          _dailyFeedCount = 0;
          _dailyPlayCount = 0;
          _dailyEventCount = 0;
          _lastMissionResetDate = today;
        });
        _saveState();
      }
    }
  }

  void _checkDailyMissions() {
    // ミッション達成チェック
    final missions = [
      {'type': 'feed', 'goal': 5, 'current': _dailyFeedCount, 'reward': 30},
      {'type': 'play', 'goal': 5, 'current': _dailyPlayCount, 'reward': 40},
      {'type': 'event', 'goal': 3, 'current': _dailyEventCount, 'reward': 50},
    ];

    for (var mission in missions) {
      if (mission['current'] == mission['goal']) {
        // ミッション達成！
        final reward = mission['reward'] as int;
        setState(() {
          _coins += reward;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 デイリーミッション達成！ +${reward}コイン'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📖 ゲームの遊び方'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 目標',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ペットを育てて、レベル100・親密度1000を目指そう！',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎮 基本操作',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• ごはん：元気+15/幸福+3/EXP+8/コイン+2\n'
                '• あそぶ：幸福+10/元気-10/EXP+12/コイン+3\n'
                '• やすむ：元気+25/幸福-2/コイン+1\n'
                '※各アクションは10秒のクールダウンあり',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🐾 ペットとの触れ合い',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ペットをタップすると反応します！\n'
                '• タップごとに幸福+1、親密度+1\n'
                '• 10タップごとに5コインボーナス',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎰 ガチャ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '50コインで1回引けます\n'
                'レア度システム（5段階）：\n'
                '⚪ コモン (50%): 小報酬\n'
                '🔵 レア (25%): 中報酬\n'
                '🟣 スーパーレア (15%): 大報酬\n'
                '🟠 ウルトラレア (7%): 超報酬\n'
                '🟡 レジェンド (3%): 究極報酬\n\n'
                '報酬内容30種類以上！\n'
                'コイン/経験値/幸福/元気/親密度',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🛍️ ショップ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'コインでアイテムを購入・装備\n'
                '• EXP獲得量アップ\n'
                '• コイン獲得量アップ\n'
                '• 幸福/元気の減衰を軽減',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎯 デイリーミッション',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '毎日リセット・達成でコイン獲得\n'
                '• ごはん5回: 30コイン\n'
                '• あそぶ5回: 40コイン\n'
                '• イベント3回: 50コイン',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎁 ログインボーナス',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '毎日ログインでボーナス獲得\n'
                '連続ログインで最大7日目まで報酬アップ！',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ 注意事項',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 10秒ごとに幸福と元気が減少\n'
                '• 幸福/元気が0になると成長が遅くなる\n'
                '• レベルが上がるほど必要経験値が増加\n'
                '• レベル20/50で進化イベント発生',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _onPetTap() {
    _petTapCount++;

    // タップ回数に応じた反応
    final reactions = [
      '😊 なでなで...',
      '💕 うれしい！',
      '✨ きゃっ',
      '🎵 たのしい～',
      '💖 もっと！',
      '🌟 えへへ',
      '🎀 くすぐったい',
      '💫 やったぁ！',
    ];

    // ランダムな反応を表示
    setState(() {
      _petReaction = reactions[Random().nextInt(reactions.length)];
      // 小さな幸福度上昇
      _happiness = (_happiness + 1).clamp(0, 100);
      _affection = (_affection + 1).clamp(0, 1000);
    });

    // 2秒後に反応を消す
    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _petReaction = '';
        });
      }
    });

    // 10回タップで小さなボーナス
    if (_petTapCount % 10 == 0) {
      setState(() {
        _coins += 5;
        _petReaction = '🎁 +5コイン！';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💖 ペットが喜んでる！ +5コイン'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    _saveState();
  }

  void _startDecay() {
    _decayTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final buff = _getItemBuff(_equippedItem);
      final decayMultiplier = buff['decay'] as double;

      setState(() {
        _happiness = (_happiness - (2 * decayMultiplier).round()).clamp(0, 100);
        _energy = (_energy - (1 * decayMultiplier).round()).clamp(0, 100);
      });
      _saveState();
    });
  }

  int _expNeededForNext() {
    // レベル50まで: 基本成長
    // レベル51以降: 大幅に必要経験値増加
    if (_level <= 50) {
      return _expPerLevelBase + (_level - 1) * 30;
    } else {
      // レベル50以降は基本値の2倍 + より急な増加
      return (_expPerLevelBase * 2) + ((_level - 1) * 60);
    }
  }

  void _gainExp(int amount) {
    setState(() {
      _exp += amount;
      while (_exp >= _expNeededForNext() && _level < 100) {
        // レベル100上限
        _exp -= _expNeededForNext();
        final oldLevel = _level;
        _level++;
        _happiness = (_happiness + 5).clamp(0, 100);
        _energy = (_energy + 10).clamp(0, 100);
        _checkLevelAchievements();
        _checkEvolution(oldLevel);
      }
    });
    _saveState();
  }

  void _checkLevelAchievements() {
    if (_level >= 5) AchievementService.unlockPetLevel5();
    if (_level >= 10) AchievementService.unlockPetLevel10();
  }

  void _checkEvolution(int oldLevel) {
    int newStage = _evolutionStage;

    // 進化条件チェック
    if (_level >= 15 && _evolutionStage < 3) {
      newStage = 3; // 成体
    } else if (_level >= 10 && _evolutionStage < 2) {
      newStage = 2; // 子供
    } else if (_level >= 5 && _evolutionStage < 1) {
      newStage = 1; // ひな
    }

    if (newStage > _evolutionStage) {
      setState(() {
        _evolutionStage = newStage;
      });
      _saveState();
      _showEvolutionDialog(newStage);
    }
  }

  void _showEvolutionDialog(int stage) {
    final stageNames = ['卵', 'ひな', '子供', '成体'];
    final stageEmojis = ['🥚', '🐣', '🐥', '🐓'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✨ 進化しました！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stageEmojis[stage],
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              '「${stageNames[stage]}」に進化！',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              stage == 1
                  ? '可愛いひなになったよ！'
                  : stage == 2
                      ? '元気いっぱいの子供になったよ！'
                      : '立派な成体に成長したよ！',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 実績「${stageNames[stage]}進化」を解除しました！'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('すごい！'),
          ),
        ],
      ),
    );
  }

  void _doFeed() {
    if (_energy >= 95) return;

    // クールダウンチェック
    if (_lastFeedTime != null) {
      final elapsed = DateTime.now().difference(_lastFeedTime!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ あと${_cooldownSeconds - elapsed}秒待ってね'),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    // 連続アクションチェック
    if (_lastAction == 'feed') {
      _consecutiveCount++;
      if (_consecutiveCount >= 3) {
        AchievementService.unlockPetOverfeed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍔 実績「食べ過ぎ注意」を解除しました！'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      _lastAction = 'feed';
      _consecutiveCount = 1;
    }

    final buff = _getItemBuff(_equippedItem);
    final coinBonus = (2 * (buff['coins'] as double)).round();
    final expBonus = (8 * (buff['exp'] as double)).round();

    setState(() {
      _energy = (_energy + 15).clamp(0, 100);
      _happiness = (_happiness + 3).clamp(0, 100);
      _coins += coinBonus;
      _lastFeedTime = DateTime.now(); // クールダウン開始
      _affection = (_affection + 1).clamp(0, 1000); // 親密度+1
      _dailyFeedCount++; // ミッションカウント
    });
    _gainExp(expBonus);
    _checkRandomEvent();
    _checkDailyMissions();
  }

  void _doPlay() {
    if (_energy < 10) return;

    // クールダウンチェック
    if (_lastPlayTime != null) {
      final elapsed = DateTime.now().difference(_lastPlayTime!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ あと${_cooldownSeconds - elapsed}秒待ってね'),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    // 連続アクションチェック
    if (_lastAction == 'play') {
      _consecutiveCount++;
      if (_consecutiveCount >= 5) {
        AchievementService.unlockPetOverplay();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('😵 実績「体力の限界」を解除しました！'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      _lastAction = 'play';
      _consecutiveCount = 1;
    }

    final buff = _getItemBuff(_equippedItem);
    final coinBonus = (3 * (buff['coins'] as double)).round();
    final expBonus = (12 * (buff['exp'] as double)).round();

    setState(() {
      _happiness = (_happiness + 10).clamp(0, 100);
      _energy = (_energy - 10).clamp(0, 100);
      _coins += coinBonus;
      _lastPlayTime = DateTime.now(); // クールダウン開始
      _affection = (_affection + 2).clamp(0, 1000); // 親密度+2
      _dailyPlayCount++; // ミッションカウント
    });
    if (_happiness >= 100) {
      AchievementService.unlockPetHappy100();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐾 実績「ごきげんMAX」を解除！'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _gainExp(expBonus);
    _checkRandomEvent();
    _checkDailyMissions();
  }

  void _doRest() {
    if (_energy >= 90) return;

    // クールダウンチェック
    if (_lastRestTime != null) {
      final elapsed = DateTime.now().difference(_lastRestTime!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ あと${_cooldownSeconds - elapsed}秒待ってね'),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    }
    // 休憩は連続カウントをリセット
    _lastAction = 'rest';
    _consecutiveCount = 0;

    final buff = _getItemBuff(_equippedItem);
    final coinBonus = (1 * (buff['coins'] as double)).round();

    setState(() {
      _energy = (_energy + 25).clamp(0, 100);
      _happiness = (_happiness - 2).clamp(0, 100);
      _coins += coinBonus;
      _lastRestTime = DateTime.now(); // クールダウン開始
    });
    _saveState();
  }

  String _petEmoji() {
    // 進化段階に応じた絵文字
    final stageEmojis = [
      '🥚', // 卵 (Lv1-4)
      '🐣', // ひな (Lv5-9)
      '🐥', // 子供 (Lv10-14)
      '🐓', // 成体 (Lv15+)
    ];

    // 幸福度に基づく表情バリエーション（ひな以降）
    if (_evolutionStage == 0) {
      return stageEmojis[0]; // 卵は変化なし
    } else if (_evolutionStage == 1) {
      if (_happiness >= 80) return '�';
      if (_happiness >= 50) return '�';
      return '🐥';
    } else if (_evolutionStage == 2) {
      if (_happiness >= 80) return '🐥';
      if (_happiness >= 50) return '�';
      return '�';
    } else {
      if (_happiness >= 80) return '🐓';
      if (_happiness >= 50) return '🦃';
      return '🦅';
    }
  }

  String _getItemEmoji(String itemId) {
    const items = {
      'hat': '🎩',
      'ribbon': '🎀',
      'glasses': '😎',
      'balloon': '🎈',
      'crown': '👑',
      'diamond': '💎',
      'star': '⭐',
      'rainbow': '🌈',
      'galaxy': '🌌',
      'ultimate': '✨',
    };
    return items[itemId] ?? '';
  }

  Map<String, dynamic> _getItemBuff(String? itemId) {
    if (itemId == null) return {'exp': 1.0, 'coins': 1.0, 'decay': 1.0};

    const buffs = {
      'hat': {'exp': 1.1, 'coins': 1.0, 'decay': 1.0}, // EXP+10%
      'ribbon': {'exp': 1.0, 'coins': 1.2, 'decay': 1.0}, // コイン+20%
      'glasses': {'exp': 1.05, 'coins': 1.1, 'decay': 1.0}, // EXP+5% コイン+10%
      'balloon': {'exp': 1.0, 'coins': 1.0, 'decay': 0.5}, // 減衰半減
      'crown': {
        'exp': 1.15,
        'coins': 1.25,
        'decay': 0.7
      }, // EXP+15% コイン+25% 減衰30%軽減
      // プレミアムアイテム
      'diamond': {'exp': 1.25, 'coins': 1.35, 'decay': 1.0}, // EXP+25% コイン+35%
      'star': {'exp': 1.3, 'coins': 1.0, 'decay': 0.4}, // EXP+30% 減衰60%軽減
      'rainbow': {'exp': 1.0, 'coins': 1.5, 'decay': 0.6}, // コイン+50% 減衰40%軽減
      'galaxy': {'exp': 1.4, 'coins': 1.4, 'decay': 1.0}, // EXP+40% コイン+40%
      'ultimate': {
        'exp': 1.5,
        'coins': 1.6,
        'decay': 0.3
      }, // EXP+50% コイン+60% 減衰70%軽減
    };

    return buffs[itemId] ?? {'exp': 1.0, 'coins': 1.0, 'decay': 1.0};
  }

  void _openShop() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ShopModal(
        coins: _coins,
        ownedItems: _ownedItems,
        equippedItem: _equippedItem,
        onBuyItem: (itemId, price) {
          if (_coins >= price && !_ownedItems.contains(itemId)) {
            setState(() {
              _coins -= price;
              _ownedItems.add(itemId);
            });
            _saveState();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${_getItemEmoji(itemId)} アイテムを購入しました！')),
            );
          }
        },
        onEquipItem: (itemId) {
          setState(() {
            _equippedItem = itemId;
          });
          _saveState();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openGacha() {
    if (_coins < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💰 コインが足りません！（50コイン必要）'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎰 コインガチャ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('50コインで1回ガチャが引けます！\n何が出るかはお楽しみ♪'),
            const SizedBox(height: 16),
            Text(
              '所持コイン: $_coins',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _playGacha();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('50コインで引く'),
          ),
        ],
      ),
    );
  }

  void _playGacha() {
    setState(() {
      _coins -= 50;
    });

    // レア度判定（確率）
    final random = Random().nextDouble();
    String rarity;
    Color rarityColor;
    String rarityEmoji;

    if (random < 0.50) {
      // 50% - コモン (Common)
      rarity = 'コモン';
      rarityColor = Colors.grey;
      rarityEmoji = '⚪';
    } else if (random < 0.75) {
      // 25% - レア (Rare)
      rarity = 'レア';
      rarityColor = Colors.blue;
      rarityEmoji = '🔵';
    } else if (random < 0.90) {
      // 15% - スーパーレア (Super Rare)
      rarity = 'スーパーレア';
      rarityColor = Colors.purple;
      rarityEmoji = '🟣';
    } else if (random < 0.97) {
      // 7% - ウルトラレア (Ultra Rare)
      rarity = 'ウルトラレア';
      rarityColor = Colors.orange;
      rarityEmoji = '🟠';
    } else {
      // 3% - レジェンド (Legend)
      rarity = 'レジェンド';
      rarityColor = Colors.amber;
      rarityEmoji = '🟡';
    }

    // レア度別の報酬テーブル
    final rewardRandom = Random().nextInt(100);
    String result;
    String rewardEmoji;
    int coinReward = 0;
    int expReward = 0;
    int happinessReward = 0;
    int energyReward = 0;
    int affectionReward = 0;

    if (rarity == 'コモン') {
      // コモン報酬（10種類）
      if (rewardRandom < 25) {
        coinReward = Random().nextInt(21) + 10; // 10-30コイン
        rewardEmoji = '💰';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 50) {
        expReward = Random().nextInt(21) + 20; // 20-40経験値
        rewardEmoji = '✨';
        result = '$expReward経験値';
      } else if (rewardRandom < 65) {
        happinessReward = Random().nextInt(6) + 5; // 5-10幸福
        rewardEmoji = '💕';
        result = '幸福+$happinessReward';
      } else if (rewardRandom < 80) {
        energyReward = Random().nextInt(6) + 5; // 5-10元気
        rewardEmoji = '⚡';
        result = '元気+$energyReward';
      } else {
        affectionReward = Random().nextInt(6) + 5; // 5-10親密度
        rewardEmoji = '💖';
        result = '親密度+$affectionReward';
      }
    } else if (rarity == 'レア') {
      // レア報酬（8種類）
      if (rewardRandom < 20) {
        coinReward = Random().nextInt(31) + 40; // 40-70コイン
        rewardEmoji = '💰';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 40) {
        expReward = Random().nextInt(41) + 50; // 50-90経験値
        rewardEmoji = '✨';
        result = '$expReward経験値';
      } else if (rewardRandom < 55) {
        coinReward = Random().nextInt(16) + 20; // 20-35コイン
        expReward = Random().nextInt(21) + 30; // 30-50経験値
        rewardEmoji = '🎁';
        result = '$coinRewardコイン + $expReward経験値';
      } else if (rewardRandom < 70) {
        happinessReward = Random().nextInt(11) + 15; // 15-25幸福
        rewardEmoji = '💕';
        result = '幸福+$happinessReward';
      } else if (rewardRandom < 85) {
        energyReward = Random().nextInt(11) + 15; // 15-25元気
        rewardEmoji = '⚡';
        result = '元気+$energyReward';
      } else {
        affectionReward = Random().nextInt(16) + 15; // 15-30親密度
        rewardEmoji = '💖';
        result = '親密度+$affectionReward';
      }
    } else if (rarity == 'スーパーレア') {
      // スーパーレア報酬（6種類）
      if (rewardRandom < 20) {
        coinReward = Random().nextInt(51) + 80; // 80-130コイン
        rewardEmoji = '💰';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 40) {
        expReward = Random().nextInt(61) + 100; // 100-160経験値
        rewardEmoji = '✨';
        result = '$expReward経験値';
      } else if (rewardRandom < 60) {
        coinReward = Random().nextInt(31) + 50; // 50-80コイン
        expReward = Random().nextInt(51) + 60; // 60-110経験値
        rewardEmoji = '🎁';
        result = '$coinRewardコイン + $expReward経験値';
      } else if (rewardRandom < 75) {
        happinessReward = Random().nextInt(16) + 30; // 30-45幸福
        energyReward = Random().nextInt(16) + 30; // 30-45元気
        rewardEmoji = '💫';
        result = '幸福+$happinessReward 元気+$energyReward';
      } else {
        affectionReward = Random().nextInt(31) + 40; // 40-70親密度
        coinReward = Random().nextInt(21) + 30; // 30-50コイン
        rewardEmoji = '💝';
        result = '親密度+$affectionReward コイン+$coinReward';
      }
    } else if (rarity == 'ウルトラレア') {
      // ウルトラレア報酬（5種類）
      if (rewardRandom < 25) {
        coinReward = Random().nextInt(101) + 150; // 150-250コイン
        rewardEmoji = '💎';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 50) {
        expReward = Random().nextInt(101) + 200; // 200-300経験値
        rewardEmoji = '🌟';
        result = '$expReward経験値';
      } else if (rewardRandom < 70) {
        coinReward = Random().nextInt(81) + 100; // 100-180コイン
        expReward = Random().nextInt(101) + 120; // 120-220経験値
        rewardEmoji = '🎊';
        result = '$coinRewardコイン + $expReward経験値';
      } else if (rewardRandom < 85) {
        happinessReward = 50;
        energyReward = 50;
        affectionReward = Random().nextInt(51) + 50; // 50-100親密度
        rewardEmoji = '🌈';
        result = '幸福MAX 元気MAX 親密度+$affectionReward';
      } else {
        // 全ステータス大幅アップ
        coinReward = Random().nextInt(51) + 80; // 80-130コイン
        expReward = Random().nextInt(81) + 100; // 100-180経験値
        happinessReward = Random().nextInt(21) + 30; // 30-50幸福
        energyReward = Random().nextInt(21) + 30; // 30-50元気
        affectionReward = Random().nextInt(31) + 40; // 40-70親密度
        rewardEmoji = '🎇';
        result = '全ステータスUP！';
      }
    } else {
      // レジェンド報酬（4種類）超豪華
      if (rewardRandom < 30) {
        coinReward = Random().nextInt(201) + 300; // 300-500コイン
        rewardEmoji = '👑';
        result = '$coinRewardコイン（超大量）';
      } else if (rewardRandom < 60) {
        expReward = Random().nextInt(301) + 400; // 400-700経験値
        rewardEmoji = '⭐';
        result = '$expReward経験値（超大量）';
      } else if (rewardRandom < 85) {
        coinReward = Random().nextInt(151) + 200; // 200-350コイン
        expReward = Random().nextInt(201) + 300; // 300-500経験値
        affectionReward = Random().nextInt(101) + 100; // 100-200親密度
        rewardEmoji = '🏆';
        result = '超豪華セット！';
      } else {
        // 究極報酬：全てMAX
        coinReward = Random().nextInt(101) + 250; // 250-350コイン
        expReward = Random().nextInt(151) + 350; // 350-500経験値
        happinessReward = 100;
        energyReward = 100;
        affectionReward = Random().nextInt(151) + 150; // 150-300親密度
        rewardEmoji = '✨';
        result = '🎉究極の大当たり🎉\n全能力MAX＋超ボーナス！';
      }
    }

    // 報酬を適用
    setState(() {
      _coins += coinReward;
      _happiness = (_happiness + happinessReward).clamp(0, 100);
      _energy = (_energy + energyReward).clamp(0, 100);
      _affection = (_affection + affectionReward).clamp(0, 1000);
    });
    if (expReward > 0) {
      _gainExp(expReward);
    }
    _saveState();

    // 結果表示（レア度に応じた演出）
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: rarityColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(rarityEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      rarity,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(rarityEmoji, style: const TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rewardEmoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        result,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                    if (_coins >= 50)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _playGacha();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rarityColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('もう1回！'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkRandomEvent() {
    _actionCount++;
    // 20-30アクションごとにランダムイベント発生（確率30%に上昇）
    if (_actionCount >= 20 && Random().nextDouble() < 0.30) {
      _actionCount = 0;
      _dailyEventCount++; // イベントミッションカウント
      _showRandomEvent();
      _checkDailyMissions(); // イベント後にミッションチェック
    }
  }

  void _showRandomEvent() {
    final events = [
      {
        'title': '🎁 宝箱発見！',
        'description': 'キラキラ光る宝箱を見つけました！',
        'choices': [
          {'text': '開ける', 'coins': 30, 'happiness': 5, 'energy': 0},
          {'text': '無視する', 'coins': 0, 'happiness': -5, 'energy': 5},
        ],
      },
      {
        'title': '👤 訪問者',
        'description': '誰かが遊びに来ました！',
        'choices': [
          {'text': '歓迎する', 'coins': 10, 'happiness': 15, 'energy': -5},
          {'text': '断る', 'coins': 5, 'happiness': -10, 'energy': 10},
        ],
      },
      {
        'title': '🎪 お祭り',
        'description': '近くでお祭りが開催中！',
        'choices': [
          {
            'text': '参加する',
            'coins': -10,
            'happiness': 20,
            'energy': -10,
            'exp': 30
          },
          {'text': '見送る', 'coins': 0, 'happiness': 0, 'energy': 0},
        ],
      },
      {
        'title': '⭐ 流れ星',
        'description': '流れ星が通り過ぎました！',
        'choices': [
          {
            'text': '願いを込める',
            'coins': 0,
            'happiness': 10,
            'energy': 0,
            'exp': 20
          },
          {'text': '見守る', 'coins': 5, 'happiness': 5, 'energy': 5},
        ],
      },
      {
        'title': '🌈 虹が出た！',
        'description': '美しい虹が空にかかっています！',
        'choices': [
          {'text': '写真を撮る', 'coins': 15, 'happiness': 12, 'energy': -3},
          {'text': 'のんびり眺める', 'coins': 0, 'happiness': 8, 'energy': 5},
        ],
      },
      {
        'title': '💎 レアアイテム発見！',
        'description': '地面にキラキラ光る石が！',
        'choices': [
          {'text': '拾う', 'coins': 50, 'happiness': 8, 'energy': 0},
          {'text': '誰かに譲る', 'coins': 20, 'happiness': 15, 'energy': 0},
        ],
      },
      {
        'title': '🍀 幸運の四つ葉',
        'description': '珍しい四つ葉のクローバーを見つけた！',
        'choices': [
          {
            'text': '大切にする',
            'coins': 10,
            'happiness': 20,
            'energy': 0,
            'exp': 25
          },
          {'text': '押し花にする', 'coins': 25, 'happiness': 10, 'energy': 0},
        ],
      },
      {
        'title': '🎵 路上ライブ',
        'description': '素敵な音楽が聞こえてきます！',
        'choices': [
          {
            'text': '聴き入る',
            'coins': -5,
            'happiness': 18,
            'energy': -5,
            'exp': 15
          },
          {
            'text': '応援する',
            'coins': -10,
            'happiness': 12,
            'energy': -2,
            'exp': 20
          },
          {'text': '通り過ぎる', 'coins': 0, 'happiness': 0, 'energy': 0},
        ],
      },
      {
        'title': '🦋 珍しい蝶々',
        'description': 'めったに見られない美しい蝶が飛んでいる！',
        'choices': [
          {
            'text': '追いかける',
            'coins': 0,
            'happiness': 15,
            'energy': -8,
            'exp': 35
          },
          {'text': '観察する', 'coins': 5, 'happiness': 10, 'energy': 0, 'exp': 20},
        ],
      },
    ];

    // 超レアイベント（5%の確率）
    if (Random().nextDouble() < 0.05) {
      final rareEvents = [
        {
          'title': '🌟 奇跡の出会い！',
          'description': '伝説の生き物に出会った！！',
          'choices': [
            {
              'text': '友達になる',
              'coins': 100,
              'happiness': 30,
              'energy': 10,
              'exp': 100
            },
            {
              'text': '写真だけ撮る',
              'coins': 50,
              'happiness': 20,
              'energy': 0,
              'exp': 50
            },
          ],
        },
        {
          'title': '💰 大当たり！',
          'description': 'コイン袋を拾った！！',
          'choices': [
            {'text': '全部もらう', 'coins': 200, 'happiness': 15, 'energy': 0},
            {
              'text': '半分寄付',
              'coins': 100,
              'happiness': 25,
              'energy': 0,
              'exp': 50
            },
          ],
        },
      ];
      final event = rareEvents[Random().nextInt(rareEvents.length)];
      _showEventDialog(event);
      return;
    }

    final event = events[Random().nextInt(events.length)];
    _showEventDialog(event);
  }

  void _showEventDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['title'] as String),
        content: Text(event['description'] as String),
        actions: (event['choices'] as List).map((choice) {
          return TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyEventEffect(choice as Map<String, dynamic>);
            },
            child: Text(choice['text'] as String),
          );
        }).toList(),
      ),
    );
  }

  void _applyEventEffect(Map<String, dynamic> effect) {
    setState(() {
      _coins = (_coins + ((effect['coins'] ?? 0) as int)).clamp(0, 999999);
      _happiness =
          (_happiness + ((effect['happiness'] ?? 0) as int)).clamp(0, 100);
      _energy = (_energy + ((effect['energy'] ?? 0) as int)).clamp(0, 100);
      if (effect['exp'] != null) {
        _gainExp(effect['exp'] as int);
      }
    });
    _saveState();

    String message = 'イベント完了！';
    if ((effect['coins'] ?? 0) > 0) message += ' +${effect['coins']}コイン';
    if ((effect['happiness'] ?? 0) > 0) message += ' +${effect['happiness']}幸福';
    if ((effect['exp'] ?? 0) > 0) message += ' +${effect['exp']}EXP';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = _exp / _expNeededForNext();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lv $_level', style: theme.textTheme.titleLarge),
            Row(
              children: [
                const Text('💰 ', style: TextStyle(fontSize: 16)),
                Text('$_coins', style: theme.textTheme.titleMedium),
                const SizedBox(width: 16),
                Text('最高: $_bestLevel', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0, 1),
          minHeight: 16,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation(Colors.teal),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _onPetTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 進化段階に応じた画像（存在しない場合は絵文字にフォールバック）
                  Builder(builder: (context) {
                    final stage = _evolutionStage.clamp(0, 3);
                    final path = 'assets/images/pet_stage_'
                        '${stage.toString()}'
                        '.png';
                    return Image.asset(
                      path,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        _petEmoji(),
                        style: const TextStyle(fontSize: 80),
                      ),
                    );
                  }),
                  if (_equippedItem != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        _getItemEmoji(_equippedItem!),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  if (_petReaction.isNotEmpty)
                    Positioned(
                      top: -30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _petReaction,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Text(
          'タップして触れ合おう！',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (_equippedItem != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getItemEmoji(_equippedItem!),
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  () {
                    final buff = _getItemBuff(_equippedItem);
                    final parts = <String>[];
                    if (buff['exp'] != 1.0) {
                      final expBonus = ((buff['exp'] as double) - 1) * 100;
                      parts.add('EXP ${expBonus.toInt()}%↑');
                    }
                    if (buff['coins'] != 1.0) {
                      final coinBonus = ((buff['coins'] as double) - 1) * 100;
                      parts.add('コイン ${coinBonus.toInt()}%↑');
                    }
                    if (buff['decay'] != 1.0) {
                      final decayReduction =
                          (1 - (buff['decay'] as double)) * 100;
                      parts.add('減衰 ${decayReduction.toInt()}%↓');
                    }
                    return parts.join(' ');
                  }(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statChip('幸福', _happiness, Colors.pink),
            _statChip('元気', _energy, Colors.amber),
            _statChip('EXP', ((_exp / _expNeededForNext()) * 100).toInt(),
                Colors.teal),
          ],
        ),
        const SizedBox(height: 12),
        // 親密度表示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💖 親密度',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('$_affection / 1000',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _affection / 1000,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation(Colors.pink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // デイリーミッション表示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎯 デイリーミッション',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _missionRow('ごはん 5回', _dailyFeedCount, 5, '30コイン'),
              _missionRow('あそぶ 5回', _dailyPlayCount, 5, '40コイン'),
              _missionRow('イベント 3回', _dailyEventCount, 3, '50コイン'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _actionButton(Icons.fastfood, 'ごはん', _doFeed,
                enabled: _energy < 95, lastActionTime: _lastFeedTime),
            _actionButton(Icons.toys, 'あそぶ', _doPlay,
                enabled: _energy >= 10, lastActionTime: _lastPlayTime),
            _actionButton(Icons.bedtime, 'やすむ', _doRest,
                enabled: _energy < 90, lastActionTime: _lastRestTime),
            _actionButton(Icons.shopping_bag, 'ショップ', _openShop, enabled: true),
            _actionButton(Icons.casino, 'ガチャ', _openGacha,
                enabled: true, buttonColor: Colors.amber),
            _actionButton(Icons.help_outline, 'ガイド', _showGuide,
                enabled: true, buttonColor: Colors.blue),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '・ごはん: 元気+15/幸福+3/exp+8/コイン+2\n・あそぶ: 幸福+10/元気-10/exp+12/コイン+3\n・やすむ: 元気+25/幸福-2/コイン+1\n一定時間で幸福/元気は減少します。Lvが上がると必要EXPが増えます。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text('$value', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _missionRow(String label, int current, int goal, String reward) {
    final isCompleted = current >= goal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '$current/$goal',
            style: TextStyle(
              fontSize: 13,
              color: isCompleted ? Colors.green : Colors.grey[600],
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reward,
              style: TextStyle(
                fontSize: 11,
                color: isCompleted ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap,
      {bool enabled = true, DateTime? lastActionTime, Color? buttonColor}) {
    String? cooldownText;
    if (lastActionTime != null) {
      final elapsed = DateTime.now().difference(lastActionTime).inSeconds;
      if (elapsed < _cooldownSeconds) {
        cooldownText = '${_cooldownSeconds - elapsed}秒';
      }
    }

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
            if (cooldownText != null)
              Text(
                cooldownText,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}

// ニュースクイズ（3択）
class _NewsQuizGame extends StatefulWidget {
  const _NewsQuizGame({super.key});

  @override
  State<_NewsQuizGame> createState() => _NewsQuizGameState();
}

class _NewsQuizGameState extends State<_NewsQuizGame> {
  late Future<List<Article>> _future;
  int _current = 0;
  int _score = 0;
  int _best = 0;
  late List<_QuizQ> _questions;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _best = p.getInt('quiz_best_score') ?? 0);
  }

  Future<List<Article>> _load() async {
    final arts = await NewsApiService.getTopHeadlines();
    _questions = _buildQuestions(arts.take(10).toList());
    _current = 0;
    _score = 0;
    return arts;
  }

  List<_QuizQ> _buildQuestions(List<Article> arts) {
    final rng = Random();
    final qs = <_QuizQ>[];
    for (final a in arts.take(5)) {
      // 常に国当てに統一（国旗クイズ）
      final cc = _inferCountry('${a.title} ${a.description} ${a.url}');
      final all = ['US', 'GB', 'JP', 'FR', 'DE', 'CN', 'IN'];
      all.shuffle(rng);
      if (!all.contains(cc)) all[0] = cc;
      qs.add(_QuizQ(
        question: 'この記事の国旗はどれ？',
        correct: cc,
        options: all.take(3).toList(),
        article: a,
      ));
    }
    return qs;
  }

  String _inferTopic(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'economy|inflation|market|bank|stock').hasMatch(t)) return '経済';
    if (RegExp(r'AI|tech|software|google|microsoft|apple|chip',
            caseSensitive: false)
        .hasMatch(text)) return 'テクノロジー';
    if (RegExp(r'football|soccer|nba|olympic|tennis|fifa').hasMatch(t))
      return 'スポーツ';
    if (RegExp(r'film|music|celebrity|netflix|hollywood').hasMatch(t))
      return 'エンタメ';
    return '政治';
  }

  String _inferCountry(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'united states|usa|us\b|biden|trump|washington').hasMatch(t))
      return 'US';
    if (RegExp(r'united kingdom|uk\b|britain|london|sunak|british').hasMatch(t))
      return 'GB';
    if (RegExp(r'japan|tokyo|kishida|japanese').hasMatch(t)) return 'JP';
    if (RegExp(r'france|paris|macron|french').hasMatch(t)) return 'FR';
    if (RegExp(r'germany|berlin|german|scholz').hasMatch(t)) return 'DE';
    if (RegExp(r'china|beijing|xi jinping|chinese').hasMatch(t)) return 'CN';
    if (RegExp(r'india|delhi|modi|indian').hasMatch(t)) return 'IN';
    return 'US';
  }

  Future<void> _answer(String selected) async {
    final q = _questions[_current];
    if (selected == q.correct) _score++;
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      final p = await SharedPreferences.getInstance();
      final previousBest = _best;
      if (_score > _best) {
        await p.setInt('quiz_best_score', _score);
        setState(() => _best = _score);

        // 新記録演出
        if (mounted) {
          AchievementNotifier.showHighScore(
            context,
            gameName: 'ニュースクイズ',
            score: _score,
            previousBest: previousBest > 0 ? previousBest : null,
          );
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(_score == _questions.length ? '🎉 満点！' : '結果'),
            content: Text('スコア: $_score / ${_questions.length}'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _future = _load();
                    });
                  },
                  child: const Text('もう一度'))
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<List<Article>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_questions.isEmpty) {
          return const Center(child: Text('問題を生成できませんでした'));
        }
        final q = _questions[_current];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🧠 ニュースクイズ ${_current + 1}/${_questions.length}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_best > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('ベスト: $_best',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(q.article.title, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.indigo[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(q.question,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                ...q.options.map((o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: () => _answer(o),
                        child: Text(o),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuizQ {
  final String question;
  final String correct;
  final List<String> options;
  final Article article;
  _QuizQ(
      {required this.question,
      required this.correct,
      required this.options,
      required this.article});
}

// シンプル・スネーク
class _SnakeGame extends StatefulWidget {
  const _SnakeGame({super.key});
  @override
  State<_SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<_SnakeGame> {
  static const int _rows = 20;
  static const int _cols = 20;
  static const Duration _tick = Duration(milliseconds: 200);
  Timer? _timer;
  List<Offset> _snake = [const Offset(10, 10)];
  Offset _dir = const Offset(1, 0);
  Offset _apple = const Offset(5, 5);
  int _best = 1;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _best = p.getInt('snake_best') ?? 1);
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _step());
  }

  void _reset() {
    setState(() {
      _snake = [const Offset(10, 10)];
      _dir = const Offset(1, 0);
      _apple = Offset(Random().nextInt(_cols).toDouble(),
          Random().nextInt(_rows).toDouble());
    });
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    if (_snake.length > _best) {
      final previousBest = _best;
      await p.setInt('snake_best', _snake.length);
      setState(() => _best = _snake.length);

      // 新記録演出
      if (mounted && _snake.length >= 10) {
        AchievementNotifier.showHighScore(
          context,
          gameName: 'スネーク',
          score: _snake.length,
          previousBest: previousBest > 1 ? previousBest : null,
        );
      }
    }
  }

  void _step() {
    final head = _snake.first + _dir;
    if (head.dx < 0 ||
        head.dy < 0 ||
        head.dx >= _cols ||
        head.dy >= _rows ||
        _snake.contains(head)) {
      _saveBest();
      _reset();
      return;
    }
    setState(() {
      _snake = [head, ..._snake];
      if (head == _apple) {
        _apple = Offset(Random().nextInt(_cols).toDouble(),
            Random().nextInt(_rows).toDouble());
      } else {
        _snake.removeLast();
      }
    });
  }

  void _change(Offset d) {
    if ((_dir + d) == Offset.zero) return; // 逆走禁止
    setState(() => _dir = d);
  }

  @override
  Widget build(BuildContext context) {
    final cell = 14.0;
    return Column(
      children: [
        Text('長さ: ${_snake.length}  ベスト: $_best'),
        const SizedBox(height: 8),
        SizedBox(
          width: _cols * cell,
          height: _rows * cell,
          child: Stack(
            children: [
              // apple
              Positioned(
                left: _apple.dx * cell,
                top: _apple.dy * cell,
                child: Image.asset(
                  'assets/flags/us.png',
                  width: cell,
                  height: cell * 0.7,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.article, size: 12),
                ),
              ),
              // snake body
              ..._snake.map((p) => Positioned(
                    left: p.dx * cell,
                    top: p.dy * cell,
                    child: Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => _change(const Offset(0, -1)),
                child: const Icon(Icons.keyboard_arrow_up)),
            ElevatedButton(
                onPressed: () => _change(const Offset(-1, 0)),
                child: const Icon(Icons.keyboard_arrow_left)),
            ElevatedButton(
                onPressed: () => _change(const Offset(1, 0)),
                child: const Icon(Icons.keyboard_arrow_right)),
            ElevatedButton(
                onPressed: () => _change(const Offset(0, 1)),
                child: const Icon(Icons.keyboard_arrow_down)),
          ],
        )
      ],
    );
  }
}

// 2048 ミニマム実装
class _Game2048 extends StatefulWidget {
  const _Game2048({super.key});
  @override
  State<_Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<_Game2048> {
  late List<List<int>> b;
  int best = 0;

  @override
  void initState() {
    super.initState();
    _reset();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    setState(() => best = p.getInt('2048_best') ?? 0);
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    final maxTile = b.expand((e) => e).fold<int>(0, (a, c) => c > a ? c : a);
    if (maxTile > best) {
      final previousBest = best;
      await p.setInt('2048_best', maxTile);
      setState(() => best = maxTile);

      // 新記録演出（128以上で表示）
      if (mounted && maxTile >= 128) {
        AchievementNotifier.showHighScore(
          context,
          gameName: '2048',
          score: maxTile,
          previousBest: previousBest > 0 ? previousBest : null,
        );
      }
    }
  }

  void _reset() {
    b = List.generate(4, (_) => List.filled(4, 0));
    _spawn();
    _spawn();
    setState(() {});
  }

  void _spawn() {
    final empty = <Offset>[];
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {
        if (b[y][x] == 0) empty.add(Offset(x.toDouble(), y.toDouble()));
      }
    }
    if (empty.isEmpty) return;
    final o = empty[Random().nextInt(empty.length)];
    b[o.dy.toInt()][o.dx.toInt()] = Random().nextDouble() < 0.9 ? 2 : 4;
  }

  void _move(int dx, int dy) {
    bool moved = false;
    for (int k = 0; k < 4; k++) {
      for (int y = (dy > 0 ? 2 : 1); y >= 0 && y < 4; y += (dy > 0 ? -1 : 1)) {
        for (int x = (dx > 0 ? 2 : 1);
            x >= 0 && x < 4;
            x += (dx > 0 ? -1 : 1)) {
          int ny = y + dy, nx = x + dx;
          if (b[y][x] == 0) continue;
          while (nx >= 0 && nx < 4 && ny >= 0 && ny < 4 && b[ny][nx] == 0) {
            b[ny][nx] = b[ny - dy][nx - dx];
            b[ny - dy][nx - dx] = 0;
            nx += dx;
            ny += dy;
            moved = true;
          }
          if (nx >= 0 &&
              nx < 4 &&
              ny >= 0 &&
              ny < 4 &&
              b[ny][nx] == b[ny - dy][nx - dx]) {
            b[ny][nx] *= 2;
            b[ny - dy][nx - dx] = 0;
            moved = true;
          }
        }
      }
    }
    if (moved) {
      _spawn();
      _saveBest();
      setState(() {});
    }
  }

  Color _tileColor(int v) {
    switch (v) {
      case 0:
        return Colors.grey[300]!;
      case 2:
        return Colors.indigo[100]!;
      case 4:
        return Colors.indigo[200]!;
      case 8:
        return Colors.indigo[300]!;
      case 16:
        return Colors.indigo[400]!;
      case 32:
        return Colors.deepPurple[300]!;
      case 64:
        return Colors.deepPurple[400]!;
      default:
        return Colors.orange[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('最大タイル: $best'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: List.generate(
                4,
                (y) => Row(
                      children: List.generate(
                          4,
                          (x) => Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _tileColor(b[y][x]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      b[y][x] == 0 ? '' : b[y][x].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                  ),
                                ),
                              )),
                    )),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => _move(0, -1),
                child: const Icon(Icons.keyboard_arrow_up)),
            ElevatedButton(
                onPressed: () => _move(-1, 0),
                child: const Icon(Icons.keyboard_arrow_left)),
            ElevatedButton(
                onPressed: () => _move(1, 0),
                child: const Icon(Icons.keyboard_arrow_right)),
            ElevatedButton(
                onPressed: () => _move(0, 1),
                child: const Icon(Icons.keyboard_arrow_down)),
            OutlinedButton(onPressed: _reset, child: const Text('リセット')),
          ],
        ),
      ],
    );
  }
}

// ショップモーダル
class _ShopModal extends StatelessWidget {
  final int coins;
  final List<String> ownedItems;
  final String? equippedItem;
  final Function(String itemId, int price) onBuyItem;
  final Function(String itemId) onEquipItem;

  const _ShopModal({
    required this.coins,
    required this.ownedItems,
    required this.equippedItem,
    required this.onBuyItem,
    required this.onEquipItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'id': 'hat',
        'emoji': '🎩',
        'name': '帽子',
        'price': 50,
        'buff': 'EXP+10%'
      },
      {
        'id': 'ribbon',
        'emoji': '🎀',
        'name': 'リボン',
        'price': 30,
        'buff': 'コイン+20%'
      },
      {
        'id': 'glasses',
        'emoji': '😎',
        'name': 'サングラス',
        'price': 40,
        'buff': 'EXP+5% コイン+10%'
      },
      {
        'id': 'balloon',
        'emoji': '🎈',
        'name': '風船',
        'price': 20,
        'buff': '減衰50%軽減'
      },
      {
        'id': 'crown',
        'emoji': '👑',
        'name': '王冠',
        'price': 100,
        'buff': 'EXP+15% コイン+25% 減衰30%軽減'
      },
      // プレミアムアイテム
      {
        'id': 'diamond',
        'emoji': '💎',
        'name': 'ダイヤモンド',
        'price': 200,
        'buff': 'EXP+25% コイン+35%'
      },
      {
        'id': 'star',
        'emoji': '⭐',
        'name': '星のペンダント',
        'price': 250,
        'buff': 'EXP+30% 減衰60%軽減'
      },
      {
        'id': 'rainbow',
        'emoji': '🌈',
        'name': '虹の羽',
        'price': 300,
        'buff': 'コイン+50% 減衰40%軽減'
      },
      {
        'id': 'galaxy',
        'emoji': '🌌',
        'name': '銀河のマント',
        'price': 400,
        'buff': 'EXP+40% コイン+40%'
      },
      {
        'id': 'ultimate',
        'emoji': '✨',
        'name': '究極の首輪',
        'price': 500,
        'buff': 'EXP+50% コイン+60% 減衰70%軽減'
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🛍️ ショップ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('💰 $coins', style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('アイテムを購入して装備しよう！',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: items.map((item) {
                final itemId = item['id'] as String;
                final emoji = item['emoji'] as String;
                final name = item['name'] as String;
                final price = item['price'] as int;
                final buff = item['buff'] as String;
                final owned = ownedItems.contains(itemId);
                final equipped = equippedItem == itemId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(emoji, style: const TextStyle(fontSize: 32)),
                    title: Text(name),
                    subtitle: Text(owned
                        ? (equipped ? '装備中 - $buff' : '所有済み - $buff')
                        : '💰 $price - $buff'),
                    trailing: owned
                        ? (equipped
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : ElevatedButton(
                                onPressed: () => onEquipItem(itemId),
                                child: const Text('装備'),
                              ))
                        : ElevatedButton(
                            onPressed: coins >= price
                                ? () => onBuyItem(itemId, price)
                                : null,
                            child: const Text('購入'),
                          ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// 数当てゲーム（1-100の数字を推測）
class _NumberGuessGame extends StatefulWidget {
  const _NumberGuessGame({super.key});

  @override
  State<_NumberGuessGame> createState() => _NumberGuessGameState();
}

class _NumberGuessGameState extends State<_NumberGuessGame> {
  int _targetNumber = 0;
  int _attempts = 0;
  int _bestScore = 999;
  List<String> _history = [];
  final TextEditingController _guessController = TextEditingController();
  String _feedback = '';
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _startNewGame();
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('guess_game_best') ?? 999;
    });
  }

  Future<void> _saveBestScore() async {
    if (_attempts < _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('guess_game_best', _attempts);
      setState(() => _bestScore = _attempts);
    }
  }

  void _startNewGame() {
    setState(() {
      _targetNumber = Random().nextInt(100) + 1;
      _attempts = 0;
      _history.clear();
      _feedback = '1〜100の数字を当ててください！';
      _gameOver = false;
    });
    _guessController.clear();
  }

  void _makeGuess() {
    final input = _guessController.text.trim();
    if (input.isEmpty) return;

    final guess = int.tryParse(input);
    if (guess == null || guess < 1 || guess > 100) {
      setState(() => _feedback = '⚠️ 1〜100の数字を入力してください');
      return;
    }

    setState(() {
      _attempts++;
      if (guess == _targetNumber) {
        _feedback = '🎉 正解！ $_attempts 回で当たりました！';
        _gameOver = true;
        _history.add('$guess → 🎯 正解！');
        _saveBestScore();

        // スコアに応じた演出レベル決定（回数が少ないほど高評価）
        GameResultLevel level;
        String? message;
        if (_attempts <= 3) {
          level = GameResultLevel.perfect;
          message = '神の勘！';
        } else if (_attempts <= 5) {
          level = GameResultLevel.excellent;
          message = '素晴らしい！';
        } else if (_attempts <= 8) {
          level = GameResultLevel.good;
          message = '良い推理！';
        } else {
          level = GameResultLevel.normal;
          message = null;
        }

        // 派手な演出で結果表示
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            AchievementNotifier.showGameResult(
              context,
              gameName: '数当てゲーム',
              score: _attempts,
              bestScore: _bestScore < 999 ? _bestScore : null,
              message: message,
              level: level,
            );
          }
        });
      } else if (guess < _targetNumber) {
        final diff = _targetNumber - guess;
        if (diff <= 5) {
          _feedback = '🔥 もう少し大きい数字です（かなり近い！）';
        } else if (diff <= 15) {
          _feedback = '📈 もっと大きい数字です（近い）';
        } else {
          _feedback = '⬆️ もっと大きい数字です';
        }
        _history.add('$guess → 小さい');
      } else {
        final diff = guess - _targetNumber;
        if (diff <= 5) {
          _feedback = '🔥 もう少し小さい数字です（かなり近い！）';
        } else if (diff <= 15) {
          _feedback = '📉 もっと小さい数字です（近い）';
        } else {
          _feedback = '⬇️ もっと小さい数字です';
        }
        _history.add('$guess → 大きい');
      }
    });

    _guessController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎲 数当てゲーム',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '試行回数: $_attempts 回',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (_bestScore < 999)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🏆 ベスト',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '$_bestScore 回',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // フィードバック
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _gameOver
                    ? Colors.green.shade50
                    : (isDark ? Colors.grey[800] : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gameOver
                      ? Colors.green.shade200
                      : (isDark ? Colors.grey[700]! : Colors.blue.shade200),
                  width: 2,
                ),
              ),
              child: Text(
                _feedback,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _gameOver
                      ? Colors.green.shade700
                      : (isDark ? Colors.blue[300] : Colors.blue.shade700),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // 入力エリア
            if (!_gameOver) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _guessController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '予想を入力',
                        hintText: '1〜100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.casino),
                      ),
                      onSubmitted: (_) => _makeGuess(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _makeGuess,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '予想',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // リセット/新しいゲーム
            if (_gameOver)
              ElevatedButton.icon(
                onPressed: _startNewGame,
                icon: const Icon(Icons.refresh),
                label: const Text('新しいゲーム'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('ゲームをリセット'),
                      content: const Text('現在のゲームをリセットして新しく始めますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _startNewGame();
                          },
                          child: const Text('リセット'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('リセット'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            const SizedBox(height: 24),

            // 履歴
            if (_history.isNotEmpty) ...[
              const Text(
                '📝 履歴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        '${index + 1}. ${_history[index]}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
