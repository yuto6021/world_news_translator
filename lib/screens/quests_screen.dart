import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../services/quest_service.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen>
    with SingleTickerProviderStateMixin {
  QuestType? _filter;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    QuestService.checkDailyReset();
    QuestService.checkWeeklyReset();
    _future = QuestService.getQuestList();
  }

  void _reload() {
    setState(() {
      _future = QuestService.getQuestList(type: _filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クエスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('すべて'),
                selected: _filter == null,
                onSelected: (_) {
                  setState(() => _filter = null);
                  _reload();
                },
              ),
              ChoiceChip(
                label: const Text('デイリー'),
                selected: _filter == QuestType.daily,
                onSelected: (_) {
                  setState(() => _filter = QuestType.daily);
                  _reload();
                },
              ),
              ChoiceChip(
                label: const Text('ウィークリー'),
                selected: _filter == QuestType.weekly,
                onSelected: (_) {
                  setState(() => _filter = QuestType.weekly);
                  _reload();
                },
              ),
              ChoiceChip(
                label: const Text('アチーブメント'),
                selected: _filter == QuestType.achievement,
                onSelected: (_) {
                  setState(() => _filter = QuestType.achievement);
                  _reload();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('表示できるクエストがありません'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final quest = list[i]['quest'] as Quest;
                    final progress = list[i]['progress'] as QuestProgress;
                    final percentage = list[i]['percentage'] as num;
                    return _QuestCard(
                      quest: quest,
                      progress: progress,
                      percentage: percentage.toDouble(),
                      onClaimed: _reload,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final QuestProgress progress;
  final double percentage;
  final VoidCallback onClaimed;

  const _QuestCard({
    required this.quest,
    required this.progress,
    required this.percentage,
    required this.onClaimed,
  });

  Color _typeColor(QuestType t) {
    switch (t) {
      case QuestType.daily:
        return Colors.lightBlue;
      case QuestType.weekly:
        return Colors.indigo;
      case QuestType.achievement:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canClaim = progress.completed && !progress.rewardClaimed;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor(quest.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    quest.type == QuestType.daily
                        ? 'デイリー'
                        : quest.type == QuestType.weekly
                            ? 'ウィークリー'
                            : 'アチーブメント',
                    style: TextStyle(
                      color: _typeColor(quest.type),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quest.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (progress.completed)
                  Icon(
                    progress.rewardClaimed ? Icons.verified : Icons.check,
                    color: progress.rewardClaimed ? Colors.green : Colors.amber,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(quest.description,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: _typeColor(quest.type),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.currentValue}/${quest.targetValue}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (quest.coinReward > 0)
                        _rewardChip(
                            Icons.monetization_on, 'x${quest.coinReward}'),
                      if (quest.expReward > 0)
                        _rewardChip(
                            Icons.auto_awesome, 'EXP x${quest.expReward}'),
                      ...quest.itemRewards.entries.map((e) => _rewardChip(
                          Icons.inventory_2, '${e.key} x${e.value}')),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: canClaim
                      ? () async {
                          final res = await QuestService.claimReward(quest.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] as String)),
                            );
                          }
                          onClaimed();
                        }
                      : null,
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('報酬を受け取る'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _rewardChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}
