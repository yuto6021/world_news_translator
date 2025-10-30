import 'package:flutter/foundation.dart';

/// 小さな UI 設定を保持するシングルトンサービス
class UIService {
  UIService._private();
  static final UIService instance = UIService._private();

  /// ホバー効果を有効にするか
  final ValueNotifier<bool> hoverEnabled = ValueNotifier<bool>(true);
}
