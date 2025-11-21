import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../models/article.dart';
import 'fx_ticker.dart';

/// トップページ用の速報バナー（最新ニュースのタイトルが横流れ）
class BreakingNewsBanner extends StatefulWidget {
  const BreakingNewsBanner({super.key});

  @override
  State<BreakingNewsBanner> createState() => _BreakingNewsBannerState();
}

class _BreakingNewsBannerState extends State<BreakingNewsBanner> {
  List<Article> _headlines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHeadlines();
  }

  Future<void> _loadHeadlines() async {
    try {
      final articles = await NewsApiService.fetchTrendingArticles();
      if (!mounted) return;
      setState(() {
        _headlines = articles.take(8).toList(); // 上位8件
        _loading = false;
      });
      if (articles.isEmpty) {
        print(
            '[BreakingNewsBanner] WARNING: fetchTrendingArticles returned empty');
      }
    } catch (e) {
      print('[BreakingNewsBanner] ERROR: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.indigo.shade900, Colors.indigo.shade800]
                : [Colors.indigo.shade700, Colors.indigo.shade800],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.7)),
            ),
          ),
        ),
      );
    }

    if (_headlines.isEmpty) {
      // 空でも最低限のプレースホルダーを表示（完全非表示を避ける）
      return Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.indigo.shade900, Colors.indigo.shade800]
                : [Colors.indigo.shade700, Colors.indigo.shade800],
          ),
        ),
        child: const Center(
          child: Text(
            '速報取得中またはレート制限中...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.indigo.shade900, Colors.indigo.shade800]
              : [Colors.indigo.shade700, Colors.indigo.shade800],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 固定の速報ラベル
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '速報',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // スクロールするニュース
              Positioned(
                left: 90,
                right: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 全ニュースを1つの文字列として結合
                        final newsText =
                            _headlines.map((a) => '● ${a.title}').join('     ');

                        return FxTicker(
                          duration: const Duration(seconds: 80),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: Text(
                              newsText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
