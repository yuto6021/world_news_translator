/// ペット画像のパスを解決するユーティリティ
class PetImageResolver {
  /// ステージ/種/状態からアセットパスを生成
  ///
  /// 例:
  /// - resolveImage('egg', 'egg', 'idle') → 'assets/pets/egg/egg_idle.png'
  /// - resolveImage('adult', 'greymon', 'normal') → 'assets/pets/adult/adult_greymon_normal.png'
  static String resolveImage(String stage, String species, String state) {
    return 'assets/pets/$stage/${stage}_${species}_$state.png';
  }

  /// アクション画像のパスを生成
  ///
  /// 例:
  /// - resolveAction('adult', 'agumon', 'eat') → 'assets/pets/adult/adult_agumon_eat.png'
  static String resolveAction(String stage, String species, String action) {
    return 'assets/pets/$stage/${stage}_${species}_$action.png';
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

  /// ステータス状態リスト
  static const List<String> states = ['normal', 'happy', 'sick', 'angry'];

  /// アクションリスト
  static const List<String> actions = ['eat', 'attack', 'sleep', 'clean'];

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
