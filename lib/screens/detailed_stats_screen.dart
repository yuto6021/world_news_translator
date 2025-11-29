import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/skill.dart';
import '../services/talent_discovery_service.dart';
import '../services/intimacy_bond_service.dart';
import '../services/training_service.dart';

/// 詳細統計画面 - ペットの全情報を表示
class DetailedStatsScreen extends StatefulWidget {
  final PetModel pet;

  const DetailedStatsScreen({super.key, required this.pet});

  @override
  State<DetailedStatsScreen> createState() => _DetailedStatsScreenState();
}

class _DetailedStatsScreenState extends State<DetailedStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _trainingStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTrainingStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainingStats() async {
    final stats = await TrainingService.getTrainingStats(widget.pet.id);
    setState(() => _trainingStats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pet.name}の詳細統計'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assessment), text: '基本'),
            Tab(icon: Icon(Icons.auto_awesome), text: '才能'),
            Tab(icon: Icon(Icons.favorite), text: '絆'),
            Tab(icon: Icon(Icons.fitness_center), text: '特訓'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicStatsTab(),
          _buildTalentTab(),
          _buildBondTab(),
          _buildTrainingTab(),
        ],
      ),
    );
  }

  // 基本統計タブ
  Widget _buildBasicStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プロフィールカード
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pets, size: 32, color: Colors.purple.shade600),
                      const SizedBox(width: 12),
                      const Text(
                        'プロフィール',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildStatRow('名前', widget.pet.name),
                  _buildStatRow('種族', widget.pet.species),
                  _buildStatRow('段階', _stageLabel(widget.pet.stage)),
                  _buildStatRow('レベル', '${widget.pet.level}'),
                  _buildStatRow('年齢', '${widget.pet.age}日'),
                  _buildStatRow('性格', widget.pet.personality),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // バトルステータス
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on,
                          size: 32, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      const Text(
                        'バトルステータス',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          '攻撃力',
                          widget.pet.attack.toString(),
                          Icons.flash_on,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          '防御力',
                          widget.pet.defense.toString(),
                          Icons.shield,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          '素早さ',
                          widget.pet.speed.toString(),
                          Icons.speed,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('HP', '${widget.pet.hp}'),
                  _buildStatRow('経験値',
                      '${widget.pet.exp} / ${widget.pet.expToNextLevel}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 戦闘記録
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events,
                          size: 32, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        '戦闘記録',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          '勝利',
                          widget.pet.wins.toString(),
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          '敗北',
                          widget.pet.losses.toString(),
                          Icons.cancel,
                          Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          '勝率',
                          '${_calculateWinRate()}%',
                          Icons.percent,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('総バトル数', '${widget.pet.battleCount}回'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 習得スキル
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 32, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      const Text(
                        '習得スキル',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (widget.pet.skills.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('スキルを習得していません'),
                      ),
                    )
                  else
                    ...widget.pet.skills.map((skillId) {
                      final skill = Skill.getSkillById(skillId);
                      if (skill == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getSkillColor(skill.type.name)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getSkillIcon(skill.type.name),
                                color: _getSkillColor(skill.type.name),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    skill.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    skill.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (skill.power > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '威力${skill.power}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 才能タブ
  Widget _buildTalentTab() {
    final talentInfo = TalentDiscoveryService.getTalentInfo(widget.pet);
    final highestTalent = TalentDiscoveryService.getHighestTalent(widget.pet);
    final lowestTalent = TalentDiscoveryService.getLowestTalent(widget.pet);
    final averageTalent = TalentDiscoveryService.getAverageTalent(widget.pet);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!widget.pet.talentDiscovered)
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.lock, size: 64, color: Colors.amber.shade700),
                    const SizedBox(height: 12),
                    const Text(
                      '才能はまだ発見されていません',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'レベル10到達 + 特訓10回 または バトル5回で発見',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // 才能サマリー
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '才能サマリー',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTalentSummary(
                          '平均',
                          averageTalent.toStringAsFixed(1),
                          Icons.analytics,
                          Colors.purple,
                        ),
                        _buildTalentSummary(
                          '得意',
                          highestTalent,
                          Icons.trending_up,
                          Colors.green,
                        ),
                        _buildTalentSummary(
                          '苦手',
                          lowestTalent,
                          Icons.trending_down,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 才能詳細
            _buildTalentDetailCard(
                '攻撃才能', talentInfo['attack'], Icons.flash_on, Colors.red),
            const SizedBox(height: 12),
            _buildTalentDetailCard(
                '防御才能', talentInfo['defense'], Icons.shield, Colors.blue),
            const SizedBox(height: 12),
            _buildTalentDetailCard(
                '速度才能', talentInfo['speed'], Icons.speed, Colors.green),
          ],
        ],
      ),
    );
  }

  // 絆タブ
  Widget _buildBondTab() {
    final bondLevel = IntimacyBondService.getBondLevel(widget.pet.intimacy);
    final bondInfo = IntimacyBondService.bondLevels[bondLevel - 1];
    final bonus = IntimacyBondService.getBondBonus(widget.pet.intimacy);
    final progress = IntimacyBondService.getBondProgress(widget.pet.intimacy);
    final unlockedSkills =
        IntimacyBondService.getUnlockedSkills(widget.pet.intimacy);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 現在の絆レベル
          Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    bondInfo['name'] as String,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '絆レベル $bondLevel / 5',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '親密度: ${widget.pet.intimacy} / 100  (次のレベルまで${100 - progress.toInt()}%)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ステータスボーナス
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ステータスボーナス',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          '攻撃',
                          '+${bonus['attack']}',
                          Icons.flash_on,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          '防御',
                          '+${bonus['defense']}',
                          Icons.shield,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          '速度',
                          '+${bonus['speed']}',
                          Icons.speed,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 解放済みスキル
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '絆スキル',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  if (unlockedSkills.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('絆レベルを上げてスキルを解放しましょう'),
                      ),
                    )
                  else
                    ...unlockedSkills.map((skillId) {
                      final skill = Skill.getSkillById(skillId);
                      if (skill == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 24, color: Colors.amber.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                skill.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 絆レベル一覧
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '絆レベル一覧',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  ...List.generate(5, (index) {
                    final level = IntimacyBondService.bondLevels[index];
                    final isUnlocked = bondLevel > index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? Colors.pink.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked
                                      ? Colors.pink.shade700
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level['name'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isUnlocked ? Colors.black : Colors.grey,
                                  ),
                                ),
                                Text(
                                  '親密度 ${level['minIntimacy']}-${level['maxIntimacy']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isUnlocked ? Icons.check_circle : Icons.lock,
                            color: isUnlocked ? Colors.green : Colors.grey,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 特訓タブ
  Widget _buildTrainingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 今日の特訓
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today, size: 32, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        '今日の特訓',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  FutureBuilder<int>(
                    future:
                        TrainingService.getTodayTrainingCount(widget.pet.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < count
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 48,
                                  color: index < count
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$count / 3 回完了',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 特訓統計
          if (_trainingStats != null) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart,
                            size: 32, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        const Text(
                          '特訓統計',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildStatRow('総特訓回数', '${_trainingStats!['totalCount']}回'),
                    _buildStatRow('攻撃特訓', '${_trainingStats!['attackCount']}回'),
                    _buildStatRow(
                        '防御特訓', '${_trainingStats!['defenseCount']}回'),
                    _buildStatRow('速度特訓', '${_trainingStats!['speedCount']}回'),
                    const Divider(height: 24),
                    _buildStatRow('平均スコア',
                        '${_trainingStats!['averageScore'].toStringAsFixed(1)}点'),
                    _buildStatRow('最高スコア', '${_trainingStats!['bestScore']}点'),
                    _buildStatRow(
                        'パーフェクト', '${_trainingStats!['perfectCount']}回'),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 活動統計
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline,
                          size: 32, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        '活動統計',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildStatRow('遊んだ回数', '${widget.pet.playCount}回'),
                  _buildStatRow('掃除した回数', '${widget.pet.cleanCount}回'),
                  _buildStatRow('バトル参加', '${widget.pet.battleCount}回'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTalentSummary(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTalentDetailCard(
    String label,
    Map<String, dynamic> info,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${info['value']} / 90',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          info['rank'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info['description'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (info['value'] as int) / 90,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stageLabel(String stage) {
    const labels = {
      'egg': 'たまご',
      'baby': '幼年期',
      'child': '成長期',
      'adult': '成熟期',
      'ultimate': '究極体',
    };
    return labels[stage] ?? stage;
  }

  int _calculateWinRate() {
    final total = widget.pet.wins + widget.pet.losses;
    if (total == 0) return 0;
    return ((widget.pet.wins / total) * 100).round();
  }

  Color _getSkillColor(String type) {
    switch (type) {
      case 'attack':
        return Colors.red;
      case 'support':
        return Colors.green;
      case 'passive':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getSkillIcon(String type) {
    switch (type) {
      case 'attack':
        return Icons.flash_on;
      case 'support':
        return Icons.favorite;
      case 'passive':
        return Icons.shield;
      default:
        return Icons.auto_awesome;
    }
  }
}
