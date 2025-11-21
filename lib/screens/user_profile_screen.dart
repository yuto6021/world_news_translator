import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/achievements_service.dart';
import '../models/achievement.dart';
import 'dart:convert';

/// ユーザープロフィール画面（実績バッジ管理）
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _selectedBadge = '🎖️'; // デフォルトアイコン
  String _userName = 'ニュース読者';
  List<Achievement> _unlockedAchievements = [];
  List<String> _unlockedBadges = []; // バッジアイコンリスト
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'ニュース読者';
    final selectedBadge = prefs.getString('profile_badge') ?? '🎖️';

    final allAchievements = await AchievementsService.getAll();
    final unlocked = allAchievements.where((a) => a.isUnlocked).toList();

    // バッジリストを読み込み（実績とは別）
    final badgeList = prefs.getStringList('unlocked_badges') ?? [];

    // 統計データ読み込み
    final totalReads = prefs.getInt('total_reads') ?? 0;
    final totalPlayTime = prefs.getInt('total_play_time_seconds') ?? 0;
    final streakDays = prefs.getInt('login_streak') ?? 0;
    final favorites = prefs.getStringList('favorites')?.length ?? 0;
    final totalCoins = prefs.getInt('game_total_coins') ?? 0;
    final gachaCount = prefs.getInt('gacha_total_count') ?? 0;
    final shopPoints = prefs.getInt('shop_points') ?? 0;

    setState(() {
      _userName = userName;
      _selectedBadge = selectedBadge;
      _unlockedAchievements = unlocked;
      _unlockedBadges = badgeList;
      _stats = {
        'totalReads': totalReads,
        'totalPlayTime': totalPlayTime,
        'streakDays': streakDays,
        'favorites': favorites,
        'totalCoins': totalCoins,
        'gachaCount': gachaCount,
        'shopPoints': shopPoints,
        'achievements': unlocked.length,
      };
    });
  }

  Future<void> _changeBadge(String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_badge', emoji);
    setState(() {
      _selectedBadge = emoji;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('バッジを $emoji に変更しました')),
    );
  }

  Future<void> _changeName() async {
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ニックネーム変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ニックネーム',
            hintText: '15文字以内',
          ),
          maxLength: 15,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('変更'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', result);
      setState(() {
        _userName = result;
      });
    }
  }

  void _showBadgeSelector() {
    final allBadges = ['🎖️', ..._unlockedBadges]; // デフォルト + 解除済みバッジ
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'バッジを選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: allBadges.length,
                itemBuilder: (ctx, index) {
                  final badge = allBadges[index];
                  final label = index == 0 ? 'デフォルト' : 'バッジ${index}';
                  return _buildBadgeItem(badge, label, index == 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(String emoji, String label, bool isDefault) {
    final isSelected = _selectedBadge == emoji;
    return InkWell(
      onTap: () {
        _changeBadge(emoji);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.withOpacity(0.2) : null,
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.indigo : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completionRate = _unlockedAchievements.isEmpty
        ? 0.0
        : (_stats['achievements'] ?? 0) / 150 * 100;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // 下部余白を追加
        child: Column(
          children: [
            // プロフィールヘッダー
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade700,
                      Colors.indigo.shade500,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // アイコン
                    GestureDetector(
                      onTap: _showBadgeSelector,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _selectedBadge,
                                style: const TextStyle(fontSize: 50),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ユーザー名
                    GestureDetector(
                      onTap: _changeName,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.edit,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 実績達成率
                    Text(
                      '実績コンプリート率: ${completionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 統計カード
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          '統計情報',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildStatRow('📖 記事閲覧数', '${_stats['totalReads'] ?? 0} 記事'),
                    _buildStatRow(
                      '⏱️ プレイ時間',
                      '${((_stats['totalPlayTime'] ?? 0) / 60).toStringAsFixed(0)} 分',
                    ),
                    _buildStatRow('🔥 連続ログイン', '${_stats['streakDays'] ?? 0} 日'),
                    _buildStatRow('❤️ お気に入り', '${_stats['favorites'] ?? 0} 件'),
                    _buildStatRow('🪙 累計コイン', '${_stats['totalCoins'] ?? 0}'),
                    _buildStatRow('🎰 ガチャ回数', '${_stats['gachaCount'] ?? 0} 回'),
                    _buildStatRow('⭐ ショップポイント', '${_stats['shopPoints'] ?? 0} pt'),
                    _buildStatRow(
                      '🏆 解除実績',
                      '${_stats['achievements'] ?? 0} / 150',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 獲得バッジコレクション（統計タブで獲得）
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.stars, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          '獲得バッジコレクション',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_unlockedBadges.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'まだバッジを獲得していません\n統計タブでバッジを集めよう！',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _unlockedBadges.map((badge) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                badge,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 解除済み実績一覧
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          '解除済み実績',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_unlockedAchievements.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'まだ実績を解除していません\n色々な活動で実績を解除しよう！',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _unlockedAchievements.map((ach) {
                          return Tooltip(
                            message: '${ach.title}\n${ach.description}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getRarityColor(ach.rarity).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRarityColor(ach.rarity),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  ach.icon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ヒント
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'アイコンをタップしてバッジを変更できます！\n実績を解除して新しいバッジを集めよう！',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
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
}
