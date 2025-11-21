import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/achievements_service.dart';
import '../services/news_api_service.dart';
import '../models/article.dart';
import '../models/achievement.dart';
import '../widgets/achievement_animation.dart';

/// ミニゲーム画面�E�暇つぶし用�E�E
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
              'ニュース征E��の暁E��ぶしに',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // ゲーム選択タブ（横スクロール�E�E
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
                      label: '神経衰弱(国旁E',
                      icon: Icons.flag,
                      isSelected: _selectedGame == 0,
                      onTap: () => setState(() => _selectedGame = 0),
                    ),
                    _GameTab(
                      label: 'タチE�E',
                      icon: Icons.touch_app,
                      isSelected: _selectedGame == 1,
                      onTap: () => setState(() => _selectedGame = 1),
                    ),
                    _GameTab(
                      label: '育戁E,
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
                      label: 'スネ�Eク',
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

            // ゲームコンチE��チE
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
  int _mismatches = 0; // めくり戻し回数�E�ノーミス判定用�E�E
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
    final rng = math.Random();
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
          // AchievementService.addGamePlayTime(elapsed);
        }

        _saveBestScore(_moves);
        // 記�E王！E2手以冁E��E
        if (_moves <= 12) {
          // AchievementService.unlockMemoryMaster();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🧠 実績「記�E王」を解除しました�E�E),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        // ノ�Eミス�E�めくり戻ぁE�E�E
        if (_mismatches == 0) {
          // AchievementService.unlockMemoryPerfect();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ 実績「完璧主義老E��を解除しました�E�E),
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
                title: const Text('🎉 クリア�E�E),
                content: Text('$_moves手でクリアしました�E�\nベスチE $_bestScore扁E),
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
      // ミスマッチ時にカウンチE
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
            Text('ベスチE ${_bestScore == 999 ? "-" : _bestScore}扁E,
                style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),

        // カードグリチE��
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

        // リセチE��ボタン
        ElevatedButton.icon(
          onPressed: () => setState(() => _initGame()),
          icon: const Icon(Icons.refresh),
          label: const Text('リセチE��'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.indigo[700] : Colors.indigo[400],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// タチE�Eチャレンジゲーム�E�高速タチE�E�E�E
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
      // AchievementService.addGamePlayTime(elapsed);
    }

    setState(() {
      _isPlaying = false;
    });
    _saveBestScore(_tapCount);

    // 高速タチE��ー実績チェチE���E�E0秒で50回以丁E/ 80回以上！E
    if (_tapCount >= 50) {
      // AchievementService.unlockFastTapper();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ 実績「ゴチE��ハンド」を解除しました�E�E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    if (_tapCount >= 80) {
      // AchievementService.unlockFastTapGod();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👑 実績「早撁E��神」を解除しました�E�E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // スコアに応じた演�Eレベル決宁E
    GameResultLevel level;
    String? message;
    if (_tapCount >= 100) {
      level = GameResultLevel.perfect;
      message = '神�E領域�E�E;
    } else if (_tapCount >= 80) {
      level = GameResultLevel.excellent;
      message = 'すごぁE��E;
    } else if (_tapCount >= 60) {
      level = GameResultLevel.good;
      message = '良ぁE��子！E;
    } else {
      level = GameResultLevel.normal;
      message = null;
    }

    // 派手な演�Eで結果表示
    if (mounted) {
      AchievementNotifier.showGameResult(
        context,
        gameName: 'タチE�Eチャレンジ',
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
        // 連続タチE�E判定！E00ms以冁E��E
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
          'ルール: 10秒間でできるだけ多くタチE�E�E�E,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // タイマ�E�E�E��コア表示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text('残り時間', style: theme.textTheme.bodySmall),
                Text(
                  '$_timeLeft私E,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: _isPlaying ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text('タチE�E数', style: theme.textTheme.bodySmall),
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

        // タチE�Eエリア
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
                    _isPlaying ? 'タチE�E�E�E : 'スタートを押してください',
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

        // スタート�Eタン�E�E�Eストスコア
        Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isPlaying ? null : _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('スターチE),
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
              'ベストスコア: $_bestScore囁E,
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

// 簡易�EチE��育成ゲーム
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
  int _evolutionStage = 0; // 進化段隁E 0=卵, 1=ひな, 2=子侁E 3=成佁E
  int _coins = 0; // コイン
  List<String> _ownedItems = []; // 所有アイチE��
  String? _equippedItem; // 裁E��中アイチE��
  int _actionCount = 0; // アクション回数
  bool _loading = true;
  Timer? _decayTimer;
  DateTime? _sessionStartTime; // セチE��ョン開始時刻
  String _lastAction = ''; // 最後�Eアクション
  int _consecutiveCount = 0; // 連続同一アクションカウンチE

  // クールダウンタイマ�E
  DateTime? _lastFeedTime;
  DateTime? _lastPlayTime;
  DateTime? _lastRestTime;
  static const _cooldownSeconds = 10; // 吁E��クションのクールダウン時間

  // チE��リーログインボ�Eナス
  int _loginStreak = 0; // 連続ログイン日数
  DateTime? _lastLoginDate; // 最後�Eログイン日

  // 親寁E��シスチE��
  int _affection = 0; // 親寁E�� (0-1000)

  // チE��リーミッション
  int _dailyFeedCount = 0;
  int _dailyPlayCount = 0;
  int _dailyEventCount = 0;
  DateTime? _lastMissionResetDate;

  // ペットインタラクション
  String _petReaction = ''; // ペット�E反応メチE��ージ
  Timer? _reactionTimer; // 反応メチE��ージを消すタイマ�E
  int _petTapCount = 0; // ペットタチE�E回数

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
    // セチE��ョン終亁E��にプレイ時間記録
    if (_sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      // AchievementService.addGamePlayTime(elapsed);
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

      // 最後�Eログイン日をチェチE��
      final lastLoginStr = prefs.getString('pet_last_login_date');
      if (lastLoginStr != null) {
        _lastLoginDate = DateTime.parse(lastLoginStr);
      }

      // 最後�EミッションリセチE��日をチェチE��
      final lastMissionResetStr =
          prefs.getString('pet_last_mission_reset_date');
      if (lastMissionResetStr != null) {
        _lastMissionResetDate = DateTime.parse(lastMissionResetStr);
      }

      _loading = false;
    });

    // チE��リーミッションリセチE��チェチE��
    _checkDailyMissionReset();

    // ログインボ�EナスチェチE��
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
        // ストリーク途�EめE
        setState(() {
          _loginStreak = 1;
          _lastLoginDate = today;
        });
        _showDailyLoginBonus(1, isNewStreak: true);
        _saveState();
      }
      // daysDiff == 0 なら今日既にログイン済み�E�何もしなぁE��E
    }
  }

  void _showDailyLoginBonus(int streak, {required bool isNewStreak}) {
    // ボ�Eナス計算（最大7日間�E累積�Eーナス�E�E
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
        title: Text(isNewStreak ? '🎁 チE��リーログイン�E�E : '🔥 連続ログイン $streak日目�E�E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNewStreak ? 'ログインボ�EナスをゲチE���E�E : '連続ログイン中�E��EーナスアチE�E�E�E,
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
                  '明日も来るとボ�Eナスが増えるよ�E�\n�E�最大7日間！E,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('めE��た！E),
          ),
        ],
      ),
    );
  }

  void _checkDailyMissionReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastMissionResetDate == null) {
      // 初回起勁E
      setState(() {
        _lastMissionResetDate = today;
      });
      _saveState();
    } else {
      final lastReset = DateTime(_lastMissionResetDate!.year,
          _lastMissionResetDate!.month, _lastMissionResetDate!.day);
      final daysDiff = today.difference(lastReset).inDays;

      if (daysDiff >= 1) {
        // 日付が変わった�EでミッションリセチE��
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
    // ミッション達�EチェチE��
    final missions = [
      {'type': 'feed', 'goal': 5, 'current': _dailyFeedCount, 'reward': 30},
      {'type': 'play', 'goal': 5, 'current': _dailyPlayCount, 'reward': 40},
      {'type': 'event', 'goal': 3, 'current': _dailyEventCount, 'reward': 50},
    ];

    for (var mission in missions) {
      if (mission['current'] == mission['goal']) {
        // ミッション達�E�E�E
        final reward = mission['reward'] as int;
        setState(() {
          _coins += reward;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 チE��リーミッション達�E�E�E+${reward}コイン'),
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
        title: const Text('📖 ゲームの遊�E方'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 目樁E,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ペットを育てて、レベル100・親寁E��1000を目持E��ぁE��E,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎮 基本操佁E,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• ご�Eん：�E氁E15/幸禁E3/EXP+8/コイン+2\n'
                '• あそぶ�E�幸禁E10/允E��E10/EXP+12/コイン+3\n'
                '• めE��む�E��E氁E25/幸禁E2/コイン+1\n'
                '※吁E��クションは10秒�Eクールダウンあり',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🐾 ペットとの触れ合ぁE,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ペットをタチE�Eすると反応します！\n'
                '• タチE�Eごとに幸禁E1、親寁E��+1\n'
                '• 10タチE�Eごとに5コインボ�Eナス',
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
                'レア度シスチE���E�E段階）：\n'
                '⚪ コモン (50%): 小報酬\n'
                '🔵 レア (25%): 中報酬\n'
                '🟣 スーパ�Eレア (15%): 大報酬\n'
                '🟠 ウルトラレア (7%): 趁E��酬\n'
                '🟡 レジェンチE(3%): 究極報酬\n\n'
                '報酬冁E��30種類以上！\n'
                'コイン/経験値/幸禁E允E��E親寁E��',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🛍�E�EショチE�E',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'コインでアイチE��を購入・裁E��\n'
                '• EXP獲得量アチE�E\n'
                '• コイン獲得量アチE�E\n'
                '• 幸禁E允E���E減衰を軽渁E,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎯 チE��リーミッション',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '毎日リセチE��・達�Eでコイン獲得\n'
                '• ご�EめE囁E 30コイン\n'
                '• あそぶ5囁E 40コイン\n'
                '• イベンチE囁E 50コイン',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎁 ログインボ�Eナス',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '毎日ログインでボ�Eナス獲得\n'
                '連続ログインで最大7日目まで報酬アチE�E�E�E,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠�E�E注意事頁E,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 10秒ごとに幸福と允E��が減少\n'
                '• 幸禁E允E��が0になると成長が遅くなる\n'
                '• レベルが上がるほど忁E��経験値が増加\n'
                '• レベル20/50で進化イベント発甁E,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じめE),
          ),
        ],
      ),
    );
  }

  void _onPetTap() {
    _petTapCount++;

    // タチE�E回数に応じた反忁E
    final reactions = [
      '�E なでなで...',
      '💕 ぁE��しい�E�E,
      '✨ きゃっ',
      '🎵 た�Eしい�E�E,
      '💖 もっと�E�E,
      '🌟 えへへ',
      '🎀 くすぐったい',
      '💫 めE��たぁ�E�E,
    ];

    // ランダムな反応を表示
    setState(() {
      _petReaction = reactions[math.Random().nextInt(reactions.length)];
      // 小さな幸福度上�E
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

    // 10回タチE�Eで小さなボ�Eナス
    if (_petTapCount % 10 == 0) {
      setState(() {
        _coins += 5;
        _petReaction = '🎁 +5コイン�E�E;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💖 ペットが喜んでる！E+5コイン'),
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
    // レベル51以陁E 大幁E��忁E��経験値増加
    if (_level <= 50) {
      return _expPerLevelBase + (_level - 1) * 30;
    } else {
      // レベル50以降�E基本値の2倁E+ より急な増加
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
    if (_level >= 5) // AchievementService.unlockPetLevel5();
    if (_level >= 10) // AchievementService.unlockPetLevel10();
  }

  void _checkEvolution(int oldLevel) {
    int newStage = _evolutionStage;

    // 進化条件チェチE��
    if (_level >= 15 && _evolutionStage < 3) {
      newStage = 3; // 成佁E
    } else if (_level >= 10 && _evolutionStage < 2) {
      newStage = 2; // 子侁E
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
    final stageNames = ['卵', 'ひな', '子侁E, '成佁E];

    // レベルに応じた演�Eレベル
    GameResultLevel level;
    String message;
    if (stage == 3) {
      level = GameResultLevel.perfect;
      message = '立派な成体に成長�E�E;
    } else if (stage == 2) {
      level = GameResultLevel.excellent;
      message = '允E��いっぱぁE�E子供に�E�E;
    } else {
      level = GameResultLevel.good;
      message = '可愛いひなになったよ�E�E;
    }

    // 画像パス
    final imagePath = 'assets/images/pet_stage_$stage.png';

    // 派手な演�Eで表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EvolutionAnimation(
        stage: stage,
        stageName: stageNames[stage],
        imagePath: imagePath,
        message: message,
        level: level,
        onComplete: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 実績、E{stageNames[stage]}進化」を解除しました�E�E),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _doFeed() {
    if (_energy >= 95) return;

    // クールダウンチェチE��
    if (_lastFeedTime != null) {
      final elapsed = DateTime.now().difference(_lastFeedTime!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ あと${_cooldownSeconds - elapsed}秒征E��てね'),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    // 連続アクションチェチE��
    if (_lastAction == 'feed') {
      _consecutiveCount++;
      if (_consecutiveCount >= 3) {
        // AchievementService.unlockPetOverfeed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍔 実績「食べ過ぎ注意」を解除しました�E�E),
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
      _lastFeedTime = DateTime.now(); // クールダウン開姁E
      _affection = (_affection + 1).clamp(0, 1000); // 親寁E��+1
      _dailyFeedCount++; // ミッションカウンチE
    });
    _gainExp(expBonus);
    _checkRandomEvent();
    _checkDailyMissions();
  }

  void _doPlay() {
    if (_energy < 10) return;

    // クールダウンチェチE��
    if (_lastPlayTime != null) {
      final elapsed = DateTime.now().difference(_lastPlayTime!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ あと${_cooldownSeconds - elapsed}秒征E��てね'),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    // 連続アクションチェチE��
    if (_lastAction == 'play') {
      _consecutiveCount++;
      if (_consecutiveCount >= 5) {
        // AchievementService.unlockPetOverplay();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('😵 実績「体力の限界」を解除しました�E�E),
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
      _lastPlayTime = DateTime.now(); // クールダウン開姁E
      _affection = (_affection + 2).clamp(0, 1000); // 親寁E��+2
      _dailyPlayCount++; // ミッションカウンチE
    });
    if (_happiness >= 100) {
      // AchievementService.unlockPetHappy100();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐾 実績「ごきげんMAX」を解除�E�E),
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

    // クールダウンチェチE��
    if (_lastRestTime != null) {
      final elapsed = DateTime.now().difference(_lastRestTime!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ あと${_cooldownSeconds - elapsed}秒征E��てね'),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    }
    // 休�Eは連続カウントをリセチE��
    _lastAction = 'rest';
    _consecutiveCount = 0;

    final buff = _getItemBuff(_equippedItem);
    final coinBonus = (1 * (buff['coins'] as double)).round();

    setState(() {
      _energy = (_energy + 25).clamp(0, 100);
      _happiness = (_happiness - 2).clamp(0, 100);
      _coins += coinBonus;
      _lastRestTime = DateTime.now(); // クールダウン開姁E
    });
    _saveState();
  }

  String _petEmoji() {
    // 進化段階に応じた絵斁E��E
    final stageEmojis = [
      '🥁E, // 卵 (Lv1-4)
      '🐣', // ひな (Lv5-9)
      '🐥', // 子侁E(Lv10-14)
      '🐓', // 成佁E(Lv15+)
    ];

    // 幸福度に基づく表惁E��リエーション�E��Eな以降！E
    if (_evolutionStage == 0) {
      return stageEmojis[0]; // 卵は変化なぁE
    } else if (_evolutionStage == 1) {
      if (_happiness >= 80) return '�E�';
      if (_happiness >= 50) return '�E�';
      return '🐥';
    } else if (_evolutionStage == 2) {
      if (_happiness >= 80) return '🐥';
      if (_happiness >= 50) return '�E�';
      return '�E�';
    } else {
      if (_happiness >= 80) return '🐓';
      if (_happiness >= 50) return '🦁E;
      return '🦁E;
    }
  }

  String _getItemEmoji(String itemId) {
    const items = {
      'hat': '🎩',
      'ribbon': '🎀',
      'glasses': '�E',
      'balloon': '🎈',
      'crown': '👑',
      'diamond': '💎',
      'star': '⭁E,
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
      'balloon': {'exp': 1.0, 'coins': 1.0, 'decay': 0.5}, // 減衰半渁E
      'crown': {
        'exp': 1.15,
        'coins': 1.25,
        'decay': 0.7
      }, // EXP+15% コイン+25% 減衰30%軽渁E
      // プレミアムアイチE��
      'diamond': {'exp': 1.25, 'coins': 1.35, 'decay': 1.0}, // EXP+25% コイン+35%
      'star': {'exp': 1.3, 'coins': 1.0, 'decay': 0.4}, // EXP+30% 減衰60%軽渁E
      'rainbow': {'exp': 1.0, 'coins': 1.5, 'decay': 0.6}, // コイン+50% 減衰40%軽渁E
      'galaxy': {'exp': 1.4, 'coins': 1.4, 'decay': 1.0}, // EXP+40% コイン+40%
      'ultimate': {
        'exp': 1.5,
        'coins': 1.6,
        'decay': 0.3
      }, // EXP+50% コイン+60% 減衰70%軽渁E
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
              SnackBar(content: Text('${_getItemEmoji(itemId)} アイチE��を購入しました�E�E)),
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
          content: Text('💰 コインが足りません�E�E��E0コイン忁E��E��E),
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

    // レア度判定（確玁E��E
    final random = math.Random().nextDouble();
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
      // 15% - スーパ�Eレア (Super Rare)
      rarity = 'スーパ�Eレア';
      rarityColor = Colors.purple;
      rarityEmoji = '🟣';
    } else if (random < 0.97) {
      // 7% - ウルトラレア (Ultra Rare)
      rarity = 'ウルトラレア';
      rarityColor = Colors.orange;
      rarityEmoji = '🟠';
    } else {
      // 3% - レジェンチE(Legend)
      rarity = 'レジェンチE;
      rarityColor = Colors.amber;
      rarityEmoji = '🟡';
    }

    // レア度別の報酬チE�Eブル
    final rewardRandom = math.Random().nextInt(100);
    String result;
    String rewardEmoji;
    int coinReward = 0;
    int expReward = 0;
    int happinessReward = 0;
    int energyReward = 0;
    int affectionReward = 0;

    if (rarity == 'コモン') {
      // コモン報酬�E�E0種類！E
      if (rewardRandom < 25) {
        coinReward = math.Random().nextInt(21) + 10; // 10-30コイン
        rewardEmoji = '💰';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 50) {
        expReward = math.Random().nextInt(21) + 20; // 20-40経験値
        rewardEmoji = '✨';
        result = '$expReward経験値';
      } else if (rewardRandom < 65) {
        happinessReward = math.Random().nextInt(6) + 5; // 5-10幸禁E
        rewardEmoji = '💕';
        result = '幸禁E$happinessReward';
      } else if (rewardRandom < 80) {
        energyReward = math.Random().nextInt(6) + 5; // 5-10允E��E
        rewardEmoji = '⚡';
        result = '允E��E$energyReward';
      } else {
        affectionReward = math.Random().nextInt(6) + 5; // 5-10親寁E��
        rewardEmoji = '💖';
        result = '親寁E��+$affectionReward';
      }
    } else if (rarity == 'レア') {
      // レア報酬�E�E種類！E
      if (rewardRandom < 20) {
        coinReward = math.Random().nextInt(31) + 40; // 40-70コイン
        rewardEmoji = '💰';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 40) {
        expReward = math.Random().nextInt(41) + 50; // 50-90経験値
        rewardEmoji = '✨';
        result = '$expReward経験値';
      } else if (rewardRandom < 55) {
        coinReward = math.Random().nextInt(16) + 20; // 20-35コイン
        expReward = math.Random().nextInt(21) + 30; // 30-50経験値
        rewardEmoji = '🎁';
        result = '$coinRewardコイン + $expReward経験値';
      } else if (rewardRandom < 70) {
        happinessReward = math.Random().nextInt(11) + 15; // 15-25幸禁E
        rewardEmoji = '💕';
        result = '幸禁E$happinessReward';
      } else if (rewardRandom < 85) {
        energyReward = math.Random().nextInt(11) + 15; // 15-25允E��E
        rewardEmoji = '⚡';
        result = '允E��E$energyReward';
      } else {
        affectionReward = math.Random().nextInt(16) + 15; // 15-30親寁E��
        rewardEmoji = '💖';
        result = '親寁E��+$affectionReward';
      }
    } else if (rarity == 'スーパ�Eレア') {
      // スーパ�Eレア報酬�E�E種類！E
      if (rewardRandom < 20) {
        coinReward = math.Random().nextInt(51) + 80; // 80-130コイン
        rewardEmoji = '💰';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 40) {
        expReward = math.Random().nextInt(61) + 100; // 100-160経験値
        rewardEmoji = '✨';
        result = '$expReward経験値';
      } else if (rewardRandom < 60) {
        coinReward = math.Random().nextInt(31) + 50; // 50-80コイン
        expReward = math.Random().nextInt(51) + 60; // 60-110経験値
        rewardEmoji = '🎁';
        result = '$coinRewardコイン + $expReward経験値';
      } else if (rewardRandom < 75) {
        happinessReward = math.Random().nextInt(16) + 30; // 30-45幸禁E
        energyReward = math.Random().nextInt(16) + 30; // 30-45允E��E
        rewardEmoji = '💫';
        result = '幸禁E$happinessReward 允E��E$energyReward';
      } else {
        affectionReward = math.Random().nextInt(31) + 40; // 40-70親寁E��
        coinReward = math.Random().nextInt(21) + 30; // 30-50コイン
        rewardEmoji = '💝';
        result = '親寁E��+$affectionReward コイン+$coinReward';
      }
    } else if (rarity == 'ウルトラレア') {
      // ウルトラレア報酬�E�E種類！E
      if (rewardRandom < 25) {
        coinReward = math.Random().nextInt(101) + 150; // 150-250コイン
        rewardEmoji = '💎';
        result = '$coinRewardコイン';
      } else if (rewardRandom < 50) {
        expReward = math.Random().nextInt(101) + 200; // 200-300経験値
        rewardEmoji = '🌟';
        result = '$expReward経験値';
      } else if (rewardRandom < 70) {
        coinReward = math.Random().nextInt(81) + 100; // 100-180コイン
        expReward = math.Random().nextInt(101) + 120; // 120-220経験値
        rewardEmoji = '🎊';
        result = '$coinRewardコイン + $expReward経験値';
      } else if (rewardRandom < 85) {
        happinessReward = 50;
        energyReward = 50;
        affectionReward = math.Random().nextInt(51) + 50; // 50-100親寁E��
        rewardEmoji = '🌈';
        result = '幸福MAX 允E��MAX 親寁E��+$affectionReward';
      } else {
        // 全スチE�Eタス大幁E��チE�E
        coinReward = math.Random().nextInt(51) + 80; // 80-130コイン
        expReward = math.Random().nextInt(81) + 100; // 100-180経験値
        happinessReward = math.Random().nextInt(21) + 30; // 30-50幸禁E
        energyReward = math.Random().nextInt(21) + 30; // 30-50允E��E
        affectionReward = math.Random().nextInt(31) + 40; // 40-70親寁E��
        rewardEmoji = '🎇';
        result = '全スチE�EタスUP�E�E;
      }
    } else {
      // レジェンド報酬�E�E種類）趁E��華
      if (rewardRandom < 30) {
        coinReward = math.Random().nextInt(201) + 300; // 300-500コイン
        rewardEmoji = '👑';
        result = '$coinRewardコイン�E�趁E��量！E;
      } else if (rewardRandom < 60) {
        expReward = math.Random().nextInt(301) + 400; // 400-700経験値
        rewardEmoji = '⭁E;
        result = '$expReward経験値�E�趁E��量！E;
      } else if (rewardRandom < 85) {
        coinReward = math.Random().nextInt(151) + 200; // 200-350コイン
        expReward = math.Random().nextInt(201) + 300; // 300-500経験値
        affectionReward = math.Random().nextInt(101) + 100; // 100-200親寁E��
        rewardEmoji = '🏆';
        result = '趁E��華セチE���E�E;
      } else {
        // 究極報酬�E��EてMAX
        coinReward = math.Random().nextInt(101) + 250; // 250-350コイン
        expReward = math.Random().nextInt(151) + 350; // 350-500経験値
        happinessReward = 100;
        energyReward = 100;
        affectionReward = math.Random().nextInt(151) + 150; // 150-300親寁E��
        rewardEmoji = '✨';
        result = '🎉究極の大当たり🎉\n全能力MAX�E�趁E�Eーナス�E�E;
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

    // 結果表示�E�レア度に応じた演�E�E�E
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
                        child: const Text('もう1回！E),
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
    // 20-30アクションごとにランダムイベント発生（確玁E0%に上�E�E�E
    if (_actionCount >= 20 && math.Random().nextDouble() < 0.30) {
      _actionCount = 0;
      _dailyEventCount++; // イベントミチE��ョンカウンチE
      _showRandomEvent();
      _checkDailyMissions(); // イベント後にミッションチェチE��
    }
  }

  void _showRandomEvent() {
    final events = [
      {
        'title': '🎁 宝箱発見！E,
        'description': 'キラキラ光る宝箱を見つけました�E�E,
        'choices': [
          {'text': '開けめE, 'coins': 30, 'happiness': 5, 'energy': 0},
          {'text': '無視すめE, 'coins': 0, 'happiness': -5, 'energy': 5},
        ],
      },
      {
        'title': '👤 訪問老E,
        'description': '誰かが遊�Eに来ました�E�E,
        'choices': [
          {'text': '歓迎すめE, 'coins': 10, 'happiness': 15, 'energy': -5},
          {'text': '断めE, 'coins': 5, 'happiness': -10, 'energy': 10},
        ],
      },
      {
        'title': '🎪 お祭めE,
        'description': '近くでお祭りが開催中�E�E,
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
        'title': '⭁E流れ昁E,
        'description': '流れ星が通り過ぎました�E�E,
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
        'title': '🌈 虹が�Eた！E,
        'description': '美しぁE��が空にかかってぁE��す！E,
        'choices': [
          {'text': '写真を撮めE, 'coins': 15, 'happiness': 12, 'energy': -3},
          {'text': 'のん�Eり眺める', 'coins': 0, 'happiness': 8, 'energy': 5},
        ],
      },
      {
        'title': '💎 レアアイチE��発見！E,
        'description': '地面にキラキラ光る石が！E,
        'choices': [
          {'text': '拾ぁE, 'coins': 50, 'happiness': 8, 'energy': 0},
          {'text': '誰かに譲めE, 'coins': 20, 'happiness': 15, 'energy': 0},
        ],
      },
      {
        'title': '🍀 幸運�E四つ葁E,
        'description': '珍しぁE��つ葉�Eクローバ�Eを見つけた�E�E,
        'choices': [
          {
            'text': '大刁E��する',
            'coins': 10,
            'happiness': 20,
            'energy': 0,
            'exp': 25
          },
          {'text': '押し花にする', 'coins': 25, 'happiness': 10, 'energy': 0},
        ],
      },
      {
        'title': '🎵 路上ライチE,
        'description': '素敵な音楽が聞こえてきます！E,
        'choices': [
          {
            'text': '聴き�EめE,
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
          {'text': '通り過ぎめE, 'coins': 0, 'happiness': 0, 'energy': 0},
        ],
      },
      {
        'title': '🦁E珍しぁE��、E,
        'description': 'めったに見られなぁE��しぁE��が飛んでぁE���E�E,
        'choices': [
          {
            'text': '追ぁE��ける',
            'coins': 0,
            'happiness': 15,
            'energy': -8,
            'exp': 35
          },
          {'text': '観察すめE, 'coins': 5, 'happiness': 10, 'energy': 0, 'exp': 20},
        ],
      },
    ];

    // 趁E��アイベント！E%の確玁E��E
    if (math.Random().nextDouble() < 0.05) {
      final rareEvents = [
        {
          'title': '🌟 奁E��の出会い�E�E,
          'description': '伝説の生き物に出会った！E��E,
          'choices': [
            {
              'text': '友達になめE,
              'coins': 100,
              'happiness': 30,
              'energy': 10,
              'exp': 100
            },
            {
              'text': '写真だけ撮めE,
              'coins': 50,
              'happiness': 20,
              'energy': 0,
              'exp': 50
            },
          ],
        },
        {
          'title': '💰 大当たり！E,
          'description': 'コイン袋を拾った！E��E,
          'choices': [
            {'text': '全部もらぁE, 'coins': 200, 'happiness': 15, 'energy': 0},
            {
              'text': '半�E寁E��E,
              'coins': 100,
              'happiness': 25,
              'energy': 0,
              'exp': 50
            },
          ],
        },
      ];
      final event = rareEvents[math.Random().nextInt(rareEvents.length)];
      _showEventDialog(event);
      return;
    }

    final event = events[math.Random().nextInt(events.length)];
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

    String message = 'イベント完亁E��E;
    if ((effect['coins'] ?? 0) > 0) message += ' +${effect['coins']}コイン';
    if ((effect['happiness'] ?? 0) > 0) message += ' +${effect['happiness']}幸禁E;
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
                Text('最髁E $_bestLevel', style: theme.textTheme.bodySmall),
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
                  // 進化段階に応じた画像（存在しなぁE��合�E絵斁E��にフォールバック�E�E
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
          'タチE�Eして触れ合おう�E�E,
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
                      parts.add('EXP ${expBonus.toInt()}%ↁE);
                    }
                    if (buff['coins'] != 1.0) {
                      final coinBonus = ((buff['coins'] as double) - 1) * 100;
                      parts.add('コイン ${coinBonus.toInt()}%ↁE);
                    }
                    if (buff['decay'] != 1.0) {
                      final decayReduction =
                          (1 - (buff['decay'] as double)) * 100;
                      parts.add('減衰 ${decayReduction.toInt()}%ↁE);
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
            _statChip('幸禁E, _happiness, Colors.pink),
            _statChip('允E��E, _energy, Colors.amber),
            _statChip('EXP', ((_exp / _expNeededForNext()) * 100).toInt(),
                Colors.teal),
          ],
        ),
        const SizedBox(height: 12),
        // 親寁E��表示
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
                  const Text('💖 親寁E��',
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
        // チE��リーミッション表示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎯 チE��リーミッション',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _missionRow('ご�EめE5囁E, _dailyFeedCount, 5, '30コイン'),
              _missionRow('あそぶ 5囁E, _dailyPlayCount, 5, '40コイン'),
              _missionRow('イベンチE3囁E, _dailyEventCount, 3, '50コイン'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _actionButton(Icons.fastfood, 'ご�EめE, _doFeed,
                enabled: _energy < 95, lastActionTime: _lastFeedTime),
            _actionButton(Icons.toys, 'あそぶ', _doPlay,
                enabled: _energy >= 10, lastActionTime: _lastPlayTime),
            _actionButton(Icons.bedtime, 'めE��む', _doRest,
                enabled: _energy < 90, lastActionTime: _lastRestTime),
            _actionButton(Icons.shopping_bag, 'ショチE�E', _openShop, enabled: true),
            _actionButton(Icons.casino, 'ガチャ', _openGacha,
                enabled: true, buttonColor: Colors.amber),
            _actionButton(Icons.help_outline, 'ガイチE, _showGuide,
                enabled: true, buttonColor: Colors.blue),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '・ご�EめE 允E��E15/幸禁E3/exp+8/コイン+2\n・あそぶ: 幸禁E10/允E��E10/exp+12/コイン+3\n・めE��む: 允E��E25/幸禁E2/コイン+1\n一定時間で幸禁E允E���E減少します、Evが上がると忁E��EXPが増えます、E,
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
        cooldownText = '${_cooldownSeconds - elapsed}私E;
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

// ニュースクイズ�E�E択！E
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
    final rng = math.Random();
    final qs = <_QuizQ>[];
    for (final a in arts.take(5)) {
      // 常に国当てに統一�E�国旗クイズ�E�E
      final cc = _inferCountry('${a.title} ${a.description} ${a.url}');
      final all = ['US', 'GB', 'JP', 'FR', 'DE', 'CN', 'IN'];
      all.shuffle(rng);
      if (!all.contains(cc)) all[0] = cc;
      qs.add(_QuizQ(
        question: 'こ�E記事�E国旗�Eどれ！E,
        correct: cc,
        options: all.take(3).toList(),
        article: a,
      ));
    }
    return qs;
  }

  String _inferTopic(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'economy|inflation|market|bank|stock').hasMatch(t)) return '経渁E;
    if (RegExp(r'AI|tech|software|google|microsoft|apple|chip',
            caseSensitive: false)
        .hasMatch(text)) return 'チE��ノロジー';
    if (RegExp(r'football|soccer|nba|olympic|tennis|fifa').hasMatch(t))
      return 'スポ�EチE;
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

        // 新記録演�E
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
            title: Text(_score == _questions.length ? '🎉 満点�E�E : '結果'),
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
          return const Center(child: Text('問題を生�Eできませんでした'));
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
                        child: Text('ベスチE $_best',
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

// シンプル・スネ�Eク
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
      _apple = Offset(math.Random().nextInt(_cols).toDouble(),
          math.Random().nextInt(_rows).toDouble());
    });
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    if (_snake.length > _best) {
      final previousBest = _best;
      await p.setInt('snake_best', _snake.length);
      setState(() => _best = _snake.length);

      // 新記録演�E
      if (mounted && _snake.length >= 10) {
        AchievementNotifier.showHighScore(
          context,
          gameName: 'スネ�Eク',
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
        _apple = Offset(math.Random().nextInt(_cols).toDouble(),
            math.Random().nextInt(_rows).toDouble());
      } else {
        _snake.removeLast();
      }
    });
  }

  void _change(Offset d) {
    if ((_dir + d) == Offset.zero) return; // 送E��禁止
    setState(() => _dir = d);
  }

  @override
  Widget build(BuildContext context) {
    final cell = 14.0;
    return Column(
      children: [
        Text('長ぁE ${_snake.length}  ベスチE $_best'),
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

// 2048 ミニマム実裁E
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

      // 新記録演�E�E�E28以上で表示�E�E
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
    final o = empty[math.Random().nextInt(empty.length)];
    b[o.dy.toInt()][o.dx.toInt()] = math.Random().nextDouble() < 0.9 ? 2 : 4;
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
            OutlinedButton(onPressed: _reset, child: const Text('リセチE��')),
          ],
        ),
      ],
    );
  }
}

// ショチE�Eモーダル
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
        'name': '帽孁E,
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
        'emoji': '�E',
        'name': 'サングラス',
        'price': 40,
        'buff': 'EXP+5% コイン+10%'
      },
      {
        'id': 'balloon',
        'emoji': '🎈',
        'name': '風船',
        'price': 20,
        'buff': '減衰50%軽渁E
      },
      {
        'id': 'crown',
        'emoji': '👑',
        'name': '王�E',
        'price': 100,
        'buff': 'EXP+15% コイン+25% 減衰30%軽渁E
      },
      // プレミアムアイチE��
      {
        'id': 'diamond',
        'emoji': '💎',
        'name': 'ダイヤモンチE,
        'price': 200,
        'buff': 'EXP+25% コイン+35%'
      },
      {
        'id': 'star',
        'emoji': '⭁E,
        'name': '星�EペンダンチE,
        'price': 250,
        'buff': 'EXP+30% 減衰60%軽渁E
      },
      {
        'id': 'rainbow',
        'emoji': '🌈',
        'name': '虹の羽',
        'price': 300,
        'buff': 'コイン+50% 減衰40%軽渁E
      },
      {
        'id': 'galaxy',
        'emoji': '🌌',
        'name': '銀河のマンチE,
        'price': 400,
        'buff': 'EXP+40% コイン+40%'
      },
      {
        'id': 'ultimate',
        'emoji': '✨',
        'name': '究極の首輪',
        'price': 500,
        'buff': 'EXP+50% コイン+60% 減衰70%軽渁E
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
              const Text('🛍�E�EショチE�E',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('💰 $coins', style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('アイチE��を購入して裁E��しよぁE��E,
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
                        ? (equipped ? '裁E��中 - $buff' : '所有済み - $buff')
                        : '💰 $price - $buff'),
                    trailing: owned
                        ? (equipped
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : ElevatedButton(
                                onPressed: () => onEquipItem(itemId),
                                child: const Text('裁E��'),
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
            child: const Text('閉じめE),
          ),
        ],
      ),
    );
  }
}

/// 進化演�EウィジェチE��
class _EvolutionAnimation extends StatefulWidget {
  final int stage;
  final String stageName;
  final String imagePath;
  final String message;
  final GameResultLevel level;
  final VoidCallback? onComplete;

  const _EvolutionAnimation({
    required this.stage,
    required this.stageName,
    required this.imagePath,
    required this.message,
    required this.level,
    this.onComplete,
  });

  @override
  State<_EvolutionAnimation> createState() => _EvolutionAnimationState();
}

class _EvolutionAnimationState extends State<_EvolutionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
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

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor();

    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // パ�EチE��クル�E�Excellent以上！E
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
                        const Text(
                          '✨ 進化しました�E�E✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ペット画僁E
                        Image.asset(
                          widget.imagePath,
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            '🐣',
                            style: TextStyle(fontSize: 100),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '、E{widget.stageName}」に進化！E,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // タチE�Eで閉じめE
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => widget.onComplete?.call(),
              child: const Center(
                child: Text(
                  'タチE�Eして閉じめE,
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

// パ�EチE��クル描画�E�Echievement_animation.dartから流用�E�E
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final math.Random _random = math.Random(42);

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 100; i++) {
      final x = _random.nextDouble() * size.width;
      final startY = _random.nextDouble() * size.height * 0.3;
      final endY = size.height;
      final currentY = startY + (endY - startY) * progress;
      if (currentY > size.height) continue;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = _getParticleColor(i).withOpacity(opacity);
      final rotation = progress * math.pi * 4 + i;
      canvas.save();
      canvas.translate(x, currentY);
      canvas.rotate(rotation);
      if (i % 2 == 0) {
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
      } else {
        canvas.drawCircle(Offset.zero, 4, paint);
      }
      canvas.restore();
    }
  }

  Color _getParticleColor(int index) {
    final colors = [color, color.withBlue(255), Colors.yellow, Colors.white];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// 数当てゲーム�E�E-100の数字を推測�E�E
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
      _targetNumber = math.Random().nextInt(100) + 1;
      _attempts = 0;
      _history.clear();
      _feedback = '1、E00の数字を当ててください�E�E;
      _gameOver = false;
    });
    _guessController.clear();
  }

  void _makeGuess() {
    final input = _guessController.text.trim();
    if (input.isEmpty) return;

    final guess = int.tryParse(input);
    if (guess == null || guess < 1 || guess > 100) {
      setState(() => _feedback = '⚠�E�E1、E00の数字を入力してください');
      return;
    }

    setState(() {
      _attempts++;
      if (guess == _targetNumber) {
        _feedback = '🎉 正解�E�E$_attempts 回で当たりました�E�E;
        _gameOver = true;
        _history.add('$guess ↁE🎯 正解�E�E);
        _saveBestScore();

        // スコアに応じた演�Eレベル決定（回数が少なぁE��ど高評価�E�E
        GameResultLevel level;
        String? message;
        if (_attempts <= 3) {
          level = GameResultLevel.perfect;
          message = '神�E勘！E;
        } else if (_attempts <= 5) {
          level = GameResultLevel.excellent;
          message = '素晴らしぁE��E;
        } else if (_attempts <= 8) {
          level = GameResultLevel.good;
          message = '良ぁE��琁E��E;
        } else {
          level = GameResultLevel.normal;
          message = null;
        }

        // 派手な演�Eで結果表示
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
          _feedback = '🔥 もう少し大きい数字です（かなり近い�E�E��E;
        } else if (diff <= 15) {
          _feedback = '📈 もっと大きい数字です（近い�E�E;
        } else {
          _feedback = '⬁E��Eもっと大きい数字でぁE;
        }
        _history.add('$guess ↁE小さぁE);
      } else {
        final diff = guess - _targetNumber;
        if (diff <= 5) {
          _feedback = '🔥 もう少し小さぁE��字です（かなり近い�E�E��E;
        } else if (diff <= 15) {
          _feedback = '📉 もっと小さぁE��字です（近い�E�E;
        } else {
          _feedback = '⬁E��Eもっと小さぁE��字でぁE;
        }
        _history.add('$guess ↁE大きい');
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
                      '試行回数: $_attempts 囁E,
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
                          '🏆 ベスチE,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '$_bestScore 囁E,
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

            // フィードバチE��
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
                        labelText: '予想を�E劁E,
                        hintText: '1、E00',
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

            // リセチE��/新しいゲーム
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
                      title: const Text('ゲームをリセチE��'),
                      content: const Text('現在のゲームをリセチE��して新しく始めますか�E�E),
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
                          child: const Text('リセチE��'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('リセチE��'),
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
