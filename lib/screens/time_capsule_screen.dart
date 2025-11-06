import 'package:flutter/material.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('タイムカプセル'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lock_open), text: '公開済み'),
              Tab(icon: Icon(Icons.lock_clock), text: '未公開'),
            ],
          ),
        ),
        body: ValueListenableBuilder<Map<String, NewsInsight>>(
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
      ),
    );
  }
}
