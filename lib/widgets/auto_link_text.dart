import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/entity_detector.dart';

/// 固有名詞を自動検出してタップ可能にするテキストウィジェット
class AutoLinkText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final void Function(String entity) onEntityTap;
  final TextStyle? linkStyle;

  const AutoLinkText({
    super.key,
    required this.text,
    required this.onEntityTap,
    this.baseStyle,
    this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final entities = EntityDetector.detectEntities(text);
    if (entities.isEmpty) {
      return SelectableText(text, style: baseStyle);
    }

    // エンティティを含むリッチテキスト構築
    final spans = <InlineSpan>[];
    int currentPos = 0;

    for (final entity in entities) {
      // エンティティ前の通常テキスト
      if (entity.start > currentPos) {
        spans.add(TextSpan(
          text: text.substring(currentPos, entity.start),
          style: baseStyle,
        ));
      }

      // エンティティリンク
      spans.add(TextSpan(
        text: entity.text,
        style: linkStyle ??
            TextStyle(
              color: Colors.blue.shade700,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => onEntityTap(entity.text),
      ));

      currentPos = entity.end;
    }

    // 残りのテキスト
    if (currentPos < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPos),
        style: baseStyle,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}
