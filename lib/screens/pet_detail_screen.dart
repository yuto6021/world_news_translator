import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../widgets/pet_card_widget.dart';
import '../utils/pet_image_resolver.dart';
import 'detailed_stats_screen.dart';

class PetDetailScreen extends StatelessWidget {
  final PetModel pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${pet.name}の詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: '詳細統計',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedStatsScreen(pet: pet),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade50, Colors.cyan.shade50],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ペットカード（レア度表示）
            Center(
              child: PetCardWidget(
                petImagePath: PetImageResolver.resolveImage(
                  pet.stage,
                  pet.species,
                  'normal',
                ),
                petName: pet.name,
                level: pet.level,
                species: pet.species,
                stage: pet.stage,
                hp: pet.hp,
                attack: pet.attack,
                defense: pet.defense,
                rarity: pet.rarity,
              ),
            ),
            const SizedBox(height: 16),
            // 戦績
            _buildBattleStatsCard(),
            const SizedBox(height: 16),

            // 性格カード
            _buildPersonalityCard(),
            const SizedBox(height: 16),

            // ケア品質カード
            _buildCareQualityCard(),
            const SizedBox(height: 16),

            // しつけ度カード
            _buildDisciplineCard(),
            const SizedBox(height: 16),

            // 連続特訓カード
            _buildTrainingStreakCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'バトル情報',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow('戦績', '${pet.wins}勝 ${pet.losses}敗',
                Icons.military_tech, Colors.red),
            _buildStatRow('経験値', '${pet.exp} / ${pet.level * 100}',
                Icons.trending_up, Colors.blue),
            _buildStatRow(
                'レア度', '★' * pet.rarity, Icons.auto_awesome, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityCard() {
    final personality = pet.truePersonality ?? 'ふつう';
    final bonus = PetService.getPersonalityBonus(personality);
    final color = _getPersonalityColor(personality);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getPersonalityIcon(personality),
                      color: color, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '性格',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    personality,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '性格効果',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...bonus.entries.map((entry) {
                final statName = _getStatName(entry.key);
                final percent = ((entry.value - 1) * 100).toStringAsFixed(0);
                final isPositive = entry.value >= 1.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        statName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? "+" : ""}$percent%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPersonalityDescription(personality),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareQualityCard() {
    final quality = pet.careQuality;
    final mistakes = pet.careMistakes;
    final color = _getCareQualityColor(quality);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: color, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'ケア品質',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCareQualityLevelString(quality),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '$quality / 100',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: quality / 100,
                  minHeight: 20,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ケアミス回数',
                      style: TextStyle(fontSize: 16),
                    ),
                    Row(
                      children: [
                        Icon(
                          mistakes == 0 ? Icons.check_circle : Icons.error,
                          color: mistakes == 0 ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$mistakes回',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mistakes == 0 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '進化への影響',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCareQualityEvolutionInfo(quality),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
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
  }

  Widget _buildDisciplineCard() {
    final discipline = pet.discipline;
    final color = _getDisciplineColor(discipline);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: color, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'しつけ度',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDisciplineLevelString(discipline),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '$discipline / 100',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: discipline / 100,
                  minHeight: 20,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: discipline < 30
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: discipline < 30
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          discipline < 30 ? Icons.warning : Icons.check_circle,
                          color: discipline < 30 ? Colors.red : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'バトル時の影響',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: discipline < 30
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      discipline < 30
                          ? '⚠️ しつけ度が低いため、バトル時に20%の確率でコマンドを無視します'
                          : '✅ しつけ度が十分なため、バトルでコマンドに従います',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
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
  }

  Widget _buildTrainingStreakCard() {
    final streak = pet.trainingStreak;
    final multiplier = streak >= 5
        ? 2.0
        : streak >= 3
            ? 1.5
            : 1.0;
    final color = streak >= 5
        ? Colors.red
        : streak >= 3
            ? Colors.orange
            : Colors.grey;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: color, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '連続特訓',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    '🔥',
                    style: TextStyle(
                      fontSize: 64,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '連続 $streak 日',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (multiplier > 1.0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Text(
                        '×${multiplier.toStringAsFixed(1)}倍 ボーナス！',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStreakMilestone(3, streak >= 3, Colors.orange, '×1.5倍'),
                  const SizedBox(height: 8),
                  _buildStreakMilestone(5, streak >= 5, Colors.red, '×2.0倍'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakMilestone(
      int days, bool achieved, Color color, String bonus) {
    return Row(
      children: [
        Icon(
          achieved ? Icons.check_circle : Icons.circle_outlined,
          color: achieved ? color : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$days日連続',
          style: TextStyle(
            fontSize: 16,
            color: achieved ? color : Colors.grey,
            fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          bonus,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: achieved ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStageName(String stage) {
    const names = {
      'egg': 'たまご',
      'baby': '幼年期',
      'child': '成長期',
      'adult': '成熟期',
      'ultimate': '完全体',
    };
    return names[stage] ?? stage;
  }

  String _getStatName(String stat) {
    const names = {
      'attack': '攻撃力',
      'defense': '防御力',
      'speed': '素早さ',
    };
    return names[stat] ?? stat;
  }

  Color _getPersonalityColor(String personality) {
    const colors = {
      'わんぱく': Colors.red,
      'おとなしい': Colors.blue,
      '勇敢': Colors.orange,
      '臆病': Colors.purple,
      'ふつう': Colors.grey,
    };
    return colors[personality] ?? Colors.grey;
  }

  IconData _getPersonalityIcon(String personality) {
    const icons = {
      'わんぱく': Icons.whatshot,
      'おとなしい': Icons.favorite,
      '勇敢': Icons.shield,
      '臆病': Icons.security,
      'ふつう': Icons.sentiment_neutral,
    };
    return icons[personality] ?? Icons.sentiment_neutral;
  }

  String _getPersonalityDescription(String personality) {
    const descriptions = {
      'わんぱく': '元気いっぱいで活発な性格。攻撃力が高く、バトルで活躍します。',
      'おとなしい': '穏やかで優しい性格。防御力が高く、耐久戦が得意です。',
      '勇敢': '正義感が強く勇敢な性格。素早さが高く、先制攻撃が得意です。',
      '臆病': '慎重で警戒心の強い性格。全体的にステータスが低めです。',
      'ふつう': 'バランスの取れた性格。特別な補正はありません。',
    };
    return descriptions[personality] ?? '特徴的な性格です。';
  }

  int _getCareQualityLevel(int quality) => quality >= 80
      ? 5
      : quality >= 60
          ? 4
          : quality >= 40
              ? 3
              : quality >= 20
                  ? 2
                  : 1;

  String _getCareQualityLevelString(int quality) {
    const levels = {5: '最高', 4: '良好', 3: '普通', 2: '低い', 1: '要注意'};
    return levels[_getCareQualityLevel(quality)] ?? '普通';
  }

  Color _getCareQualityColor(int quality) {
    if (quality >= 80) return Colors.green;
    if (quality >= 60) return Colors.lightGreen;
    if (quality >= 40) return Colors.orange;
    if (quality >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  String _getCareQualityEvolutionInfo(int quality) {
    if (quality >= 80) {
      return '最高のケア品質です！進化時にプレミアム進化先（ウォーグレイモン、メタルガルルモンなど）が選択可能になります。';
    } else if (quality >= 50) {
      return '標準的なケア品質です。通常の進化先が選択可能です。';
    } else {
      return 'ケア品質が低いです。進化時に別ルート（スカルグレイモン、ダークドラモンなど）に分岐する可能性があります。';
    }
  }

  int _getDisciplineLevel(int discipline) => discipline >= 80
      ? 5
      : discipline >= 60
          ? 4
          : discipline >= 40
              ? 3
              : discipline >= 20
                  ? 2
                  : 1;

  String _getDisciplineLevelString(int discipline) {
    const levels = {5: '完璧', 4: '良好', 3: '普通', 2: '低い', 1: '要改善'};
    return levels[_getDisciplineLevel(discipline)] ?? '普通';
  }

  Color _getDisciplineColor(int discipline) {
    if (discipline >= 80) return Colors.green;
    if (discipline >= 60) return Colors.lightGreen;
    if (discipline >= 40) return Colors.orange;
    if (discipline >= 20) return Colors.deepOrange;
    return Colors.red;
  }
}
