import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_item.dart';

class InventoryService {
  static const String _keyInventory = 'inventory';
  static const String _keyCoins = 'coins';

  /// インベントリ取得（アイテムID → 個数のマップ）
  static Future<Map<String, int>> getInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyInventory);

    if (jsonString == null) return {};

    try {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  /// アイテム追加
  static Future<void> addItem(String itemId, {int quantity = 1}) async {
    final inventory = await getInventory();
    inventory[itemId] = (inventory[itemId] ?? 0) + quantity;
    await _saveInventory(inventory);
  }

  /// アイテム削除
  static Future<bool> removeItem(String itemId, {int quantity = 1}) async {
    final inventory = await getInventory();
    final currentQty = inventory[itemId] ?? 0;

    if (currentQty < quantity) return false;

    inventory[itemId] = currentQty - quantity;
    if (inventory[itemId]! <= 0) {
      inventory.remove(itemId);
    }

    await _saveInventory(inventory);
    return true;
  }

  /// アイテム個数確認
  static Future<int> getItemCount(String itemId) async {
    final inventory = await getInventory();
    return inventory[itemId] ?? 0;
  }

  /// アイテム所持チェック
  static Future<bool> hasItem(String itemId, {int quantity = 1}) async {
    final count = await getItemCount(itemId);
    return count >= quantity;
  }

  /// インベントリ保存
  static Future<void> _saveInventory(Map<String, int> inventory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInventory, json.encode(inventory));
  }

  /// 全アイテム取得（GameItemオブジェクトと個数）
  static Future<List<MapEntry<GameItem, int>>> getAllItemsWithCount() async {
    final inventory = await getInventory();
    final items = <MapEntry<GameItem, int>>[];

    for (var entry in inventory.entries) {
      final item = GameItems.getItemById(entry.key);
      if (item != null) {
        items.add(MapEntry(item, entry.value));
      }
    }

    return items;
  }

  // === コイン管理 ===

  /// コイン取得
  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCoins) ?? 0;
  }

  /// コイン追加
  static Future<void> addCoins(int amount) async {
    final current = await getCoins();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, current + amount);
  }

  /// コイン消費
  static Future<bool> spendCoins(int amount) async {
    final current = await getCoins();
    if (current < amount) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, current - amount);
    return true;
  }

  /// アイテム購入
  static Future<bool> buyItem(String itemId, {int quantity = 1}) async {
    final item = GameItems.getItemById(itemId);
    if (item == null) return false;

    final totalPrice = item.price * quantity;
    final success = await spendCoins(totalPrice);

    if (success) {
      await addItem(itemId, quantity: quantity);
      return true;
    }

    return false;
  }

  /// カテゴリ別アイテム取得
  static Future<List<MapEntry<GameItem, int>>> getItemsByCategory(
      String category) async {
    final allItems = await getAllItemsWithCount();
    return allItems.where((entry) => entry.key.category == category).toList();
  }

  /// インベントリクリア（デバッグ用）
  static Future<void> clearInventory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInventory);
  }

  /// コインリセット（デバッグ用）
  static Future<void> resetCoins({int amount = 1000}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, amount);
  }
}
