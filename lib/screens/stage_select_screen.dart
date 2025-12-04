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
              title: '獣の領域',
              description: '獣系の敵が群れをなす。',
              icon: '🦁',
              difficulty: '普通',
              difficultyColor: Colors.orange,
              recommendedLevel: '10-15',
              enemies: ['ドルモン', 'ガオモン', 'バンチョーレオモン'],
            ),
            _buildStageCard(
              context,
              stageNumber: 5,
              title: '炎の試練',
              description: '灼熱の世界。炎属性特化。',
              icon: '🔥',
              difficulty: '難しい',
              difficultyColor: Colors.red,
              recommendedLevel: '15-20',
              enemies: ['ドラゴン', '火の騎士'],
            ),
            _buildStageCard(
              context,
              stageNumber: 6,
              title: '水の神殿',
              description: '水中戦闘。水属性特化。',
              icon: '💧',
              difficulty: '難しい',
              difficultyColor: Colors.blue,
              recommendedLevel: '15-20',
              enemies: ['スライム', '水の騎士'],
            ),
            _buildStageCard(
              context,
              stageNumber: 7,
              title: '生命の森',
              description: '古代樹の守護者たち。',
              icon: '🌳',
              difficulty: '難しい',
              difficultyColor: Colors.green,
              recommendedLevel: '15-20',
              enemies: ['フェアリー', '木の騎士'],
            ),
            _buildStageCard(
              context,
              stageNumber: 8,
              title: '雷鳴の塔',
              description: '電撃が駆け巡る高塔。',
              icon: '⚡',
              difficulty: '超難',
              difficultyColor: Colors.yellow[700]!,
              recommendedLevel: '20-25',
              enemies: ['雷の騎士', 'ヘラクレスカブテリモン'],
            ),
            _buildStageCard(
              context,
              stageNumber: 9,
              title: '光の聖域',
              description: '神聖な光が満ちる場所。',
              icon: '✨',
              difficulty: '超難',
              difficultyColor: Colors.amber,
              recommendedLevel: '20-25',
              enemies: ['フェアリー', '光の騎士'],
            ),
            _buildStageCard(
              context,
              stageNumber: 10,
              title: '闇の深淵',
              description: '暗黒の力が渦巻く。',
              icon: '🌑',
              difficulty: '超難',
              difficultyColor: Colors.purple[900]!,
              recommendedLevel: '20-25',
              enemies: ['ファントモン', 'ピエモン'],
            ),
            _buildStageCard(
              context,
              stageNumber: 11,
              title: 'ドラゴンの巣',
              description: 'ドラゴン種の集う場所。',
              icon: '🐉',
              difficulty: '超難',
              difficultyColor: Colors.deepOrange,
              recommendedLevel: '25-30',
              enemies: ['ドラゴン', 'ドルゴラモン'],
            ),
            _buildStageCard(
              context,
              stageNumber: 12,
              title: '機械要塞',
              description: '機械の軍勢が待ち受ける。',
              icon: '🤖',
              difficulty: '超難',
              difficultyColor: Colors.blueGrey,
              recommendedLevel: '25-30',
              enemies: ['マッハガオガモン', 'ミラージュガオガモン'],
            ),
            _buildStageCard(
              context,
              stageNumber: 13,
              title: '五属性の祭壇',
              description: '全属性の騎士が集結。',
              icon: '🌟',
              difficulty: '極難',
              difficultyColor: Colors.pink,
              recommendedLevel: '30-35',
              enemies: ['五属性騎士'],
            ),
            _buildStageCard(
              context,
              stageNumber: 14,
              title: 'エリート戦場',
              description: '最強の戦士たちとの戦い。',
              icon: '⚔️',
              difficulty: '極難',
              difficultyColor: Colors.red[900]!,
              recommendedLevel: '35-40',
              enemies: ['バンチョーレオモン', 'ヘラクレスカブテリモン', 'ピエモン'],
            ),
            _buildStageCard(
              context,
              stageNumber: 15,
              title: 'カオスの渦',
              description: 'すべての敵がランダムに出現。',
              icon: '🌀',
              difficulty: '極難',
              difficultyColor: Colors.black,
              recommendedLevel: '40+',
              enemies: ['全敵ランダム'],
            ),
            _buildStageCard(
              context,
              stageNumber: 16,
              title: '魔王の城',
              description: '最終ステージ。強力なボスたちが待つ。',
              icon: '🏰',
              difficulty: '最難',
              difficultyColor: Colors.deepPurple[900]!,
              recommendedLevel: '50+',
              enemies: ['タイタン', 'ダークロード', '精霊王'],
            ),
            _buildStageCard(
              context,
              stageNumber: 17,
              title: '紅蓮の地獄',
              description: '炎系の強化版が待ち受ける。',
              icon: '🔥',
              difficulty: '超難',
              difficultyColor: Colors.deepOrange[900]!,
              recommendedLevel: '55+',
              enemies: ['ドラゴン(強)', '火の騎士(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 18,
              title: '深淵の海溝',
              description: '水系の強化版エリア。',
              icon: '🌊',
              difficulty: '超難',
              difficultyColor: Colors.blue[900]!,
              recommendedLevel: '55+',
              enemies: ['スライム(強)', '水の騎士(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 19,
              title: '世界樹の頂',
              description: '草系の究極形態。',
              icon: '🌳',
              difficulty: '超難',
              difficultyColor: Colors.green[900]!,
              recommendedLevel: '60+',
              enemies: ['木の騎士(強)', 'トレント(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 20,
              title: '雷帝の宮殿',
              description: '雷系最強クラス。',
              icon: '⚡',
              difficulty: '極難',
              difficultyColor: Colors.yellow[900]!,
              recommendedLevel: '60+',
              enemies: ['雷の騎士(強)', 'ヘラクレスカブテリモン(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 21,
              title: '聖光の大聖堂',
              description: '光属性の聖域。',
              icon: '✨',
              difficulty: '極難',
              difficultyColor: Colors.amber[700]!,
              recommendedLevel: '65+',
              enemies: ['光の騎士(強)', 'フェアリー(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 22,
              title: '虚無の暗黒界',
              description: '闇の最深部。',
              icon: '🌑',
              difficulty: '極難',
              difficultyColor: Colors.black,
              recommendedLevel: '65+',
              enemies: ['ファントモン(強)', 'ピエモン(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 23,
              title: '五大騎士の試練',
              description: '五属性騎士の強化版が全員登場。',
              icon: '⚔️',
              difficulty: '極難',
              difficultyColor: Colors.red[900]!,
              recommendedLevel: '70+',
              enemies: ['全騎士(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 24,
              title: '伝説の覇者たち',
              description: 'すべての最強エリートが集結。',
              icon: '👑',
              difficulty: '最難',
              difficultyColor: Colors.purple[900]!,
              recommendedLevel: '75+',
              enemies: ['全エリート(強)'],
            ),
            _buildStageCard(
              context,
              stageNumber: 25,
              title: '終焉の大決戦',
              description: '両裏ボスとの最終決戦。Wave 7の超長期戦。',
              icon: '💀',
              difficulty: '最難',
              difficultyColor: Colors.red,
              recommendedLevel: '99+',
              enemies: ['精霊王', '最強裏ボス'],
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
