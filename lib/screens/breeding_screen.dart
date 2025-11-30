import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../services/dex_service.dart';
import 'breeding_recipe_screen.dart';

/// ペット繁殖画面
class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  List<PetModel> _adultPets = [];
  PetModel? _parent1;
  PetModel? _parent2;
  bool _isBreeding = false;

  @override
  void initState() {
    super.initState();
    _loadAdultPets();
  }

  Future<void> _loadAdultPets() async {
    final box = await PetService.getBox();
    final pets = box.values.where((pet) {
      return pet.isAlive &&
          (pet.stage == 'adult' || pet.stage == 'ultimate') &&
          pet.level >= 10 &&
          pet.intimacy >= 70;
    }).toList();

    setState(() => _adultPets = pets);
  }

  Future<void> _breed() async {
    if (_parent1 == null || _parent2 == null) return;
    if (_parent1!.id == _parent2!.id) {
      _showMessage('同じペットは選べません');
      return;
    }

    // 配合レシピチェック
    final recipeSpecies = DexService.checkBreedingRecipe(
      _parent1!.species,
      _parent2!.species,
    );
    final recipe = recipeSpecies != null
        ? DexService.getBreedingRecipe(recipeSpecies)
        : null;

    setState(() => _isBreeding = true);

    // 繁殖演出
    await Future.delayed(const Duration(milliseconds: 1500));

    final eggId = await PetService.breedPets(_parent1!.id, _parent2!.id);

    if (eggId.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Text(recipe != null ? '✨ ' : '🎉 '),
              Text(recipe != null ? '特別なたまご誕生！' : 'たまご誕生！'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipe != null ? '🌟🥚🌟' : '🥚',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              Text(
                recipe != null ? '配合限定！${recipe.name}のたまご！' : '新しいたまごが生まれました！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: recipe != null ? Colors.purple : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              if (recipe != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: recipe.rarity == 'mythic'
                          ? [Colors.purple.shade900, Colors.pink.shade900]
                          : [Colors.orange.shade700, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recipe.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('親:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_parent1!.name} × ${_parent2!.name}'),
                    const SizedBox(height: 8),
                    const Text('継承スキル:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    FutureBuilder<PetModel?>(
                      future: PetService.getPetById(eggId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('...');
                        final egg = snapshot.data!;
                        return Text(
                          egg.skills.isEmpty ? 'なし' : egg.skills.join(', '),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ペット一覧から育てましょう！',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true); // 繁殖成功を通知
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isBreeding = false;
      _parent1 = null;
      _parent2 = null;
    });
    _loadAdultPets();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ペット繁殖'),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: '配合レシピ図鑑',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BreedingRecipeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/backgrounds/bg_room_day.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _adultPets.isEmpty
            ? Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text(
                          '繁殖できるペットがいません',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '条件:\n• 成熟期または究極体\n• レベル10以上\n• 親密度70以上',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  // 説明カード
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'ペット繁殖',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('2体の親ペットを選んで新しいたまごを作りましょう！'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('✨ 特徴:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('• 親のスキルをランダムで2つ継承'),
                                Text('• ステータスは親の平均値'),
                                Text('• 属性は親のどちらかを継承'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 親選択エリア
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            '親ペット選択',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildParentSlot('親1', _parent1, 1),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.favorite, color: Colors.pink),
                              ),
                              Expanded(
                                child: _buildParentSlot('親2', _parent2, 2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 配合予測表示
                          if (_parent1 != null && _parent2 != null) ...[
                            _buildBreedingPrediction(),
                            const SizedBox(height: 16),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: (_parent1 != null &&
                                      _parent2 != null &&
                                      !_isBreeding)
                                  ? _breed
                                  : null,
                              icon: _isBreeding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.favorite),
                              label: Text(_isBreeding ? '繁殖中...' : '繁殖する'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ペット一覧
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '選択可能なペット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _adultPets.length,
                      itemBuilder: (context, index) {
                        final pet = _adultPets[index];
                        final isSelected =
                            pet.id == _parent1?.id || pet.id == _parent2?.id;

                        return Card(
                          color:
                              isSelected ? Colors.pink.shade50 : Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: _buildPetAvatar(pet),
                            title: Text(
                              pet.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${pet.stage} Lv.${pet.level} | 親密度:${pet.intimacy}\n'
                              'スキル: ${pet.skills.isEmpty ? 'なし' : pet.skills.join(', ')}',
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.pink)
                                : null,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  // 選択解除
                                  if (_parent1?.id == pet.id) {
                                    _parent1 = null;
                                  } else if (_parent2?.id == pet.id) {
                                    _parent2 = null;
                                  }
                                } else {
                                  // 選択
                                  if (_parent1 == null) {
                                    _parent1 = pet;
                                  } else if (_parent2 == null) {
                                    _parent2 = pet;
                                  } else {
                                    _showMessage('2体まで選択できます');
                                  }
                                }
                              });
                            },
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

  Widget _buildBreedingPrediction() {
    if (_parent1 == null || _parent2 == null) {
      return const SizedBox.shrink();
    }

    final recipeSpecies = DexService.checkBreedingRecipe(
      _parent1!.species,
      _parent2!.species,
    );
    final recipe = recipeSpecies != null
        ? DexService.getBreedingRecipe(recipeSpecies)
        : null;

    if (recipe != null) {
      // 配合限定ペット
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: recipe.rarity == 'mythic'
                ? [Colors.purple.shade600, Colors.pink.shade600]
                : [Colors.orange.shade600, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade300,
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  '✨',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '配合限定: ${recipe.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
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
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recipe.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.yellow, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'スキル3つ継承 + ステータス+20%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 通常配合
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '通常配合: ${_parent1!.species} または ${_parent2!.species}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildParentSlot(String label, PetModel? pet, int slot) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: pet != null ? Colors.pink.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pet != null ? Colors.pink : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: pet == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPetAvatar(pet, size: 40),
                  const SizedBox(height: 4),
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Lv.${pet.level}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPetAvatar(PetModel pet, {double size = 48}) {
    final imagePath =
        'assets/pets/${pet.stage}/${pet.stage}_${pet.species}_normal.png';

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getStageEmoji(pet.stage),
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        );
      },
    );
  }

  String _getStageEmoji(String stage) {
    switch (stage) {
      case 'egg':
        return '🥚';
      case 'baby':
        return '👶';
      case 'child':
        return '🧒';
      case 'adult':
        return '🦖';
      case 'ultimate':
        return '🐉';
      default:
        return '🐾';
    }
  }
}
