import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pet_service.dart';

/// 特訓サービス - 個別ステータス強化システム
class TrainingService {
  static const String _keyTrainingData = 'training_data';
  static const String _keyTrainingHistory = 'training_history';
  static final _random = Random();

  /// 特訓タイプ
  static const trainingTypes = {
    'attack': {
      'name': '攻撃訓練',
      'description': '攻撃力を鍛える（ミニゲーム：タイミング）',
      'icon': '⚔️',
      'cost': 50, // コイン消費
      'baseGain': 2, // 基礎成長値
      'maxGain': 5, // 最大成長値
    },
    'defense': {
      'name': '防御訓練',
      'description': '防御力を鍛える（ミニゲーム：連打）',
      'icon': '🛡️',
      'cost': 50,
      'baseGain': 2,
      'maxGain': 5,
    },
    'speed': {
      'name': '俊敏訓練',
      'description': '素早さを鍛える（ミニゲーム：反射）',
      'icon': '⚡',
      'cost': 50,
      'baseGain': 2,
      'maxGain': 5,
    },
  };

  /// 特訓を実行（ミニゲーム結果に基づいてステータス上昇）
  static Future<TrainingResult> executeTrain({
    required String petId,
    required String trainingType,
    required int miniGameScore, // 0-100のスコア
  }) async {
    final config = trainingTypes[trainingType];
    if (config == null) {
      throw Exception('無効な特訓タイプ');
    }

    final prefs = await SharedPreferences.getInstance();

    // コイン消費チェック
    final coins = prefs.getInt('coins') ?? 0;
    if (coins < (config['cost'] as int)) {
      throw Exception('コインが不足しています');
    }

    // 連続特訓ボーナスを計算
    final streakBonus = await _updateTrainingStreak(petId);

    // ミニゲームスコアから成長値を計算
    final baseGain = config['baseGain'] as int;
    final maxGain = config['maxGain'] as int;
    final scoreRatio = miniGameScore / 100.0;
    var statGain = (baseGain + (maxGain - baseGain) * scoreRatio).round();

    // 連続特訓ボーナス適用
    statGain = (statGain * streakBonus).round();

    // ボーナス判定（パーフェクトで追加ボーナス）
    final bonusGain = miniGameScore >= 95 ? 2 : 0;
    final totalGain = statGain + bonusGain;

    // ステータス更新
    final pet = await PetService.getPetById(petId);
    if (pet == null) throw Exception('ペットが見つかりません');

    switch (trainingType) {
      case 'attack':
        await PetService.updatePetStats(petId, attack: pet.attack + totalGain);
        break;
      case 'defense':
        await PetService.updatePetStats(petId,
            defense: pet.defense + totalGain);
        break;
      case 'speed':
        await PetService.updatePetStats(petId, speed: pet.speed + totalGain);
        break;
    }

    // コイン消費
    await prefs.setInt('coins', coins - (config['cost'] as int));

    // 特訓回数記録
    await _recordTraining(petId, trainingType, totalGain);

    // 最新のストリーク情報を取得
    final updatedPet = await PetService.getPetById(petId);
    final currentStreak = updatedPet?.trainingStreak ?? 0;

    return TrainingResult(
      trainingType: trainingType,
      statGain: totalGain,
      score: miniGameScore,
      isPerfect: miniGameScore >= 95,
      bonusGain: bonusGain,
      trainingStreak: currentStreak,
    );
  }

  /// 特訓履歴を記録
  static Future<void> _recordTraining(
    String petId,
    String trainingType,
    int gain,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyTrainingData) ?? '{}';
    final Map<String, dynamic> trainingData = json.decode(data);

    final petData = trainingData[petId] as Map<String, dynamic>? ?? {};
    petData[trainingType] = (petData[trainingType] as int? ?? 0) + 1;
    petData['${trainingType}_total_gain'] =
        (petData['${trainingType}_total_gain'] as int? ?? 0) + gain;

    trainingData[petId] = petData;
    await prefs.setString(_keyTrainingData, json.encode(trainingData));
  }

  /// 特訓統計を取得
  static Future<Map<String, int>> getTrainingStats(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyTrainingData) ?? '{}';
    final Map<String, dynamic> trainingData = json.decode(data);

    final petData = trainingData[petId] as Map<String, dynamic>? ?? {};
    return {
      'attack_count': petData['attack'] as int? ?? 0,
      'defense_count': petData['defense'] as int? ?? 0,
      'speed_count': petData['speed'] as int? ?? 0,
      'attack_total': petData['attack_total_gain'] as int? ?? 0,
      'defense_total': petData['defense_total_gain'] as int? ?? 0,
      'speed_total': petData['speed_total_gain'] as int? ?? 0,
    };
  }

  /// 今日の特訓回数を取得（1日3回制限）
  static Future<int> getTodayTrainingCount(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getString(_keyTrainingHistory) ?? '{}';
    final Map<String, dynamic> history = json.decode(historyData);

    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayData = history[today] as Map<String, dynamic>? ?? {};
    return todayData[petId] as int? ?? 0;
  }

  /// 特訓回数をカウント
  static Future<void> incrementTodayTrainingCount(String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getString(_keyTrainingHistory) ?? '{}';
    final Map<String, dynamic> history = json.decode(historyData);

    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayData = history[today] as Map<String, dynamic>? ?? {};
    todayData[petId] = (todayData[petId] as int? ?? 0) + 1;
    history[today] = todayData;

    await prefs.setString(_keyTrainingHistory, json.encode(history));
  }

  /// ミニゲーム：タイミングゲーム用のターゲットタイミング生成
  static double generateTimingTarget() {
    return 0.4 + _random.nextDouble() * 0.2; // 0.4~0.6秒
  }

  /// ミニゲーム：タイミングゲームのスコア計算
  static int calculateTimingScore(double targetTime, double actualTime) {
    final diff = (targetTime - actualTime).abs();
    if (diff < 0.05) return 100; // パーフェクト
    if (diff < 0.1) return 90;
    if (diff < 0.15) return 80;
    if (diff < 0.2) return 70;
    if (diff < 0.3) return 60;
    if (diff < 0.4) return 50;
    return 30;
  }

  /// ミニゲーム：連打ゲームのスコア計算
  static int calculateTapScore(int tapCount, int timeLimit) {
    // 制限時間内のタップ数からスコア算出（目標: 30回/5秒）
    final ratio = tapCount / (timeLimit * 6.0);
    if (ratio >= 1.2) return 100;
    if (ratio >= 1.0) return 90;
    if (ratio >= 0.8) return 80;
    if (ratio >= 0.6) return 70;
    if (ratio >= 0.4) return 60;
    return 50;
  }

  /// ミニゲーム：反射ゲームのスコア計算
  static int calculateReflexScore(List<int> reactionTimes) {
    if (reactionTimes.isEmpty) return 0;

    final avgTime =
        reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // 平均反応時間からスコア（目標: 300ms以下）
    if (avgTime < 250) return 100;
    if (avgTime < 300) return 90;
    if (avgTime < 400) return 80;
    if (avgTime < 500) return 70;
    if (avgTime < 600) return 60;
    return 50;
  }

  /// 連続特訓ボーナスを計算・更新
  static Future<double> _updateTrainingStreak(String petId) async {
    final pet = await PetService.getPetById(petId);
    if (pet == null) return 1.0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = pet.trainingStreak;
    DateTime? lastTraining = pet.lastTrainingDate;

    if (lastTraining != null) {
      final lastDay =
          DateTime(lastTraining.year, lastTraining.month, lastTraining.day);
      final daysDiff = today.difference(lastDay).inDays;

      if (daysDiff == 1) {
        // 連続
        currentStreak++;
      } else if (daysDiff > 1) {
        // 途切れた
        currentStreak = 1;
      }
      // daysDiff == 0 は同日内なのでストリークは変わらない
    } else {
      currentStreak = 1; // 初回
    }

    // 連続日数に応じたボーナス倍率
    double bonus = 1.0;
    if (currentStreak >= 5) {
      bonus = 2.0;
    } else if (currentStreak >= 3) {
      bonus = 1.5;
    }

    // ペット情報更新
    await PetService.updatePet(petId, {
      'trainingStreak': currentStreak,
      'lastTrainingDate': now,
    });

    return bonus;
  }
}

/// 特訓結果モデル
class TrainingResult {
  final String trainingType;
  final int statGain; // 上昇値
  final int score; // ミニゲームスコア
  final bool isPerfect; // パーフェクト達成
  final int bonusGain; // ボーナス上昇値
  final int trainingStreak; // 連続特訓日数

  TrainingResult({
    required this.trainingType,
    required this.statGain,
    required this.score,
    required this.isPerfect,
    required this.bonusGain,
    this.trainingStreak = 0,
  });

  String get typeName {
    switch (trainingType) {
      case 'attack':
        return '攻撃力';
      case 'defense':
        return '防御力';
      case 'speed':
        return '素早さ';
      default:
        return '';
    }
  }
}
