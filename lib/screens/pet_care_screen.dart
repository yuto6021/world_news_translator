import 'package:flutter/material.dart';

class PetCareScreen extends StatelessWidget {
  const PetCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ペットケア'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('プレビュー', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      _PreviewTile('assets/pets/egg/egg_idle.png'),
                      _PreviewTile('assets/pets/baby/baby_genki_normal.png'),
                      _PreviewTile('assets/pets/child/child_warrior_normal.png'),
                      _PreviewTile('assets/pets/adult/adult_greymon_normal.png'),
                      _PreviewTile('assets/pets/ultimate/ultimate_wargreymon_normal.png'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('アクション', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      _ActionButton(label: '食事', assetPath: 'assets/pets/adult/adult_agumon_eat.png'),
                      _ActionButton(label: '攻撃', assetPath: 'assets/pets/adult/adult_agumon_attack.png'),
                      _ActionButton(label: '睡眠', assetPath: 'assets/pets/adult/adult_agumon_sleep.png'),
                      _ActionButton(label: '掃除', assetPath: 'assets/pets/adult/adult_agumon_clean.png'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final String assetPath;
  const _PreviewTile(this.assetPath);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  'Not found',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          assetPath.split('/').last,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String assetPath;
  const _ActionButton({required this.label, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(label),
            content: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text('Not found'),
            ),
          ),
        );
      },
      icon: const Icon(Icons.pets),
      label: Text(label),
    );
  }
}
