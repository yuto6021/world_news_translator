import 'package:hive_flutter/hive_flutter.dart';

/// 読書時間トラッキングサービス（実測、Hive使用）
class ReadingTimeService {
  static const String _boxName = 'reading_time';
  static const String _totalSecondsKey = 'total_seconds';
  static const String _sessionStartKey = 'session_start';
  static Box? _box;

  /// 初期化
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  /// セッション開始（記事を開いたタイミング）
  static Future<void> startSession() async {
    final box = _box ?? await Hive.openBox(_boxName);
    await box.put(_sessionStartKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// セッション終了（記事を閉じたタイミング、または画面遷移時）
  static Future<int> endSession(
      {int minSeconds = 5, int maxSeconds = 600}) async {
    final box = _box ?? await Hive.openBox(_boxName);
    final startMs = box.get(_sessionStartKey) as int?;
    if (startMs == null) return 0;

    final elapsed = (DateTime.now().millisecondsSinceEpoch - startMs) ~/ 1000;
    await box.delete(_sessionStartKey);

    // 異常値フィルタリング（5秒未満 or 10分以上は無視）
    if (elapsed < minSeconds || elapsed > maxSeconds) return 0;

    final total = await getTotalSeconds();
    await box.put(_totalSecondsKey, total + elapsed);
    return elapsed;
  }

  /// 累計読書秒数取得
  static Future<int> getTotalSeconds() async {
    final box = _box ?? await Hive.openBox(_boxName);
    return box.get(_totalSecondsKey, defaultValue: 0) ?? 0;
  }

  /// 累計読書分数取得
  static Future<int> getTotalMinutes() async {
    final seconds = await getTotalSeconds();
    return seconds ~/ 60;
  }

  /// 累計読書時間取得（時:分形式）
  static Future<String> getTotalFormatted() async {
    final minutes = await getTotalMinutes();
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}時間${mins}分';
  }

  /// リセット（テスト用）
  static Future<void> reset() async {
    final box = _box ?? await Hive.openBox(_boxName);
    await box.clear();
  }
}
