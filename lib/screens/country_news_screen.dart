import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../services/translation_service.dart';
import '../widgets/news_card.dart';
import '../widgets/headline_banner.dart';
import '../models/article.dart';

class CountryNewsScreen extends StatefulWidget {
  final String countryCode;
  final String countryName;

  const CountryNewsScreen(
      {super.key, required this.countryCode, required this.countryName});

  @override
  State<CountryNewsScreen> createState() => _CountryNewsScreenState();
}

class _CountryNewsScreenState extends State<CountryNewsScreen> {
  late Future<List<Article>> _articles;
  // 翻訳済みテキストの Future（並列で取得）
  Future<List<String>>? _translationsFuture;

  @override
  void initState() {
    super.initState();
    _articles = NewsApiService.fetchArticlesByCountry(widget.countryCode);
    // 記事一覧取得後に翻訳を並列で走らせる
    _translationsFuture = _articles.then((articles) {
      // 翻訳する本文が無ければタイトルを代わりに翻訳する
      final futures = articles.map((a) {
        final textForTranslation =
            (a.description != null && a.description!.trim().isNotEmpty)
                ? a.description!
                : a.title;
        return TranslationService.translateToJapanese(textForTranslation);
      }).toList();
      return Future.wait(futures);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.countryName.toUpperCase()}のニュース')),
      body: FutureBuilder<List<Article>>(
        future: _articles,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('記事が見つかりませんでした'));
          }

          final articles = snapshot.data!;
          // 翻訳を待つ FutureBuilder
          return FutureBuilder<List<String>>(
            future: _translationsFuture,
            builder: (context, tSnapshot) {
              final translations = tSnapshot.data;
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _articles = NewsApiService.fetchArticlesByCountry(
                        widget.countryCode);
                    _translationsFuture = _articles.then((articles) {
                      final futures = articles.map((a) {
                        final textForTranslation = (a.description != null &&
                                a.description!.trim().isNotEmpty)
                            ? a.description!
                            : a.title;
                        return TranslationService.translateToJapanese(
                            textForTranslation);
                      }).toList();
                      return Future.wait(futures);
                    });
                  });
                  await _articles;
                  await (_translationsFuture ?? Future.value([]));
                },
                child: ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // 先頭記事をバナー表示
                      final firstArticle = articles[0];
                      final firstTranslation =
                          translations != null && translations.isNotEmpty
                              ? translations[0]
                              : (tSnapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? '翻訳中...'
                                  : '（翻訳なし）');
                      return HeadlineBanner(
                          article: firstArticle,
                          translatedText: firstTranslation);
                    }
                    // items after the banner should be different articles
                    final article = articles[index];
                    final translated = (translations != null &&
                            translations.length > index)
                        ? translations[index]
                        : (tSnapshot.connectionState == ConnectionState.waiting
                            ? '翻訳中...'
                            : '（翻訳なし）');
                    return NewsCard(
                        article: article, translatedText: translated);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
