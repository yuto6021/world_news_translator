# ペットカード装飾カスタマイズガイド 🎨

## 概要
`PetCardWidget` のレアリティ星デコレーションとカード枠線が**完全カスタマイズ可能**になりました！

---

## ✨ 新機能：カスタマイズ可能なパラメータ

### 星（スパークル）デコレーションのカスタマイズ

```dart
PetCardWidget(
  petImagePath: 'assets/pets/adult/agumon/normal_idle.png',
  petName: 'アグモン',
  level: 50,
  species: 'アグモン',
  stage: 'ultimate',
  hp: 200,
  attack: 150,
  defense: 100,
  rarity: 5,
  
  // 🌟 星のサイズ調整
  sparkleWidth: 100,    // デフォルト: 80
  sparkleHeight: 100,   // デフォルト: 80
  
  // 🌟 星の位置調整
  sparkleTop: 5,        // デフォルト: 10（上からのピクセル）
  sparkleRight: 5,      // デフォルト: 10（右からのピクセル）
  
  // 🌟 星の表示モード
  sparkleFit: BoxFit.cover,  // デフォルト: BoxFit.contain
  // オプション: cover, contain, fill, scaleDown, fitWidth, fitHeight
  
  // 🎨 カード枠線のカスタマイズ
  borderColor: Colors.gold,  // デフォルト: レアリティに基づく色
  borderWidth: 5.0,          // デフォルト: レアリティに基づく太さ（2 or 4）
);
```

---

## 🎨 カード枠線のデフォルト色

レアリティが設定されている場合、自動的に以下の色が適用されます：

| レアリティ | 色 | 太さ |
|-----------|-----|------|
| 1 (コモン) | グレー | 2px |
| 2 (アンコモン) | グリーン | 2px |
| 3 (レア) | ブルー | 4px |
| 4 (エピック) | パープル | 4px |
| 5 (レジェンダリー) | ゴールド | 4px |

---

## 📍 使用例

### 例1: 星を小さく、控えめに表示
```dart
PetCardWidget(
  // ... 基本パラメータ ...
  rarity: 3,
  sparkleWidth: 50,
  sparkleHeight: 50,
  sparkleTop: 15,
  sparkleRight: 15,
  sparkleFit: BoxFit.contain,
)
```

### 例2: 星を大きく、目立たせる（レジェンダリー向け）
```dart
PetCardWidget(
  // ... 基本パラメータ ...
  rarity: 5,
  sparkleWidth: 120,
  sparkleHeight: 120,
  sparkleTop: 0,
  sparkleRight: 80,  // (280 - 120) / 2 = 80で中央
  sparkleFit: BoxFit.contain,
)
```

### 例3: カスタム枠線色（虹色エフェクト）
```dart
PetCardWidget(
  // ... 基本パラメータ ...
  rarity: 5,
  borderColor: Colors.pink.shade400,  // カスタム色
  borderWidth: 6.0,                   // 太い枠線
  sparkleWidth: 90,
  sparkleHeight: 90,
)
```

### 例4: 枠線なし、星も非表示
```dart
PetCardWidget(
  // ... 基本パラメータ ...
  rarity: 1,
  borderWidth: 0,        // 枠線を非表示
  sparkleWidth: 0,       // 星を非表示
  sparkleHeight: 0,
)
```

### 例5: 左上に星を配置（通常は右上）
```dart
PetCardWidget(
  // ... 基本パラメータ ...
  rarity: 4,
  sparkleWidth: 70,
  sparkleHeight: 70,
  sparkleTop: 10,
  sparkleRight: 200,  // 280 - 80 = 200 で左寄せに
)
```

---

## 🔧 実装詳細

### ファイル位置
- `lib/widgets/pet_card_widget.dart`

### 追加されたパラメータ（Lines 13-24）

#### 星デコレーション
```dart
final double? sparkleWidth;   // 星の幅（デフォルト: 80.0）
final double? sparkleHeight;  // 星の高さ（デフォルト: 80.0）
final double? sparkleTop;     // 上からの位置（デフォルト: 10.0）
final double? sparkleRight;   // 右からの位置（デフォルト: 10.0）
final BoxFit? sparkleFit;     // 表示モード（デフォルト: BoxFit.contain）
```

#### カード枠線
```dart
final Color? borderColor;   // 枠線の色（デフォルト: レアリティに基づく）
final double? borderWidth;  // 枠線の太さ（デフォルト: レアリティに基づく）
```

### ヘルパーメソッド（Lines 445-478）

```dart
/// レアリティに応じた枠線の色
Color _getRarityBorderColor() {
  if (rarity == null) return Colors.transparent;
  
  switch (rarity!) {
    case 1: return Colors.grey.shade400;
    case 2: return Colors.green.shade600;
    case 3: return Colors.blue.shade600;
    case 4: return Colors.purple.shade600;
    case 5: return Colors.amber.shade600;
    default: return Colors.grey;
  }
}

/// レアリティに応じた枠線の太さ
double _getRarityBorderWidth() {
  if (rarity == null) return 0;
  return rarity! >= 3 ? 4.0 : 2.0;
}
```

---

## 🎯 推奨設定（レアリティ別）

### レジェンダリー（レアリティ5）
```dart
sparkleWidth: 100,
sparkleHeight: 100,
sparkleTop: 8,
sparkleRight: 8,
sparkleFit: BoxFit.contain,
borderColor: Colors.amber.shade700,
borderWidth: 5.0,
```

### エピック（レアリティ4）
```dart
sparkleWidth: 85,
sparkleHeight: 85,
sparkleTop: 10,
sparkleRight: 10,
borderColor: Colors.purple.shade600,
borderWidth: 4.0,
```

### レア（レアリティ3）
```dart
sparkleWidth: 70,
sparkleHeight: 70,
sparkleTop: 12,
sparkleRight: 12,
borderColor: Colors.blue.shade600,
borderWidth: 3.0,
```

### アンコモン（レアリティ2）
```dart
sparkleWidth: 60,
sparkleHeight: 60,
sparkleTop: 15,
sparkleRight: 15,
borderWidth: 2.0,
```

### コモン（レアリティ1）
```dart
sparkleWidth: 50,
sparkleHeight: 50,
sparkleTop: 18,
sparkleRight: 18,
borderWidth: 2.0,
```

---

## 📐 位置計算のヒント

### カード中央に配置
```dart
// カード幅: 280px
// 星の幅: 100px
// 中央位置: (280 - 100) / 2 = 90px

sparkleRight: 90,  // 左右中央
sparkleTop: 0,     // 上部
```

### 左上隅に配置
```dart
sparkleTop: 10,
sparkleRight: 200,  // 280 - 80 = 200
```

### 下部に配置（非推奨だが可能）
```dart
// Positionedウィジェットを直接編集する必要があります
// bottom: 10, を使用
```

---

## 🚀 使い方の流れ

1. **基本パラメータを設定**（必須）
   - `petImagePath`, `petName`, `level`, など

2. **レアリティを設定**（オプション）
   - `rarity: 1-5` でレア度を指定

3. **デフォルトを確認**
   - 何も指定しないと自動的に適切な設定が適用される

4. **カスタマイズ**
   - 必要に応じて `sparkleWidth`, `borderColor` などを指定

---

## ⚠️ 注意事項

- `sparkleWidth` と `sparkleHeight` を大きくしすぎるとカードからはみ出す可能性があります
- `sparkleTop` と `sparkleRight` は **カードの境界内** に収まるように設定してください
- `borderWidth: 0` で枠線を非表示にできますが、レアリティの視覚的フィードバックが失われます
- `sparkleFit: BoxFit.cover` は星を拡大してカード全体に広げるため、通常は推奨されません

---

## 🐛 トラブルシューティング

### 星が表示されない
- `assets/ui/decorations/ui_sparkle_rarity.png` が存在するか確認
- `sparkleWidth` と `sparkleHeight` が0でないか確認
- `rarity` パラメータが `null` でないか確認

### 枠線が表示されない
- `borderWidth` が0でないか確認
- `borderColor` が透明色でないか確認

### 星がカードからはみ出す
- `sparkleWidth` と `sparkleHeight` を小さくする
- `sparkleTop` と `sparkleRight` を調整する

---

**更新日**: 2025年11月30日  
**バージョン**: 2.0（カスタマイズ対応版）
