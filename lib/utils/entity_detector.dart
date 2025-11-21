/// 固有名詞（エンティティ）を簡易検出するユーティリティ
class EntityDetector {
  // 固有名詞候補: 大文字始まり + (アルファベット | スペース | ハイフン | アポストロフィ) 2語以上
  static final RegExp _entityPattern = RegExp(
    r'\b([A-Z][a-z]+(?:[\s\-][A-Z][a-z]+)+)\b',
    multiLine: true,
  );

  // 除外ワード（一般的な文章表現で固有名詞でないもの）
  static final Set<String> _excludePatterns = {
    'The United States',
    'United States',
    'United Kingdom',
    'The New',
    'New York',
    'According To',
    'As Of',
    'At Least',
    'More Than',
    'Less Than',
  };

  /// テキストからエンティティ候補を抽出し、開始位置・終了位置・文字列を返す
  static List<EntityMatch> detectEntities(String text) {
    final matches = <EntityMatch>[];
    for (final match in _entityPattern.allMatches(text)) {
      final entity = match.group(0)!;
      // 除外リストチェック
      if (_excludePatterns.contains(entity)) continue;
      // 2語以上であることを確認（スペース区切り）
      if (entity.split(RegExp(r'[\s\-]')).length < 2) continue;
      matches.add(EntityMatch(
        start: match.start,
        end: match.end,
        text: entity,
      ));
    }
    return matches;
  }
}

class EntityMatch {
  final int start;
  final int end;
  final String text;

  EntityMatch({required this.start, required this.end, required this.text});
}
