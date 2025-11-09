import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/news_insight.dart';
import '../services/time_capsule_service.dart';
import '../widgets/news_insight_card.dart';

class TimeCapsuleScreen extends StatelessWidget {
  const TimeCapsuleScreen({super.key});

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '残り${duration.inDays}日';
    }
    if (duration.inHours > 0) {
      return '残り${duration.inHours}時間';
    }
    if (duration.inMinutes > 0) {
      return '残り${duration.inMinutes}分';
    }
    return 'まもなく公開';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('タイムカプセル'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lock_open), text: '公開済み'),
              Tab(icon: Icon(Icons.lock_clock), text: '未公開'),
            ],
          ),
        ),
        body: Stack(
          children: [
            _BackgroundLayer(isDark: isDark),
            ValueListenableBuilder<Map<String, NewsInsight>>(
          valueListenable: TimeCapsuleService.instance.capsules,
          builder: (context, capsules, _) {
            final unlockedNews = TimeCapsuleService.instance.getUnlockedNews();
            final lockedNews = TimeCapsuleService.instance.getLockedNews();

            return TabBarView(
              children: [
                // 公開済みタブ
                unlockedNews.isEmpty
                    ? const Center(
                        child: Text('公開された記事はありません'),
                      )
                    : ListView.builder(
                        itemCount: unlockedNews.length,
                        itemBuilder: (context, index) {
                          final news = unlockedNews[index];
                          return Dismissible(
                            key: ValueKey(news.url),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              TimeCapsuleService.instance
                                  .removeFromCapsule(news.url);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('記事を削除しました'),
                                ),
                              );
                            },
                            child: NewsInsightCard(news: news),
                          );
                        },
                      ),

                // 未公開タブ
                lockedNews.isEmpty
                    ? const Center(
                        child: Text('未公開の記事はありません'),
                      )
                    : ListView.builder(
                        itemCount: lockedNews.length,
                        itemBuilder: (context, index) {
                          final news = lockedNews[index];
                          final timeLeft = TimeCapsuleService.instance
                              .getTimeUntilUnlock(news);

                          return Stack(
                            children: [
                              Opacity(
                                opacity: 0.6,
                                child: NewsInsightCard(news: news),
                              ),
                              Positioned.fill(
                                child: Card(
                                  margin: const EdgeInsets.all(8),
                                  color: Colors.black54,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lock_clock,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatDuration(timeLeft!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ],
            );
          },
        ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  final bool isDark;
  const _BackgroundLayer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0B1020), const Color(0xFF101a3a)]
                    : [const Color(0xFFE8ECFF), const Color(0xFFDDE7FF)],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.5),
                    ]
                  : [
                      Colors.white.withOpacity(0.75),
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0.65),
                    ],
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}
