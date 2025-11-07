import 'package:flutter/material.dart';
import 'trending_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'comments_screen.dart';
import 'time_capsule_screen.dart';
import '../utils/constants.dart';
import '../widgets/country_tab.dart';
import '../widgets/social_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // タブ数を6に変更
  }

  @override
  void dispose() {
    _tabController.dispose();
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.7), // 透明度を調整
            BlendMode.lighten,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // 背景画像（ダークモード時は非表示）
          if (!isDark) _buildBackground(),

          // メインコンテンツ
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: true,
                  pinned: true,
                  elevation: innerBoxIsScrolled ? 4 : 0,
                  backgroundColor: isDark
                      ? const Color(0xFF242424).withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      '世界のニュース',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade100 : Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [Colors.indigo.shade900, Colors.indigo.shade800]
                              : [
                                  Colors.indigo.shade400,
                                  Colors.indigo.shade300
                                ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: '検索',
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: '設定',
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor:
                        isDark ? Colors.grey.shade100 : Colors.indigo,
                    labelColor: isDark ? Colors.grey.shade100 : Colors.indigo,
                    unselectedLabelColor:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    tabs: const [
                      Tab(icon: Icon(Icons.newspaper), text: 'ニュース'),
                      Tab(icon: Icon(Icons.favorite), text: 'お気に入り'),
                      Tab(icon: Icon(Icons.chat), text: 'コメント'),
                      Tab(icon: Icon(Icons.language), text: '国別'),
                      Tab(icon: Icon(Icons.hourglass_bottom), text: 'タイムカプセル'),
                      Tab(icon: Icon(Icons.psychology), text: '知識ベース'),
                      Tab(icon: Icon(Icons.insights), text: 'インサイト'),
                    ],
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ニュースタブ
                      const TrendingScreen(),
                      // お気に入りタブ
                      const FavoritesScreen(),
                      // コメントタブ
                      const CommentsScreen(),
                      // 国別タブ
                      const CountryNewsScreen(),
                      // タイムカプセルタブ
                      const TimeCapsuleScreen(),
                      // 知識ベースタブ
                      const KnowledgeBaseScreen(),
                      // インサイトタブ
                      const InsightsScreen(),
                      // お気に入りタブ
                      const FavoritesScreen(),
                      // コメントタブ
                      const CommentsScreen(),
                      // 国別タブ
                      SingleChildScrollView(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: countryCodes.entries
                              .map((entry) => CountryTab(
                                    name: entry.key,
                                    code: entry.value,
                                  ))
                              .toList(),
                        ),
                      ),
                      // タイムカプセルタブ
                      const TimeCapsuleScreen(),
                    ],
                  ),
                ),
                const SocialFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
