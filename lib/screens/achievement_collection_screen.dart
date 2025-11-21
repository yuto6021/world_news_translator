import 'package:flutter/material.dart';
import '../services/achievements_service.dart';
import '../models/achievement.dart';

/// 実績コレクション画面（図鑑形式）
class AchievementCollectionScreen extends StatefulWidget {
  const AchievementCollectionScreen({super.key});

  @override
  State<AchievementCollectionScreen> createState() => _AchievementCollectionScreenState();
}

class _AchievementCollectionScreenState extends State<AchievementCollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Achievement> _allAchievements = [];
  int _unlockedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    final achievements = await AchievementsService.getAll();
    final unlocked = achievements.where((a) => a.isUnlocked).length;

    setState(() {
      _allAchievements = achievements;
      _unlockedCount = unlocked;
      _totalCount = achievements.length;
    });
  }

  List<Achievement> _filterByCategory(String category) {
    switch (category) {
      case 'reading':
        return _allAchievements.where((a) =>
            a.id.contains('reading') || a.id.contains('streak')).toList();
      case 'game':
        return _allAchievements.where((a) =>
            a.id.contains('tap') || a.id.contains('snake') ||
            a.id.contains('2048') || a.id.contains('memory') ||
            a.id.contains('pet') || a.id.contains('quiz') ||
            a.id.contains('number')).toList();
      case 'social':
        return _allAchievements.where((a) =>
            a.id.contains('comment') || a.id.contains('favorite')).toList();
      case 'secret':
        return _allAchievements.where((a) => a.isSecret).toList();
      default:
        return _allAchievements;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completionRate = _totalCount > 0
        ? (_unlockedCount / _totalCount * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('実績図鑑 📚'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '全て'),
            Tab(text: '📖 読書'),
            Tab(text: '🎮 ゲーム'),
            Tab(text: '💬 ソーシャル'),
            Tab(text: '🔒 シークレット'),
          ],
        ),
      ),
      body: Column(
        children: [
          // コンプリート率表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade700,
                  Colors.indigo.shade500,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'コンプリート率',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_unlockedCount/$_totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: _totalCount > 0 ? _unlockedCount / _totalCount : 0,
                            strokeWidth: 10,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$completionRate%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAchievementGrid('all'),
                _buildAchievementGrid('reading'),
                _buildAchievementGrid('game'),
                _buildAchievementGrid('social'),
                _buildAchievementGrid('secret'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(String category) {
    final achievements = _filterByCategory(category);

    if (achievements.isEmpty) {
      return const Center(
        child: Text('該当する実績がありません'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final ach = achievements[index];
        return _buildAchievementCard(ach);
      },
    );
  }

  Widget _buildAchievementCard(Achievement ach) {
    final isSecret = ach.isSecret && !ach.isUnlocked;
    final rarityColor = _getRarityColor(ach.rarity);

    return Card(
      elevation: ach.isUnlocked ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: ach.isUnlocked
            ? BorderSide(color: rarityColor, width: 3)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: ach.isUnlocked
              ? LinearGradient(
                  colors: [
                    rarityColor.withOpacity(0.3),
                    rarityColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: ach.isUnlocked ? null : Colors.grey.withOpacity(0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アイコン
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ach.isUnlocked
                      ? rarityColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  boxShadow: ach.isUnlocked
                      ? [
                          BoxShadow(
                            color: rarityColor.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    isSecret ? '❓' : ach.icon,
                    style: TextStyle(
                      fontSize: 40,
                      color: ach.isUnlocked ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // タイトル
              Text(
                isSecret ? '???' : ach.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ach.isUnlocked ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // レア度バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              const SizedBox(height: 8),

              // 説明
              Text(
                isSecret ? 'シークレット実績' : ach.description,
                style: TextStyle(
                  fontSize: 11,
                  color: ach.isUnlocked ? Colors.grey[600] : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (ach.isUnlocked) ...[
                const SizedBox(height: 8),
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
