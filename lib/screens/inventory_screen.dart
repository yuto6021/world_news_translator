import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../services/item_effect_service.dart';
import '../services/pet_service.dart';
import '../models/game_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _inventory = {};
  bool _loading = true;
  String? _activePetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _loading = true);

    final pet = await PetService.getActivePet();
    _activePetId = pet?.id;

    final items = await InventoryService.getInventory();
    setState(() {
      _inventory = items;
      _loading = false;
    });
  }

  Future<void> _useItem(String itemId) async {
    if (_activePetId == null) {
      _showMessage('エラー', 'ペットが見つかりません');
      return;
    }

    final result = await ItemEffectService.useItem(itemId, _activePetId!);

    if (result.success) {
      _showMessage('✅ 使用成功', result.message);
      await _loadInventory();
    } else {
      _showMessage('⚠️ 使用失敗', result.message);
    }
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

  void _showItemDetail(GameItem item, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              item.imagePath,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.inventory_2, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description),
              const Divider(height: 24),
              if (item.stats != null && item.stats!.isNotEmpty) ...[
                const Text('ステータス効果:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...item.stats!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${e.key}: +${e.value}'),
                    )),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('所持数: $count個',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('価格: ${item.price}コイン',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          if (item.category == 'consumables' || item.category == 'rare')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _useItem(item.id);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('使用する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(String category) {
    final items = GameItems.getItemsByCategory(category);
    final ownedItems = items.where((item) {
      final count = _inventory[item.id] ?? 0;
      return count > 0;
    }).toList();

    if (ownedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'このカテゴリのアイテムを\n所持していません',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: ownedItems.length,
      itemBuilder: (context, index) {
        final item = ownedItems[index];
        final count = _inventory[item.id] ?? 0;
        return _buildItemCard(item, count);
      },
    );
  }

  Widget _buildItemCard(GameItem item, int count) {
    Color categoryColor;
    switch (item.category) {
      case 'consumables':
        categoryColor = Colors.green;
        break;
      case 'equipment':
        categoryColor = Colors.blue;
        break;
      case 'rare':
        categoryColor = Colors.purple;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: categoryColor.withOpacity(0.5), width: 2),
      ),
      child: InkWell(
        onTap: () => _showItemDetail(item, count),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.inventory_2, size: 50, color: categoryColor),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '×$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アイテムボックス'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: '消費'),
            Tab(icon: Icon(Icons.shield), text: '装備'),
            Tab(icon: Icon(Icons.star), text: 'レア'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInventory,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemGrid('consumables'),
                  _buildItemGrid('equipment'),
                  _buildItemGrid('rare'),
                ],
              ),
            ),
    );
  }
}
