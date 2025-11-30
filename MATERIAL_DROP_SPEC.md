# Material Drop Specification

本ドキュメントはバトル終了時の素材ドロップ仕様を整理したものです。`battle_screen.dart` 内 `_getEnemyDropMaterial` と勝利処理を参照。

## 基本ルール
- ドロップ判定は勝利時に実施。
- 素材ドロップ確率: 30%
  - 成功時: 下記カテゴリルールに従い1個付与。
  - 追加ボーナス: 1% の確率で同じ素材をもう1個追加（合計2個）。
- アイテム（`itemDrop`）とは別判定。
- ボーナス演出: 追加1%ヒット時にログへ `✨ レア素材ボーナス！ もう1個入手！` を表示。

## カテゴリ判定フロー
上から順番に条件を評価し、最初に一致したカテゴリの素材群からランダム選択。

1. ドラゴン系: 名前に `ドラゴン` または `竜`
   - 候補: `dragon_scale`, `dragon_bone`, `dragon_flame_sac`
2. ゴーレム/タイタン系: 名前に `ゴーレム` または `タイタン`
   - 候補: `iron_ingot`, `ore_rock_fragment`, `rune_stone`
3. 獣系: 名前に `ウルフ` または `ゴブリン`
   - 候補: `beast_fang`, `beast_claw`, `beast_hide`
4. フェアリー/天使系: 名前に `フェアリー` または `エンジェル`
   - 固定: `ore_light_shard`
5. 闇属性/闇系: element == `dark` または 名前に `ダーク` / `ゾンビ` / `デビル`
   - 固定: `ore_dark_shard`
6. エレメンタル/未知系: 名前に `エレメンタル` または `???`
   - 候補: `magic_core_small`, `magic_core_medium`, `magic_core_large`
7. 水属性/スライム系: element == `water` または 名前に `スライム`
   - 固定: `ore_water_pearl`
8. 炎属性: element == `fire`
   - 固定: `ore_fire_crystal`
9. 草属性: element == `grass`
   - 固定: `ore_nature_leafstone`
10. デフォルト（汎用素材）
    - 候補: `wood_plank`, `iron_ingot`, `leather_strip`, `rune_stone`

## 今後の拡張案
- ステージ別レア素材テーブル（StageService連動）
- ボス/シークレットボス専用レア素材（低確率）
- 天候/時間帯による素材種別バイアス（WeatherCycleService連動）
- ペットの所持スキルや装備によるドロップ率補正

## 実装参照ポイント
- ドロップ処理位置: `_victory()` 内の `// 素材ドロップ（30%確率）` ブロック。
- 素材ID→名称解決: `EquipmentService.getMaterialName(id)`
- 付与処理: `EquipmentService.addMaterial(materialId, count)`

## データ一貫性
- 素材ID は `assets/materials/` 配下命名規則と一致させる。
- 追加素材を導入する場合は `EquipmentService` の名称辞書更新を忘れないこと。

## バランス指針
- 30% は“ほぼ毎戦何か出る”手前の頻度。連戦ボーナスにより取得総量が増えるため控えめ。
- 1% 追加ボーナスは視覚的なサプライズ演出用。確率表示は行わず体感でレア感を演出。
- 高ステージ帯では基礎報酬が StageConfig により増加するため、素材確率自体は固定でシンプルに維持。

## 変更履歴
- v1.0 初版作成（StageService倍率導入後整理）
