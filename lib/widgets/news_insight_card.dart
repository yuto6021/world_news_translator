import 'package:flutter/material.dart';
import '../models/news_insight.dart';

class NewsInsightCard extends StatelessWidget {
  final NewsInsight news;
  final VoidCallback? onTap;

  const NewsInsightCard({
    super.key,
    required this.news,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: news.analysis?.getMoodColor(),
      elevation: 3,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.urlToImage != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    news.urlToImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (news.analysis != null) ...[
                    const Divider(),
                    _buildMoodIndicator(context),
                    const SizedBox(height: 8),
                    _buildKeywords(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIndicator(BuildContext context) {
    IconData moodIcon;
    String moodText;
    Color iconColor;

    switch (news.analysis?.mood.toLowerCase()) {
      case 'positive':
        moodIcon = Icons.sentiment_satisfied;
        moodText = 'ポジティブ';
        iconColor = Colors.green;
        break;
      case 'negative':
        moodIcon = Icons.sentiment_dissatisfied;
        moodText = 'ネガティブ';
        iconColor = Colors.red;
        break;
      case 'exciting':
        moodIcon = Icons.auto_awesome;
        moodText = 'エキサイティング';
        iconColor = Colors.orange;
        break;
      default:
        moodIcon = Icons.sentiment_neutral;
        moodText = '中立';
        iconColor = Colors.grey;
    }

    return Row(
      children: [
        Icon(moodIcon, color: iconColor),
        const SizedBox(width: 8),
        Text(
          moodText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: iconColor,
              ),
        ),
      ],
    );
  }

  Widget _buildKeywords(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final keyword in news.analysis?.keywords ?? [])
          Chip(
            label: Text(
              keyword,
              style: const TextStyle(fontSize: 12),
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
      ],
    );
  }
}
