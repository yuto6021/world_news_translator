import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/streak_service.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  Map<DateTime, int> _data = {};
  int _consecutive = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await StreakService.instance.getRecentCounts(daysBack: 70);
    final p = await SharedPreferences.getInstance();
    setState(() {
      _data = data;
      _consecutive = p.getInt('consecutive_days') ?? 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = _data.keys.toList()..sort();
    final cols = 10;
    return Scaffold(
      appBar: AppBar(title: const Text('🔥 読書ストリーク')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text('連続日数: $_consecutive日',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final d = days[i];
                  final v = _data[d] ?? 0;
                  final c = v == 0
                      ? (isDark ? Colors.grey[800] : Colors.grey[300])
                      : Color.lerp(Colors.green[200], Colors.green[700], 0.7)!;
                  return Tooltip(
                    message: '${d.month}/${d.day}  ${v > 0 ? 'ログイン' : '未ログイン'}',
                    child: Container(
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('直近${days.length}日を表示',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
