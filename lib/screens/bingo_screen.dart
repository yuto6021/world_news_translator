import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BingoScreen extends StatefulWidget {
  const BingoScreen({super.key});
  @override
  State<BingoScreen> createState() => _BingoScreenState();
}

class _BingoScreenState extends State<BingoScreen> {
  late List<_BingoCell> cells;
  String _cycle = 'daily'; // daily or weekly

  @override
  void initState() {
    super.initState();
    cells = _generate();
    _load();
  }

  List<_BingoCell> _generate() {
    return [
      _BingoCell('5カ国制覇', '5か国のニュースを読む'),
      _BingoCell('全カテゴリ読破', '主要カテゴリを1つずつ'),
      _BingoCell('お気に入り3', '3件お気に入り登録'),
      _BingoCell('翻訳10', '翻訳を10回使用'),
      _BingoCell('連続3日', '3日連続で起動'),
      _BingoCell('コメントする', '1件コメント投稿'),
      _BingoCell('共有する', '記事を1件シェア'),
      _BingoCell('クイズ挑戦', 'ニュースクイズを1回'),
      _BingoCell('ゲーム遊ぶ', '任意のゲームを1回'),
    ];
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final scope = _scopeKey();
    final done = p.getStringList('bingo_done_$scope') ?? [];
    setState(() {
      for (int i = 0; i < cells.length && i < done.length; i++) {
        cells[i].done = done[i] == '1';
      }
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    final scope = _scopeKey();
    await p.setStringList(
        'bingo_done_$scope', cells.map((c) => c.done ? '1' : '0').toList());
  }

  String _scopeKey() {
    final now = DateTime.now();
    if (_cycle == 'daily') return 'd_${now.year}${now.month}${now.day}';
    // weekly key (year-weekNumber)
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final days = now.difference(firstDayOfYear).inDays;
    final week = (days / 7).floor() + 1;
    return 'w_${now.year}_$week';
  }

  int _rowCountCompleted() {
    int lines = 0;
    // rows
    for (int r = 0; r < 3; r++) {
      if (cells.sublist(r * 3, r * 3 + 3).every((c) => c.done)) lines++;
    }
    // cols
    for (int c = 0; c < 3; c++) {
      if ([cells[c], cells[c + 3], cells[c + 6]].every((c) => c.done)) lines++;
    }
    // diags
    if ([cells[0], cells[4], cells[8]].every((c) => c.done)) lines++;
    if ([cells[2], cells[4], cells[6]].every((c) => c.done)) lines++;
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _rowCountCompleted();
    return Scaffold(
      appBar: AppBar(title: const Text('🎯 ニュースビンゴ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('チャレンジを達成してビンゴを狙おう！'),
                DropdownButton<String>(
                  value: _cycle,
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('日替わり')),
                    DropdownMenuItem(value: 'weekly', child: Text('週替わり')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _cycle = v);
                    await _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: cells.length,
                itemBuilder: (_, i) {
                  final c = cells[i];
                  return GestureDetector(
                    onTap: () async {
                      setState(() => c.done = !c.done);
                      await _save();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.done ? Colors.green[300] : Colors.indigo[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                c.done ? Colors.green : Colors.indigo.shade200,
                            width: 2),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c.title,
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(c.desc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Icon(
                              c.done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: c.done ? Colors.white : Colors.indigo),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('ビンゴ達成ライン: $lines',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _BingoCell {
  final String title;
  final String desc;
  bool done;
  _BingoCell(this.title, this.desc, {this.done = false});
}
