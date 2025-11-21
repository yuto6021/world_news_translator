import 'package:hive_flutter/hive_flutter.dart';

/// ゲームスコア統合管理サービス（Hive使用）
class GameScoresService {
  static const String _boxName = 'game_scores';
  static Box<int>? _box;

  /// 初期化
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<int>(_boxName);
    } else {
      _box = Hive.box<int>(_boxName);
    }
  }

  /// ベストスコア取得
  static Future<int> getBest(String gameId) async {
    final box = _box ?? await Hive.openBox<int>(_boxName);
    return box.get(gameId, defaultValue: 0) ?? 0;
  }

  /// ベストスコア更新（新記録の場合のみ）
  static Future<bool> updateBest(String gameId, int score) async {
    final box = _box ?? await Hive.openBox<int>(_boxName);
    final current = await getBest(gameId);
    if (score > current) {
      await box.put(gameId, score);
      return true; // 新記録
    }
    return false;
  }

  /// 全スコア取得
  static Future<Map<String, int>> getAll() async {
    final box = _box ?? await Hive.openBox<int>(_boxName);
    return Map<String, int>.fromEntries(
      box.keys.map((k) => MapEntry(k.toString(), box.get(k) ?? 0)),
    );
  }

  /// 特定ゲームのスコアクリア
  static Future<void> clear(String gameId) async {
    final box = _box ?? await Hive.openBox<int>(_boxName);
    await box.delete(gameId);
  }

  /// 全スコアクリア
  static Future<void> clearAll() async {
    final box = _box ?? await Hive.openBox<int>(_boxName);
    await box.clear();
  }
}
