import 'package:shared_preferences/shared_preferences.dart';

/// ステージ設定情報
class StageConfig {
  final int stage; // ステージ番号 (1,2,3...)
  final double rewardMultiplier; // 報酬(コイン/EXP)倍率
  final double spMultiplier; // スキルポイント倍率
  final double enemyStatMultiplier; // 敵ステータス倍率 (HP/攻撃/防御)

  const StageConfig({
    required this.stage,
    required this.rewardMultiplier,
    required this.spMultiplier,
    required this.enemyStatMultiplier,
  });
}

/// ステージ関連ユーティリティ
class StageService {
  static const _highestClearedKey = 'highest_cleared_stage';

  /// ステージ定義テーブル（必要に応じて拡張）
  static const List<StageConfig> _configs = [
    StageConfig(
        stage: 1,
        rewardMultiplier: 1.0,
        spMultiplier: 1.0,
        enemyStatMultiplier: 1.0),
    StageConfig(
        stage: 2,
        rewardMultiplier: 1.15,
        spMultiplier: 1.05,
        enemyStatMultiplier: 1.10),
    StageConfig(
        stage: 3,
        rewardMultiplier: 1.30,
        spMultiplier: 1.10,
        enemyStatMultiplier: 1.20),
    StageConfig(
        stage: 4,
        rewardMultiplier: 1.45,
        spMultiplier: 1.15,
        enemyStatMultiplier: 1.30),
    StageConfig(
        stage: 5,
        rewardMultiplier: 1.60,
        spMultiplier: 1.20,
        enemyStatMultiplier: 1.40),
    StageConfig(
        stage: 6,
        rewardMultiplier: 1.80,
        spMultiplier: 1.25,
        enemyStatMultiplier: 1.55),
    StageConfig(
        stage: 7,
        rewardMultiplier: 2.00,
        spMultiplier: 1.30,
        enemyStatMultiplier: 1.70),
    StageConfig(
        stage: 8,
        rewardMultiplier: 2.25,
        spMultiplier: 1.35,
        enemyStatMultiplier: 1.85),
    StageConfig(
        stage: 9,
        rewardMultiplier: 2.50,
        spMultiplier: 1.40,
        enemyStatMultiplier: 2.00),
    StageConfig(
        stage: 10,
        rewardMultiplier: 2.80,
        spMultiplier: 1.50,
        enemyStatMultiplier: 2.20),
  ];

  static StageConfig getConfig(int stage) {
    return _configs.firstWhere(
      (c) => c.stage == stage,
      orElse: () => _configs.last,
    );
  }

  static Future<int> getHighestClearedStage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highestClearedKey) ?? 1;
  }

  static Future<void> saveHighestClearedStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_highestClearedKey) ?? 1;
    if (stage > current) {
      await prefs.setInt(_highestClearedKey, stage);
    }
  }
}
