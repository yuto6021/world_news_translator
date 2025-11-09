import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_api_service.dart';
import '../services/translation_service.dart';

class DigestScreen extends StatefulWidget {
  const DigestScreen({super.key});

  @override
  State<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<DigestScreen> {
  final _newsService = NewsApiService();
  List<Article>? _topArticles;
  String? _digest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDigest();
  }

  Future<void> _loadDigest() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // トップニュースを取得
      final articles = await _newsService.getTopHeadlines();
      if (!mounted) return;
      setState(() => _topArticles = articles);

      // ダイジェストを生成（実際のAI要約ロジックはここに実装）
      final topics = articles.take(5).map((a) => a.title).join("\n");
      final digest = await _generateDigest(topics);
      if (!mounted) return;
      setState(() => _digest = digest);
    } catch (e) {
      if (!mounted) return;
      setState(() => _digest = "ダイジェストの生成に失敗しました。");
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<String> _generateDigest(String topics) async {
    // TODO: 実際のAI要約ロジックを実装
    // 例: OpenAI APIやその他の要約APIを使用
    return """
【今日のニュースまとめ】

$topics

上記のニュースを基に、以下のポイントに注目が集まっています：
• 国際情勢の変化と各国の対応
• 経済動向と市場への影響
• 科学技術の進展と社会への影響

※ このダイジェストは自動生成されています。
    """;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '今日のダイジェスト',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadDigest,
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    _digest ?? 'データを読み込めませんでした',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          if (_topArticles != null) ...[
            const SizedBox(height: 24),
            Text(
              '関連ニュース',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._topArticles!.take(5).map((article) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(article.title),
                    subtitle: Text(article.description ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // 記事詳細への遷移
                    },
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
