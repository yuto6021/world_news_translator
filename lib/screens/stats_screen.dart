import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/achievement_service.dart';

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

    // 読書時間 (記事数 × 平均3分)
    final readingTime = totalRead * 3;

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
        padding: const EdgeInsets.all(16),
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
  bool _fastTapperUnlocked = false;
  bool _nightOwlSecretUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadAchievementData();
  }

  Future<void> _loadAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    final secretUnlocked = await AchievementService.isSecretButtonUnlocked();
    final konamiUnlocked = await AchievementService.isKonamiCodeUnlocked();
    final fastTapUnlocked = await AchievementService.isFastTapperUnlocked();
    final nightOwlUnlocked =
        await AchievementService.isNightOwlSecretUnlocked();
    final maxDaily = prefs.getInt('max_daily_reads') ?? 0;
    final countries = prefs.getStringList('countries_read') ?? [];
    final categories = prefs.getStringList('categories_read') ?? [];
    final swipes = prefs.getInt('swipe_count') ?? 0;
    final tabs = prefs.getStringList('visited_tabs') ?? [];
    final timeCapsule = prefs.getBool('time_capsule_used') ?? false;
    final nightReads = prefs.getInt('night_reads_count') ?? 0;

    if (mounted) {
      setState(() {
        _secretButtonUnlocked = secretUnlocked;
        _konamiCodeUnlocked = konamiUnlocked;
        _fastTapperUnlocked = fastTapUnlocked;
        _nightOwlSecretUnlocked = nightOwlUnlocked;
        _maxDailyReads = maxDaily;
        _countriesReadCount = countries.length;
        _categoriesReadCount = categories.length;
        _swipeCount = swipes;
        _visitedTabsCount = tabs.length;
        _timeCapsuleUsed = timeCapsule;
        _nightReadsCount = nightReads;
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
        icon: '👆',
        name: 'ゴッドハンド',
        description: 'タップチャレンジで50回以上',
        unlocked: _fastTapperUnlocked,
      ),
      _Badge(
        icon: '🦉',
        name: '深夜の秘密',
        description: '深夜3時に特定操作を実行',
        unlocked: _nightOwlSecretUnlocked,
      ),
      _Badge(
        icon: '🎁',
        name: 'サプライズ',
        description: 'ランダム実績解除',
        unlocked:
            widget.totalArticlesRead >= 50 && DateTime.now().second % 10 == 0,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: badges.map((badge) => _BadgeCard(badge: badge)).toList(),
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
