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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('世界のニュースを日本語で読む'),
        actions: [
          IconButton(
            tooltip: '検索',
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.newspaper), text: 'ニュース'),
            Tab(icon: Icon(Icons.favorite), text: 'お気に入り'),
            Tab(icon: Icon(Icons.chat), text: 'コメント'),
            Tab(icon: Icon(Icons.language), text: '国別'),
            Tab(icon: Icon(Icons.hourglass_bottom), text: 'タイムカプセル'),
          ],
        ),
      ),
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
    );
  }
}
