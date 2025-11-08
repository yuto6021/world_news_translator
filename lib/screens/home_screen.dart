import 'package:flutter/material.dart';
import 'trending_screen.dart';
import 'favorites_screen.dart';
import 'comments_screen.dart';
import 'time_capsule_screen.dart';
import 'weather_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
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
    // 背景はシンプルに白/ダークの無地に戻す（視認性優先）。
    return Container(color: isDark ? Colors.black : Colors.white);
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
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: innerBoxIsScrolled ? 2 : 0,
                backgroundColor: Colors.transparent,
                title: Text(
                  '世界のニュース',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade100 : Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
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
                  labelColor: isDark ? Colors.grey.shade100 : Colors.indigo,
                  unselectedLabelColor:
                      isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: _tabs
                      .map((tab) => Tooltip(
                            message: tab.semanticLabel,
                            child: Tab(
                              icon: Icon(tab.icon),
                              text: tab.label,
                            ),
                          ))
                      .toList(),
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
