import 'package:flutter/material.dart';
import '../models/game_item.dart';
import '../services/inventory_service.dart';

class ItemShopScreen extends StatefulWidget {
  const ItemShopScreen({super.key});

  @override
  State<ItemShopScreen> createState() => _ItemShopScreenState();
}

class _ItemShopScreenState extends State<ItemShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coins = 0;
  Map<String, int> _inventory = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final coins = await InventoryService.getCoins();
    final inventory = await InventoryService.getInventory();
    setState(() {
      _coins = coins;
      _inventory = inventory;
    });
  }

  void _showMessage(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _buyItem(GameItem item) async {
    final success = await InventoryService.buyItem(item.id);

    if (success) {
      _showMessage('${item.name}を購入しました！');
      _loadData();
    } else {
      _showMessage('コインが足りません', isSuccess: false);
    }
  }

  void _showItemDetail(GameItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              item.imagePath,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.inventory, size: 40);
              },
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('価格:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text('${item.price}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('所持数:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_inventory[item.id] ?? 0}個',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            if (item.stats != null) ...[
              const SizedBox(height: 12),
              const Text('装備効果:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...item.stats!.entries
                  .map((e) => Text('  ${e.key}: +${e.value}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _buyItem(item);
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('購入'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アイテムショップ'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '$_coins',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.fastfood), text: '消費'),
            Tab(icon: Icon(Icons.security), text: '装備'),
            Tab(icon: Icon(Icons.star), text: 'レア'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFFfff9c4), const Color(0xFFffecb3)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildItemGrid(GameItems.consumables),
            _buildItemGrid(GameItems.equipment),
            _buildItemGrid(GameItems.rare),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid(List<GameItem> items) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final ownedCount = _inventory[item.id] ?? 0;

          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () => _showItemDetail(item),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            _getCategoryColor(item.category).withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Image.asset(
                              item.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.inventory,
                                    size: 60, color: Colors.grey);
                              },
                            ),
                          ),
                          if (ownedCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$ownedCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.monetization_on,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.price}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.add_shopping_cart,
                                color: _coins >= item.price
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'consumable':
        return Colors.green;
      case 'equipment':
        return Colors.blue;
      case 'rare':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
