# カードUI仕様書 (初期版 / Tier0+)

## 目的
ポケモンカード風にペットを1枚の情報カードとして成立させ、一覧状態で“育成操作(世話/アクション)”が完結する最小デザインと将来拡張余地を定義する。

---
## カード表示で必須の育成要素 (詳細画面不要で操作可能)
| 要素 | 表示形式 | 操作 | 備考 |
|------|----------|------|------|
| ペット画像 | 512x512 (中央) | タップでアクション切替サイクル(任意) | 擬似アニメラッパ適用 |
| 名前 + 種族 | 上部左揃えテキスト | （編集は詳細へ） | 例: Greymon / グレイモン |
| レベル/経験値 | 上部右: `Lv.45` + 細バー | バー押下→経験値詳細(任意) | バーは 0-100% グラデ |
| 4ゲージ (HP/お腹/機嫌/汚れ) | 下部ミニバー(高さ6px×4本) | 各バータップ→対応アクションボタン点滅 | 色: HP赤 / お腹オレンジ / 機嫌黄 / 汚れ茶 |
| アクションボタン (餌/遊び/掃除/薬) | 4丸アイコン 横並び | 直接実行 | クールダウン時グレースケール |
| 親密度 | ハートアイコン + 数値 | 詳細で履歴 | 後の配合条件 |
| レア度 | 星バッジ(1-5) + Sparkle | 長押し→説明 | 初期から導入 |
| 進化準備 | 右上小バッジ `EVOLVE` + 脈動 | タップ→確認ダイアログ | 条件達成時のみ表示 |
| 状態アイコン (sick/happy/angry/sleep) | 画像右下オーバーレイ | クリックで説明ポップ | 優先順位: sick > sleep > angry > happy |
| タイム(現在時刻/昼夜) | 背景グラデトーン | なし | 夜間は全体彩度↓ |

---
## レイヤー構成
1. 背景グラデ (属性+時間帯)
2. カードフレーム (角丸 + 2pxアウトライン + 内側シャドウ)
3. ペット画像コンテナ (擬似アニメ適用)
4. 状態/エフェクトオーバーレイ (heart, sick, angry, sleep-Z)
5. 情報バー (名前/レベル/レア度/進化バッジ)
6. 下部ステータスミニバー (4ゲージ + 親密度ハート)
7. アクションボタン行
8. Sparkleパーティクル層 (レア度高 or 進化準備時)

---
## 色/スタイルトークン
| トークン | 値 | 用途 |
|----------|----|------|
| frameBorder | #2C2F36 | カード枠線 |
| frameInnerShadow | rgba(0,0,0,0.25) | 立体感 |
| bgWarrior | linear-gradient(135deg,#FF9432,#FF5E00) | 戦士系背景 |
| bgBeast | linear-gradient(135deg,#8BC34A,#4CAF50) | 獣系背景 |
| bgAngel | linear-gradient(135deg,#B3E5FC,#81D4FA) | 聖系背景 |
| bgDemon | linear-gradient(135deg,#512DA8,#311B92) | 闇系背景 |
| rarityStarFill | #FFD700 | レア度星塗り |
| rarityHoloHighlight | radial-gradient(circle,#FFFFFF55,#00000000) | ホログラム光 |
| evolvePulseColor | #FFFF66 | 進化準備パルス |
| gaugeHp | #FF3D3D | HPバー |
| gaugeHunger | #FF9800 | お腹 |
| gaugeMood | #FFC107 | 機嫌 |
| gaugeDirty | #795548 | 汚れ |
| gaugeBg | #222831 | バー背景 |

---
## Rarity (レア度) 表示仕様
| レア度 | 星数 | Sparkle強度 | 枠装飾 |
|--------|------|-------------|--------|
| Common | 1 | なし | 単色フレーム |
| Uncommon | 2 | 小 (疎) | フレーム内側薄グラデ |
| Rare | 3 | 中 (中密度) | 角に小さな光粒 |
| Epic | 4 | 高 (密度) | 枠外周にパルス淡光 |
| Legendary | 5 | 高 + 虹色ローテ | ホログラム(Shader) + 外周回転ライン |

Sparkle生成: `Random`で粒子(半径1-2px)を Positioned + Fade + Scale。LegendaryはHSVで色相回転。性能軽減のため最大同時粒子数20。Ticker制御で非表示時停止。

---
## 進化準備エフェクト
条件達成時:
1. バッジ表示 `EVOLVE` (角丸矩形 + グラデ #FFE066→#FFC300)
2. フレームパルス: 1.5秒周期で外枠アルファ 0.6→0.2
3. 微細Sparkle: Rare以上と重複時は強度を+20%するが最大粒子数は統合で上限維持
4. ペット画像Scale: 1.0→1.03→1.0 (TweenSequence)

---
## 擬似アニメ API 初期案
```dart
typedef PetAnimationBuilder = Widget Function(BuildContext context, Widget child);

class PetAnimations {
  static Widget scalePulse(BuildContext c, Widget child) => _Pulse(child); // idle
  static Widget horizontalOscillation(BuildContext c, Widget child) => _Oscillate(child); // walk/attack準備
  static Widget verticalBounce(BuildContext c, Widget child) => _Bounce(child); // play
  static Widget opacityBreathing(BuildContext c, Widget child) => _Breathing(child); // sleep
  static Widget quickScaleForward(BuildContext c, Widget child) => _QuickForward(child); // attack瞬間
}
```
各内部は `AnimatedBuilder` + `AnimationController` (vsync: SingleTickerProviderStateMixin)。カード非表示時 `TickerMode(enabled:false)`。

---
## ファイル名解決ロジック (擬似コード)
```dart
String resolvePetAsset({required String stage, required String species, String? state, String? action}) {
  final base = 'assets/pets';
  final preferred = action != null ? '${stage}_${species}_$action.png' : '${stage}_${species}_$state.png';
  if (exists('$base/$stage/$species/$preferred')) return '$base/$stage/$species/$preferred';
  if (state != null && exists('$base/$stage/$species/${stage}_${species}_$state.png')) {
    return '$base/$stage/$species/${stage}_${species}_$state.png';
  }
  return '$base/$stage/$species/${stage}_${species}_normal.png';
}
```
存在判定は `AssetManifest.json` のキーを事前キャッシュし O(1) ルックアップ。

---
## 詳細画面 (後から開く拡張) にのみ表示する要素
| 要素 | 説明 | なぜカードから外すか |
|------|------|-----------------------|
| 行動履歴タイムライン | 餌/遊び/清掃/薬使用時刻 | 一覧ではノイズが多い |
| 進化条件進捗詳細 | 各条件の現在値/閾値 | カードは“進化可能”かだけ示せば十分 |
| スキル一覧・習得管理 | 3枠+説明+強化ボタン | 面積大きく多情報 |
| 写真アルバム (死亡/進化記録) | サムネイルグリッド | 周回要素、常時表示不要 |
| バトル戦績詳細 (勝敗リスト) | 過去10戦ログ | カードは勝率または勝数簡略値のみ |
| 配合履歴 | 親ペアと結果 | 高頻度参照でない |
| 通知設定 | ON/OFF | 一覧操作向きでない |

詳細遷移トリガ: カード長押し or 上部情報バータップ。

---
## Widget 階層構造 (Flutter)
```
PetCard(
  header: CardHeader(name, level, rarityBadge, evolveBadge),
  image: AnimatedPetSprite(assetPath, animation: currentAnimation),
  statusBars: MiniGauges(hp, hunger, mood, dirty),
  actionRow: CareActionRow(onFeed, onPlay, onClean, onMedicine),
  overlays: [StateIconLayer(state), SparkleLayer(rarity,evolveReady)],
)
```
`PetCardController` が state/action 変更とアニメを同期。Providerまたは ValueNotifier 経由で差し替え。

---
## 初期実装優先度 (カード関連)
1. ファイル名解決ユーティリティ
2. PetCard骨組み (静止画像 + 4ゲージ + ボタン)
3. RaritySparkleLayer (Common～Legendary差分)
4. EvolvePulseOverlay
5. Idle / Play / Sleep アニメ適用
6. 状態アイコン合成 (sick/happy/angry/sleep)
7. 性能最適化 (TickerMode / 粒子数制御)

---
## パフォーマンス指針
- 粒子: Paintベースに後で移行可能 (初期は Widgetで簡易実装)。
- 60fps不要: 30fps程度で十分 (Duration / controller.updateInterval 調整)。
- 画像プリロード: 最初に現在ステージ + 全アクション静止画を precacheImage。
- メモリ節約: 不在アセット参照は即 normal へフォールバック。

---
## 拡張フック
| フック | 用途 |
|-------|------|
| onEvolutionReady() | 進化準備時演出開始 |
| onActionExecuted(action) | アニメ再生 & ログ追記 |
| provideExternalEffects(stream) | 外部効果(天気/ニュース等)で背景揺らし |

---
## 未決定事項 (後でユーザー確認)
1. レア度の最初の割当ロジック (固定 vs ガチャ vs 成長による昇格)
2. 親密度の表示形式 (数値/ゲージ/ハート積層)
3. バッジ形状 (星アイコン以外に六角形等?)

---
## 次アクション
- この仕様確定後、`lib/widgets/pet_card.dart` スタブ作成 → 画像投入連絡後本実装。
- SparkleLayerは簡易版 (Positioned + AnimatedOpacity) から開始し後で CustomPainter に移行。

