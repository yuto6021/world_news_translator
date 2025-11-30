import 'dart:async';
import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/idle_training_service.dart';
import '../services/pet_service.dart';
import '../widgets/animated_reward.dart';

class IdleTrainingScreen extends StatefulWidget {
  const IdleTrainingScreen({super.key});

  @override
  State<IdleTrainingScreen> createState() => _IdleTrainingScreenState();
}

class _IdleTrainingScreenState extends State<IdleTrainingScreen> {
  PetModel? _pet;
  Map<String, dynamic>? _active;
  Map<String, dynamic> _mastery = {};
  int? _remain;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final pet = await PetService.getActivePet();
    final active = await IdleTrainingService.getActivePlan();
    final mastery = pet != null
        ? await IdleTrainingService.getMastery(pet.id)
        : <String, dynamic>{};
    final remain = await IdleTrainingService.getRemainingSeconds();
    if (!mounted) return;
    setState(() {
      _pet = pet;
      _active = active;
      _mastery = mastery;
      _remain = remain;
      _loading = false;
    });
    _setupTicker();
  }

  void _setupTicker() {
    _timer?.cancel();
    if (_active == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remain = await IdleTrainingService.getRemainingSeconds();
      if (!mounted) return;
      setState(() => _remain = remain);
      if (remain != null && remain <= 0) {
        _timer?.cancel();
      }
    });
  }

  Future<void> _startPlan(String planId) async {
    if (_pet == null) return;
    setState(() => _loading = true);
    await IdleTrainingService.startPlan(petId: _pet!.id, planId: planId);
    await _load();
  }

  Future<void> _cancelPlan() async {
    await IdleTrainingService.cancelPlan();
    await _load();
  }

  Future<void> _claim() async {
    final result = await IdleTrainingService.claim();
    await _load();
    if (!mounted) return;
    if (result['success'] == true) {
      final sp = result['sp'] as int? ?? 0;
      final m = result['mastery'] as Map<String, dynamic>?;
      final stat = m?['stat'] ?? '-';
      final lv = m?['level'] ?? 0;

      // SP獲得アニメーション
      AnimationHelper.showSpGain(context, sp);

      // マスタリーアップアニメーション
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        AnimationHelper.showReward(
          context,
          text: '$stat Lv.$lv',
          icon: Icons.military_tech,
          color: Colors.orange,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? '受取できません')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
                : [Colors.purple.shade50, Colors.indigo.shade50],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: const Text('放置トレーニング',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  tooltip: '更新',
                ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _pet == null
                      ? const Center(child: Text('アクティブなペットがいません'))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildPetHeader(),
                            const SizedBox(height: 12),
                            _buildMasteryCard(),
                            const SizedBox(height: 16),
                            if (_active == null)
                              _buildPlanList()
                            else
                              _buildActivePanel(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              child: Text(_pet!.name.characters.first),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_pet!.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Lv.${_pet!.level} / SP: ${_pet!.skillPoints}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryCard() {
    final atk = Map<String, dynamic>.from(_mastery['attack'] ?? {});
    final def = Map<String, dynamic>.from(_mastery['defense'] ?? {});
    final spd = Map<String, dynamic>.from(_mastery['speed'] ?? {});
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'マスタリー',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _masteryBar('⚔️ 攻撃', atk, Colors.red),
            const SizedBox(height: 10),
            _masteryBar('🛡️ 防御', def, Colors.blue),
            const SizedBox(height: 10),
            _masteryBar('⚡ 素早さ', spd, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _masteryBar(String label, Map<String, dynamic> data, Color color) {
    final lv = (data['level'] as int?) ?? 0;
    final xp = (data['xp'] as int?) ?? 0;
    final ratio = xp / IdleTrainingService.masteryXpPerLevel;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$label Lv.$lv',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.lerp(color, Colors.black, 0.3)!,
                  ),
                ),
              ),
              Text(
                '$xp/${IdleTrainingService.masteryXpPerLevel}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('プラン一覧',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...IdleTrainingService.plans.entries.map((e) {
          final id = e.key;
          final cfg = e.value;
          final name = cfg['name'] as String;
          final emoji = cfg['emoji'] as String;
          final dur = cfg['durationSec'] as int;
          final sp = cfg['sp'] as int;
          return Card(
            child: ListTile(
              leading: Text(emoji, style: const TextStyle(fontSize: 24)),
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${(dur / 60).round()}分 / 受取: SP+$sp'),
              trailing: ElevatedButton(
                onPressed: () => _startPlan(id),
                child: const Text('開始'),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActivePanel() {
    final cfg = IdleTrainingService.plans[_active!['planId'] as String]!;
    final emoji = cfg['emoji'] as String;
    final name = cfg['name'] as String;
    final dur = _active!['durationSec'] as int;
    final remain = _remain ?? dur;
    final done = (dur - remain).clamp(0, dur);
    final ratio = (done / dur).clamp(0.0, 1.0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Text(_formatRemain(remain)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: ratio >= 1.0 ? Colors.green : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _cancelPlan,
                  icon: const Icon(Icons.stop),
                  label: const Text('中止'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: ratio >= 1.0 ? _claim : null,
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('受け取る'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatRemain(int seconds) {
    if (seconds <= 0) return '完了';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
