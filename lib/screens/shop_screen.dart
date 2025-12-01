import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../services/equipment_service.dart';
import '../services/item_effect_service.dart';
import '../services/pet_service.dart';

/// ショップ画面
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _points = 0;
  List<String> _purchased = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final points = await ShopService.getPoints();
    final purchased = await ShopService.getPurchasedItems();

    setState(() {
      _points = points;
      _purchased = purchased;
    });
  }

  Future<void> _purchaseItem(ShopItem item) async {
    // 購入確認
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.icon} ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            Text(
              '価格: ${item.price}pt',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '残高: $_points pt',
              style: TextStyle(
                color: _points >= item.price ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: _points >= item.price
                ? () => Navigator.pop(context, true)
                : null,
            child: const Text('購入'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ShopService.purchaseItem(item);
      if (success) {
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name}を購入しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ポイントが不足しています'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPurchasedAction(ShopItem item) {
    // テーマ適用
    if (item.type == 'theme') {
      return ElevatedButton(
        onPressed: () async {
          await ShopService.setActiveTheme(item.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${item.name}を適用しました\nアプリを再起動すると反映されます'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '再起動',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
          );
        },
        child: const Text('適用'),
      );
    }

    // スキルブック使用
    if (item.id == 'skill_book') {
      return ElevatedButton(
        onPressed: () async {
          final pet = await PetService.getActivePet();
          if (pet == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('アクティブなペットがいません'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          final result = await ItemEffectService.useItem('skill_book', pet.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'スキルブックを使用しました'),
              backgroundColor: result.success ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
              action: result.success
                  ? SnackBarAction(
                      label: 'スキル確認',
                      textColor: Colors.white,
                      onPressed: () async {
                        final updatedPet = await PetService.getPetById(pet.id);
                        if (updatedPet != null && mounted) {
                          Navigator.pushNamed(
                            context,
                            '/skillTree',
                            arguments: updatedPet,
                          );
                        }
                      },
                    )
                  : null,
            ),
          );
        },
        child: const Text('使用'),
      );
    }

    // その他購入済み表示
    return const Icon(Icons.check_circle, color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ショップ 🛍️'),
        backgroundColor: Colors.deepOrange,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '全て'),
            Tab(text: '🎨 テーマ'),
            Tab(text: '🐾 ペット'),
            Tab(text: '🎫 その他'),
            Tab(text: '🎁 購入済み'),
            Tab(text: '💰 売却'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ポイント表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.shade700,
                  Colors.deepOrange.shade500,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Text(
                  '所持ポイント: $_points pt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemList(ShopService.getAllItems()),
                _buildItemList(ShopService.getItemsByType('theme')),
                _buildItemList(ShopService.getItemsByType('pet_item')),
                _buildItemList([
                  ...ShopService.getItemsByType('time_capsule'),
                  ...ShopService.getItemsByType('gacha_ticket'),
                  ...ShopService.getItemsByType('hint'),
                ]),
                _buildPurchasedList(),
                _buildSellTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellTab() {
    return FutureBuilder<Map<String, int>>(
      future: EquipmentService.getInventory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final inventory = snapshot.data!;

        // 売却対象: 素材のみ（装備売却は後続対応）
        final sellable = inventory.entries
            .where((e) => ShopService.getMaterialSellPrice(e.key) > 0)
            .toList();

        if (sellable.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.sell, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('売却可能な素材がありません', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sellable.length,
          itemBuilder: (context, index) {
            final entry = sellable[index];
            final materialId = entry.key;
            final count = entry.value;
            final price = ShopService.getMaterialSellPrice(materialId);
            final materialName = EquipmentService.getMaterialName(materialId);
            final imagePath = EquipmentService.getMaterialImage(materialId);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: imagePath != null
                    ? Image.asset(imagePath, width: 48, height: 48)
                    : const Icon(Icons.inventory_2),
                title: Text(materialName),
                subtitle: Text('所持: $count / 単価: $price pt'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final qty = await _askQuantity(context, count);
                    if (qty != null && qty > 0) {
                      final ok =
                          await ShopService.sellMaterial(materialId, qty);
                      if (!mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$materialName を $qty 個売却しました (+${price * qty}pt)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _loadData();
                        if (!mounted) return;
                        setState(() {});
                      }
                    }
                  },
                  child: const Text('売却'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _askQuantity(BuildContext context, int maxCount) async {
    final controller = TextEditingController(text: '1');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数量を入力'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(helperText: '最大: $maxCount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context, n.clamp(0, maxCount));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
  }

  Widget _buildItemList(List<ShopItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('アイテムがありません'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isPurchased = _purchased.contains(item.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.shade400,
                    Colors.deepOrange.shade600,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  item.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isPurchased)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price} pt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _points >= item.price ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: isPurchased ? null : () => _purchaseItem(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: Text(isPurchased ? '購入済み' : '購入'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildPurchasedList() {
    final purchasedItems = ShopService.getAllItems()
        .where((item) => _purchased.contains(item.id))
        .toList();

    if (purchasedItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'まだアイテムを購入していません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchasedItems.length,
      itemBuilder: (context, index) {
        final item = purchasedItems[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Text(item.icon, style: const TextStyle(fontSize: 32)),
            title: Text(item.name),
            subtitle: Text(item.description),
            trailing: _buildPurchasedAction(item),
          ),
        );
      },
    );
  }
}
