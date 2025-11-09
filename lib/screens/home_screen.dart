import 'package:flutter/material.dart';
import 'dart:ui';
import 'trending_screen.dart';
import 'favorites_screen.dart';
import 'comments_screen.dart';
import 'time_capsule_screen.dart';
import 'weather_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'wikipedia_search_screen.dart';
import '../widgets/country_tab.dart';
import '../widgets/social_footer.dart';

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
    _TabInfo(Icons.wb_sunny, '天気', '世界の天気情報'),
    _TabInfo(Icons.favorite, 'お気に入り', 'お気に入り記事一覧'),
    _TabInfo(Icons.chat, 'コメント', 'コメント一覧'),
    _TabInfo(Icons.book, 'Wikipedia', 'Wikipedia検索'),
    _TabInfo(Icons.hourglass_bottom, 'タイムカプセル', 'タイムカプセル一覧'),
  ];

  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
            // 背景グラデーション
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.black.withOpacity(scrolled ? 0.7 : 0.3),
                          Colors.indigo.shade900
                              .withOpacity(scrolled ? 0.6 : 0.2),
                        ]
                      : [
                          Colors.white.withOpacity(scrolled ? 0.8 : 0.4),
                          Colors.indigo.shade50
                              .withOpacity(scrolled ? 0.7 : 0.3),
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
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Stack(
        children: [
          _buildBackground(isDark),
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: _buildFlexibleSpace(innerBoxIsScrolled, isDark),
                title: AnimatedOpacity(
                  opacity: innerBoxIsScrolled ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '世界のニュース',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade100 : Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchScreen()),
                    ),
                    tooltip: '検索',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    ),
                    tooltip: 'アプリ設定',
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: isDark ? Colors.grey.shade100 : Colors.indigo,
                  indicatorWeight: 3,
                  labelColor: isDark ? Colors.grey.shade100 : Colors.indigo,
                  unselectedLabelColor:
                      isDark ? Colors.grey.shade400 : Colors.grey.shade700,
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
            body: TabBarView(
              controller: _tabController,
              children: [
                const TrendingScreen(),
                Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.language,
                                    color: Theme.of(context).primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '国別ニュース',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Column(
                                children: [
                                  for (var i = 0; i < 5; i++)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: SizedBox(
                                                height: 80,
                                                child: Semantics(
                                                  label: [
                                                        '日本',
                                                        'イギリス',
                                                        'ドイツ',
                                                        '韓国',
                                                        'オーストラリア'
                                                      ][i] +
                                                      'のニュース',
                                                  child: CountryTab(
                                                    name: [
                                                      '日本',
                                                      'イギリス',
                                                      'ドイツ',
                                                      '韓国',
                                                      'オーストラリア'
                                                    ][i],
                                                    code: [
                                                      'jp',
                                                      'gb',
                                                      'de',
                                                      'kr',
                                                      'au'
                                                    ][i],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8),
                                              child: SizedBox(
                                                height: 80,
                                                child: Semantics(
                                                  label: [
                                                        'アメリカ',
                                                        'フランス',
                                                        '中国',
                                                        'インド',
                                                        'ブラジル'
                                                      ][i] +
                                                      'のニュース',
                                                  child: CountryTab(
                                                    name: [
                                                      'アメリカ',
                                                      'フランス',
                                                      '中国',
                                                      'インド',
                                                      'ブラジル'
                                                    ][i],
                                                    code: [
                                                      'us',
                                                      'fr',
                                                      'cn',
                                                      'in',
                                                      'br'
                                                    ][i],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const WeatherScreen(),
                const FavoritesScreen(),
                const CommentsScreen(),
                const WikipediaSearchScreen(),
                const TimeCapsuleScreen(),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SocialFooter(),
          ),
        ],
      ),
    );
  }
}
