# ペットカード修正ガイド

## 1. 星デコレーションの画像サイズ調整

### 場所
`lib/widgets/pet_card_widget.dart` の `_buildRaritySparkle` メソッド（136行目付近）

### 現在のコード
```dart
Widget _buildRaritySparkle(int rarity) {
  final opacity = (0.1 + (rarity.clamp(1, 5) - 1) * 0.12).clamp(0.1, 0.6);
  return Positioned.fill(
    child: IgnorePointer(
      child: Image.asset(
        'assets/ui/decorations/ui_sparkle_rarity.png',
        fit: BoxFit.cover,  // ← ここを変更
        color: Colors.white.withOpacity(opacity.toDouble()),
        colorBlendMode: BlendMode.screen,
      ),
    ),
  );
}
```

### サイズ調整方法

#### 方法1: fit を contain に変更（画像を縮小）
```dart
fit: BoxFit.contain,  // 画像全体を収める
```

#### 方法2: fit を scaleDown に変更（大きい場合のみ縮小）
```dart
fit: BoxFit.scaleDown,  // はみ出す場合のみ縮小
```

#### 方法3: width/height を指定して固定サイズ
```dart
child: Center(  // 中央配置に変更
  child: Image.asset(
    'assets/ui/decorations/ui_sparkle_rarity.png',
    width: 200,  // 固定幅
    height: 200,  // 固定高さ
    fit: BoxFit.contain,
    color: Colors.white.withOpacity(opacity.toDouble()),
    colorBlendMode: BlendMode.screen,
  ),
),
```

#### 方法4: Positioned で位置とサイズを細かく制御
```dart
Widget _buildRaritySparkle(int rarity) {
  final opacity = (0.1 + (rarity.clamp(1, 5) - 1) * 0.12).clamp(0.1, 0.6);
  return Positioned(
    top: 10,     // 上からの位置
    right: 10,   // 右からの位置
    width: 80,   // 幅
    height: 80,  // 高さ
    child: IgnorePointer(
      child: Image.asset(
        'assets/ui/decorations/ui_sparkle_rarity.png',
        fit: BoxFit.contain,
        color: Colors.white.withOpacity(opacity.toDouble()),
        colorBlendMode: BlendMode.screen,
      ),
    ),
  );
}
```

## 2. カード枠デコレーション追加

### 場所
同じファイルの `build` メソッド内、Container の decoration

### 現在（枠なし）
```dart
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(16),
  gradient: LinearGradient(...),
  boxShadow: [...],
),
```

### 枠を追加
```dart
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(16),
  gradient: LinearGradient(...),
  boxShadow: [...],
  border: Border.all(
    color: Colors.amber,  // 枠の色（レア度で変える場合は _getRarityBorderColor(rarity) など）
    width: 3,             // 枠の太さ
  ),
),
```

### レア度別の枠色を実装する場合
```dart
// クラス内に追加
Color _getRarityBorderColor(int? rarity) {
  if (rarity == null) return Colors.grey;
  switch (rarity) {
    case 5: return Colors.red;           // レジェンダリー
    case 4: return Colors.purple;        // エピック
    case 3: return Colors.blue;          // レア
    case 2: return Colors.green;         // アンコモン
    case 1: return Colors.grey;          // コモン
    default: return Colors.grey;
  }
}

// build メソッド内で使用
border: Border.all(
  color: _getRarityBorderColor(rarity),
  width: rarity != null && rarity >= 3 ? 4 : 2,  // レア度3以上は太い枠
),
```

## 推奨設定

個人的には以下の組み合わせがおすすめです：

1. **星デコレーション**: 方法4（右上隅に小さく配置）
2. **カード枠**: レア度別の色付き枠（太さは rarity >= 3 で 4px、それ以外 2px）

これで画像がはみ出さず、カードらしい見た目になります。
