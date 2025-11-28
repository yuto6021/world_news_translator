import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'trending_screen.dart';
import 'favorites_screen.dart';
import 'comments_screen.dart';
import 'time_capsule_screen.dart';
import 'registration_screen.dart';
import 'weather_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'markets_screen.dart';
import 'map_news_screen.dart';
import 'country_news_screen.dart';
import 'swipe_news_screen.dart';
import 'stats_screen.dart';
import 'game_screen.dart';
import 'gacha_screen.dart';
import 'achievement_collection_screen.dart';
import 'shop_screen.dart';
import 'user_profile_screen.dart';
import 'pet_care_screen_full.dart';
import '../models/country.dart';
import '../services/availability_service.dart';
import '../widgets/country_tab_enhanced.dart';
import '../widgets/social_footer.dart';
import '../widgets/breaking_news_banner.dart';
import '../widgets/keyboard_shortcuts.dart';

class _TabInfo {
  final IconData icon;
  final String label;
  final String semanticLabel;

  const _TabInfo(this.icon, this.label, this.semanticLabel);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    _TabInfo(Icons.newspaper, 'ニュース', 'トレンドニュース一覧'),
    _TabInfo(Icons.language, '国別', '国別ニュース'),
    _TabInfo(Icons.swipe, 'スワイプ', 'スワイプ可能ニュースカード'),
    _TabInfo(Icons.analytics, '統計', '読書統計ダッシュボード'),
    _TabInfo(Icons.videogame_asset, 'ゲーム', 'ミニゲームで暇つぶし'),
    _TabInfo(Icons.show_chart, 'マーケット', '為替・暗号資産の簡易チャート'),
    _TabInfo(Icons.public, '地図', '地域グリッドから国別ニュースへ'),
    _TabInfo(Icons.wb_sunny, '天気', '世界の天気情報'),
    _TabInfo(Icons.favorite, 'お気に入り', 'お気に入り記事一覧'),
    _TabInfo(Icons.chat, 'コメント', 'コメント一覧'),
    _TabInfo(Icons.book, 'Wikipedia', 'Wikipedia検索'),
    _TabInfo(Icons.hourglass_bottom, 'タイムカプセル', 'タイムカプセル一覧'),
    _TabInfo(Icons.account_circle, 'プロフィール', 'ユーザープロフィールとバッジ'),
    _TabInfo(Icons.person_add, '会員登録', 'アカウント作成'),
  ];

  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showTopFab = false;
  List<Country> _availableCountries = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // タブ変更を監視して訪問記録
    _tabController.addListener(_onTabChanged);
    // 利用可能な国リストをロード
    AvailabilityService.getAvailableCountries(includeJapan: true).then((list) {
      if (mounted) setState(() => _availableCountries = list);
    });
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.offset;
      final shouldShow = offset > 300; // スクロール方向関係なく300px以上で表示
      if (shouldShow != _showTopFab) {
        setState(() => _showTopFab = shouldShow);
      }
    });
  }

  void _onTabChanged() async {
    if (!_tabController.indexIsChanging) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabIndex = _tabController.index;
      final visitedTabs = prefs.getStringList('visited_tabs') ?? [];
      final tabKey = 'tab_$tabIndex';
      if (!visitedTabs.contains(tabKey)) {
        visitedTabs.add(tabKey);
        await prefs.setStringList('visited_tabs', visitedTabs);
      }
    } catch (_) {
      // エラー無視
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBackground(bool isDark) {
    // assets/images/background.jpg を背景に使用、視認性のためにグラデーションオーバーレイを追加
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 画像読み込みエラー時はグラデーション背景へフォールバック
            final colors = isDark
                ? [
                    const Color(0xFF0B1020),
                    const Color(0xFF101a3a),
                    const Color(0xFF0b1020),
                  ]
                : [
                    const Color(0xFFE8ECFF),
                    const Color(0xFFDDE7FF),
                    const Color(0xFFF5F7FF),
                  ];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            );
          },
        ),
        // 視認性確保のためのグラデーションオーバーレイ
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.55),
                    ]
                  : [
                      Colors.white.withOpacity(0.75),
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0.65),
                    ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlexibleSpace(bool scrolled, bool isDark) {
    // スクロール位置に応じて装飾とサブタイトルの表示/非表示を制御
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: scrolled ? 10 : 0,
          sigmaY: scrolled ? 10 : 0,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景グラデーション（透明度を上げて可読性向上）
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.black.withOpacity(scrolled ? 0.92 : 0.5),
                          Colors.indigo.shade900
                              .withOpacity(scrolled ? 0.88 : 0.4),
                        ]
                      : [
                          Colors.white.withOpacity(scrolled ? 0.95 : 0.6),
                          Colors.indigo.shade50
                              .withOpacity(scrolled ? 0.92 : 0.5),
                        ],
                ),
              ),
            ),
            // 装飾: 斜めに配置された半透明シェイプ群
            Positioned(
              top: -40,
              left: -30,
              child: Transform.rotate(
                angle: 0.35,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      colors: [
                        (isDark ? Colors.indigo : Colors.indigoAccent)
                            .withOpacity(0.25),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: -50,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark
                                ? Colors.indigo.shade700
                                : Colors.indigo.shade200)
                            .withOpacity(0.30),
                        Colors.transparent,
                      ],
                      radius: 0.85,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -60,
              child: Transform.rotate(
                angle: 0.15,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    gradient: LinearGradient(
                      colors: [
                        (isDark
                                ? Colors.indigo.shade800
                                : Colors.indigo.shade300)
                            .withOpacity(0.18),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            // キャッチコピーはヘッダーから除去（Footerで表示）
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KeyboardShortcuts(
      onSearch: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      ),
      onRefresh: () {
        // 現在のタブを再読み込み（setStateで再構築）
        setState(() {});
      },
      onSettings: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ),
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
        body: Stack(
          children: [
            _buildBackground(isDark),
            Column(
              children: [
                // 速報バナーを固定位置に配置
                const BreakingNewsBanner(),
                Expanded(
                  child: NestedScrollView(
                    controller: _scrollController,
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        expandedHeight: 160,
                        floating: false,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        flexibleSpace:
                            _buildFlexibleSpace(innerBoxIsScrolled, isDark),
                        title: AnimatedOpacity(
                          opacity: innerBoxIsScrolled ? 1.0 : 0.9,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            '世界のニュース',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey.shade100 : Colors.indigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        centerTitle: true,
                        actions: [
                          // より目立つ検索ボタン（サイズ＋背景色）
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            child: Material(
                              color: isDark
                                  ? Colors.indigo.shade700.withOpacity(0.3)
                                  : Colors.indigo.shade100.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SearchScreen()),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search,
                                          size: 22,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.indigo.shade700),
                                      const SizedBox(width: 6),
                                      Text(
                                        '検索',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.indigo.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 実績ガチャボタン
                          IconButton(
                            icon: const Icon(Icons.casino),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GachaScreen(),
                              ),
                            ),
                            tooltip: '実績ガチャ',
                          ),
                          // 実績図鑑ボタン
                          IconButton(
                            icon: const Icon(Icons.menu_book),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AchievementCollectionScreen(),
                              ),
                            ),
                            tooltip: '実績図鑑',
                          ),
                          // ショップボタン
                          IconButton(
                            icon: const Icon(Icons.shopping_bag),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ShopScreen(),
                              ),
                            ),
                            tooltip: 'ショップ',
                          ),
                          // 設定ボタン
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SettingsScreen()),
                            ),
                            tooltip: 'アプリ設定',
                          ),
                          // ゲーム起動（右上）
                          IconButton(
                            icon: const Icon(Icons.sports_esports),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PetCareScreenFull(),
                              ),
                            ),
                            tooltip: 'ペットケア',
                          ),
                          const SizedBox(width: 8),
                        ],
                        bottom: TabBar(
                          controller: _tabController,
                          indicatorColor:
                              isDark ? Colors.grey.shade100 : Colors.indigo,
                          indicatorWeight: 3,
                          labelColor:
                              isDark ? Colors.grey.shade100 : Colors.indigo,
                          unselectedLabelColor: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
                          tabs: _tabs.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final tab = entry.value;
                            return AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, child) {
                                final isSelected = _tabController.index == idx;
                                return Transform.scale(
                                  scale: isSelected ? 1.1 : 1.0,
                                  child: Tooltip(
                                    message: tab.semanticLabel,
                                    child: Tab(
                                      icon: Icon(
                                        tab.icon,
                                        size: isSelected ? 26 : 22,
                                      ),
                                      text: tab.label,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    body: Column(
                      children: [
                        // タブコンテンツ
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            // _tabs: ニュース, 国別, スワイプ, 統計, マーケット, 地図, 天気, お気に入り, コメント, Wikipedia, タイムカプセル
                            children: [
                              // ニュース
                              const TrendingScreen(),
                              // 国別
                              Scrollbar(
                                child: ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 80),
                                  children: [
                                    Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.language,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  size: 28,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '国別ニュース',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            _availableCountries.isEmpty
                                                ? const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(16.0),
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  )
                                                : Wrap(
                                                    spacing: 8,
                                                    runSpacing: 12,
                                                    children:
                                                        _availableCountries
                                                            .map((c) =>
                                                                CountryTabEnhanced(
                                                                  name: c.name,
                                                                  code: c.code,
                                                                  onTap: () {
                                                                    Navigator
                                                                        .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                CountryNewsScreen(
                                                                          countryName:
                                                                              c.name,
                                                                          countryCode:
                                                                              c.code,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ))
                                                            .toList(),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // スワイプ
                              const SwipeNewsScreen(),
                              // 統計
                              const StatsScreen(),
                              // ゲーム
                              const GameScreen(),
                              // マーケット
                              const MarketsScreen(),
                              // 地図
                              const MapNewsScreen(),
                              // 天気
                              const WeatherScreen(),
                              const FavoritesScreen(),
                              const CommentsScreen(),
                              const PetCareScreenFull(),
                              const TimeCapsuleScreen(),
                              // プロフィール
                              const UserProfileScreen(),
                              // 会員登録
                              const RegistrationScreen(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SocialFooter(),
            ),
            // 先頭へ戻る FAB（スクロール方向が forward かつ一定オフセット以上で表示）
            if (_showTopFab)
              Positioned(
                right: 16,
                bottom: 90,
                child: FloatingActionButton(
                  heroTag: 'toTopFab',
                  tooltip: '先頭へ',
                  elevation: 8,
                  onPressed: () {
                    _scrollController.animateTo(0,
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOut);
                  },
                  child: const Icon(Icons.vertical_align_top),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
