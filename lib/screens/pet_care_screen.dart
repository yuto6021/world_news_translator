import 'package:flutter/material.dart';
import '../utils/pet_image_resolver.dart';

class PetCareScreen extends StatefulWidget {
  const PetCareScreen({super.key});

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen> {
  String _selectedStage = 'egg';
  String _selectedSpecies = 'egg';
  String _selectedState = 'normal';
  String _selectedAction = 'eat';
  bool _showAction = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ステージに応じて種リストを更新
    final availableSpecies =
        PetImageResolver.speciesByStage[_selectedStage] ?? ['egg'];
    if (!availableSpecies.contains(_selectedSpecies)) {
      _selectedSpecies = availableSpecies.first;
    }

    // 表示する画像パスを決定
    final displayImage = _showAction
        ? PetImageResolver.resolveAction(
            _selectedStage, _selectedSpecies, _selectedAction)
        : PetImageResolver.resolveImage(
            _selectedStage, _selectedSpecies, _selectedState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ペットケア'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('操作ガイド'),
                  content: const Text(
                    'ステージ・種・状態を選んでペット画像を確認できます。\n'
                    'アクションボタンで食事・攻撃・睡眠・掃除の様子も見られます。',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFFe3f2fd), const Color(0xFFbbdefb)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // メイン表示カード
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ペット画像表示エリア
                    Container(
                      width: double.infinity,
                      height: 320,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          displayImage,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '画像が見つかりません',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    displayImage.split('/').last,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 現在の設定表示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoChip('ステージ', _selectedStage, Colors.blue),
                          _buildInfoChip('種', _selectedSpecies, Colors.green),
                          _buildInfoChip(
                            _showAction ? 'アクション' : '状態',
                            _showAction ? _selectedAction : _selectedState,
                            _showAction ? Colors.orange : Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ステージ選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ステージ選択',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['egg', 'baby', 'child', 'adult', 'ultimate']
                          .map((stage) => ChoiceChip(
                                label: Text(_stageLabel(stage)),
                                selected: _selectedStage == stage,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedStage = stage;
                                      _showAction = false;
                                    });
                                  }
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 種選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '種選択',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSpecies
                          .map((species) => ChoiceChip(
                                label: Text(species),
                                selected: _selectedSpecies == species,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedSpecies = species;
                                      _showAction = false;
                                    });
                                  }
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 状態/アクション選択
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '表示切替',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('状態')),
                            ButtonSegment(value: true, label: Text('アクション')),
                          ],
                          selected: {_showAction},
                          onSelectionChanged: (Set<bool> newSelection) {
                            setState(() {
                              _showAction = newSelection.first;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_showAction)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PetImageResolver.states
                            .map((state) => ChoiceChip(
                                  label: Text(_stateLabel(state)),
                                  selected: _selectedState == state,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedState = state);
                                    }
                                  },
                                ))
                            .toList(),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PetImageResolver.actions
                            .map((action) => ActionChip(
                                  avatar: Icon(_actionIcon(action), size: 18),
                                  label: Text(_actionLabel(action)),
                                  onPressed: () {
                                    setState(() => _selectedAction = action);
                                  },
                                  backgroundColor: _selectedAction == action
                                      ? Colors.blue[100]
                                      : null,
                                ))
                            .toList(),
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

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _stageLabel(String stage) {
    const labels = {
      'egg': '🥚たまご',
      'baby': '👶幼年期',
      'child': '🧒成長期',
      'adult': '💪成熟期',
      'ultimate': '⚡究極体',
    };
    return labels[stage] ?? stage;
  }

  String _stateLabel(String state) {
    const labels = {
      'normal': '😊通常',
      'happy': '😄幸福',
      'sick': '🤒病気',
      'angry': '😠怒り',
    };
    return labels[state] ?? state;
  }

  String _actionLabel(String action) {
    const labels = {
      'eat': '食事',
      'attack': '攻撃',
      'sleep': '睡眠',
      'clean': '掃除',
    };
    return labels[action] ?? action;
  }

  IconData _actionIcon(String action) {
    const icons = {
      'eat': Icons.restaurant,
      'attack': Icons.flash_on,
      'sleep': Icons.bedtime,
      'clean': Icons.cleaning_services,
    };
    return icons[action] ?? Icons.pets;
  }
}
