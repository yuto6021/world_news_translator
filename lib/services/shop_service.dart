import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// ショップアイテム
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int price;
  final String type; // theme, pet_item, time_capsule, gacha_ticket, hint
  final Map<String, dynamic>? data;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.price,
    required this.type,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'price': price,
        'type': type,
        'data': data,
      };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        icon: json['icon'],
        price: json['price'],
        type: json['type'],
        data: json['data'],
      );
}

/// ショップサービス
class ShopService {
  static const String _pointsKey = 'achievement_points';
  static const String _purchasedKey = 'purchased_items';
  static const String _activeThemeKey = 'active_theme';

  /// 実績ポイントを取得
  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(_pointsKey);
    
    // 初回は1000pt付与（テスト用）
    if (points == null) {
      await prefs.setInt(_pointsKey, 1000);
      return 1000;
    }
    
    return points;
  }

  /// 実績ポイントを追加
  static Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_pointsKey) ?? 0;
    await prefs.setInt(_pointsKey, current + points);
  }

  /// 実績解除時にポイント付与
  static Future<void> awardPointsForAchievement(Achievement achievement) async {
    int points;
    switch (achievement.rarity) {
      case AchievementRarity.common:
        points = 10;
        break;
      case AchievementRarity.rare:
        points = 30;
        break;
      case AchievementRarity.epic:
        points = 100;
        break;
      case AchievementRarity.legendary:
        points = 300;
        break;
    }
    await addPoints(points);
  }

  /// アイテムを購入
  static Future<bool> purchaseItem(ShopItem item) async {
    final points = await getPoints();
    if (points < item.price) return false;

    final prefs = await SharedPreferences.getInstance();
    
    // ポイント減算
    await prefs.setInt(_pointsKey, points - item.price);
    
    // 購入履歴に追加
    final purchasedStr = prefs.getString(_purchasedKey) ?? '[]';
    final purchased = List<String>.from(json.decode(purchasedStr));
    purchased.add(item.id);
    await prefs.setString(_purchasedKey, json.encode(purchased));
    
    return true;
  }

  /// 購入済みアイテムIDを取得
  static Future<List<String>> getPurchasedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final purchasedStr = prefs.getString(_purchasedKey) ?? '[]';
    return List<String>.from(json.decode(purchasedStr));
  }

  /// アイテムが購入済みかチェック
  static Future<bool> isPurchased(String itemId) async {
    final purchased = await getPurchasedItems();
    return purchased.contains(itemId);
  }

  /// テーマを適用
  static Future<void> setActiveTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeThemeKey, themeId);
  }

  /// アクティブなテーマを取得
  static Future<String> getActiveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeThemeKey) ?? 'default';
  }

  /// アクティブなテーマの色を取得
  static Future<Map<String, dynamic>> getActiveThemeColors() async {
    final themeId = await getActiveTheme();
    if (themeId == 'default') {
      return {
        'primary_color': '#3F51B5', // indigo
        'accent_color': '#FF4081',
      };
    }
    
    final item = getAllItems().firstWhere(
      (item) => item.id == themeId,
      orElse: () => ShopItem(
        id: 'default',
        name: 'デフォルト',
        description: '',
        icon: '',
        price: 0,
        type: 'theme',
        data: {'primary_color': '#3F51B5', 'accent_color': '#FF4081'},
      ),
    );
    
    return item.data ?? {'primary_color': '#3F51B5', 'accent_color': '#FF4081'};
  }

  /// ショップアイテム一覧を取得
  static List<ShopItem> getAllItems() {
    return [
      // テーマスキン
      ShopItem(
        id: 'theme_halloween',
        name: 'ハロウィンテーマ',
        description: 'カボチャと幽霊のアイコンで楽しむハロウィン気分🎃👻',
        icon: '🎃',
        price: 500,
        type: 'theme',
        data: {
          'primary_color': '#FF6600',
          'accent_color': '#9966FF',
          'icon_set': 'halloween',
        },
      ),
      ShopItem(
        id: 'theme_christmas',
        name: 'クリスマステーマ',
        description: '雪とクリスマスツリーで冬の雰囲気を🎄❄️',
        icon: '🎄',
        price: 500,
        type: 'theme',
        data: {
          'primary_color': '#CC0000',
          'accent_color': '#00AA00',
          'icon_set': 'christmas',
        },
      ),
      ShopItem(
        id: 'theme_sakura',
        name: '桜テーマ',
        description: 'ピンクの桜で春を感じる和風デザイン🌸',
        icon: '🌸',
        price: 500,
        type: 'theme',
        data: {
          'primary_color': '#FFB7C5',
          'accent_color': '#FF69B4',
          'icon_set': 'sakura',
        },
      ),
      ShopItem(
        id: 'theme_ocean',
        name: 'オーシャンテーマ',
        description: '海と波のブルーで爽やかな夏気分🌊',
        icon: '🌊',
        price: 500,
        type: 'theme',
        data: {
          'primary_color': '#0077BE',
          'accent_color': '#00CED1',
          'icon_set': 'ocean',
        },
      ),
      ShopItem(
        id: 'theme_galaxy',
        name: 'ギャラクシーテーマ',
        description: '宇宙をテーマにした神秘的なデザイン🌌',
        icon: '🌌',
        price: 800,
        type: 'theme',
        data: {
          'primary_color': '#1A1A40',
          'accent_color': '#8E44AD',
          'icon_set': 'galaxy',
        },
      ),

      // ペットアイテム
      ShopItem(
        id: 'pet_evolution_boost',
        name: 'ペット進化促進剤',
        description: 'ペットの経験値を+100する',
        icon: '⚡',
        price: 200,
        type: 'pet_item',
      ),
      ShopItem(
        id: 'pet_happiness_max',
        name: 'ハッピネスMAXキット',
        description: 'ペットの幸福度を100にする',
        icon: '🥳',
        price: 150,
        type: 'pet_item',
      ),

      // その他
      ShopItem(
        id: 'time_capsule_slot',
        name: 'タイムカプセル枠拡張',
        description: 'タイムカプセルの保存枠を+5増やす',
        icon: '📦',
        price: 300,
        type: 'time_capsule',
      ),
      ShopItem(
        id: 'gacha_ticket',
        name: 'ガチャチケット',
        description: '追加で1回ガチャを引ける',
        icon: '🎫',
        price: 100,
        type: 'gacha_ticket',
      ),
      ShopItem(
        id: 'secret_hint',
        name: 'シークレット実績ヒント',
        description: 'ランダムで1つのシークレット実績のヒントを表示',
        icon: '🔮',
        price: 150,
        type: 'hint',
      ),
    ];
  }

  /// カテゴリ別アイテム取得
  static List<ShopItem> getItemsByType(String type) {
    return getAllItems().where((item) => item.type == type).toList();
  }
}
