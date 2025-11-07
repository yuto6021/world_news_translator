import 'package:flutter/foundation.dart';

/// 小さな UI 設定を保持するシングルトンサービス
class UIService {
  UIService._private();
  static final UIService instance = UIService._private();

  /// ホバー効果を有効にするか
  final ValueNotifier<bool> hoverEnabled = ValueNotifier<bool>(true);

  /// カード表示モード: 'list' (既存) or 'overlay' (画像上にタイトルを重ねる)
  final ValueNotifier<String> cardMode = ValueNotifier<String>('list');

  /// アイコン等のヒット領域を広げるか（UX向上のため）
  final ValueNotifier<bool> expandHitTargets = ValueNotifier<bool>(true);
}
