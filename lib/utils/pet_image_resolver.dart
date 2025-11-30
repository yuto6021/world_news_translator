/// ペット画像のパスを解決するユーティリティ
class PetImageResolver {
  /// 旧仕様 + 新仕様 両対応ステートフォールバックマップ
  /// 新仕様要求 -> 旧仕様候補順（存在しない場合は次を試す）
  static const Map<String, List<String>> _stateFallbacks = {
    'sad': ['sick', 'normal'],
    'sleeping': ['sleep', 'normal'],
    'battle': ['attack', 'angry', 'normal'],
    'playing': ['play', 'jump', 'walk', 'idle', 'happy', 'normal'],
    'eating': ['eat'],
  };

  /// 旧仕様で保持しているステータス系
  static const List<String> _legacyStates = [
    'normal',
    'happy',
    'sick',
    'angry'
  ];

  /// 旧仕様で保持しているアクション系
  static const List<String> _legacyActions = [
    'eat',
    'attack',
    'sleep',
    'clean'
  ];

  /// 新仕様で追加された状態（内部的にはフォールバックで旧へマップされる）
  static const List<String> _newStates = [
    'sad',
    'sleeping',
    'battle',
    'playing',
    'eating',
  ];

  /// 両対応の柔軟解決メソッド（状態 or アクション問わず）
  /// 呼び出し側は希望状態(新/旧)を渡せば最適な既存アセットパスを返す
  static String resolveFlexible(String stage, String species, String desired) {
    // 直接旧仕様に存在する場合はそのまま
    if (_legacyStates.contains(desired) || _legacyActions.contains(desired)) {
      return 'assets/pets/$stage/${stage}_${species}_$desired.png';
    }

    // 新仕様状態の場合フォールバック列を生成
    final candidates = <String>[];
    if (_stateFallbacks.containsKey(desired)) {
      candidates.addAll(_stateFallbacks[desired]!);
    } else {
      // 未知の入力は normal に丸める
      candidates.add('normal');
    }

    for (final c in candidates) {
      if (_legacyStates.contains(c) || _legacyActions.contains(c)) {
        return 'assets/pets/$stage/${stage}_${species}_$c.png';
      }
    }
    // 最終保険
    return 'assets/pets/$stage/${stage}_${species}_normal.png';
  }

  /// 互換維持のため旧メソッドはそのまま利用可（既存コード用）
  static String resolveImage(String stage, String species, String state) {
    return resolveFlexible(stage, species, state);
  }

  static String resolveAction(String stage, String species, String action) {
    return resolveFlexible(stage, species, action);
  }

  /// ステージごとの利用可能な種リスト
  static const Map<String, List<String>> speciesByStage = {
    'egg': ['egg'],
    'baby': ['genki'],
    'child': ['warrior', 'beast', 'angel', 'demon'],
    'adult': [
      'greymon',
      'garurumon',
      'angemon',
      'devimon',
      'agumon',
      'gabumon',
      'leomon'
    ],
    'ultimate': ['wargreymon', 'metalgarurumon', 'seraphimon', 'daemon'],
  };

  /// ステータス状態リスト（旧 + 新）
  static const List<String> states = [
    ..._legacyStates,
    ..._newStates,
  ];

  /// アクションリスト（旧）
  static const List<String> actions = [
    ..._legacyActions,
  ];

  /// 属性アイコンのパス
  static String elementIcon(String element) {
    return 'assets/ui/icons/elements/icon_element_$element.png';
  }

  /// ステータスアイコンのパス
  static String statusIcon(String status) {
    return 'assets/ui/icons/status/icon_status_$status.png';
  }

  /// アイテム画像のパス
  static String itemImage(String category, String itemName) {
    return 'assets/items/$category/item_$itemName.png';
  }

  /// エネミー画像のパス
  static String enemyImage(String enemyName, String pose) {
    return 'assets/enemies/enemy_${enemyName}_$pose.png';
  }

  /// UI装飾パーツのパス
  static String uiDecoration(String decorationName) {
    return 'assets/ui/decorations/$decorationName.png';
  }
}
