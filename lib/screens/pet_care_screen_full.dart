import 'package:flutter/material.dart';
import '../utils/pet_image_resolver.dart';
import '../services/pet_service.dart';
import '../models/pet.dart';
import '../services/talent_discovery_service.dart';
import '../services/intimacy_bond_service.dart';
import 'battle_screen.dart';
import 'item_shop_screen.dart';
import 'inventory_screen.dart';
import 'training_screen.dart';
import 'training_policy_screen.dart';
import 'awakening_screen.dart';

class PetCareScreenFull extends StatefulWidget {
  const PetCareScreenFull({super.key});

  @override
  State<PetCareScreenFull> createState() => _PetCareScreenFullState();
}

class _PetCareScreenFullState extends State<PetCareScreenFull>
    with SingleTickerProviderStateMixin {
  PetModel? _currentPet;
  bool _loading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _loadPet();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPet() async {
    setState(() => _loading = true);
    final pet = await PetService.getActivePet();

    if (pet != null) {
      await PetService.updateGauges(pet.id);
      final updatedPet = await PetService.getActivePet();
      setState(() {
        _currentPet = updatedPet;
        _loading = false;
      });

      // 才能発見チェック
      if (updatedPet != null && !updatedPet.talentDiscovered) {
        final canDiscover =
            await TalentDiscoveryService.checkDiscoveryConditions(updatedPet);
        if (canDiscover) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _showTalentDiscoveryDialog();
          });
        }
      }

      // 絆レベルアップチェック
      if (updatedPet != null) {
        await _checkBondLevelUp(updatedPet);
      }
    } else {
      setState(() {
        _currentPet = null;
        _loading = false;
      });
    }
  }

  Future<void> _performAction(String action) async {
    if (_currentPet == null || !_currentPet!.isAlive) return;

    try {
      switch (action) {
        case 'feed':
          await PetService.feedPet(_currentPet!.id);
          _showMessage('🍚 ごはんを食べました！', 'お腹+30、機嫌+5');
          break;
        case 'play':
          await PetService.playWithPet(_currentPet!.id, 'ball');
          _showMessage('🎾 楽しく遊びました！', '機嫌+20、経験値+10、親密度+2');
          break;
        case 'clean':
          await PetService.cleanPet(_currentPet!.id);
          _showMessage('🧼 ピカピカになりました！', '汚れ0、機嫌+15');
          break;
        case 'medicine':
          if (_currentPet!.isSick) {
            await PetService.giveMedicine(_currentPet!.id);
            _showMessage('💊 病気が治りました！', '元気になりました');
          } else {
            _showMessage('💊 病気ではありません', '健康です');
          }
          break;
      }
      await _loadPet();
      _checkEvolution();
    } catch (e) {
      _showMessage('エラー', '$e');
    }
  }

  void _goToBattle() {
    if (_currentPet == null || !_currentPet!.isAlive) {
      _showMessage('エラー', 'ペットが元気ではありません');
      return;
    }
    if (_currentPet!.stamina < 20) {
      _showMessage('体力不足', 'バトルには体力20以上必要です');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BattleScreen(pet: _currentPet!),
      ),
    ).then((_) => _loadPet());
  }

  void _showMessage(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkEvolution() async {
    if (_currentPet == null) return;

    final canEvolve = await PetService.canEvolve(_currentPet!.id);
    if (canEvolve) {
      final evolutions =
          await PetService.getAvailableEvolutions(_currentPet!.id);
      if (evolutions.isNotEmpty) {
        _showEvolutionDialog(evolutions);
      }
    }
  }

  void _showEvolutionDialog(List<String> evolutions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('進化可能！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_currentPet!.name}が進化できます！'),
            const SizedBox(height: 16),
            ...evolutions.map((species) => ListTile(
                  title: Text(species),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    Navigator.pop(context);
                    await PetService.evolvePet(_currentPet!.id, species);
                    await _loadPet();
                    _showMessage('🎉 進化成功！', '$speciesに進化しました！');
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  String _getPetImagePath(PetModel pet) {
    String state = 'normal';
    if (pet.isSick) {
      state = 'sick';
    } else if (pet.mood >= 80) {
      state = 'happy';
    } else if (pet.mood <= 20) {
      state = 'angry';
    }
    return PetImageResolver.resolveImage(pet.stage, pet.species, state);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ペットケア')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentPet == null) {
      return _buildNoPetScreen(isDark);
    }

    if (!_currentPet!.isAlive) {
      return _buildDeathScreen(isDark);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPet!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ItemShopScreen()),
              );
            },
            tooltip: 'ショップ',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showStatsDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: () => _showAllPetsDialog(),
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
        child: RefreshIndicator(
          onRefresh: _loadPet,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPetDisplay(isDark),
              const SizedBox(height: 16),
              _buildStatusBars(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildInfoCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetDisplay(bool isDark) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.grey[850]!, Colors.grey[900]!]
                : [Colors.white, Colors.grey[50]!],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // レベル・年齢表示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Lv', '${_currentPet!.level}', Colors.orange),
                _buildStatChip('年齢', '${_currentPet!.age}日', Colors.green),
                _buildStatChip('親密度', _currentPet!.intimacyLevel, Colors.pink),
              ],
            ),
            const SizedBox(height: 20),

            // ペット画像
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.05),
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: _currentPet!.isSick
                          ? Colors.red.withOpacity(0.1)
                          : (_currentPet!.mood >= 80
                              ? Colors.yellow.withOpacity(0.1)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _currentPet!.isSick
                            ? Colors.red
                            : (_currentPet!.mood >= 80
                                ? Colors.amber
                                : Colors.grey[400]!),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        _getPetImagePath(_currentPet!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                _currentPet!.species,
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[600]),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ステージバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[700]!, Colors.purple[500]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _stageLabel(_currentPet!.stage),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBars() {
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
                const Icon(Icons.favorite, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text('ステータス',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  _currentPet!.healthStatus,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _currentPet!.isSick ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGaugeBar(
                'お腹', _currentPet!.hunger, Icons.restaurant, Colors.orange),
            _buildGaugeBar(
                '機嫌', _currentPet!.mood, Icons.emoji_emotions, Colors.pink),
            _buildGaugeBar('清潔', 100 - _currentPet!.dirty,
                Icons.cleaning_services, Colors.blue),
            _buildGaugeBar('体力', _currentPet!.stamina,
                Icons.battery_charging_full, Colors.green),
            if (_currentPet!.isSick)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sick, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('病気',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text('症状: ${_currentPet!.sickness}',
                              style: const TextStyle(fontSize: 12)),
                        ],
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

  Widget _buildGaugeBar(String label, int value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$value/100',
                  style: TextStyle(
                      fontSize: 14, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value / 100,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app, size: 24),
                SizedBox(width: 8),
                Text('アクション',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildActionButton('食事', Icons.restaurant, Colors.orange,
                    () => _performAction('feed')),
                _buildActionButton('遊ぶ', Icons.sports_esports, Colors.pink,
                    () => _performAction('play')),
                _buildActionButton('掃除', Icons.cleaning_services, Colors.blue,
                    () => _performAction('clean')),
                _buildActionButton('薬', Icons.medication, Colors.red,
                    () => _performAction('medicine')),
                _buildActionButton(
                    'バトル', Icons.flash_on, Colors.deepPurple, _goToBattle),
                _buildActionButton(
                  'アイテム',
                  Icons.inventory_2,
                  Colors.teal,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventoryScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  '特訓',
                  Icons.fitness_center,
                  Colors.amber,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainingScreen(pet: _currentPet!),
                      ),
                    );

                    // 特訓後に才能発見記録
                    await TalentDiscoveryService.recordTraining(
                        _currentPet!.id);
                    await _loadPet();
                  },
                ),
                _buildActionButton(
                  '育成方針',
                  Icons.trending_up,
                  Colors.indigo,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TrainingPolicyScreen(pet: _currentPet!),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  '覚醒',
                  Icons.auto_awesome,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AwakeningScreen(pet: _currentPet!),
                      ),
                    ).then((_) => _loadPet());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('詳細情報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow('種族', _currentPet!.species),
            _buildInfoRow(
                '経験値', '${_currentPet!.exp}/${_currentPet!.expToNextLevel}'),
            const Divider(height: 24),
            const Text('バトルステータス',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _buildStatBox(
                        '攻撃', _currentPet!.attack, Icons.flash_on, Colors.red)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatBox(
                        '防御', _currentPet!.defense, Icons.shield, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatBox(
                        '速さ', _currentPet!.speed, Icons.speed, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('勝利', '${_currentPet!.wins}回'),
            _buildInfoRow('敗北', '${_currentPet!.losses}回'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          Text('$value',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPetScreen(bool isDark) {
    return Scaffold(
      appBar: AppBar(title: const Text('ペットケア')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.egg, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'ペットがいません',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '新しいたまごを作りましょう！',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final name = await _showNameInputDialog();
                if (name != null && name.isNotEmpty) {
                  PetModel.createEgg(name);
                  _loadPet();
                }
              },
              icon: const Icon(Icons.add_circle, size: 28),
              label: const Text('たまごを作る', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeathScreen(bool isDark) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentPet!.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_very_dissatisfied,
                size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              '${_currentPet!.name}は',
              style: const TextStyle(fontSize: 24),
            ),
            const Text(
              '天国へ旅立ちました...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '享年: ${_currentPet!.age}日',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final name = await _showNameInputDialog();
                if (name != null && name.isNotEmpty) {
                  PetModel.createEgg(name);
                  _loadPet();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('新しいたまごを作る'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showNameInputDialog() async {
    String name = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいたまご'),
        content: TextField(
          onChanged: (value) => name = value,
          decoration: const InputDecoration(
            hintText: 'ペットの名前を入力',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, name),
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('統計情報'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('遊んだ回数: ${_currentPet!.playCount}回'),
              Text('掃除した回数: ${_currentPet!.cleanCount}回'),
              Text('バトル参加: ${_currentPet!.battleCount}回'),
              const Divider(),
              const Text('ジャンル経験値:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._currentPet!.genreStats.entries
                  .map((e) => Text('${e.key}: ${e.value}')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showAllPetsDialog() async {
    final allPets = await PetService.getAllPets();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全てのペット'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allPets.length,
            itemBuilder: (context, index) {
              final pet = allPets[index];
              return ListTile(
                leading: Icon(
                  pet.isAlive ? Icons.pets : Icons.sentiment_very_dissatisfied,
                  color: pet.isAlive ? Colors.green : Colors.grey,
                ),
                title: Text(pet.name),
                subtitle: Text('${pet.species} Lv.${pet.level}'),
                trailing: pet.isActive
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
                onTap: pet.isAlive
                    ? () async {
                        await PetService.setActivePet(pet.id);
                        Navigator.pop(context);
                        _loadPet();
                      }
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる')),
        ],
      ),
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

  // 才能発見ダイアログ
  Future<void> _showTalentDiscoveryDialog() async {
    if (_currentPet == null || _currentPet!.talentDiscovered) return;

    await TalentDiscoveryService.discoverTalent(_currentPet!);
    final talentInfo = TalentDiscoveryService.getTalentInfo(_currentPet!);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade600, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '才能発見！',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_currentPet!.nickname}の隠された才能が明らかになりました！',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              _buildTalentCard(
                '攻撃才能',
                talentInfo['attack'],
                Icons.flash_on,
                Colors.red,
              ),
              const SizedBox(height: 12),
              _buildTalentCard(
                '防御才能',
                talentInfo['defense'],
                Icons.shield,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildTalentCard(
                '速度才能',
                talentInfo['speed'],
                Icons.speed,
                Colors.green,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '才能値が高いほど、レベルアップ時の成長率が向上します',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('素晴らしい！', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTalentCard(
    String label,
    Map<String, dynamic> info,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${info['value']} / 90  -  ${info['rank']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info['description'] as String,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 絆レベルアップチェック
  int _lastBondLevel = 0;

  Future<void> _checkBondLevelUp(PetModel pet) async {
    final currentLevel = IntimacyBondService.getBondLevel(pet.intimacy);

    if (_lastBondLevel == 0) {
      _lastBondLevel = currentLevel;
      return;
    }

    if (currentLevel > _lastBondLevel) {
      _lastBondLevel = currentLevel;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _showBondLevelUpDialog(currentLevel);
      });
    }
  }

  Future<void> _showBondLevelUpDialog(int newLevel) async {
    if (_currentPet == null) return;

    final bondLevel = IntimacyBondService.bondLevels[newLevel - 1];
    final bonus = IntimacyBondService.getBondBonus(_currentPet!.intimacy);
    final newSkills = IntimacyBondService.getUnlockedSkillsForLevel(newLevel);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade400, Colors.purple.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '絆レベルアップ！',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    bondLevel['name'] as String,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '絆レベル $newLevel',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            const Text(
              'ステータスボーナス',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBonusStat(
                    '攻撃', bonus['attack']!, Icons.flash_on, Colors.red),
                _buildBonusStat(
                    '防御', bonus['defense']!, Icons.shield, Colors.blue),
                _buildBonusStat(
                    '速度', bonus['speed']!, Icons.speed, Colors.green),
              ],
            ),
            if (newSkills.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                '新スキル習得',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...newSkills.map((skill) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 20, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          skill.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('ありがとう！', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusStat(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          '+$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
