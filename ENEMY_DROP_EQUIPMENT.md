# エネミードロップ素材装備一覧

バトルで敵から入手できる素材を使用してクラフト可能な装備のリストです。

## 📋 装備カテゴリ

### ⚔️ ノーマル敵素材装備（Tier 1-2）

通常の敵から入手できる素材で作成可能な中級装備群

| 装備ID | 日本語名 | 必要素材 | 必要数 | 効果 | 画像ファイル名 |
|--------|----------|----------|--------|------|----------------|
| `item_sword_slime` | スライムソード | slime_jelly | 3 | HP+15%, 防御+5% | item_sword_slime.png |
| `item_sword_goblin` | ゴブリンソード | goblin_sword | 2 | 攻撃+20% | item_sword_goblin.png |
| `item_armor_wolf` | ウルフアーマー | wolf_fang | 3 | 攻撃+10%, 素早さ+10% | item_armor_wolf.png |
| `item_staff_zombie` | ゾンビスタッフ | zombie_bone | 3 | スキル威力+20% | item_staff_zombie.png |
| `item_ring_fairy` | フェアリーリング | fairy_dust | 2 | HP+20%, サポート+15% | item_ring_fairy.png |
| `item_amulet_elemental` | エレメンタルアミュレット | elemental_crystal | 2 | スキル威力+25% | item_amulet_elemental.png |
| `item_shield_golem` | ゴーレムシールド | golem_core | 2 | 防御+30%, HP+10% | item_shield_golem.png |

**合計**: 7装備

### 👑 ボス素材装備（Tier 3）

ボス敵から入手できる貴重な素材で作成可能な高級装備

| 装備ID | 日本語名 | 必要素材 | 必要数 | 効果 | 画像ファイル名 |
|--------|----------|----------|--------|------|----------------|
| `item_hammer_titan` | タイタンハンマー | titan_hammer | 1 | 攻撃+40%, HP+20% | item_hammer_titan.png |
| `item_sword_darklord` | ダークロードソード | dark_sword | 1 | 攻撃+50%, クリティカル率+15% | item_sword_darklord.png |

**合計**: 2装備

### 🌟 裏ボス素材装備（Legendary）

最強の敵から入手できる究極の素材で作成可能な伝説級装備

| 装備ID | 日本語名 | 必要素材 | 必要数 | 効果 | 画像ファイル名 |
|--------|----------|----------|--------|------|----------------|
| `item_armor_ultimate` | 究極の鎧 | ultimate_crystal | 1 | 全ステータス+30% (攻撃/防御/HP/素早さ/スキル威力) | item_armor_ultimate.png |

**合計**: 1装備

---

## 📊 総計

- **全装備数**: 10種類
- **必要画像数**: 10枚（すべて`assets/items/equipment/`配下）

---

## 🎯 素材入手元

### ノーマル敵

| 敵名 | ドロップ素材 | 使用装備 |
|------|-------------|----------|
| スライム | slime_jelly | スライムソード |
| ゴブリン | goblin_sword | ゴブリンソード |
| ウルフ | wolf_fang | ウルフアーマー |
| ゾンビ | zombie_bone | ゾンビスタッフ |
| フェアリー | fairy_dust | フェアリーリング |
| エレメンタル | elemental_crystal | エレメンタルアミュレット |
| ゴーレム | golem_core | ゴーレムシールド |

### ボス敵

| 敵名 | ドロップ素材 | 使用装備 |
|------|-------------|----------|
| タイタン | titan_hammer | タイタンハンマー |
| ダークロード | dark_sword | ダークロードソード |

### 裏ボス

| 敵名 | ドロップ素材 | 使用装備 |
|------|-------------|----------|
| ??? | ultimate_crystal | 究極の鎧 |

---

## 🛠️ クラフトシステム

### 実装場所

- **レシピ定義**: `lib/services/equipment_service.dart` の `recipes` マップ
- **日本語名**: `lib/utils/localization_helper.dart` の `equipmentNames` マップ
- **クラフトUI**: ショップ画面のクラフトタブ

### クラフト仕様

1. 必要素材数を所持していることを確認
2. クラフト実行で素材を消費
3. 装備がインベントリに追加される
4. 装備はペット詳細画面で装備可能

---

## 🎨 画像作成ガイドライン

### ファイル配置

すべて `assets/items/equipment/` に配置

### 推奨仕様

- **形式**: PNG（透過背景推奨）
- **サイズ**: 128x128px 〜 256x256px
- **スタイル**: 既存装備（ドラゴンソード等）と統一感のあるファンタジー風

### Tier別デザイン提案

#### Tier 1-2（ノーマル敵素材）

- **スライムソード**: 青緑色の半透明な刃
- **ゴブリンソード**: 粗野な鉄製の短剣
- **ウルフアーマー**: 毛皮と牙の装飾がある軽鎧
- **ゾンビスタッフ**: 骨でできた杖、頭蓋骨の装飾
- **フェアリーリング**: キラキラした小さな指輪
- **エレメンタルアミュレット**: 4属性の結晶が埋め込まれたペンダント
- **ゴーレムシールド**: 岩のような重厚な大盾

#### Tier 3（ボス素材）

- **タイタンハンマー**: 巨大な戦槌、雷のエフェクト
- **ダークロードソード**: 黒い刀身に赤い紋様、禍々しい雰囲気

#### Legendary（裏ボス素材）

- **究極の鎧**: 虹色に輝くフルプレート、全属性のオーラ

---

## 📝 実装状況

### ✅ 完了

- [x] レシピ定義（`equipment_service.dart`）
- [x] 日本語名追加（`localization_helper.dart`）
- [x] 素材のドロップシステム実装済み（`battle_screen.dart`）
- [x] クラフトUI実装済み（`shop_screen.dart`）

### 🎨 画像作成待ち

- [ ] item_sword_slime.png
- [ ] item_sword_goblin.png
- [ ] item_armor_wolf.png
- [ ] item_staff_zombie.png
- [ ] item_ring_fairy.png
- [ ] item_amulet_elemental.png
- [ ] item_shield_golem.png
- [ ] item_hammer_titan.png
- [ ] item_sword_darklord.png
- [ ] item_armor_ultimate.png

---

## 🔍 バランス設計

### 効果値の考え方

| Tier | 攻撃バフ | 防御バフ | HPバフ | その他 |
|------|----------|----------|--------|--------|
| Tier 1-2 | +10-25% | +5-30% | +10-20% | 速度+10%, スキル威力+20-25% |
| Tier 3 | +40-50% | - | +20% | クリティカル率+15% |
| Legendary | +30% | +30% | +30% | 全ステータス同時強化 |

### 必要素材数

- **ノーマル敵素材**: 2-3個（入手しやすい）
- **ボス素材**: 1個（入手困難だが強力）
- **裏ボス素材**: 1個（最高難度、最強効果）
