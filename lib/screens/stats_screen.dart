import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/achievement_service.dart';
import '../services/reading_time_service.dart';
import '../services/achievements_service.dart';
import '../services/game_scores_service.dart';
import '../services/badge_service.dart';
import '../models/achievement.dart';
import '../widgets/achievement_animation.dart';
import 'streak_screen.dart';
import 'bingo_screen.dart';
import 'social_screen.dart';

/// 統計ダッシュボード画面 (読書記録の可視化)
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
  int _totalReadingTime = 0; // 分単位
  Map<String, int> _categoryStats = {}; // カテゴリ別記事数
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

    // 隠しボタンの状態をロード
    final secretUnlocked = await AchievementService.isSecretButtonUnlocked();

    // 記事閲覧数（article_detail_screenで記録）
    final totalRead = prefs.getInt('articles_read_count') ?? 0;

    // お気に入り数（favorites_serviceで記録）
    final favCount = prefs.getInt('favorites_count') ?? 0;

    // 連続日数
    final consecutiveDays = prefs.getInt('consecutive_days') ?? 1;

    // 読書時間（実測値を使用）
    final readingTime = await ReadingTimeService.getTotalMinutes();

    // カテゴリ統計（実データ）
    final categoriesRead = prefs.getStringList('categories_read') ?? [];
    final categoryStats = {
      'ビジネス':
          categoriesRead.contains('business') ? (totalRead * 0.3).toInt() : 0,
      'テクノロジー':
          categoriesRead.contains('tech') ? (totalRead * 0.25).toInt() : 0,
      'エンタメ': categoriesRead.contains('entertainment')
          ? (totalRead * 0.2).toInt()
          : 0,
      'スポーツ':
          categoriesRead.contains('sports') ? (totalRead * 0.15).toInt() : 0,
      'その他': (totalRead * 0.1).toInt(),
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
            // ヘッダー + 隠しボタン
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPress: () async {
                      final now = DateTime.now();
                      // 深夜3時（2:00-4:00）に長押しで実績解除
                      if (now.hour >= 2 && now.hour < 4) {
                        await AchievementService.unlockNightOwlSecret();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('🦉 実績「深夜の秘密」を解除しました！\nこんな時間まで起きてて大丈夫？'),
                              duration: Duration(seconds: 3),
                              backgroundColor: Colors.deepPurple,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      '📊 あなたの読書統計',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 隠しボタン（タップで実績解除）
                GestureDetector(
                  onTap: () async {
                    await AchievementService.unlockSecretButton();
                    if (mounted) {
                      setState(() {
                        _secretButtonUnlocked = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🧙 隠し実績「隠者」を解除しました！'),
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

            // サマリーカード
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.article,
                    label: '読んだ記事',
                    value: '$_totalArticlesRead',
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.favorite,
                    label: 'お気に入り',
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
                    value: '$_totalReadingTime分',
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

            // カテゴリ別グラフ
            Text(
              'カテゴリ別記事数',
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
              'レベル進捗',
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
              '🏆 獲得バッジ',
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
            const SizedBox(height: 24),

            // テスト実績解除ボタン
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '🧪 テスト実績解除',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _unlockTestAchievement(context, 'test_common'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          child: const Text('コモン'),
                        ),
                        ElevatedButton(
                          onPressed: () => _unlockTestAchievement(context, 'test_rare'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('レア'),
                        ),
                        ElevatedButton(
                          onPressed: () => _unlockTestAchievement(context, 'test_epic'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          child: const Text('エピック'),
                        ),
                        ElevatedButton(
                          onPressed: () => _unlockTestAchievement(context, 'test_legendary'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                          child: const Text('レジェンダリー'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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

  /// テスト実績を解除
  Future<void> _unlockTestAchievement(BuildContext context, String achievementId) async {
    await AchievementsService.unlock(achievementId);
    
    if (!context.mounted) return;
    
    final achievements = await AchievementsService.getAll();
    final achievement = achievements.firstWhere(
      (a) => a.id == achievementId,
    );
    
    // 実績演出を表示
    AchievementNotifier.show(context, achievement);
    
    // スナックバー表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ${achievement.title} を解除しました！'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
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
      return const Center(child: Text('データがありません'));
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
                  Text('$percentage% (${e.value}記事)',
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
                '次のレベルまで ${((1 - progress) * 10).toInt()}記事',
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
  bool _memoryPerfectUnlocked = false; // 新規
  bool _petLv5Unlocked = false;
  bool _petLv10Unlocked = false;
  bool _petHappyUnlocked = false;
  bool _petOverfeedUnlocked = false; // 新規
  bool _petOverplayUnlocked = false; // 新規
  bool _playTime30Unlocked = false; // 新規
  bool _playTime60Unlocked = false; // 新規
  bool _playTime180Unlocked = false; // 新規
  int _wikiSearchCount = 0; // 新規
  int _numberGuessBest = 999; // 新規
  int _commentsCount = 0; // 新規
  int _reactionsCount = 0; // 新規
  int _translationsCount = 0; // 新規

  @override
  void initState() {
    super.initState();
    _loadAchievementData();
  }

  Future<void> _loadAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    final secretUnlocked = await AchievementService.isSecretButtonUnlocked();
    final konamiUnlocked = await AchievementService.isKonamiCodeUnlocked();
    final konamiDouble = await AchievementService.isKonamiDoubleUnlocked();
    final fastTapUnlocked = await AchievementService.isFastTapperUnlocked();
    final fastTapGod = await AchievementService.isFastTapGodUnlocked();
    final memoryMaster = await AchievementService.isMemoryMasterUnlocked();
    final memoryPerfect =
        await AchievementService.isMemoryPerfectUnlocked(); // 新規
    final nightOwlUnlocked =
        await AchievementService.isNightOwlSecretUnlocked();
    final petLv5 = await AchievementService.isPetLevel5Unlocked();
    final petLv10 = await AchievementService.isPetLevel10Unlocked();
    final petHappy = await AchievementService.isPetHappy100Unlocked();
    final petOverfeed = await AchievementService.isPetOverfeedUnlocked(); // 新規
    final petOverplay = await AchievementService.isPetOverplayUnlocked(); // 新規
    final playTime30 = await AchievementService.isPlayTime30Unlocked(); // 新規
    final playTime60 = await AchievementService.isPlayTime60Unlocked(); // 新規
    final playTime180 = await AchievementService.isPlayTime180Unlocked(); // 新規
    final maxDaily = prefs.getInt('max_daily_reads') ?? 0;
    final countries = prefs.getStringList('countries_read') ?? [];
    final categories = prefs.getStringList('categories_read') ?? [];
    final swipes = prefs.getInt('swipe_count') ?? 0;
    final tabs = prefs.getStringList('visited_tabs') ?? [];
    final timeCapsule = prefs.getBool('time_capsule_used') ?? false;
    final nightReads = prefs.getInt('night_reads_count') ?? 0;

    // 新機能の統計
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
        _memoryPerfectUnlocked = memoryPerfect; // 新規
        _petLv5Unlocked = petLv5;
        _petLv10Unlocked = petLv10;
        _petHappyUnlocked = petHappy;
        _petOverfeedUnlocked = petOverfeed; // 新規
        _petOverplayUnlocked = petOverplay; // 新規
        _playTime30Unlocked = playTime30; // 新規
        _playTime60Unlocked = playTime60; // 新規
        _playTime180Unlocked = playTime180; // 新規
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
    final isNightOwl = now.hour >= 0 && now.hour < 5; // 深夜帯チェック
    final isEarlyBird = now.hour >= 5 && now.hour < 7; // 早朝チェック

    final badges = [
      // 基本実績
      _Badge(
        icon: '🎯',
        name: '初心者',
        description: '最初の記事を読む',
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
        name: '継続は力なり',
        description: '3日連続ログイン',
        unlocked: widget.consecutiveDays >= 3,
      ),
      _Badge(
        icon: '💎',
        name: 'コレクター',
        description: '5記事お気に入り',
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
        name: 'レジェンド',
        description: '100記事読む',
        unlocked: widget.totalArticlesRead >= 100,
      ),

      // 上級実績
      _Badge(
        icon: '💯',
        name: '完璧主義者',
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
        icon: '🎖️',
        name: '常連さん',
        description: '30日連続ログイン',
        unlocked: widget.consecutiveDays >= 30,
      ),
      _Badge(
        icon: '💝',
        name: 'お気に入り魔',
        description: '20記事お気に入り',
        unlocked: widget.favoritesCount >= 20,
      ),

      // ユニーク実績（遊び心）
      _Badge(
        icon: '🦉',
        name: '夜更かし魔',
        description: '深夜0-5時にアクセス',
        unlocked: isNightOwl && widget.totalArticlesRead >= 1,
      ),
      _Badge(
        icon: '🐦',
        name: '早起き鳥',
        description: '早朝5-7時にアクセス',
        unlocked: isEarlyBird && widget.totalArticlesRead >= 1,
      ),
      _Badge(
        icon: '🎰',
        name: 'ラッキー7',
        description: 'お気に入り数が7の倍数',
        unlocked: widget.favoritesCount > 0 && widget.favoritesCount % 7 == 0,
      ),
      _Badge(
        icon: '🍀',
        name: '四つ葉',
        description: 'お気に入り数がちょうど4の倍数',
        unlocked: widget.favoritesCount > 0 && widget.favoritesCount % 4 == 0,
      ),
      _Badge(
        icon: '🎲',
        name: 'ゾロ目',
        description: '記事数が11, 22, 33...のゾロ目',
        unlocked: widget.totalArticlesRead >= 11 &&
            widget.totalArticlesRead.toString().split('').toSet().length == 1,
      ),
      _Badge(
        icon: '🚀',
        name: 'スピードリーダー',
        description: '1日で10記事以上読む',
        unlocked: _maxDailyReads >= 10,
      ),
      _Badge(
        icon: '🌍',
        name: '世界を知る者',
        description: '5カ国以上のニュース閲覧',
        unlocked: _countriesReadCount >= 5,
      ),
      _Badge(
        icon: '🎨',
        name: 'カラフル',
        description: '全カテゴリを1回以上閲覧',
        unlocked: _categoriesReadCount >= 5,
      ),
      _Badge(
        icon: '🔮',
        name: '予言者',
        description: '未来のニュースを読む（タイムカプセル使用）',
        unlocked: _timeCapsuleUsed,
      ),
      _Badge(
        icon: '🎭',
        name: 'マルチタスカー',
        description: '全タブを1回ずつ訪問',
        unlocked: _visitedTabsCount >= 8,
      ),
      _Badge(
        icon: '🧙',
        name: '隠者',
        description: '秘密のボタンを発見',
        unlocked: _secretButtonUnlocked,
      ),
      _Badge(
        icon: '💫',
        name: 'スワイプマスター',
        description: 'スワイプで30記事閲覧',
        unlocked: _swipeCount >= 30,
      ),
      _Badge(
        icon: '🎪',
        name: 'エンターテイナー',
        description: '全機能を一度は使う',
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
        name: 'コナミコマンド',
        description: '伝説のコマンドを入力（↑↑↓↓←→←→BA）',
        unlocked: _konamiCodeUnlocked,
      ),
      _Badge(
        icon: '🎆',
        name: '二連コナミ',
        description: 'コマンドを2回決める',
        unlocked: _konamiDoubleUnlocked,
      ),
      _Badge(
        icon: '👆',
        name: 'ゴッドハンド',
        description: 'タップチャレンジで50回以上',
        unlocked: _fastTapperUnlocked,
      ),
      _Badge(
        icon: '👏',
        name: '早撃ち神',
        description: 'タップチャレンジで80回以上',
        unlocked: _fastTapGodUnlocked,
      ),
      _Badge(
        icon: '🌃',
        name: '深夜の秘密',
        description: '深夜3時に特定操作を実行',
        unlocked: _nightOwlSecretUnlocked,
      ),
      _Badge(
        icon: '🧠',
        name: '記憶王',
        description: '記憶ゲームでベスト12手以内',
        unlocked: _memoryMasterUnlocked,
      ),
      _Badge(
        icon: '🐾',
        name: '育成Lv5',
        description: 'ペットLv5到達',
        unlocked: _petLv5Unlocked,
      ),
      _Badge(
        icon: '🐲',
        name: '育成Lv10',
        description: 'ペットLv10到達',
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
        name: '30分プレイ',
        description: 'ゲーム合計30分以上プレイ',
        unlocked: _playTime30Unlocked,
      ),
      _Badge(
        icon: '⏰',
        name: '1時間プレイ',
        description: 'ゲーム合計1時間以上プレイ',
        unlocked: _playTime60Unlocked,
      ),
      _Badge(
        icon: '⌛',
        name: '3時間プレイ',
        description: 'ゲーム合計3時間以上プレイ',
        unlocked: _playTime180Unlocked,
      ),
      _Badge(
        icon: '🎯',
        name: '完璧主義者',
        description: '記憶ゲームをノーミスでクリア',
        unlocked: _memoryPerfectUnlocked,
      ),
      _Badge(
        icon: '🔍',
        name: 'Wikipedia探検家',
        description: 'Wikipedia検索を20回以上使用',
        unlocked: _wikiSearchCount >= 20,
      ),
      _Badge(
        icon: '🔢',
        name: '数当てマスター',
        description: '数当てゲームで5回以内にクリア',
        unlocked: _numberGuessBest <= 5 && _numberGuessBest > 0,
      ),
      _Badge(
        icon: '💬',
        name: 'コメンテーター',
        description: 'コメントを30個以上投稿',
        unlocked: _commentsCount >= 30,
      ),
      _Badge(
        icon: '❤️',
        name: 'リアクション王',
        description: 'リアクションを50回以上追加',
        unlocked: _reactionsCount >= 50,
      ),
      _Badge(
        icon: '🌏',
        name: '国際派',
        description: '10カ国以上のニュースを閲覧',
        unlocked: _countriesReadCount >= 10,
      ),
      _Badge(
        icon: '🔤',
        name: '翻訳マスター',
        description: '翻訳機能を100回以上使用',
        unlocked: _translationsCount >= 100,
      ),
      _Badge(
        icon: '🍔',
        name: '食べ過ぎ注意',
        description: 'ペットに連続3回ごはん',
        unlocked: _petOverfeedUnlocked,
      ),
      _Badge(
        icon: '😵',
        name: '体力の限界',
        description: 'ペットと連続5回遊ぶ',
        unlocked: _petOverplayUnlocked,
      ),
    ];

    // 解除済みバッジをBadgeServiceに保存
    final unlockedEmojis = badges
        .where((b) => b.unlocked)
        .map((b) => b.icon)
        .toList();
    
    if (unlockedEmojis.isNotEmpty) {
      BadgeService.unlockBadges(unlockedEmojis);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 120), // フッターに隠れない余白
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

// 実績一覧ウィジェット
class _AchievementsList extends StatelessWidget {
  const _AchievementsList();

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
          children: achievements.map((ach) {
            final progress = ach.progress / ach.target;
            final rarityColor = _getRarityColor(ach.rarity);

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
                  child: Text(ach.icon, style: const TextStyle(fontSize: 32)),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(ach.title)),
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

// ゲームスコア一覧ウィジェット
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
          'tap_best': '👆 タップチャレンジ',
          'pet_level': '🐾 ペット育成',
          'number_guess_best': '🎲 数字当て',
          'snake_best': '🐍 スネーク',
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
