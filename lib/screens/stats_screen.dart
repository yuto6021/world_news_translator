import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/achievements_service.dart';
import '../services/reading_time_service.dart';
import '../services/game_scores_service.dart';
import '../models/achievement.dart';
import '../widgets/achievement_animation.dart';
import 'streak_screen.dart';
import 'bingo_screen.dart';
import 'social_screen.dart';

/// 統計ダチE��ュボ�Eド画面 (読書記録の可視化)
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  int _totalArticlesRead = 0;
  int _favoritesCount = 0;
  int _consecutiveDays = 1;
  int _totalReadingTime = 0; // 刁E��佁E
  Map<String, int> _categoryStats = {}; // カチE��リ別記事数
  bool _secretButtonUnlocked = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _loadStats();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    // 隠し�Eタンの状態をローチE
    final secretUnlocked = await // AchievementService.isSecretButtonUnlocked();

    // 記事閲覧数�E�Erticle_detail_screenで記録�E�E
    final totalRead = prefs.getInt('articles_read_count') ?? 0;

    // お気に入り数�E�Eavorites_serviceで記録�E�E
    final favCount = prefs.getInt('favorites_count') ?? 0;

    // 連続日数
    final consecutiveDays = prefs.getInt('consecutive_days') ?? 1;

    // 読書時間�E�実測値を使用�E�E
    final readingTime = await ReadingTimeService.getTotalMinutes();

    // カチE��リ統計（実データ�E�E
    final categoriesRead = prefs.getStringList('categories_read') ?? [];
    final categoryStats = {
      'ビジネス':
          categoriesRead.contains('business') ? (totalRead * 0.3).toInt() : 0,
      'チE��ノロジー':
          categoriesRead.contains('tech') ? (totalRead * 0.25).toInt() : 0,
      'エンタメ': categoriesRead.contains('entertainment')
          ? (totalRead * 0.2).toInt()
          : 0,
      'スポ�EチE:
          categoriesRead.contains('sports') ? (totalRead * 0.15).toInt() : 0,
      'そ�E仁E: (totalRead * 0.1).toInt(),
    };

    if (!mounted) return;
    setState(() {
      _totalArticlesRead = totalRead;
      _favoritesCount = favCount;
      _consecutiveDays = consecutiveDays;
      _totalReadingTime = readingTime;
      _categoryStats = categoryStats;
      _secretButtonUnlocked = secretUnlocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー + 隠し�Eタン
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPress: () async {
                      final now = DateTime.now();
                      // 深夁E時！E:00-4:00�E�に長押しで実績解除
                      if (now.hour >= 2 && now.hour < 4) {
                        await // AchievementService.unlockNightOwlSecret();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('🦁E実績「深夜�E秘寁E��を解除しました�E�\nこんな時間まで起きてて大丈夫�E�E),
                              duration: Duration(seconds: 3),
                              backgroundColor: Colors.deepPurple,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      '📊 あなた�E読書統訁E,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 隠し�Eタン�E�タチE�Eで実績解除�E�E
                GestureDetector(
                  onTap: () async {
                    await // AchievementService.unlockSecretButton();
                    if (mounted) {
                      setState(() {
                        _secretButtonUnlocked = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🧁E隠し実績「隠老E��を解除しました�E�E),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _secretButtonUnlocked
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _secretButtonUnlocked
                            ? Colors.amber
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.star,
                      color: _secretButtonUnlocked
                          ? Colors.amber
                          : Colors.grey.withOpacity(0.1),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // サマリーカーチE
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.article,
                    label: '読んだ記亁E,
                    value: '$_totalArticlesRead',
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.favorite,
                    label: 'お気に入めE,
                    value: '$_favoritesCount',
                    color: Colors.pink,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    label: '連続日数',
                    value: '$_consecutiveDays日',
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer,
                    label: '読書時間',
                    value: '$_totalReadingTime刁E,
                    color: Colors.green,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StreakScreen()),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('ストリークカレンダー'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BingoScreen()),
                    );
                  },
                  icon: const Icon(Icons.grid_view),
                  label: const Text('ニュースビンゴ'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SocialScreen()),
                    );
                  },
                  icon: const Icon(Icons.people_outline),
                  label: const Text('ソーシャル'),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            // カチE��リ別グラチE
            Text(
              'カチE��リ別記事数',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _CategoryChart(
              data: _categoryStats,
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // レベルプログレス (仮)
            Text(
              'レベル進捁E,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _LevelProgress(
              currentLevel: (_totalArticlesRead / 10).floor() + 1,
              progress: (_totalArticlesRead % 10) / 10,
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // バッジセクション
            Text(
              '🏆 獲得バチE��',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _BadgeGrid(
              totalArticlesRead: _totalArticlesRead,
              favoritesCount: _favoritesCount,
              consecutiveDays: _consecutiveDays,
            ),
            const SizedBox(height: 32),

            // 実績一覧
            Text(
              '🎯 実績',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const _AchievementsList(),
            const SizedBox(height: 32),

            // ゲームスコア
            Text(
              '🎮 ゲームスコア',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const _GameScoresList(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<String, int> data;
  final bool isDark;

  const _CategoryChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return const Center(child: Text('チE�Eタがありません'));
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Column(
      children: data.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final e = entry.value;
        final percentage = (e.value / total * 100).toStringAsFixed(1);
        final color = colors[index % colors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('$percentage% (${e.value}記亁E',
                      style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: e.value / total,
                  minHeight: 12,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  final int currentLevel;
  final double progress;
  final bool isDark;

  const _LevelProgress({
    required this.currentLevel,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'レベル $currentLevel',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              Text(
                '次のレベルまで ${((1 - progress) * 10).toInt()}記亁E,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 16,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatefulWidget {
  final int totalArticlesRead;
  final int favoritesCount;
  final int consecutiveDays;

  const _BadgeGrid({
    required this.totalArticlesRead,
    required this.favoritesCount,
    required this.consecutiveDays,
  });

  @override
  State<_BadgeGrid> createState() => _BadgeGridState();
}

class _BadgeGridState extends State<_BadgeGrid> {
  bool _secretButtonUnlocked = false;
  int _maxDailyReads = 0;
  int _countriesReadCount = 0;
  int _categoriesReadCount = 0;
  int _swipeCount = 0;
  int _visitedTabsCount = 0;
  bool _timeCapsuleUsed = false;
  int _nightReadsCount = 0;
  bool _konamiCodeUnlocked = false;
  bool _konamiDoubleUnlocked = false;
  bool _fastTapperUnlocked = false;
  bool _fastTapGodUnlocked = false;
  bool _nightOwlSecretUnlocked = false;
  bool _memoryMasterUnlocked = false;
  bool _memoryPerfectUnlocked = false; // 新要E
  bool _petLv5Unlocked = false;
  bool _petLv10Unlocked = false;
  bool _petHappyUnlocked = false;
  bool _petOverfeedUnlocked = false; // 新要E
  bool _petOverplayUnlocked = false; // 新要E
  bool _playTime30Unlocked = false; // 新要E
  bool _playTime60Unlocked = false; // 新要E
  bool _playTime180Unlocked = false; // 新要E
  int _wikiSearchCount = 0; // 新要E
  int _numberGuessBest = 999; // 新要E
  int _commentsCount = 0; // 新要E
  int _reactionsCount = 0; // 新要E
  int _translationsCount = 0; // 新要E

  @override
  void initState() {
    super.initState();
    _loadAchievementData();
  }

  Future<void> _loadAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    final secretUnlocked = await // AchievementService.isSecretButtonUnlocked();
    final konamiUnlocked = await // AchievementService.isKonamiCodeUnlocked();
    final konamiDouble = await // AchievementService.isKonamiDoubleUnlocked();
    final fastTapUnlocked = await // AchievementService.isFastTapperUnlocked();
    final fastTapGod = await // AchievementService.isFastTapGodUnlocked();
    final memoryMaster = await // AchievementService.isMemoryMasterUnlocked();
    final memoryPerfect =
        await // AchievementService.isMemoryPerfectUnlocked(); // 新要E
    final nightOwlUnlocked =
        await // AchievementService.isNightOwlSecretUnlocked();
    final petLv5 = await // AchievementService.isPetLevel5Unlocked();
    final petLv10 = await // AchievementService.isPetLevel10Unlocked();
    final petHappy = await // AchievementService.isPetHappy100Unlocked();
    final petOverfeed = await // AchievementService.isPetOverfeedUnlocked(); // 新要E
    final petOverplay = await // AchievementService.isPetOverplayUnlocked(); // 新要E
    final playTime30 = await // AchievementService.isPlayTime30Unlocked(); // 新要E
    final playTime60 = await // AchievementService.isPlayTime60Unlocked(); // 新要E
    final playTime180 = await // AchievementService.isPlayTime180Unlocked(); // 新要E
    final maxDaily = prefs.getInt('max_daily_reads') ?? 0;
    final countries = prefs.getStringList('countries_read') ?? [];
    final categories = prefs.getStringList('categories_read') ?? [];
    final swipes = prefs.getInt('swipe_count') ?? 0;
    final tabs = prefs.getStringList('visited_tabs') ?? [];
    final timeCapsule = prefs.getBool('time_capsule_used') ?? false;
    final nightReads = prefs.getInt('night_reads_count') ?? 0;

    // 新機�Eの統訁E
    final wikiSearchCount = prefs.getInt('wiki_search_count') ?? 0;
    final numberGuessBest = prefs.getInt('guess_game_best') ?? 999;
    final commentsCount = prefs.getInt('comments_count') ?? 0;
    final reactionsCount = prefs.getInt('reactions_count') ?? 0;
    final translationsCount = prefs.getInt('translations_count') ?? 0;

    if (mounted) {
      setState(() {
        _secretButtonUnlocked = secretUnlocked;
        _konamiCodeUnlocked = konamiUnlocked;
        _konamiDoubleUnlocked = konamiDouble;
        _fastTapperUnlocked = fastTapUnlocked;
        _fastTapGodUnlocked = fastTapGod;
        _memoryMasterUnlocked = memoryMaster;
        _memoryPerfectUnlocked = memoryPerfect; // 新要E
        _petLv5Unlocked = petLv5;
        _petLv10Unlocked = petLv10;
        _petHappyUnlocked = petHappy;
        _petOverfeedUnlocked = petOverfeed; // 新要E
        _petOverplayUnlocked = petOverplay; // 新要E
        _playTime30Unlocked = playTime30; // 新要E
        _playTime60Unlocked = playTime60; // 新要E
        _playTime180Unlocked = playTime180; // 新要E
        _nightOwlSecretUnlocked = nightOwlUnlocked;
        _maxDailyReads = maxDaily;
        _countriesReadCount = countries.length;
        _categoriesReadCount = categories.length;
        _swipeCount = swipes;
        _visitedTabsCount = tabs.length;
        _timeCapsuleUsed = timeCapsule;
        _nightReadsCount = nightReads;
        _wikiSearchCount = wikiSearchCount;
        _numberGuessBest = numberGuessBest;
        _commentsCount = commentsCount;
        _reactionsCount = reactionsCount;
        _translationsCount = translationsCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isNightOwl = now.hour >= 0 && now.hour < 5; // 深夜帯チェチE��
    final isEarlyBird = now.hour >= 5 && now.hour < 7; // 早朝チェチE��

    final badges = [
      // 基本実績
      _Badge(
        icon: '🎯',
        name: '初忁E��E,
        description: '最初�E記事を読む',
        unlocked: widget.totalArticlesRead >= 1,
      ),
      _Badge(
        icon: '📚',
        name: '読書家',
        description: '10記事読む',
        unlocked: widget.totalArticlesRead >= 10,
      ),
      _Badge(
        icon: '🔥',
        name: '継続�E力なめE,
        description: '3日連続ログイン',
        unlocked: widget.consecutiveDays >= 3,
      ),
      _Badge(
        icon: '💎',
        name: 'コレクター',
        description: '5記事お気に入めE,
        unlocked: widget.favoritesCount >= 5,
      ),
      _Badge(
        icon: '👑',
        name: 'マスター',
        description: '50記事読む',
        unlocked: widget.totalArticlesRead >= 50,
      ),
      _Badge(
        icon: '🌟',
        name: 'レジェンチE,
        description: '100記事読む',
        unlocked: widget.totalArticlesRead >= 100,
      ),

      // 上級実績
      _Badge(
        icon: '💯',
        name: '完璧主義老E,
        description: '200記事読破',
        unlocked: widget.totalArticlesRead >= 200,
      ),
      _Badge(
        icon: '🏆',
        name: 'チャンピオン',
        description: '7日連続ログイン',
        unlocked: widget.consecutiveDays >= 7,
      ),
      _Badge(
        icon: '🎖�E�E,
        name: '常連さん',
        description: '30日連続ログイン',
        unlocked: widget.consecutiveDays >= 30,
      ),
      _Badge(
        icon: '💝',
        name: 'お気に入り魁E,
        description: '20記事お気に入めE,
        unlocked: widget.favoritesCount >= 20,
      ),

      // ユニ�Eク実績�E�遊び忁E��E
      _Badge(
        icon: '🦁E,
        name: '夜更かし魁E,
        description: '深夁E-5時にアクセス',
        unlocked: isNightOwl && widget.totalArticlesRead >= 1,
      ),
      _Badge(
        icon: '🐦',
        name: '早起き鳥',
        description: '早朁E-7時にアクセス',
        unlocked: isEarlyBird && widget.totalArticlesRead >= 1,
      ),
      _Badge(
        icon: '🎰',
        name: 'ラチE��ー7',
        description: 'お気に入り数ぁEの倍数',
        unlocked: widget.favoritesCount > 0 && widget.favoritesCount % 7 == 0,
      ),
      _Badge(
        icon: '🍀',
        name: '四つ葁E,
        description: 'お気に入り数がちめE��ど4の倍数',
        unlocked: widget.favoritesCount > 0 && widget.favoritesCount % 4 == 0,
      ),
      _Badge(
        icon: '🎲',
        name: 'ゾロ目',
        description: '記事数ぁE1, 22, 33...のゾロ目',
        unlocked: widget.totalArticlesRead >= 11 &&
            widget.totalArticlesRead.toString().split('').toSet().length == 1,
      ),
      _Badge(
        icon: '🚀',
        name: 'スピ�Eドリーダー',
        description: '1日で10記事以上読む',
        unlocked: _maxDailyReads >= 10,
      ),
      _Badge(
        icon: '🌍',
        name: '世界を知る老E,
        description: '5カ国以上�Eニュース閲覧',
        unlocked: _countriesReadCount >= 5,
      ),
      _Badge(
        icon: '🎨',
        name: 'カラフル',
        description: '全カチE��リめE回以上閲覧',
        unlocked: _categoriesReadCount >= 5,
      ),
      _Badge(
        icon: '🔮',
        name: '予言老E,
        description: '未来のニュースを読む�E�タイムカプセル使用�E�E,
        unlocked: _timeCapsuleUsed,
      ),
      _Badge(
        icon: '🎭',
        name: 'マルチタスカー',
        description: '全タブを1回ずつ訪啁E,
        unlocked: _visitedTabsCount >= 8,
      ),
      _Badge(
        icon: '🧁E,
        name: '隠老E,
        description: '秘寁E�Eボタンを発要E,
        unlocked: _secretButtonUnlocked,
      ),
      _Badge(
        icon: '💫',
        name: 'スワイプ�Eスター',
        description: 'スワイプで30記事閲覧',
        unlocked: _swipeCount >= 30,
      ),
      _Badge(
        icon: '🎪',
        name: 'エンターチE��ナ�E',
        description: '全機�Eを一度は使ぁE,
        unlocked:
            _visitedTabsCount >= 10 && _swipeCount >= 5 && _timeCapsuleUsed,
      ),
      _Badge(
        icon: '🌙',
        name: 'ムーンウォーカー',
        description: '深夜に100記事読破',
        unlocked: _nightReadsCount >= 100,
      ),
      _Badge(
        icon: '⚡',
        name: '電光石火',
        description: '1日で20記事以上閲覧',
        unlocked: _maxDailyReads >= 20,
      ),
      _Badge(
        icon: '🎮',
        name: 'コナミコマンチE,
        description: '伝説のコマンドを入力（�E↑�E↓�E→�E→BA�E�E,
        unlocked: _konamiCodeUnlocked,
      ),
      _Badge(
        icon: '🎮',
        name: '二連コナミ',
        description: 'コマンドを2回決める',
        unlocked: _konamiDoubleUnlocked,
      ),
      _Badge(
        icon: '👆',
        name: 'ゴチE��ハンチE,
        description: 'タチE�Eチャレンジで50回以丁E,
        unlocked: _fastTapperUnlocked,
      ),
      _Badge(
        icon: '👆',
        name: '早撁E��祁E,
        description: 'タチE�Eチャレンジで80回以丁E,
        unlocked: _fastTapGodUnlocked,
      ),
      _Badge(
        icon: '🦁E,
        name: '深夜�E秘寁E,
        description: '深夁E時に特定操作を実衁E,
        unlocked: _nightOwlSecretUnlocked,
      ),
      _Badge(
        icon: '🧠',
        name: '記�E玁E,
        description: '記�EゲームでベスチE2手以冁E,
        unlocked: _memoryMasterUnlocked,
      ),
      _Badge(
        icon: '🐾',
        name: '育成Lv5',
        description: 'ペッチEv5到遁E,
        unlocked: _petLv5Unlocked,
      ),
      _Badge(
        icon: '🐲',
        name: '育成Lv10',
        description: 'ペッチEv10到遁E,
        unlocked: _petLv10Unlocked,
      ),
      _Badge(
        icon: '🥳',
        name: 'ごきげんMAX',
        description: 'ペット幸福度100',
        unlocked: _petHappyUnlocked,
      ),
      // 新規実績
      _Badge(
        icon: '🕐',
        name: '30刁E�Eレイ',
        description: 'ゲーム合訁E0刁E��上�Eレイ',
        unlocked: _playTime30Unlocked,
      ),
      _Badge(
        icon: '⏰',
        name: '1時間プレイ',
        description: 'ゲーム合訁E時間以上�Eレイ',
        unlocked: _playTime60Unlocked,
      ),
      _Badge(
        icon: '⌁E,
        name: '3時間プレイ',
        description: 'ゲーム合訁E時間以上�Eレイ',
        unlocked: _playTime180Unlocked,
      ),
      _Badge(
        icon: '🎯',
        name: '完璧主義老E,
        description: '記�Eゲームをノーミスでクリア',
        unlocked: _memoryPerfectUnlocked,
      ),
      _Badge(
        icon: '📚',
        name: 'Wikipedia探検家',
        description: 'Wikipedia検索めE0回以上使用',
        unlocked: _wikiSearchCount >= 20,
      ),
      _Badge(
        icon: '🎲',
        name: '数当てマスター',
        description: '数当てゲームで5回以冁E��クリア',
        unlocked: _numberGuessBest <= 5 && _numberGuessBest > 0,
      ),
      _Badge(
        icon: '💬',
        name: 'コメンチE�Eター',
        description: 'コメントを30個以上投稿',
        unlocked: _commentsCount >= 30,
      ),
      _Badge(
        icon: '❤�E�E,
        name: 'リアクション玁E,
        description: 'リアクションめE0回以上追加',
        unlocked: _reactionsCount >= 50,
      ),
      _Badge(
        icon: '🌏',
        name: '国際派',
        description: '10カ国以上�Eニュースを閲覧',
        unlocked: _countriesReadCount >= 10,
      ),
      _Badge(
        icon: '🔤',
        name: '翻訳マスター',
        description: '翻訳機�EめE00回以上使用',
        unlocked: _translationsCount >= 100,
      ),
      _Badge(
        icon: '🍔',
        name: '食べ過ぎ注愁E,
        description: 'ペットに連綁E回ごはめE,
        unlocked: _petOverfeedUnlocked,
      ),
      _Badge(
        icon: '😵',
        name: '体力の限界',
        description: 'ペットと連綁E回遊ぶ',
        unlocked: _petOverplayUnlocked,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 120), // フッターに隠れなぁE��白
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: badges.map((badge) => _BadgeCard(badge: badge)).toList(),
      ),
    );
  }
}

class _Badge {
  final String icon;
  final String name;
  final String description;
  final bool unlocked;

  _Badge({
    required this.icon,
    required this.name,
    required this.description,
    required this.unlocked,
  });
}

class _BadgeCard extends StatelessWidget {
  final _Badge badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.4,
      child: Container(
        width: (MediaQuery.of(context).size.width - 56) / 3,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              badge.unlocked ? Border.all(color: Colors.amber, width: 2) : null,
          boxShadow: badge.unlocked
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// 実績一覧ウィジェチE��
class _AchievementsList extends StatefulWidget {
  const _AchievementsList();

  @override
  State<_AchievementsList> createState() => _AchievementsListState();
}

class _AchievementsListState extends State<_AchievementsList> {
  void _testAchievement(
    BuildContext context,
    String achievementId,
    List<Achievement> achievements,
  ) {
    final achievement = achievements.firstWhere((a) => a.id == achievementId);
    // 実績演�Eをテスト表示
    final overlay = OverlayEntry(
      builder: (context) => AchievementUnlockedAnimation(
        achievement: achievement,
        onComplete: () {},
      ),
    );
    Overlay.of(context).insert(overlay);
    Future.delayed(Duration(seconds: achievement.rarity == AchievementRarity.legendary ? 4 : 3), () {
      overlay.remove();
    });
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
    return FutureBuilder(
      future: AchievementsService.getAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final achievements = snapshot.data!;
        return Column(
          children: [
            // チE��チE��用チE��ト�Eタン
            Card(
              color: Colors.orange.withOpacity(0.2),
              child: ExpansionTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('🧪 実績チE��ト（開発用�E�E),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TestButton(
                        label: 'コモン',
                        color: Colors.grey,
                        onPressed: () => _testAchievement(
                          context,
                          'reading_30min',
                          achievements,
                        ),
                      ),
                      _TestButton(
                        label: 'レア',
                        color: Colors.blue,
                        onPressed: () => _testAchievement(
                          context,
                          'reading_2hours',
                          achievements,
                        ),
                      ),
                      _TestButton(
                        label: 'エピック',
                        color: Colors.purple,
                        onPressed: () => _testAchievement(
                          context,
                          'reading_10hours',
                          achievements,
                        ),
                      ),
                      _TestButton(
                        label: 'レジェンダリー',
                        color: Colors.amber,
                        onPressed: () => _testAchievement(
                          context,
                          'streak_100',
                          achievements,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 実績リスチE
            ...achievements.map((ach) {
            final progress = ach.progress / ach.target;
            final rarityColor = _getRarityColor(ach.rarity);
            final isSecret = ach.isSecret && !ach.isUnlocked;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: ach.isUnlocked ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: ach.isUnlocked
                    ? BorderSide(color: rarityColor, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSecret ? '❁E : ach.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(isSecret ? '???' : ach.title),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rarityColor, width: 1),
                      ),
                      child: Text(
                        _getRarityLabel(ach.rarity),
                        style: TextStyle(
                          fontSize: 10,
                          color: rarityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ach.description),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      color: rarityColor,
                    ),
                    if (!isSecret)
                      Text('${ach.progress}/${ach.target}',
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: ach.isUnlocked
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// チE��ト�EタンウィジェチE��
class _TestButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _TestButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ゲームスコア一覧ウィジェチE��
class _GameScoresList extends StatelessWidget {
  const _GameScoresList();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GameScoresService.getAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final scores = snapshot.data!;
        final gameNames = {
          'game_flag_memory_best': '🎴 国旗神経衰弱',
          'tap_best': '👆 タチE�Eチャレンジ',
          'pet_level': '🐾 ペット育戁E,
          'number_guess_best': '🎲 数字当て',
          'snake_best': '🐍 スネ�Eク',
          '2048_best': '🎮 2048',
          'quiz_best_score': '📰 ニュースクイズ',
        };

        return Column(
          children: scores.entries.map((e) {
            final name = gameNames[e.key] ?? e.key;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(name),
                trailing: Text(
                  e.value.toString(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
