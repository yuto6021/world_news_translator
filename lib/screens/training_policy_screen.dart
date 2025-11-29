import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/training_policy_service.dart';

/// 育成方針選択画面
class TrainingPolicyScreen extends StatefulWidget {
  final PetModel pet;

  const TrainingPolicyScreen({super.key, required this.pet});

  @override
  State<TrainingPolicyScreen> createState() => _TrainingPolicyScreenState();
}

class _TrainingPolicyScreenState extends State<TrainingPolicyScreen> {
  String _currentPolicy = 'balanced';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPolicy();
  }

  Future<void> _loadCurrentPolicy() async {
    try {
      final policy = await TrainingPolicyService.getPolicy(widget.pet.id);
      setState(() {
        _currentPolicy = policy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('方針の読み込みに失敗: $e')),
        );
      }
    }
  }

  Future<void> _changePolicy(String newPolicy) async {
    if (newPolicy == _currentPolicy) return;

    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('育成方針の変更'),
        content: Text(
          TrainingPolicyService.getChangePolicyMessage(
              _currentPolicy, newPolicy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('変更する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await TrainingPolicyService.setPolicy(widget.pet.id, newPolicy);
      setState(() => _currentPolicy = newPolicy);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('育成方針を変更しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('変更に失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pet.name}の育成方針'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 説明カード
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline,
                              size: 48, color: Colors.blue.shade700),
                          const SizedBox(height: 8),
                          Text(
                            '育成方針について',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'レベルアップ時の成長率に影響します。\n'
                            '特化型は得意なステータスが大きく伸びますが、\n'
                            '他のステータスの伸びは控えめになります。',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 方針選択リスト
                  ...TrainingPolicyService.getAllPolicies().map((entry) {
                    final policyKey = entry.key;
                    final policyInfo = entry.value;
                    final isSelected = policyKey == _currentPolicy;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PolicyCard(
                        policyKey: policyKey,
                        policyInfo: policyInfo,
                        isSelected: isSelected,
                        pet: widget.pet,
                        onTap: () => _changePolicy(policyKey),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // 現在のボーナス表示
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '現在の成長補正',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _BonusDisplay(
                            policyKey: _currentPolicy,
                            level: widget.pet.level,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// 育成方針カード
class _PolicyCard extends StatelessWidget {
  final String policyKey;
  final Map<String, dynamic> policyInfo;
  final bool isSelected;
  final PetModel pet;
  final VoidCallback onTap;

  const _PolicyCard({
    required this.policyKey,
    required this.policyInfo,
    required this.isSelected,
    required this.pet,
    required this.onTap,
  });

  Color _getModColor(double mod) {
    if (mod >= 1.4) return Colors.green.shade700;
    if (mod <= 0.85) return Colors.red.shade700;
    return Colors.grey.shade700;
  }

  String _getModText(double mod) {
    final percentage = ((mod - 1.0) * 100).round();
    if (percentage > 0) return '+$percentage%';
    if (percentage < 0) return '$percentage%';
    return '±0%';
  }

  @override
  Widget build(BuildContext context) {
    final attackMod = policyInfo['attackMod'] as double;
    final defenseMod = policyInfo['defenseMod'] as double;
    final speedMod = policyInfo['speedMod'] as double;

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.amber.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.amber.shade700, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  Text(
                    policyInfo['icon'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          policyInfo['name'] as String,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          policyInfo['description'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '選択中',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const Divider(height: 24),

              // ステータス補正
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatMod(
                    label: '攻撃',
                    icon: Icons.flash_on,
                    mod: attackMod,
                    color: _getModColor(attackMod),
                    text: _getModText(attackMod),
                  ),
                  _StatMod(
                    label: '防御',
                    icon: Icons.shield,
                    mod: defenseMod,
                    color: _getModColor(defenseMod),
                    text: _getModText(defenseMod),
                  ),
                  _StatMod(
                    label: '速度',
                    icon: Icons.speed,
                    mod: speedMod,
                    color: _getModColor(speedMod),
                    text: _getModText(speedMod),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ステータス補正表示
class _StatMod extends StatelessWidget {
  final String label;
  final IconData icon;
  final double mod;
  final Color color;
  final String text;

  const _StatMod({
    required this.label,
    required this.icon,
    required this.mod,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// ボーナス表示
class _BonusDisplay extends StatelessWidget {
  final String policyKey;
  final int level;

  const _BonusDisplay({
    required this.policyKey,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final bonus =
        TrainingPolicyService.calculateCumulativeBonus(policyKey, level);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _BonusStat(
          icon: Icons.flash_on,
          label: '攻撃',
          value: bonus['attack']!,
          color: Colors.red.shade600,
        ),
        _BonusStat(
          icon: Icons.shield,
          label: '防御',
          value: bonus['defense']!,
          color: Colors.blue.shade600,
        ),
        _BonusStat(
          icon: Icons.speed,
          label: '速度',
          value: bonus['speed']!,
          color: Colors.green.shade600,
        ),
      ],
    );
  }
}

class _BonusStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _BonusStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          '×${value.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
