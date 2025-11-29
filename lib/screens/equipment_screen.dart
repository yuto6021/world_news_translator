import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/equipment_service.dart';

class EquipmentScreen extends StatefulWidget {
  final PetModel pet;

  const EquipmentScreen({super.key, required this.pet});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  Map<String, int> _inventory = {};

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final inventory = await EquipmentService.getInventory();
    setState(() => _inventory = inventory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('装備管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: () => _showCraftingDialog(),
            tooltip: 'クラフト',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.blue.shade50],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 現在の装備
            _buildCurrentEquipment(),
            const SizedBox(height: 24),

            // 装備効果サマリー
            _buildEquipmentStats(),
            const SizedBox(height: 24),

            // 所持装備リスト
            _buildEquipmentInventory(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEquipment() {
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
                const Icon(Icons.shield, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Text(
                  '装備中',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildEquipmentSlot(
              'weapon',
              '⚔️ 武器',
              widget.pet.equippedWeapon,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildEquipmentSlot(
              'armor',
              '🛡️ 防具',
              widget.pet.equippedArmor,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildEquipmentSlot(
              'accessory',
              '💍 アクセサリー',
              widget.pet.equippedAccessory,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSlot(
      String slot, String label, String? equipmentId, Color color) {
    final equipment =
        equipmentId != null ? EquipmentService.recipes[equipmentId] : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label.split(' ')[0],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  equipment?['name'] ?? '未装備',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: equipment != null
                        ? Colors.grey.shade800
                        : Colors.grey.shade400,
                  ),
                ),
                if (equipment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getEffectDescription(equipment['effect']),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          if (equipment != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _unequip(slot),
            )
          else
            IconButton(
              icon: Icon(Icons.add_circle, color: color),
              onPressed: () => _showEquipDialog(slot),
            ),
        ],
      ),
    );
  }

  Widget _buildEquipmentStats() {
    final bonus = EquipmentService.getTotalEquipmentBonus(
      widget.pet.equippedWeapon,
      widget.pet.equippedArmor,
      widget.pet.equippedAccessory,
    );

    if (bonus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '装備効果',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...bonus.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStatName(entry.key),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '×${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentInventory() {
    final equipments = _inventory.entries
        .where((e) => EquipmentService.recipes.containsKey(e.key))
        .toList();

    if (equipments.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  '装備を所持していません',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'クラフトで作成しましょう',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                const Icon(Icons.inventory, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '所持装備',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...equipments
                .map((entry) => _buildEquipmentItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentItem(String equipmentId, int count) {
    final equipment = EquipmentService.recipes[equipmentId]!;
    final isEquipped = widget.pet.equippedWeapon == equipmentId ||
        widget.pet.equippedArmor == equipmentId ||
        widget.pet.equippedAccessory == equipmentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEquipped ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEquipped ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('⚔️', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getEffectDescription(equipment['effect']),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '装備中',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '×$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEquipDialog(String slot) {
    final equipments = _inventory.entries
        .where((e) => EquipmentService.recipes.containsKey(e.key))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getSlotName(slot)}を装備'),
        content: equipments.isEmpty
            ? const Text('装備可能なアイテムがありません')
            : SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: equipments
                      .map((e) => ListTile(
                            leading: _buildItemImage(
                                EquipmentService.recipes[e.key]!['image'],
                                '⚔️'),
                            title:
                                Text(EquipmentService.recipes[e.key]!['name']),
                            subtitle: Text(
                              _getEffectDescription(
                                  EquipmentService.recipes[e.key]!['effect']),
                            ),
                            trailing: Text('×${e.value}'),
                            onTap: () {
                              Navigator.pop(context);
                              _equip(slot, e.key);
                            },
                          ))
                      .toList(),
                ),
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

  void _showCraftingDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CraftingScreen(
          onCrafted: () {
            _loadInventory();
          },
        ),
      ),
    );
  }

  Future<void> _equip(String slot, String equipmentId) async {
    final success =
        await EquipmentService.equip(widget.pet.id, equipmentId, slot);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${EquipmentService.recipes[equipmentId]!['name']}を装備しました'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _unequip(String slot) async {
    await EquipmentService.unequip(widget.pet.id, slot);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('装備を外しました'),
        ),
      );
      setState(() {});
    }
  }

  String _getSlotName(String slot) {
    switch (slot) {
      case 'weapon':
        return '武器';
      case 'armor':
        return '防具';
      case 'accessory':
        return 'アクセサリー';
      default:
        return '';
    }
  }

  String _getStatName(String stat) {
    switch (stat) {
      case 'attack':
        return '攻撃力';
      case 'defense':
        return '防御力';
      case 'speed':
        return '素早さ';
      case 'lifesteal':
        return 'HP吸収';
      case 'hp':
        return 'HP';
      case 'skill_power':
        return 'スキル威力';
      case 'support':
        return 'サポート効果';
      case 'crit_rate':
        return 'クリティカル率';
      default:
        return stat;
    }
  }

  String _getEffectDescription(Map<String, dynamic> effect) {
    final parts = <String>[];
    effect.forEach((key, value) {
      if (key == 'lifesteal' || key == 'crit_rate') {
        parts.add('${_getStatName(key)}+${(value * 100).toStringAsFixed(0)}%');
      } else {
        final statName = _getStatName(key);
        final percent = ((value - 1) * 100).toStringAsFixed(0);
        parts.add('$statName+$percent%');
      }
    });
    return parts.join(', ');
  }

  Widget _buildItemImage(String? imagePath, String fallbackEmoji) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(fallbackEmoji, style: const TextStyle(fontSize: 24));
        },
      );
    }
    return Text(fallbackEmoji, style: const TextStyle(fontSize: 24));
  }
}

// クラフト画面
class CraftingScreen extends StatefulWidget {
  final VoidCallback onCrafted;

  const CraftingScreen({super.key, required this.onCrafted});

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends State<CraftingScreen> {
  Map<String, int> _inventory = {};

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final inventory = await EquipmentService.getInventory();
    setState(() => _inventory = inventory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クラフト'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade50, Colors.red.shade50],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 素材リスト
            _buildMaterialsCard(),
            const SizedBox(height: 24),

            // レシピリスト
            _buildRecipesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final materials = _inventory.entries
        .where((e) => EquipmentService.dropMaterials.containsKey(e.key))
        .toList();

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
                const Icon(Icons.inventory_2, color: Colors.brown, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '所持素材',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (materials.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '素材を所持していません\nバトルで入手しましょう',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...materials.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _buildMaterialImage(e.key),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            EquipmentService.getMaterialName(e.key),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '×${e.value}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesCard() {
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
                const Icon(Icons.build_circle, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'レシピ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...EquipmentService.recipes.entries.map((entry) {
              final recipe = entry.value;
              final material = recipe['material'] as String;
              final required = recipe['requiredCount'] as int;
              final owned = _inventory[material] ?? 0;
              final canCraft = owned >= required;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: canCraft ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canCraft ? Colors.green : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildItemImage(recipe['image'], '⚔️'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getEffectDescription(recipe['effect']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMaterialImage(material),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            EquipmentService.getMaterialName(material),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '$owned / $required',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: canCraft ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: canCraft ? () => _craft(entry.key) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('作成'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _craft(String equipmentId) async {
    final success = await EquipmentService.craft(equipmentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${EquipmentService.recipes[equipmentId]!['name']}を作成しました！'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadInventory();
      widget.onCrafted();
    }
  }

  String _getMaterialEmoji(String materialId) {
    const emojis = {
      'dragon_scale': '🐉',
      'dragon_bone': '🦴',
      'dragon_flame_sac': '🔥',
      'beast_fang': '🦷',
      'beast_claw': '🐾',
      'beast_hide': '🧵',
      'ore_fire_crystal': '💎',
      'ore_water_pearl': '🫧',
      'ore_nature_leafstone': '🍃',
      'ore_rock_fragment': '🪨',
      'ore_light_shard': '✨',
      'ore_dark_shard': '🌑',
      'magic_core_small': '🔮',
      'magic_core_medium': '💫',
      'magic_core_large': '⭐',
      'enchanted_thread': '🧵',
      'wood_plank': '🪵',
      'iron_ingot': '⚙️',
      'leather_strip': '🧵',
      'rune_stone': '📜',
    };
    return emojis[materialId] ?? '📦';
  }

  Widget _buildMaterialImage(String materialId) {
    final imagePath = EquipmentService.getMaterialImage(materialId);
    final fallbackEmoji = _getMaterialEmoji(materialId);

    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(fallbackEmoji, style: const TextStyle(fontSize: 24));
        },
      );
    }
    return Text(fallbackEmoji, style: const TextStyle(fontSize: 24));
  }

  Widget _buildItemImage(String? imagePath, String fallbackEmoji) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(fallbackEmoji, style: const TextStyle(fontSize: 32));
        },
      );
    }
    return Text(fallbackEmoji, style: const TextStyle(fontSize: 32));
  }

  String _getEffectDescription(Map<String, dynamic> effect) {
    final parts = <String>[];
    effect.forEach((key, value) {
      if (key == 'lifesteal' || key == 'crit_rate') {
        parts.add('$key+${(value * 100).toStringAsFixed(0)}%');
      } else {
        final percent = ((value - 1) * 100).toStringAsFixed(0);
        parts.add('$key+$percent%');
      }
    });
    return parts.join(', ');
  }
}
