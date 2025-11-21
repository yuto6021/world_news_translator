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
  List<DateTime> _daysOrdered = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await StreakService.instance.getRecentCounts(daysBack: 70);
    final p = await SharedPreferences.getInstance();

    // 直近70日を対象に、月曜始まりの7列グリッドに整列
    final keys = data.keys.toList()..sort();
    List<DateTime> ordered = [];
    if (keys.isNotEmpty) {
      final start = keys.first;
      final startWeekday = start.weekday; // 1=Mon .. 7=Sun
      final padLeft = (startWeekday + 6) % 7; // Mon->0 .. Sun->6
      for (int i = -padLeft; i < 70; i++) {
        ordered.add(DateTime(start.year, start.month, start.day)
            .add(Duration(days: i)));
      }
    }

    setState(() {
      _data = data;
      _daysOrdered = ordered;
      _consecutive = p.getInt('consecutive_days') ?? 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days =
        _daysOrdered.isNotEmpty ? _daysOrdered : (_data.keys.toList()..sort());
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
            // 曜日ヘッダ（Mon~Sun）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _WeekdayLabel('月'),
                _WeekdayLabel('火'),
                _WeekdayLabel('水'),
                _WeekdayLabel('木'),
                _WeekdayLabel('金'),
                _WeekdayLabel('土'),
                _WeekdayLabel('日'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final d = days[i];
                  final v = _data[d] ?? 0;
                  final c = v == 0
                      ? (isDark ? Colors.grey[900] : Colors.grey[200])
                      : Colors.green[400];
                  return Tooltip(
                    message: '${d.month}/${d.day}  ${v > 0 ? '読了/起動あり' : 'なし'}',
                    child: Container(
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('直近${days.length}日を表示（7列=週）',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
