import 'package:flutter/material.dart';
import '../services/dex_service.dart';

/// 配合レシピ図鑑画面
class BreedingRecipeScreen extends StatelessWidget {
  const BreedingRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipes = DexService.breedingRecipes.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('配合レシピ図鑑'),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade100,
              Colors.pink.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // ヘッダー
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.purple, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '配合限定ペット',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '特定の親ペット同士を配合することで、通常では入手できない特別なペットが誕生します！',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // レシピリスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final entry = recipes[index];
                  final recipe = entry.value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: recipe.rarity == 'mythic'
                            ? LinearGradient(
                                colors: [
                                  Colors.purple.shade50,
                                  Colors.pink.shade50,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.orange.shade50,
                                  Colors.red.shade50,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // タイトル＆レアリティ
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: recipe.rarity == 'mythic'
                                          ? [
                                              Colors.purple.shade600,
                                              Colors.pink.shade600
                                            ]
                                          : [
                                              Colors.orange.shade600,
                                              Colors.red.shade600
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    recipe.rarity == 'mythic' ? '神話級' : '伝説級',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recipe.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: recipe.rarity == 'mythic'
                                          ? Colors.purple.shade900
                                          : Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 説明
                            Text(
                              recipe.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 配合レシピ
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: recipe.rarity == 'mythic'
                                      ? Colors.purple.shade200
                                      : Colors.orange.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.science, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        '配合レシピ:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildParentBox(
                                          recipe.requiredParents[0],
                                        ),
                                      ),
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(
                                          Icons.favorite,
                                          color: Colors.pink,
                                          size: 24,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildParentBox(
                                          recipe.requiredParents[1],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ボーナス情報
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 18),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'スキル3つ継承 + ステータス+20%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentBox(String species) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text(
            _getSpeciesEmoji(species),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            _getSpeciesName(species),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getSpeciesEmoji(String species) {
    final emojiMap = {
      'wargreymon': '🐉',
      'metalgarurumon': '🐺',
      'omegamon': '⚔️',
      'imperialdramon': '🐲',
      'alphamon': '👑',
      'seraphimon': '👼',
      'bancholeomon': '🦁',
      'piedmon': '🃏',
      'cyberdramon': '🤖',
      'devimon': '😈',
      'beelzemon': '👹',
      'venommyotismon': '🦇',
    };
    return emojiMap[species] ?? '🐾';
  }

  String _getSpeciesName(String species) {
    final nameMap = {
      'wargreymon': 'ウォーグレイモン',
      'metalgarurumon': 'メタルガルルモン',
      'omegamon': 'オメガモン',
      'imperialdramon': 'インペリアルドラモン',
      'alphamon': 'アルファモン',
      'seraphimon': 'セラフィモン',
      'bancholeomon': 'バンチョーレオモン',
      'piedmon': 'ピエモン',
      'cyberdramon': 'サイバードラモン',
      'devimon': 'デビモン',
      'beelzemon': 'ベルゼモン',
      'venommyotismon': 'ヴェノムヴァンデモン',
      'darkdramon': 'ダークドラモン',
    };
    return nameMap[species] ?? species;
  }
}
