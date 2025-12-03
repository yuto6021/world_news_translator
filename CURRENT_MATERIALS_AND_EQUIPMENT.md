# 現在実装されている素材と装備一覧

## 素材（全20種）

### 鉱石系（6種）
1. **ore_fire_crystal** - 炎の結晶
2. **ore_water_pearl** - 水の真珠
3. **ore_nature_leafstone** - 自然の葉石
4. **ore_rock_fragment** - 岩石の欠片
5. **ore_light_shard** - 光の欠片
6. **ore_dark_shard** - 闇の欠片

### 獣系（3種）
7. **beast_fang** - 獣の牙
8. **beast_claw** - 鋭い爪
9. **beast_hide** - 獣の毛皮

### ドラゴン系（3種）
10. **dragon_scale** - ドラゴンの鱗
11. **dragon_bone** - ドラゴンの骨
12. **dragon_flame_sac** - 炎袋

### 魔法系（4種）
13. **magic_core_small** - 小型魔力核
14. **magic_core_medium** - 中型魔力核
15. **magic_core_large** - 大型魔力核
16. **enchanted_thread** - 魔法糸

### 共通素材（4種）
17. **wood_plank** - 木板
18. **iron_ingot** - 鉄インゴット
19. **leather_strip** - 革ひも
20. **rune_stone** - ルーン石

---

## クラフト可能装備（17種）

### 剣系（3種）
1. **item_sword_bronze** - ブロンズソード
   - 素材: iron_ingot x2
   - 効果: 攻撃+10%

2. **item_sword_iron** - アイアンソード
   - 素材: iron_ingot x3
   - 効果: 攻撃+15%

3. **item_sword_dragon** - ドラゴンソード
   - 素材: dragon_scale x3
   - 効果: 攻撃+25%

### 盾系（3種）
4. **item_shield_wood** - 木の盾
   - 素材: wood_plank x2
   - 効果: 防御+10%

5. **item_shield_iron** - 鉄の盾
   - 素材: iron_ingot x3
   - 効果: 防御+15%

6. **item_shield_dragon** - ドラゴンシールド
   - 素材: dragon_scale x3
   - 効果: 防御+25%

### 鎧系（3種）
7. **item_armor_leather** - レザーメイル
   - 素材: leather_strip x2
   - 効果: HP+10%

8. **item_armor_chain** - チェインメイル
   - 素材: iron_ingot x4
   - 効果: HP+20%

9. **item_armor_paladin** - パラディンアーマー
   - 素材: ore_light_shard x3
   - 効果: HP+25%, 防御+10%

### 杖系（3種）
10. **item_staff_oak** - オークスタッフ
    - 素材: wood_plank x2
    - 効果: サポート効果+10%

11. **item_staff_mage** - メイジスタッフ
    - 素材: magic_core_medium x2
    - 効果: スキル威力+15%

12. **item_staff_seraph** - セラフロッド
    - 素材: ore_light_shard x3
    - 効果: スキル威力+25%

### アクセサリ系（5種）
13. **item_ring_crit** - クリティカルリング
    - 素材: rune_stone x2
    - 効果: クリティカル率+10%

14. **item_amulet_guard** - ガードアミュレット
    - 素材: rune_stone x2
    - 効果: 防御+10%

15. **item_boots_swift** - スウィフトブーツ
    - 素材: leather_strip x2
    - 効果: 素早さ+15%

---

## ショップ専用装備（6種）

16. **shop_ring_power** - パワーリング
    - 効果: 攻撃+8%
    - 画像: 未作成（shop_ring_power.png）

17. **shop_amulet_shield** - シールドアミュレット
    - 効果: 防御+8%
    - 画像: item_shield_amulet.png

18. **shop_boots_speed** - スピードブーツ
    - 効果: 素早さ+10%
    - 画像: item_speed_boots.png

19. **shop_necklace_hp** - HPネックレス
    - 効果: HP+12%
    - 画像: 未作成（shop_necklace_hp.png）

20. **shop_crown_exp** - クラウン
    - 効果: 経験値+15%
    - 画像: item_exp_crown.png

21. **shop_gloves_crit** - グローブ
    - 効果: クリティカル率+8%
    - 画像: item_critical_gloves.png

---

## 合計
- **素材**: 20種（全て画像完備）
- **装備**: 23種（クラフト17種 + ショップ6種）
  - 画像完備: 21種
  - 画像未作成: 2種（shop_ring_power.png, shop_necklace_hp.png）

---

## 注意点
- 「ゴブリンソード」「スライムジェリー」などの名称は現在の実装には含まれていません
- 上記が現在実装されている全素材・全装備です
- 新規追加したい場合は `MISSING_ASSETS_AND_NEW_EQUIPMENT.md` の新素材・新装備提案を参照してください
