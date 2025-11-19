import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../services/news_api_service.dart';
import '../services/translation_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// スワイプ可能ニュースカード画面 (Tinder風インタラクション)
class SwipeNewsScreen extends StatefulWidget {
  const SwipeNewsScreen({super.key});

  @override
  State<SwipeNewsScreen> createState() => _SwipeNewsScreenState();
}

class _SwipeNewsScreenState extends State<SwipeNewsScreen>
    with TickerProviderStateMixin {
  List<Article> _articles = [];
  bool _loading = true;
  int _currentIndex = 0;

  // スワイプアニメーション用
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeInOutCubic),
    );
    _loadArticles();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() => _loading = true);
    try {
      final articles = await NewsApiService.fetchTrendingArticles();
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _currentIndex = 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadArticles();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.25; // 閾値を下げてスワイプしやすく

    if (_dragOffset.dx.abs() > threshold) {
      // スワイプ完了 → 次のカードへ（加速アニメーション）
      final direction = _dragOffset.dx > 0 ? 1.0 : -1.0;
      _swipeAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset(direction * screenWidth * 2.5, _dragOffset.dy * 1.5),
      ).animate(
        CurvedAnimation(parent: _swipeController, curve: Curves.easeInCubic),
      );
      _swipeController.forward(from: 0).then((_) {
        setState(() {
          _currentIndex++;
          _dragOffset = Offset.zero;
          _isDragging = false;
        });
        _swipeController.reset();
        _recordSwipe();
      });
    } else {
      // 元に戻す（バウンスアニメーション）
      _swipeAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _swipeController, curve: Curves.elasticOut),
      );
      _swipeController.forward(from: 0).then((_) {
        setState(() {
          _dragOffset = Offset.zero;
          _isDragging = false;
        });
        _swipeController.reset();
      });
    }
  }

  void _skipCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-screenWidth * 2.5, -100),
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeInCubic),
    );
    _swipeController.forward(from: 0).then((_) {
      setState(() => _currentIndex++);
      _swipeController.reset();
      _recordSwipe();
    });
  }

  void _likeCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(screenWidth * 2.5, -100),
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeInCubic),
    );
    _swipeController.forward(from: 0).then((_) {
      setState(() => _currentIndex++);
      _swipeController.reset();
      _recordSwipe();
    });
  }

  Future<void> _recordSwipe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final swipeCount = prefs.getInt('swipe_count') ?? 0;
      await prefs.setInt('swipe_count', swipeCount + 1);
    } catch (_) {
      // エラー無視
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.article_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('ニュースがありません'),
                  const SizedBox(height: 8),
                  const Text('下に引っ張って更新', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadArticles,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_currentIndex >= _articles.length) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('すべてのカードを見ました！',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('下に引っ張って更新', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _loading = true;
                      });
                      _loadArticles();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('もう一度読み込む'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final article = _articles[_currentIndex];
    final nextArticle = _currentIndex + 1 < _articles.length
        ? _articles[_currentIndex + 1]
        : null;

    return Stack(
      children: [
        // 背景 (次のカード)
        if (nextArticle != null)
          Center(
            child: _NewsCard(article: nextArticle, opacity: 0.5, scale: 0.92),
          ),
        // メインカード
        Center(
          child: AnimatedBuilder(
            animation: _swipeController,
            builder: (context, child) {
              final offset = _isDragging
                  ? _dragOffset
                  : (_swipeController.isAnimating
                      ? _swipeAnimation.value
                      : Offset.zero);
              final rotation =
                  offset.dx / MediaQuery.of(context).size.width * 0.4;
              // スワイプ方向にスケール変化を追加
              final scale = 1.0 -
                  (offset.dx.abs() / MediaQuery.of(context).size.width * 0.1);
              return Transform.scale(
                scale: scale.clamp(0.85, 1.0),
                child: Transform.translate(
                  offset: offset,
                  child: Transform.rotate(
                    angle: rotation,
                    child: child,
                  ),
                ),
              );
            },
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: _NewsCard(article: article),
            ),
          ),
        ),
        // ボタン
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: Colors.red,
                onPressed: _skipCard,
              ),
              const SizedBox(width: 50),
              _ActionButton(
                icon: Icons.favorite,
                color: Colors.pink,
                onPressed: _likeCard,
              ),
            ],
          ),
        ),
        // プログレスバー
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _articles.length,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Article article;
  final double opacity;
  final double scale;

  const _NewsCard({
    required this.article,
    this.opacity = 1.0,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.80,
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 画像背景
                if (article.urlToImage != null &&
                    article.urlToImage!.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      article.urlToImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? Colors.grey[850] : Colors.grey[300],
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      color: isDark ? Colors.grey[850] : Colors.grey[300],
                    ),
                  ),
                // グラデーションオーバーレイ
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // コンテンツ
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: TranslationService.translateToJapanese(
                              article.title),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? article.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        if (article.description != null &&
                            article.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          FutureBuilder<String>(
                            future: TranslationService.translateToJapanese(
                                article.description!),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? article.description!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 3)
                                  ],
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.article,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Uri.parse(article.url).host,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(article.url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new,
                                  color: Colors.white, size: 16),
                              label: const Text('記事を読む',
                                  style: TextStyle(color: Colors.white)),
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
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.white,
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
