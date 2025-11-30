import 'package:flutter/material.dart';
import '../models/pet.dart';
import 'battle_screen.dart';

class StageSelectScreen extends StatelessWidget {
  final PetModel pet;

  const StageSelectScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ステージ選択'),
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
            _buildStageCard(
              context,
              stageNumber: 1,
              title: '草原の始まり',
              description: '初心者向けの平和な草原。スライムやゴブリンが出現。',
              icon: '🌱',
              difficulty: '易しい',
              difficultyColor: Colors.green,
              recommendedLevel: '1-5',
              enemies: ['スライム', 'ゴブリン', 'ウルフ'],
            ),
            _buildStageCard(
              context,
              stageNumber: 2,
              title: '深い森',
              description: 'やや危険な森。獣や精霊が潜んでいる。',
              icon: '🌲',
              difficulty: '普通',
              difficultyColor: Colors.orange,
              recommendedLevel: '5-10',
              enemies: ['ウルフ', 'トレント', 'エレメンタル'],
            ),
            _buildStageCard(
              context,
              stageNumber: 3,
              title: '暗黒の洞窟',
              description: '危険な洞窟。強力なモンスターが待ち受ける。',
              icon: '⛰️',
              difficulty: '難しい',
              difficultyColor: Colors.red,
              recommendedLevel: '10-15',
              enemies: ['ゴーレム', 'ドラゴン', 'ダークナイト'],
            ),
            _buildStageCard(
              context,
              stageNumber: 4,
              title: '魔王の城',
              description: '最終ステージ。ボスとシークレットボスが出現。',
              icon: '🏰',
              difficulty: '超難',
              difficultyColor: Colors.purple,
              recommendedLevel: '15+',
              enemies: ['ボス', 'シークレットボス'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context, {
    required int stageNumber,
    required String title,
    required String description,
    required String icon,
    required String difficulty,
    required Color difficultyColor,
    required String recommendedLevel,
    required List<String> enemies,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BattleScreen(
                pet: pet,
                initialStage: stageNumber,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: difficultyColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'STAGE $stageNumber',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: difficultyColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: difficultyColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                difficulty,
                                style: TextStyle(
                                  color: difficultyColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      '推奨レベル: $recommendedLevel',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: enemies.map((enemy) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      enemy,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
