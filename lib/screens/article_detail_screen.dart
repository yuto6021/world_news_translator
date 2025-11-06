import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/article.dart';
import '../services/translation_service.dart';
import '../services/app_settings_service.dart';
import '../services/time_capsule_service.dart';
import '../models/news_insight.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String? _translated;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // 自動翻訳が有効な場合のみ翻訳を行う
    if (AppSettingsService.instance.autoTranslate.value) {
      _fetchTranslation();
    } else {
      // ただし、将来切り替えた場合に対応するために listener を残しておく
      AppSettingsService.instance.autoTranslate.addListener(() {
        if (AppSettingsService.instance.autoTranslate.value &&
            _translated == null &&
            !_loading) {
          _fetchTranslation();
        }
      });
    }
  }

  Future<void> _fetchTranslation() async {
    setState(() {
      _loading = true;
    });
    final textToTranslate = (widget.article.description != null &&
            widget.article.description!.trim().isNotEmpty)
        ? widget.article.description!
        : widget.article.title;
    final t = await TranslationService.translateToJapanese(textToTranslate);
    setState(() {
      _translated = t;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('記事詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(Uri.parse(widget.article.url)),
            tooltip: '原文をブラウザで開く',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.article.url));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('記事のリンクをコピーしました')));
            },
            tooltip: 'リンクをコピー',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.article.urlToImage != null)
                Hero(
                  tag: widget.article.url,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.article.urlToImage!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (c, u) =>
                          Container(height: 220, color: Colors.grey.shade200),
                      errorWidget: (c, u, e) => Container(
                        height: 220,
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(widget.article.title,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (widget.article.description != null &&
                  widget.article.description!.isNotEmpty)
                Text(widget.article.description!),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('日本語翻訳', style: Theme.of(context).textTheme.titleMedium),
                  if (_loading) const CircularProgressIndicator(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchTranslation,
                    tooltip: '翻訳を再試行',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_translated ?? (_loading ? '翻訳中...' : '（翻訳なし）')),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  // 解禁日時を選択
                  final messenger = ScaffoldMessenger.of(context);
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date == null) return;
                  if (!mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (!mounted) return;
                  final unlock = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time?.hour ?? 12,
                    time?.minute ?? 0,
                  );
                  final insight = NewsInsight.fromArticle(widget.article);
                  await TimeCapsuleService.instance
                      .addToCapsule(insight, unlock);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('タイムカプセルに保存しました')),
                  );
                },
                icon: const Icon(Icons.hourglass_bottom),
                label: const Text('タイムカプセルに保存'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => launchUrl(Uri.parse(widget.article.url)),
        child: const Icon(Icons.open_in_new),
        tooltip: '原文をブラウザで開く',
      ),
    );
  }
}
