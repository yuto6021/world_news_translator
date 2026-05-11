/// ペット画像のパスを解決するユーティリティ
class PetImageResolver {
  // 一部アセットはファイル名に大文字が含まれるため、種名を正規化する。
  static const Map<String, String> _speciesFileAliases = {
    'alphamon': 'Alphamon',
    'apocalymon': 'Apocalymon',
    'gallantmon': 'Gallantmon',
    'omegamon': 'Omegamon',
    'susanoomon': 'Susanoomon',
  };

  // 旧命名セット（attack/sleep/eat/clean ベース）を持つ種。
  static const Set<String> _legacyAssetSpecies = {
    'genki',
    'warrior',
    'beast',
    'angel',
    'demon',
    'agumon',
    'gabumon',
    'greymon',
    'garurumon',
    'angemon',
    'devimon',
    'leomon',
    'wargreymon',
    'metalgarurumon',
    'seraphimon',
    'daemon',
  };

  // 旧命名から新命名への変換（新命名アセットを持つ種向け）。
  static const Map<String, String> _legacyToModern = {
    'attack': 'battle',
    'sleep': 'sleeping',
    'eat': 'eating',
    'sick': 'sad',
  };

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
    // ステージは小文字固定、種名は論理判定用とファイル名用で分離する。
    final st = stage.toLowerCase();
    final sp = species.toLowerCase();
    final spFile = _speciesFileAliases[sp] ?? sp;
    final des = desired.toLowerCase();
    final candidates = <String>[];
    final isLegacySpecies = _legacyAssetSpecies.contains(sp);

    if (isLegacySpecies) {
      if (_stateFallbacks.containsKey(des)) {
        candidates.addAll(_stateFallbacks[des]!);
      } else {
        candidates.add(des);
      }
      candidates.add('normal');
    } else {
      if (_legacyToModern.containsKey(des)) {
        candidates.add(_legacyToModern[des]!);
      }
      candidates.add(des);
      candidates.add('normal');
    }

    final seen = <String>{};
    for (final c in candidates) {
      if (seen.add(c)) {
        return 'assets/pets/$st/${st}_${spFile}_$c.png';
      }
    }

    return 'assets/pets/$st/${st}_${spFile}_normal.png';
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
