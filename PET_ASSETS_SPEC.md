# ペット育成システム – 画像アセット発注仕様書（静止画第1フェーズ版）

## 📦 発注概要（更新）
第1フェーズは静止画最小構成（Tier0）に追加アクションポーズ（Tier0+）を導入。将来アニメ導入時は同プレフィックスでフレーム差し替え。

現行想定総数: 約**164枚**
- ペット本体: 71枚（たまご7 + 幼年期8 + 成長期16 + 成熟期24 + 究極体16〈2種×8〉）
- エネミー: 12枚（野生4種×2状態 + ボス2種×2状態）
- UI部品: 24枚（ボタン8 + 背景/パネル10 + 装飾パーツ6）
- アイコン: 12枚（属性6 + 状態6）
- アイテム: 20枚（消耗品8 + レア12）
- エフェクト: 3枚（進化演出用）
- ガチャ: 4枚（レア度別カプセル）
- 背景詳細: 8枚（バトルフィールド詳細版）

**注意**: ステータスパネル、ポップアップ、カード枠の3つはFlutterウィジェットで実装済み。画像不要。感情・バトルエフェクトはコードで暫定実装（絵文字+パーティクル）。

（旧記述 105 / 125 / 135 / 192 / 240 / 272 枚などは差し替え前参照値）

### UI実装方針: コード実装 + 画像のハイブリッド
1. **コード実装（3種類）**: ステータスパネル、ポップアップ、カード枠
   - HTMLプロトタイプを参考にFlutterウィジェット化
   - グラデーション枠線、虹色ボーダー、回路装飾などをCustomPaint/BoxDecoration/ShaderMaskで実装
   - 利点: 動的な色変更、サイズ調整、アニメーション統合が容易
   - 詳細は下記「Flutter実装サンプル参考」セクション参照

2. **画像から取得（24枚 + アイコン16枚）**: それ以外のUI要素
   - ボタン: 4種×2状態（通常/押下）= 8枚
   - 背景: 昼/夜の部屋背景、バトル背景など = 10枚
   - 装飾パーツ: カード枠角装飾、キラキラ、発光オーラ = 6枚
   - アイコン: 属性8種 + 状態6種 + その他2種 = 16枚

3. **ゲージは全てFlutter描画**: グラデーション塗り＋角丸で実装、画像不要

→ **ペット本体55枚に制作リソースを集中**しつつ、UI品質も確保するバランス型設計。

---

## 🎨 全体スタイルガイド

### デザインスタイル
- **テイスト**: ドット絵風 or 手描き風（統一すること）
- **推奨**: 16×16pxドット絵を32倍拡大（512×512px）
- **色彩**: 彩度高め、ビビッドカラー
- **輪郭線**: 2-3px、黒またはダークグレー
- **影**: ドロップシャドウ軽め（透明度30%、2pxオフセット）

### 技術仕様
| 項目 | 仕様 |
|------|------|
| フォーマット | PNG-24（透過あり） |
| 解像度 | 512×512px（ペット本体）、256×256px（アイテム）、128×128px（UI）|
| 背景 | **完全透過必須**（アルファチャンネル） |
| 圧縮 | TinyPNG等で最適化（目標50KB/枚以下） |
| 命名規則 | スネークケース、小文字のみ、英数字のみ |
| カラースペース | sRGB |

---

## 🥇 **最優先**: ペット本体画像（第1フェーズ: 静止画+アクション 55枚）

### 方針（アニメーション → 静止画）
生成AI活用と初期コスト削減のため、各ペットは「状態ごと 1 枚」の静止画のみを制作。アニメーションフレーム（walk / eat / play など）は将来の第Xフェーズで差し替え可能な“論理スロット”として命名規約だけ保持します。

### 計算式（第1フェーズ 実制作枚数 再計算）
```
たまご: 7アクション（idle / walk / eat / play / sleep / clean / attack）
幼年期(パピモン): 4状態 + 4アクション = 8枚
成長期2種(ウォリア / ビースト): 2種 × (4状態+4アクション) = 16枚
成熟期3種(グレイ / ガルル / エンジェ): 3種 × (4状態+4アクション) = 24枚
合計 = 7 + 8 + 16 + 24 = 55枚
```

（拡張用 “論理スロット” 例: `*_normal_idle.png`, `*_normal_attack.png` などは未制作で OK）

**注意**: ゲージ画像は不要（Flutterで実装）。静止画に軽微な擬似アニメ（拡大・揺れ・フェード）を付与する方針。

### A-1) たまご（7枚）
| ファイル名 | 説明 |
|-----------|------|
| `egg_idle.png` | 直立基本姿勢 |
| `egg_walk.png` | わずかに左右へ揺れて移動感 |
| `egg_eat.png` | 口部分に小さな割れ目 + 食べ物影（演出用）|
| `egg_play.png` | 上下に弾む姿勢（ジャンプ頂点）|
| `egg_sleep.png` | 少し下向き + Zエフェクト重ね用 |
| `egg_clean.png` | 水しぶき or 泡を2〜3個付与 |
| `egg_attack.png` | 前傾し微細なヒビ（攻撃準備）|

**デザイン指示（共通）**:
- サイズ: 縦長楕円（高さ400px、幅320px）
- 色: クリーム色ベース、模様（水玉 or 縞）統一可能
- 表面: 光沢（ハイライト）+ 状態差分は「小道具/角度/ヒビ/泡」で表現

---

### A-2) 幼年期（8枚）
**1種類 × (4状態 + 4アクション) = 8枚**

#### パピモン（元気タイプ）
ファイル名例: `baby_genki_normal_idle.png`

**デザイン指示**:
- 体型: 丸っこい、頭身1.5:1
- 色: 明るいオレンジ
- 特徴: 大きな瞳、笑顔、短い手足
- サイズ: 縦350px、横280px

**状態バリエーション（ステータス）**:
- `normal`: 通常
- `happy`: 頬に💗、目がキラキラ
- `sick`: 顔色青白い、目が渦巻き
- `angry`: 怒りマーク💢、眉が下がる

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 口を開け食べ物に向かう
- `jump` (play代替): 少し宙に浮いた姿勢
- `attack`: 前方へ体を傾け腕（または体）を突き出し
- `sleep`: 目を閉じ丸くなる / Zエフェクト別途合成

ファイル命名例（状態）: `baby_genki_normal.png`
ファイル命名例（アクション）: `baby_genki_attack.png`

論理スロット（将来アニメ化）: `idle / walk / eat / play|jump / sleep / clean / battle / attack / hurt`

---

### A-3) 成長期（32枚）
**4種類 × (4状態 + 4アクション) = 32枚**

#### ウォリアモン（戦士系・炎）
ファイル名例: `child_warrior_normal.png`

**デザイン指示**:
- 体型: 筋肉質、頭身2:1
- 色: 深紅、メタリックグレー
- 装備: 小さな剣と盾
- サイズ: 縦420px、横350px

**状態バリエーション（ステータス）**:
- `normal`: 盾を構えた直立姿勢
- `happy`: 剣を高く掲げ、勝利ポーズ
- `sick`: 盾を落とし、膝をつく
- `angry`: 戦闘姿勢、剣と盾を前に

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 武器を置いて食事
- `attack`: 剣を振りかぶる姿勢
- `sleep`: 盾を枕に横たわる
- `clean`: 剣を磨く

ファイル命名例: `child_warrior_normal.png`, `child_warrior_attack.png`

#### ビーストモン（獣系・草）
ファイル名例: `child_beast_normal.png`

**デザイン指示**:
- 体型: 四足歩行
- 色: ブラウン、白い腹部
- 特徴: 鋭い牙、尻尾
- サイズ: 縦380px、横420px

**状態バリエーション（ステータス）**:
- `normal`: 警戒姿勢、耳を立てる
- `happy`: 尻尾を大きく振る、笑顔
- `sick`: 伏せた姿勢、耳が垂れる
- `angry`: 牙を剥き、毛を逆立てる

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 頃を下げて食事
- `attack`: 飛びかかる姿勢、爪を前に
- `sleep`: 丸くなり尻尾で顔を覚う
- `clean`: 体を舜める動作

ファイル命名例: `child_beast_normal.png`, `child_beast_attack.png`

#### エンジェモン幼体（聖系・光）
ファイル名例: `child_angel_normal.png`

**デザイン指示**:
- 体型: 細身、頭身2.5:1
- 色: 白、金のアクセント
- 装備: 小さな翼（羽4枚）、輪っか
- サイズ: 縦450px、横320px

**状態バリエーション（ステータス）**:
- `normal`: 通常飛行姿勢
- `happy`: 輪っか輝き、微笑む
- `sick`: 翼たれ、輪っか消失
- `angry`: 輪っかが赤く光る、眉を潜める

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 光の粒子を吸収
- `attack`: 光弾発射姿勢
- `sleep`: 翼で体を包む
- `clean`: 聖なる光で浄化

ファイル命名例: `child_angel_normal.png`, `child_angel_attack.png`

#### デビモン幼体（闇系・闇）
ファイル名例: `child_demon_normal.png`

**デザイン指示**:
- 体型: やや猫背、頭身2:1
- 色: 紫、黒
- 特徴: 小さな角、尖った尻尾、コウモリ翼
- サイズ: 縦400px、横310px

**状態バリエーション（ステータス）**:
- `normal`: 不敵な笑み
- `happy`: 闇のオーラが強まる
- `sick`: 紫色が薄くなる、尻尾だれる
- `angry`: 角が伸びる、目が赤く光る

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 闇のエネルギー吸収
- `attack`: 闇の球体を構える
- `sleep`: 逆さ吊り姿勢
- `clean`: 闇の霧で包む

ファイル命名例: `child_demon_normal.png`, `child_demon_attack.png`

---

### A-4) 成熟期（56枚）
**7種類 × (4状態 + 4アクション) = 56枚**

#### 主要4種（詳細指示）

##### グレイモン（戦士・炎）
ファイル名例: `adult_greymon_normal_idle.png`

**デザイン指示**:
- 体型: 恐竜型、二足歩行、頭身3:1
- 色: オレンジ主体、腹部クリーム色
- 特徴:
  - 頭部: 角×2、鋭い目
  - 体: ゴツゴツした鱗、背中にトゲ
  - 腕: 筋肉質、3本指の爪
  - 尻尾: 長く太い、先端にトゲ
- エフェクト: 口から炎の息
- サイズ: 縦480px、横400px
- 参考: ティラノサウルス + ドラゴン

##### ガルルモン（獣・氷）
ファイル名例: `adult_garurumon_normal_idle.png`

**デザイン指示**:
- 体型: 狼型、四足歩行
- 色: 青白、銀色のたてがみ
- 特徴:
  - 頭部: 鋭い目、長い耳、牙
  - 体: しなやかな筋肉、流線型
  - 足: 大きな肉球、鋭い爪
  - 尻尾: ふさふさ
- エフェクト: 冷気オーラ
- サイズ: 縦420px、横480px
- 参考: シベリアンハスキー + 氷の狼

##### エンジェモン（聖・光）
ファイル名例: `adult_angemon_normal_idle.png`

**デザイン指示**:
- 体型: 人型、頭身4:1、細身
- 色: 白、金、淡い青
- 特徴:
  - 頭部: 兜（金）、優しい目
  - 体: ローブ風、体のラインが見える
  - 翼: 6枚（背中から3対）、羽毛細密
  - 装備: 杖（金）、先端に十字架
  - 光背: 後光（輪っか）
- エフェクト: 聖なる光
- サイズ: 縦500px、横360px
- 参考: 天使 + 聖騎士

#### デビモン（闇・呪）
ファイル名例: `adult_devimon_normal.png`

**デザイン指示**:
- 体型: 人型、頭身4:1、痩せ型
- 色: 黒、紫、赤目
- 特徴:
  - 頭部: 角×2（曲線）、邪悪な笑み
  - 体: マントボロボロ、筋肉質
  - 翼: コウモリ翼（破れあり）
  - 腕: 長い爪、赤い手袋風
- エフェクト: 紫の瘴気
- サイズ: 縦490px、横380px
- 参考: 堕天使 + デーモン

**状態バリエーション（ステータス）**:
- `normal`: 不敵な直立、マントをなびかせる
- `happy`: 邪悪な笑い、翼を広げる
- `sick`: 翼たれ、紫の瘴気薄い
- `angry`: 爪を立てる、翼を大きく広げる

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 闇のエネルギーを吸収
- `attack`: 爪を振りかざす姿勢
- `sleep`: 翼で体を包む
- `clean`: 紫の瘴気で浄化

ファイル命名例: `adult_devimon_normal.png`, `adult_devimon_attack.png`

#### アグモン（小型恐竜・炎）
ファイル名例: `adult_agumon_normal.png`

**デザイン指示**:
- 体型: 小型恐竜、頭身2:1、可愛い系
- 色: 黄色、爪は白
- 特徴: グレイモンの下位互換、丸い目、小さな角
- エフェクト: 小さな炎
- サイズ: 縦420px、横360px

**状態バリエーション（ステータス）**:
- `normal`: 元気に直立、笑顔
- `happy`: 両腕を上げて喜ぶ
- `sick`: しょぼんと座り込む
- `angry`: 口を開けて威嚇、小さな炎

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 大きな口で食べる
- `attack`: パンチを繰り出す姿勢
- `sleep`: 丸くなって眠る
- `clean`: 体を拭く動作

ファイル命名例: `adult_agumon_normal.png`, `adult_agumon_attack.png`

#### ガブモン（子狼・氷）
ファイル名例: `adult_gabumon_normal.png`

**デザイン指示**:
- 体型: 四足歩行、頭身1.5:1
- 色: 水色、毛皮モフモフ
- 特徴: ガルルモンの下位互換、垂れ耳、ふさふさ尻尾
- エフェクト: 冷気
- サイズ: 縦400px、横420px

**状態バリエーション（ステータス）**:
- `normal`: おとなしく座る
- `happy`: 尻尾を振り、微笑む
- `sick`: 伏せて耳を垂らす
- `angry`: 牙を剥き、毛を逆立てる

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 頃を下げて食事
- `attack`: 飛びかかる姿勢
- `sleep`: 丸くなって眠る
- `clean`: 毛づくろい

ファイル命名例: `adult_gabumon_normal.png`, `adult_gabumon_attack.png`

#### レオモン（ライオン戦士・岩）
ファイル名例: `adult_leomon_normal.png`

**デザイン指示**:
- 体型: 二足歩行、頭身3:1、筋肉質
- 色: 茶色、たてがみ金色
- 特徴: 剣持ち、ライオンの顔、武道着
- エフェクト: 岩のオーラ
- サイズ: 縦480px、横390px

**状態バリエーション（ステータス）**:
- `normal`: 剣を構えた直立姿勢
- `happy`: 剣を高く掲げ、勇ましい姿
- `sick`: 剣を杖に膝をつく
- `angry`: 戦闘姿勢、剣を両手で構える

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 剣を置いて食事
- `attack`: 剣を振りかざす姿勢
- `sleep`: 座禅する姿勢
- `clean`: 剣を磨く

ファイル命名例: `adult_leomon_normal.png`, `adult_leomon_attack.png`

---

### A-5) 究極体（32枚）
**4種類 × (4状態 + 4アクション) = 32枚**

#### 主要2種（詳細指示）

##### ウォーグレイモン（最強戦士）
ファイル名例: `ultimate_wargreymon_normal.png`

**デザイン指示**:
- 体型: 人型恐竜、頭身3.5:1、筋骨隆々
- 色: 鮮やかなオレンジ、金属部分シルバー
- 装備:
  - 頭部: メタルヘルム（角状アンテナ）
  - 胴体: プレートアーマー（胸・肩・腰）
  - 腕: 巨大な爪盾（ドラモンキラー）× 2
  - 背中: 翼なし、背面に推進器風
- エフェクト: オーラ（赤橙）、地面に亀裂
- サイズ: 縦510px、横420px
- 参考: メカゴジラ + ドラゴンナイト

**状態バリエーション（ステータス）**:
- `normal`: 通常直立、両腕の爪盾を構える
- `happy`: 勝利ポーズ、片腕を上げる
- `sick`: 膝をつき、オーラ消失
- `angry`: 前傾姿勢、爪盾を交差、オーラ増強

**アクションポーズ（Tier0+ 静止）**:
- `eat`: 爪盾を外し食事（エネルギー補給）
- `attack`: 爪盾を突き出し突進姿勢
- `sleep`: 座り込み、ヘルム外した状態
- `clean`: 装甲メンテナンス（工具持ち）

ファイル命名例: `ultimate_wargreymon_normal.png`, `ultimate_wargreymon_attack.png`

##### メタルガルルモン（究極獣）
ファイル名例: `ultimate_metalgarurumon_normal.png`

**デザイン指示**:
- 体型: サイボーグ狼、四足
- 色: 青、シルバー、黒
- 装備:
  - 頭部: メタルマスク、赤い複眼
  - 体: 機械装甲（関節部分はメカニカル）
  - 翼: 金属製ブレード型×2
  - 武器: 背中にミサイルポッド
- エフェクト: 冷気+電撃
- サイズ: 縦450px、横500px
- 参考: ロボット犬 + 戦闘機

**状態バリエーション（ステータス）**:
- `normal`: 四足直立、翼展開
- `happy`: 遠吠え姿勢、冷気オーラ
- `sick`: 伏せた姿勢、装甲くすむ
- `angry`: 牙を剥き、ミサイルポッド展開

**アクションポーズ（Tier0+ 静止）**:
- `eat`: エネルギーカプセル摂取
- `attack`: 飛び掛かる姿勢、爪を前に
- `sleep`: 丸くなり翼を畳む
- `clean`: 自己修復モード（スパーク表現）

ファイル命名例: `ultimate_metalgarurumon_normal.png`, `ultimate_metalgarurumon_attack.png`

#### セラフィモン（最高天使・光）
ファイル名例: `ultimate_seraphimon_normal.png`

**デザイン指示**:
- 体型: 人型、頭身5:1、威厳ある
- 色: 白、金、プラチナ
- 装備:
  - 頭部: 黄金の冠、優しくも厳格な目
  - 体: 神聖な鎧（プレート+ローブ）
  - 翼: 10枚（背中から5対）、光り輝く
  - 武器: 光の剣（両手持ち）
- エフェクト: 聖なる光柱、天空の輪
- サイズ: 縦520px、横380px

**状態・アクション**: 上記2種と同様の8ポーズ

#### デーモン（大悪魔・闇）
ファイル名例: `ultimate_daemon_normal.png`

**デザイン指示**:
- 体型: 人型悪魔、頭身4.5:1、威圧的
- 色: 黒赤、紫のオーラ
- 装備:
  - 頭部: 7つの目、巨大な角×2
  - 体: 鱗のような装甲、炎の模様
  - 翼: 巨大なコウモリ翼×2
  - 武器: 闇の大鎌
- エフェクト: 地獄の炎、闇のオーラ
- サイズ: 縦530px、横420px

**状態・アクション**: 上記2種と同様の8ポーズ

---

### 🚀 将来拡張: Animation Upgrade Roadmap（論理スロット指針）
| ティア | 目的 | 追加スロット例 | 1状態あたりフレーム目安 | ペット1種あたり総フレーム例（4状態） |
|-------|------|----------------|--------------------------|----------------------------------------|
| Tier0 (現行) | コスト最小 / 実装優先 | `idle`静止のみ | 1 | 4 |
| Tier1 | 軽量ループ演出 | `idle`, `walk`, `attack` | idle2 / walk4 / attack4 | (2+4+4)×4 = 40 |
| Tier2 | 育成アクション表現 | `idle`,`walk`,`eat`,`play`,`sleep`,`clean`,`attack`,`hurt` | 4 /6 /6 /6 /4 /4 /8 /4 | 42×4 = 168 |
| Tier3 | リッチ演出 / 商品性 | Tier2 + `evolve`,`charge`,`special` + パーティクル | evolve6 / charge6 / special12 | 168 + 6+6+12 = 192 |

命名規則（フレーム展開時）:
```
{stage}_{species}_{state}_{action}_{frame2d}.png
例: adult_greymon_happy_walk_03.png
```

静止画段階: `adult_greymon_happy.png` のみ。差し替え時は同プレフィックスでアニメフレームを追加/切替。

Flutter擬似アニメ指針（Tier0補完）:
1. ScaleTransition + TweenSequence → 鼓動（idle代替）
2. AnimatedOpacity + SlideTransition → 簡易walk/attack
3. ShaderMask グラデ流し → charge準備演出
4. ColorFiltered（彩度↓）→ sick状態表現
5. Transform.rotate 微小揺れ → dizzy表現

論理スロット → 関数マッピング例:
```
slot idle   -> scalePulse()
slot walk   -> horizontalOscillation()
slot attack -> quickScaleForward()
slot sleep  -> opacityBreathing()
slot clean  -> particleOverlay('bubbles')
slot eat    -> mouthOverlayCycle()
```

拡張時は `assets/pets/{stage}/{species}/anim/` 以下にフレーム格納推奨。

---

### A-5) 究極体（第2フェーズ以降）
**第1フェーズでは未実装**。成熟期まで育成できたら追加検討。

#### 主要2種（詳細指示）

##### ウォーグレイモン（最強戦士）
ファイル名例: `ultimate_wargreymon_normal_idle.png`

**デザイン指示**:
- 体型: 人型恐竜、頭身3.5:1、筋骨隆々
- 色: 鮮やかなオレンジ、金属部分シルバー
- 装備:
  - 頭部: メタルヘルム（角状アンテナ）
  - 胴体: プレートアーマー（胸・肩・腰）
  - 腕: 巨大な爪盾（ドラモンキラー）× 2
  - 背中: 翼なし、背面に推進器風
- エフェクト: オーラ（赤橙）、地面に亀裂
- サイズ: 縦510px、横420px
- 参考: メカゴジラ + ドラゴンナイト

##### メタルガルルモン（究極獣）
ファイル名例: `ultimate_metalgarurumon_normal_idle.png`

**デザイン指示**:
- 体型: サイボーグ狼、四足
- 色: 青、シルバー、黒
- 装備:
  - 頭部: メタルマスク、赤い複眼
  - 体: 機械装甲（関節部分はメカニカル）
  - 翼: 金属製ブレード型×2
  - 武器: 背中にミサイルポッド
- エフェクト: 冷気+電撃
- サイズ: 縦450px、横500px
- 参考: ロボット犬 + 戦闘機

#### 残り7種（簡易指示）
| 種類 | 系統 | コンセプト | 主色 |
|------|------|-----------|------|
| セラフィモン | 聖 | 10枚翼の最高天使 | 白金 |
| デーモン | 闇 | 大悪魔 | 黒赤 |
| オメガモン | 融合 | 騎士 | 白青 |
| メタルシードラモン | 水 | 海竜サイボーグ | 銀青 |
| ムゲンドラモン | 機械 | 巨大戦車 | 灰黒 |
| ピノッキモン | 木 | 操り人形魔術師 | 木茶 |
| フェニックスモン | 火 | 不死鳥 | 紅金 |

---

## 🥈 **高優先**: UI部品（8枚 / ボタンのみ）

### B-1) アクションボタン（4種 × 2状態 = 8枚）
| ファイル名 | アイコン | 背景色 |
|-----------|---------|-------|
| `btn_feed.png` | 🍖肉アイコン | オレンジ円形 |
| `btn_feed_pressed.png` | 同上 | 10%暗め |
| `btn_play.png` | 🎮ゲームパッドアイコン | 青円形 |
| `btn_play_pressed.png` | 同上 | 10%暗め |
| `btn_clean.png` | 🧹ほうきアイコン | 緑円形 |
| `btn_clean_pressed.png` | 同上 | 10%暗め |
| `btn_medicine.png` | 💊薬アイコン | 赤円形 |
| `btn_medicine_pressed.png` | 同上 | 10%暗め |

**仕様**:
- サイズ: 128×128px
- 形: 完全な円
- 内側アイコン: 白、64×64px
- 押下状態: 元画像を10%暗くした別ファイル

---

### B-2) 背景・パネル画像（18種 × 各サイズ）

**注意**: ステータスパネル、ポップアップ、カード枠の3つはFlutterコード実装のため画像不要。

#### 基本背景（10種）
| ファイル名 | サイズ | デザイン指示 |
|-----------|--------|-------------|
| `bg_room_day.png` | 1080×1920px | 明るい部屋（窓から日光、木製家具、暖色系） |
| `bg_room_night.png` | 1080×1920px | 夜の部屋（月明かり、ランプ、寒色系） |
| `bg_battle_fire.png` | 1080×1920px | 炎属性バトル場（溶岩、赤橙グラデ） |
| `bg_battle_water.png` | 1080×1920px | 水属性バトル場（海底、青緑グラデ） |
| `bg_battle_nature.png` | 1080×1920px | 自然属性バトル場（森林、緑グラデ） |
| `bg_evolution.png` | 1080×1920px | 進化演出用（光の渦、虹色グラデ） |
| `panel_evolution_tree.png` | 800×1200px | 進化ツリー背景（ノード接続図ベース） |
| `panel_gacha_bg.png` | 1080×1920px | ガチャ演出背景（キラキラ、金色） |
| `ui_gravestone.png` | 256×256px | 墓標アイコン（🪦石碑+RIP文字） |
| `ui_flash_white.png` | 1080×1920px | 白フラッシュ用（完全白、透過なし） |

#### バトルフィールド詳細版（8種）
| ファイル名 | サイズ | デザイン指示 |
|-----------|--------|-------------|
| `bg_battle_forest.png` | 1080×1920px | 森林フィールド（巨木、木漏れ日、緑豊か） |
| `bg_battle_desert.png` | 1080×1920px | 砂漠フィールド（砂丘、サボテン、黄金色） |
| `bg_battle_snow.png` | 1080×1920px | 雪原フィールド（雪景色、氷柱、白青） |
| `bg_battle_cave.png` | 1080×1920px | 洞窟フィールド（鍾乳石、暗闇、青紫） |
| `bg_battle_volcano.png` | 1080×1920px | 火山フィールド（噴火口、マグマ、赤黒） |
| `bg_battle_ocean.png` | 1080×1920px | 海洋フィールド（深海、泡、青） |
| `bg_battle_sky.png` | 1080×1920px | 天空フィールド（雲海、光、水色） |
| `bg_battle_ruins.png` | 1080×1920px | 遺跡フィールド（古代神殿、石柱、灰色） |

**仕様**:
- フォーマット: PNG-24（透過あり、フラッシュ以外）
- 解像度: 背景1080×1920px、パネル800×1200px、小物256×256px
- 圧縮: 背景は200KB以下、パネル/小物は50KB以下推奨

**Flutter実装との組み合わせ**:
- 背景画像上にコード実装のステータスパネルやカードを重ねて表示
- 進化演出時は`bg_evolution.png`を表示し、その上にアニメーションエフェクトを追加

---

### B-3) UI装飾パーツ（3種 × 各サイズ）

| ファイル名 | サイズ | デザイン指示 |
|-----------|--------|-------------|
| `ui_frame_corner_tl.png` | 64×64px | カード枠角装飾（金属質、光沢、L字型）※他3隅はウィジェットで回転/反転配置 |
| `ui_sparkle_rarity.png` | 128×128px | レア度表示用キラキラ（星型、白金色、発光） |
| `ui_evolution_glow.png` | 256×256px | 進化可能時の発光オーラ（円形、虹色グラデ、透過） |

**用途**:
- 角装飾: PanelCardFrameの4隅に配置してカードの高級感を演出
- キラキラ: レア度3以上のカードに表示（アニメーション回転）
- 発光オーラ: 進化条件達成時にペット画像の背後に表示

**仕様**:
- フォーマット: PNG-24（透過必須）
- 圧縮: 各30KB以下
- 角装飾はコードで回転/反転して使用（4方向対称デザイン推奨）

---

### B-4) アイコンセット（12種 × 64×64px）

#### 属性アイコン（8種）
属性システムを8属性に拡張。光/闇を追加してエンジェル系・デビル系に対応。

| ファイル名 | 属性名 | デザイン指示 | 相性 |
|-----------|--------|-------------|------|
| `icon_element_fire.png` | 炎🔥 | 赤オレンジ、炎マーク、丸型背景 | 強: 草/氷、弱: 水/岩 |
| `icon_element_water.png` | 水💧 | 青、水滴マーク、丸型背景 | 強: 炎/岩、弱: 電気/草 |
| `icon_element_grass.png` | 草🌿 | 緑、葉マーク、丸型背景 | 強: 水/岩、弱: 炎/氷 |
| `icon_element_electric.png` | 電気⚡ | 黄色、稲妻マーク、丸型背景 | 強: 水、弱: 岩 |
| `icon_element_ice.png` | 氷❄️ | 水色、雪結晶マーク、丸型背景 | 強: 草、弱: 炎/岩 |
| `icon_element_rock.png` | 岩🪨 | 灰茶色、岩マーク、丸型背景 | 強: 炎/氷/電気、弱: 水/草 |
| `icon_element_light.png` | 光✨ | 白金、十字マーク、丸型背景 | 強: 闇、弱: なし |
| `icon_element_dark.png` | 闇🌑 | 黒紫、三日月マーク、丸型背景 | 強: 光、弱: なし |

#### 状態アイコン（6種）
| ファイル名 | 状態名 | デザイン指示 | 効果 |
|-----------|--------|-------------|------|
| `icon_status_hungry.png` | 空腹 | 黄色、胃袋マーク、点滅 | お腹ゲージ低下時表示 |
| `icon_status_happy.png` | 幸福 | ピンク、ハートマーク、輝き | 機嫌ゲージ最大時表示 |
| `icon_status_sick.png` | 病気 | 緑、バイキンマーク、渦巻き | 体力ゲージ低下+病気時 |
| `icon_status_angry.png` | 怒り | 赤、怒りマーク💢、激しい | 機嫌ゲージ最低時表示 |
| `icon_status_sleepy.png` | 眠い | 紫、Zマーク、半透明 | 夜間または疲労時表示 |
| `icon_status_dirty.png` | 汚れ | 茶色、泥マーク、点々 | 清潔ゲージ低下時表示 |

#### その他アイコン（2種）
| ファイル名 | 用途 | デザイン指示 |
|-----------|------|-------------|
| `icon_evolution_ready.png` | 進化可能 | 金色、上向き矢印、キラキラ |
| `icon_battle.png` | バトル | 赤、交差する剣×2、光沢 |

**用途**:
- 属性アイコン: カード左上、バトル画面、進化ツリーで表示
- 状態アイコン: ステータスパネル横、ペット画像上にオーバーレイ
- その他アイコン: UI各所で機能表示

**仕様**:
- サイズ: 64×64px（アイコン本体は48px、周囲8px余白）
- フォーマット: PNG-24（透過あり）
- 背景: 円形または角丸四角、属性カラー
- 圧縮: 各10KB以下

---

## 🥉 **中優先**: アイテムアイコン（20枚）

### C-1) 消耗品（8種 × 256×256px）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `item_food_premium.png` | 豪華なステーキ皿 |
| `item_toy.png` | カラフルなボール |
| `item_bath.png` | 桶+石鹸+タオル |
| `item_energy.png` | 光るドリンクボトル |
| `item_medicine.png` | 赤十字マークの薬瓶 |
| `item_revive.png` | 金色の翼チケット |
| `item_candy.png` | 虹色のキャンディ |
| `item_breed.png` | ハート形のチケット |

### C-2) レアアイテム（12種 × 256×256px）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `item_dark_fragment.png` | 紫色の結晶片 |
| `item_rainbow_feather.png` | 虹色に輝く羽 |
| `item_skill_book.png` | 魔法書（開いた状態）|
| `item_timecapsule.png` | カプセル型時計 |
| `item_lucky_charm.png` | 四つ葉のクローバーお守り |
| `item_exp_potion_s.png` | 小瓶（緑）|
| `item_exp_potion_m.png` | 中瓶（青）|
| `item_exp_potion_l.png` | 大瓶（紫）|
| `item_evolution_stone.png` | 光る宝石 |
| `item_friendship_badge.png` | 友情バッジ |
| `item_battle_pass.png` | 剣マークのパス |
| `item_gacha_ticket.png` | 金色のくじ券 |

### C-3) 装備品（6種 × 256×256px）
| ファイル名 | デザイン指示 | 効果 |
|-----------|-------------|------|
| `item_power_ring.png` | 赤い指輪、炎エフェクト | 攻撃力+20% |
| `item_shield_amulet.png` | 青いお守り、盾マーク | 防御力+20% |
| `item_speed_boots.png` | 緑のブーツ、風エフェクト | 素早さ+20% |
| `item_hp_necklace.png` | 紫のネックレス、ハート | 最大HP+30% |
| `item_critical_gloves.png` | 黄色い手袋、星マーク | クリティカル率+15% |
| `item_exp_crown.png` | 金の王冠、キラキラ | 獲得経験値+50% |

**用途**: ペットに装備させて能力強化。バトルで有利に。

### C-4) 推奨追加アイテム（今後の拡張用）

以下は現時点では不要ですが、将来的にゲームを拡張する際に追加推奨:

#### 消耗品追加候補
- `item_super_food.png` - 超豪華ディナー（全ゲージ+50%）
- `item_evolution_catalyst.png` - 進化触媒（進化を即座に実行）
- `item_skill_reset.png` - スキルリセット薬

#### レアアイテム追加候補
- `item_shiny_charm.png` - 色違い確率UP
- `item_breeding_incense.png` - 配合時レア度UP
- `item_mega_stone.png` - メガ進化用アイテム

#### 装備品追加候補
- `item_element_orb_{fire,water,grass,etc}.png` - 属性強化オーブ8種
- `item_mega_accessory.png` - メガ進化アクセサリ

**現時点では基本28種で十分**です。必要に応じて後から追加できます。

---

## 👹 エネミー画像（20種 × 512×512px）

### E-1) 野生モンスター（8種 × 2状態 = 16枚）

#### スライム系（弱敵・水）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_slime_normal.png` | 青いスライム、丸型、目が2つ、ニコニコ |
| `enemy_slime_attack.png` | 体を伸ばして攻撃姿勢、目が鋭く |

#### ゴブリン系（雑魚）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_goblin_normal.png` | 緑色ゴブリン、棍棒持ち、いたずら顔 |
| `enemy_goblin_attack.png` | 棍棒を振り上げ、威嚇ポーズ |

#### ウルフ系（中堅）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_wolf_normal.png` | 灰色狼、四足歩行、鋭い目 |
| `enemy_wolf_attack.png` | 飛びかかる姿勢、牙を剥く |

#### ドラゴン系（強敵）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_dragon_normal.png` | 赤いドラゴン、翼広げ、威圧感 |
| `enemy_dragon_attack.png` | 口から炎を吐く姿勢 |

#### ゴーレム系（中堅・岩）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_golem_normal.png` | 石造りの人型、苔生える、ゆっくり歩く |
| `enemy_golem_attack.png` | 拳を振り上げる、岩石飛ばす |

#### エレメンタル系（強敵・電気）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_elemental_normal.png` | 雷の精霊、浮遊、人型シルエット |
| `enemy_elemental_attack.png` | 稲妻を放つ、両腕広げる |

#### ゾンビ系（中堅・闇）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_zombie_normal.png` | 腐敗した人型、緑色、ボロボロ服 |
| `enemy_zombie_attack.png` | 両腕を前に、襲いかかる |

#### フェアリー系（弱敵・光）
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_fairy_normal.png` | 小さな妖精、透明な翼、キラキラ |
| `enemy_fairy_attack.png` | 魔法の粉を振りまく |

### E-2) ボスモンスター（2種 × 2状態 = 4枚）

#### 闇の魔王
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_boss_darklord_normal.png` | 黒紫ローブ、角×2、邪悪オーラ、杖持ち |
| `enemy_boss_darklord_attack.png` | 杖から黒い波動、魔法陣展開 |

#### 古代の巨神
| ファイル名 | デザイン指示 |
|-----------|-------------|
| `enemy_boss_titan_normal.png` | 石造りの巨人、苔生える、古代文字 |
| `enemy_boss_titan_attack.png` | 拳を地面に叩きつけ、亀裂発生 |

**仕様**:
- サイズ: 512×512px（ペット本体と同じ）
- フォーマット: PNG-24（透過あり）
- 体型: ペットと区別しやすいデザイン（より凶悪、威圧的）
- 圧縮: 各50KB以下

**用途**:
- バトル画面で敵キャラとして表示
- ボスはイベント戦闘、クエストで登場

---

## 🎭 エフェクト画像

### F-1) 進化演出用エフェクト（3種 × 256×256px）

| ファイル名 | デザイン指示 |
|-----------|-------------|
| `effect_evolution_light.png` | 光の渦、白金色、螺旋状、透過グラデ |
| `effect_evolution_particle.png` | 光の粒子×8個、キラキラ、ランダム配置 |
| `effect_evolution_ring.png` | 光の輪、虹色、円形、拡大用 |

**用途**:
- 進化演出時に`bg_evolution.png`上で重ねて表示
- アニメーション: 渦は回転、粒子は浮遊、輪は拡大

**仕様**:
- サイズ: 256×256px
- フォーマット: PNG-24（透過必須）
- 圧縮: 各30KB以下

### F-2) 感情・バトルエフェクト（コード実装）

**暫定実装方針**:
- **感情エフェクト**: 絵文字 + AnimatedOpacity（💗❤️😡😴💫🤢）
- **バトルエフェクト**: CustomPaint + パーティクルシステム
  - キラキラ: 白い円をランダム配置 + ScaleTransition
  - 爆発: 円形グラデーション + 拡大アニメーション
  - 斬撃: 白い線 + SlideTransition
  - 回復: 緑の光粒子上昇
  - 毒: 紫の泡浮遊

---

## 🎰 ガチャ演出画像（4種 × 256×256px）

| ファイル名 | レア度 | デザイン指示 |
|-----------|--------|-------------|
| `gacha_capsule_common.png` | ★1-2 | 灰色カプセル、シンプル、無地 |
| `gacha_capsule_rare.png` | ★3 | 青いカプセル、銀の帯、少し光沢 |
| `gacha_capsule_epic.png` | ★4 | 紫のカプセル、金の帯、キラキラ |
| `gacha_capsule_legendary.png` | ★5 | 虹色カプセル、金装飾、強い発光 |

**用途**:
- ガチャ画面で回転演出
- カプセルが割れてペットが出現

**仕様**:
- サイズ: 256×256px
- フォーマット: PNG-24（透過あり）
- 形状: 上下に分かれるカプセル型
- 圧縮: 各30KB以下

---

## 🎭 削除: エフェクト（暫定コード実装）

**第1フェーズではエフェクト画像は制作せず、Flutterコードで暫定実装します。**

### 暫定実装方針
- **感情エフェクト**: 絵文字 + AnimatedOpacity（💗❤️😡😴💫🤢）
- **バトルエフェクト**: CustomPaint + パーティクルシステム
  - キラキラ: 白い円をランダム配置 + ScaleTransition
  - 爆発: 円形グラデーション + 拡大アニメーション
  - 斬撃: 白い線 + SlideTransition
  - 回復: 緑の光粒子上昇
  - 毒: 紫の泡浮遊

### 将来拡張（第2フェーズ）
画像エフェクトを追加する場合の仕様:
- 感情: 128×128px、各3-5フレーム、計約16枚
- バトル: 256×256px、各4-8フレーム、計約26枚

---

## 📁 フォルダ構成（Tier0静止画例）

```
assets/
├── pets/
│   ├── egg/
│   │   └── egg_{idle,walk,eat,play,sleep,clean,attack}.png
│   ├── baby/
│   │   └── genki/baby_genki_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   ├── child/
│   │   ├── warrior/child_warrior_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   ├── beast/child_beast_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   ├── angel/child_angel_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   └── demon/child_demon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   ├── adult/
│   │   ├── greymon/adult_greymon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   ├── garurumon/adult_garurumon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   ├── angemon/adult_angemon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   ├── devimon/adult_devimon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   ├── agumon/adult_agumon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   ├── gabumon/adult_gabumon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   │   └── leomon/adult_leomon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│   └── ultimate/
│       ├── wargreymon/ultimate_wargreymon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│       ├── metalgarurumon/ultimate_metalgarurumon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│       ├── seraphimon/ultimate_seraphimon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
│       └── daemon/ultimate_daemon_{normal,happy,sick,angry,eat,attack,sleep,clean}.png
├── enemies/
│   ├── slime_{normal,attack}.png
│   ├── goblin_{normal,attack}.png
│   ├── wolf_{normal,attack}.png
│   ├── dragon_{normal,attack}.png
│   ├── golem_{normal,attack}.png
│   ├── elemental_{normal,attack}.png
│   ├── zombie_{normal,attack}.png
│   ├── fairy_{normal,attack}.png
│   └── boss/
│       ├── darklord_{normal,attack}.png
│       └── titan_{normal,attack}.png
├── ui/
│   ├── buttons/
│   │   └── btn_{feed,play,clean,medicine}_{normal,pressed}.png
│   ├── backgrounds/
│   │   ├── bg_room_{day,night}.png
│   │   ├── bg_battle_{fire,water,nature,forest,desert,snow,cave,volcano,ocean,sky,ruins}.png
│   │   ├── bg_evolution.png
│   │   ├── panel_evolution_tree.png
│   │   └── panel_gacha_bg.png
│   ├── decorations/
│   │   ├── ui_frame_corner_{tl,tr,bl,br}.png
│   │   ├── ui_sparkle_rarity.png
│   │   └── ui_evolution_glow.png
│   ├── icons/
│   │   ├── elements/
│   │   │   └── icon_element_{fire,water,grass,electric,ice,rock,light,dark}.png
│   │   ├── status/
│   │   │   └── icon_status_{hungry,happy,sick,angry,sleepy,dirty}.png
│   │   └── misc/
│   │       └── icon_{evolution_ready,battle}.png
│   └── misc/
│       ├── ui_gravestone.png
│       └── ui_flash_white.png
├── items/
│   ├── consumables/
│   │   └── item_{food_premium,toy,bath,energy,medicine,revive,candy,breed,super_food,evolution_catalyst}.png
│   ├── rare/
│   │   └── item_{dark_fragment,rainbow_feather,skill_book,timecapsule,lucky_charm,exp_potion_s,exp_potion_m,exp_potion_l,evolution_stone,friendship_badge,battle_pass,gacha_ticket}.png
│   └── equipment/
│       └── item_{power_ring,shield_amulet,speed_boots,hp_necklace,critical_gloves,exp_crown}.png
├── effects/
│   ├── evolution/
│   │   ├── effect_evolution_light.png
│   │   ├── effect_evolution_particle.png
│   │   └── effect_evolution_ring.png
│   └── battle/ （コード実装: パーティクルシステム）
└── gacha/
    └── gacha_capsule_{common,rare,epic,legendary}.png
```

---

## ✅ 納品チェックリスト

### 制作前確認
- [ ] PNG-24形式（透過あり）
- [ ] 背景完全透過
- [ ] 命名規則スネークケース
- [ ] 指定サイズ厳守

### 制作後確認
- [ ] 各画像50KB以下
- [ ] アルファチャンネル正常
- [ ] ファイル名タイポなし
- [ ] フォルダ構成一致

### 品質確認
- [ ] 輪郭線統一（2-3px）
- [ ] 色彩統一（ビビッド）
- [ ] ドット絵の場合、ジャギー処理
- [ ] アニメーション連続性

---

## 💻 Flutter実装サンプル参考（コード実装UI）

以下の3つのUIコンポーネントは**画像不要**で、Flutterコードで実装済みです。
HTMLプロトタイプコードを参考に実装されています。

### 1. ステータスパネル (`PanelStatus`)
**実装要素**:
- サイズ: 600×200px（レスポンシブ対応）
- 背景: 半透明白（opacity 85%）
- 枠線: 2px、青→水色グラデーション（`border-image`相当をCustomPainterで実装）
- 角装飾: 4隅に回路パターン風の装飾（10×10px、青色線）
- ゲージ: 4本（お腹/機嫌/清潔/体力）、各々グラデーション塗り
  - 80%以上: 緑系 `#4ade80 → #10b981`
  - 40-79%: 黄色系 `#facc15 → #f59e0b`
  - 1-39%: 赤系 `#f87171 → #ef4444`

**Flutter実装ポイント**:
```dart
// グラデーション枠線
CustomPaint(
  painter: _GradientBorderPainter(
    gradient: LinearGradient(colors: [Color(0xFF007BFF), Color(0xFF00C7FF)]),
    strokeWidth: 2.0,
  ),
  child: Container(...),
)

// ゲージバー
LinearProgressIndicator(
  value: 0.8,
  backgroundColor: Color(0xFFE5E7EB),
  valueColor: AlwaysStoppedAnimation(Color(0xFF4ADE80)),
)
```

### 2. ポップアップパネル (`PanelPopup`)
**実装要素**:
- サイズ: 800×600px（モーダル表示）
- 背景: 白→薄青グラデーション（opacity 95%）
- 外枠: 金色二重線（4px + 影）＋虹色装飾（✨絵文字アニメーション）
- ヘッダー: 青→紫グラデーション、上部中央に金色エンブレム（🏆）
- フッター: 金色二重境界線、ボタン2個（OK/キャンセル）

**Flutter実装ポイント**:
```dart
// 金色枠線
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Color(0xFFFFC107), width: 4),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10),
    ],
  ),
)

// キラキラアニメーション
AnimatedOpacity(
  opacity: _twinkle ? 0.8 : 1.0,
  duration: Duration(milliseconds: 1500),
  child: Text('✨', style: TextStyle(fontSize: 24)),
)
```

### 3. カード枠パネル (`PanelCardFrame`)
**実装要素**:
- サイズ: 280×400px
- 背景: 属性別グラデーション（ダークブルー系など）
- 外枠: 虹色グラデーション（4px）＋ホログラム風
  - マゼンタ→シアン→イエロー→オレンジレッド
- 画像エリア: 白い太枠（3px）＋内側に薄い影
- フッター: ATK/DEF/SPDの3本ゲージ（4px高さ、色分け）
- 角装飾: 4隅に回路パターン（8×8px）

**Flutter実装ポイント**:
```dart
// 虹色枠線（ShaderMask使用）
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [Color(0xFFFF00FF), Color(0xFF00FFFF), Color(0xFFFFFF00), Color(0xFFFF4500)],
  ).createShader(bounds),
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(width: 4, color: Colors.white),
      borderRadius: BorderRadius.circular(16),
    ),
  ),
)

// ステータスゲージ（フッター）
Row(
  children: [
    _StatBar(label: 'ATK', value: 0.8, color: Colors.red),
    _StatBar(label: 'DEF', value: 0.65, color: Colors.blue),
    _StatBar(label: 'SPD', value: 0.9, color: Colors.green),
  ],
)
```

**HTMLプロトタイプとの対応**:
- CSS `linear-gradient` → Flutter `LinearGradient`
- CSS `box-shadow` → Flutter `BoxShadow`
- CSS `border-image` → Flutter `CustomPaint` with gradient painter
- CSS `@keyframes` → Flutter `AnimationController` + `Tween`
- CSS `::before/::after` → Flutter `Stack` + `Positioned`

---

## 📊 制作優先度と枚数（第1フェーズ / Tier0+ 静止ポーズ拡張）

| 優先度 | カテゴリ | 枚数 | 納期目安 |
|--------|---------|------|----------|
| 🔴最優先 | ペット本体（たまご7+幼年期8+成長期32+成熟期56+究極体32） | 135枚 | 10-14日 |
| 🟠高 | エネミー（野生16+ボス4） | 20枚 | 3-4日 |
| 🟠高 | UI部品（ボタン8+背景18+装飾6） | 32枚 | 3-4日 |
| 🟡中 | アイコン（属性8+状態6+その他2） | 16枚 | 2日 |
| 🟡中 | アイテム（消耗10+レア12+装備6） | 28枚 | 3日 |
| 🟢低 | エフェクト（進化演出3） | 3枚 | 1日 |
| 🟢低 | ガチャ（カプセル4種） | 4枚 | 1日 |

**合計: 約247枚**（納期目安: 3-4週間）

**注意**: 
- ステータスパネル、ポップアップ、カード枠はFlutterコード実装のため画像不要（lib/widgets/配置済み）
- 感情・バトルエフェクトはコード実装（絵文字+パーティクルシステム）
- **光/闇属性を追加**してエンジェル系・デビル系に対応

**第2フェーズ以降**: 残りモンスター種類、究極体、レアアイテム等を追加

---

## 💡 制作のヒント

### ドット絵制作の場合
1. **Aseprite**または**Pixaki**推奨
2. 16×16pxで描いて32倍拡大（Nearest Neighbor）
3. カラーパレット事前作成（16色程度）
4. レイヤー分け（本体/装備/エフェクト）

### 手描き風の場合
1. **Procreate**または**Clip Studio Paint**推奨
2. ベクター化でスケール対応
3. 線画→塗り→影→ハイライトの順
4. 最終的にラスタライズ→PNG出力

### アニメーション作成
1. 各フレーム個別ファイル（`_01`, `_02`...）
2. フレーム数は偶数推奨（ループ容易）
3. 待機アニメは2-4フレーム
4. 動作アニメは6-8フレーム

---

## 🎯 最終目標
**ポケモンカード風のUI**で、たまごっち×デジモン×ドラクエモンスターズの融合育成ゲームを実現。

### UI差別化ポイント
- **カード型レイアウト**: ペット画像をポケモンカード風の枠で表示
- **ゲージはFlutter製**: グラデーション＋角丸を完全制御、画像不要
- **段階的拡張**: 第1フェーズで基本種のみ実装、後続で拡張

**最優先発注**: たまご(7アクション) + 幼年期(4状態+4アクション=8) + 成長期2種(各8) + 成熟期3種(各8) の計55枚から開始してください！（静止画 Tier0+）

**UI部品**: アクションボタン4種×2状態=8枚のみ。パネル・背景はFlutterウィジェット実装済みで画像不要。

---

## 🔵 **第2フェーズ**: 追加モンスター種類（静止画追加 + アニメ段階的導入）

### 第2フェーズで追加する内容
第1フェーズで基本システムが完成した後、以下を段階的に追加します。

---

### A-2追加) 幼年期（追加1種: 32枚）
**1種類 × 4状態 × 8アニメーション = 32枚**

#### プチモン（おとなしいタイプ）
ファイル名例: `baby_shy_normal_idle.png`

**デザイン指示**:
- 体型: パピモンより小さめ、頭身1.3:1
- 色: 淡いブルー
- 特徴: 半目、控えめな表情、小さな手足
- サイズ: 縦320px、横260px

**状態バリエーション**:
- `normal`: 通常
- `happy`: 頬に💗、目がキラキラ
- `sick`: 顔色青白い、目が渦巻き
- `angry`: 怒りマーク💢、眉が下がる

**アニメーションバリエーション**:
1. `idle`: 左右にゆっくり揺れる
2. `walk`: 足を交互に動かして移動
3. `eat`: 口を開けて食べる（3フレーム）
4. `play`: ジャンプ（上昇→頂点→着地）
5. `sleep`: 目を閉じてZZZ、寝息
6. `clean`: 水しぶきエフェクト
7. `battle`: ファイティングポーズ
8. `attack`: パンチorキック

---

### A-3追加) 成長期（追加2種: 64枚）
**2種類 × 4状態 × 8アニメーション = 64枚**

#### エンジェモン幼体（聖系）
ファイル名例: `child_angel_normal_idle.png`

**デザイン指示**:
- 体型: 細身、頭身2.5:1
- 色: 白、金のアクセント
- 装備: 小さな翼（羽4枚）、輪っか
- サイズ: 縦450px、横320px

#### デビモン幼体（闇系）
ファイル名例: `child_demon_normal_idle.png`

**デザイン指示**:
- 体型: やや猫背
- 色: 紫、黒
- 特徴: 小さな角、尖った尻尾
- サイズ: 縦400px、横310px

---

### A-4追加) 成熟期（追加7種: 224枚）
**7種類 × 4状態 × 8アニメーション = 224枚**

#### デビモン（闇・呪）
ファイル名例: `adult_devimon_normal_idle.png`

**デザイン指示**:
- 体型: 人型、頭身4:1、痩せ型
- 色: 黒、紫、赤目
- 特徴:
  - 頭部: 角×2（曲線）、邪悪な笑み
  - 体: マントボロボロ、筋肉質
  - 翼: コウモリ翼（破れあり）
  - 腕: 長い爪、赤い手袋風
- エフェクト: 紫の瘴気
- サイズ: 縦490px、横380px
- 参考: 堕天使 + デーモン

#### 残り6種（簡易指示）
| 種類 | コンセプト | 主色 | 特徴 | サイズ |
|------|-----------|------|------|--------|
| **アグモン** | 小型恐竜 | 黄色 | グレイモンの下位互換、可愛い系 | 縦420px、横360px |
| **ガブモン** | 子狼 | 水色 | ガルルモンの下位互換、毛皮モフモフ | 縦400px、横420px |
| **パタモン** | 天使ハムスター | 白 | エンジェモンの下位、耳が大きい | 縦380px、横340px |
| **ドラコモン** | ドラゴン幼体 | 緑 | 翼小さめ、爬虫類系 | 縦440px、横400px |
| **レオモン** | ライオン戦士 | 茶色 | 剣持ち二足歩行、筋肉質 | 縦480px、横390px |
| **ゴブリモン** | ゴブリン | 灰緑 | いたずら好き、棍棒持ち | 縦420px、横350px |

---

### A-5追加) 究極体（第2フェーズ: 追加7種）
**第2フェーズで追加する究極体（7種 × 8ポーズ = 56枚）**

#### 主要種（詳細指示）

##### セラフィモン（最高天使）
ファイル名例: `ultimate_seraphimon_normal.png`

**デザイン指示**:
- 体型: 人型、頭身5:1、威厳ある
- 色: 白、金、プラチナ
- 装備:
  - 頭部: 黄金の冠、優しくも厳格な目
  - 体: 神聖な鎧（プレート+ローブ）
  - 翼: 10枚（背中から5対）、光り輝く
  - 武器: 光の剣（両手持ち）
- エフェクト: 聖なる光柱、天空の輪
- サイズ: 縦520px、横380px
- 参考: 大天使ミカエル

---

### 第2フェーズ残りの究極体（簡易指示）
| 種類 | 系統 | コンセプト | 主色 | 特徴 |
|------|------|-----------|------|------|
| **デーモン** | 闇 | 大悪魔 | 黒赤 | 巨大な翼、7つの目、炎 |
| **オメガモン** | 融合 | 騎士 | 白青 | グレイモン+ガルルモン合体 |
| **メタルシードラモン** | 水 | 海竜サイボーグ | 銀青 | 機械蛇、レーザー砲 |

**注意**: 残り3種（ムゲンドラモン、ピノッキモン、フェニックスモン）は第3フェーズ以降。

---

### 第2フェーズ画像枚数まとめ（静止画のみ試算）

| カテゴリ | 追加種類 | 枚数 |
|---------|---------|------|
| 幼年期（プチモン） | 1種 | 32枚 |
| 成長期（エンジェ幼体・デビ幼体） | 2種 | 64枚 |
| 成熟期（デビモン他6種） | 7種 | 224枚 |
| 究極体（ウォーグレ・メタルガル・セラフィ） | 3種 | 96枚 |
| **第2フェーズ静止画合計** | **13種** | **(幼年期1×4) + (成長期2×4) + (成熟期7×4) + (究極体3×4) = 4 + 8 + 28 + 12 = 52枚** |

Tier1 を導入する場合の追加フレーム参考: 13種 × 4状態 × (idle2 + walk4 + attack4) = 13 × 4 × 10 = 520フレーム（差し替え・追加）。

---

### 第2フェーズ実装タイミング
1. **実装条件**: 第1フェーズのペットが成熟期まで育成できた後
2. **優先順位**: 
   - 高: 究極体3種（ユーザーがレベル70到達時に必要）
   - 中: 成熟期7種（進化の選択肢増加）
   - 低: 幼年期・成長期追加（多様性向上）

---

## 📊 全体制作スケジュール（再試算）

| フェーズ | 内容 | 静止画枚数（Tier0） | 納期目安 | 実装時期 |
|---------|------|---------------------|-----------|-----------|
| 第1フェーズ | 基本6種 + UI + アイテム + エフェクト | 約105枚 | 2週間以内 | 即座 |
| 第2フェーズ | 追加13種（静止画） | 52枚 | 1-2週間 | 基本安定後 |
| 第3フェーズ | 究極体残り + アニメTier1導入 | 追加差分（都度試算） | 指標次第 | 利用状況次第 |
| アニメ拡張 | Tier1→Tier2→Tier3 | フレーム増（別途予算化） | 段階別 | KPI改善時 |

総計（静止画ベース想定）: 第1 + 第2 ≒ 157枚。アニメ導入時は Tier1で最大 ~40フレーム/種（4状態）追加想定。
