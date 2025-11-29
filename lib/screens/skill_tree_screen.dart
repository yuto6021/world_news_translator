import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/skill.dart';
import '../services/pet_service.dart';

class SkillTreeScreen extends StatefulWidget {
  final PetModel pet;

  const SkillTreeScreen({super.key, required this.pet});

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  late PetModel _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _refreshPet();
  }

  Future<void> _refreshPet() async {
    final updatedPet = await PetService.getPetById(widget.pet.id);
    if (updatedPet != null && mounted) {
      setState(() => _pet = updatedPet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final learnedSkills = _pet.skills
        .map((id) => Skill.getSkillById(id))
        .where((s) => s != null)
        .cast<Skill>()
        .toList();

    final availableSkills = Skill.predefinedSkills
        .where(
            (s) => s.requiredLevel <= _pet.level && !_pet.skills.contains(s.id))
        .toList();

    final futureSkills = Skill.predefinedSkills
        .where((s) => s.requiredLevel > _pet.level)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('スキルツリー'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade50, Colors.purple.shade50],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // スキルポイント表示
            _buildSkillPointsCard(),
            const SizedBox(height: 16),

            // 習得済みスキル
            if (learnedSkills.isNotEmpty) ...[
              _buildSectionHeader('習得済みスキル', Icons.check_circle, Colors.green),
              const SizedBox(height: 12),
              ...learnedSkills.map((skill) => _buildLearnedSkillCard(skill)),
              const SizedBox(height: 24),
            ],

            // 習得可能スキル
            if (availableSkills.isNotEmpty) ...[
              _buildSectionHeader('習得可能', Icons.auto_awesome, Colors.amber),
              const SizedBox(height: 12),
              ...availableSkills
                  .map((skill) => _buildAvailableSkillCard(skill)),
              const SizedBox(height: 24),
            ],

            // 未来のスキル
            if (futureSkills.isNotEmpty) ...[
              _buildSectionHeader('今後習得可能', Icons.lock, Colors.grey),
              const SizedBox(height: 12),
              ...futureSkills.map((skill) => _buildFutureSkillCard(skill)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillPointsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.white, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'スキルポイント',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_pet.skillPoints} SP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    '習得済み',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${_pet.skills.length}/${Skill.predefinedSkills.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLearnedSkillCard(Skill skill) {
    final mastery = _pet.skillMastery[skill.id] ?? 0;
    final isMastered = mastery >= 20;
    final masteryPercent = (mastery / 20 * 100).clamp(0, 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMastered ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getElementColor(skill.element).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getElementEmoji(skill.element),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              skill.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isMastered) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'マスター',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          skill.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (skill.power > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${skill.power}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '習熟度',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '$mastery / 20',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              isMastered ? Colors.amber : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: masteryPercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        isMastered ? Colors.amber : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableSkillCard(Skill skill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.new_releases, color: Colors.amber, size: 28),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skill.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lv.${skill.requiredLevel}で自動習得',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureSkillCard(Skill skill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Opacity(
        opacity: 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.lock, color: Colors.grey, size: 28),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.${skill.requiredLevel}で習得',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
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

  Color _getElementColor(String? element) {
    const colors = {
      'fire': Colors.deepOrange,
      'water': Colors.blue,
      'grass': Colors.green,
      'electric': Colors.yellow,
      'ice': Colors.cyan,
      'dark': Colors.purple,
      'light': Colors.amber,
    };
    return colors[element] ?? Colors.grey;
  }

  String _getElementEmoji(String? element) {
    const emojis = {
      'fire': '🔥',
      'water': '💧',
      'grass': '🌿',
      'electric': '⚡',
      'ice': '❄️',
      'dark': '🌑',
      'light': '✨',
    };
    return emojis[element] ?? '⚪';
  }
}
