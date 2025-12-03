# 新規ペット画像作成ガイド

## 📋 概要

60種以上のペットそれぞれに対して、**8パターン**の画像が必要です。
各ペットは成長段階（stage）に応じたディレクトリに保存します。

---

## 🎨 必要な8パターン

各ペットの種族（species）ごとに、以下の8つの状態画像を作成してください：

### 1. **normal** - 通常状態
- ファイル名: `{stage}_{species}_normal.png`
- 説明: デフォルトの元気な状態
- 用途: メイン表示、ステータス画面
### ステージ方針（重要な更新）

- 全ての種族は「1種族 = 1ステージ」のみとします（Adult か Ultimate のどちらか一方）。
- つまり、同一種族に Adult 版と Ultimate 版の両方を用意しません。重複は排除してください。
- 既存に両ステージが存在する場合は、どちらか片方を“正”とし、もう片方は廃止（画像を追加しない）で問題ありません。
- 画面・育成・戦闘は `PetImageResolver` のフォールバックにより動作します。欠けるステートは `normal` に自動フォールバックします。
- 旧命名（attack/sleep/sick/clean等）と新命名（battle/sleeping/sad/playing/eating等）の差は解決済みです。新規作成時は新命名を推奨します。
- 説明: 嬉しそうな表情、笑顔
### パターン（8種・推奨｜ステージは一つ）

### 3. **sad** - 悲しい状態
- ファイル名: `{stage}_{species}_sad.png`
- 説明: 元気がない、しょんぼり
- 用途: 空腹時、病気時

### 4. **angry** - 怒り状態
- ファイル名: `{stage}_{species}_angry.png`
- 説明: 怒った表情、攻撃的
- 用途: バトル時、しつけ失敗時

### 5. **sleeping** - 睡眠状態
### 保存先と命名規則（1ステージのみ）
- 説明: 寝ている、目を閉じている
```
assets/pets/{stage}/            # {stage} は Adult か Ultimate のどちらか一方だけを採用
  {stage}_{species}_{state}.png # 例: ultimate_saberleomon_battle.png または adult_agumon_idle.png
```
- 説明: 食べている様子
- 用途: 餌やり演出

### 7. **playing** - 遊び中
- ファイル名: `{stage}_{species}_playing.png`
### 既存資産との整合性（移行ガイド）

- 既存で Adult/Ultimate の両方が存在する種族は、プロジェクト側で「正ステージ」を決定してください（例: `ultimate_saberleomon_*` を正）。
- 正ステージのみ今後画像を作成・更新し、もう片方は追加不要です。
- 参照は `PetImageResolver` が自動吸収し、欠けるステートは `normal` にフォールバックします。
- 命名差異はフォールバックで安全に解決されるため、既存育成・戦闘は維持されます。
- 用途: 遊び演出
### 配合限定（5種・再確認｜1ステージのみ）
### 8. **battle** - バトル状態
- 配合限定の5種も「1種族 = 1ステージ」準拠。必要なら Ultimate のみ等、片方に統一してください。
- 例: 全配合限定を Ultimate 統一、一般種は Adult 統一など、運用ポリシーに合わせて選択可能です。
- 用途: バトル画面

### ステージ省略ルール
進化ライン内の各種族に必ず全ステージ画像が必要ではありません。以下指針:
| 種類 | 目的 | 必須ステージ | 省略例 |
|------|------|--------------|--------|
| 基礎育成ライン (例: Leomon ライン) | 成長体験重視 | baby / child / adult / ultimate | baby を省略し child 始まり |
| 中間短縮ライン | 制作工数削減 | child / ultimate | adult を飛ばし直接究極体 |
| 高レア通常進化 | レア感演出 | adult / ultimate | adult 省略不可（前段演出あり） |
| 配合限定 | 特殊獲得 | ultimate のみ | なし |
| 単体スタンドアロン | コレクション埋め | 該当ステージのみ | ultimate のみ |

### 制作チェックリスト（1ステージ運用）

- [ ] 種族ごとに Adult/Ultimate どちらか一方のみ選択（プロジェクトで統一方針を持つ）

### 正ステージ割当一覧（確定）

既存 PNG の有無と進化ライン役割から各種族の採用ステージを確定しました。今後はこの一覧にあるステージのみ画像を作成してください（反対側ステージは作らない）。

| species | stage | 理由 |
|---------|-------|------|
| agumon | adult | 既存 adult 資産揃い / 基礎ラインの拠点 |
| greymon | adult | 中間進化の象徴 / 既存 adult 資産 |
| wargreymon | ultimate | 最終目標 / 既存 ultimate 資産 |
| gabumon | adult | 既存 adult 資産 / 並列基礎ライン |
| garurumon | adult | 中間進化 / 既存 adult 資産保有 |
| metalgarurumon | ultimate | 最終形 / 既存 ultimate 資産 |
| angemon | adult | 光系中間 / 既存 adult 資産 |
| seraphimon | ultimate | 光系最終 / 既存 ultimate 資産 |
| devimon | adult | 闇系中間 / 既存 adult 資産 |
| daemon | ultimate | 闇系最終 / 既存 ultimate 資産 |
| leomon | adult | 獣系基礎 / 既存 adult 資産 |
| saberleomon | ultimate | leomon 上位 / レア演出強化 |
| （配合限定5種） | ultimate | レア度強調のため全て究極体統一 |

補足:
- 既に存在しないが追加予定の新規最終進化種も「レア性を出したいなら ultimate」で定義。
- 逆に“親しみやすさ/育成の入り口”を狙う新規種は adult を選択。
- baby/child など下位ステージは原則省略（必要になったら別ガイドで追加）。

命名例:
```
assets/pets/adult/adult_agumon_battle.png
assets/pets/ultimate/ultimate_wargreymon_sleeping.png
```

配合限定種（例: omegamon, alphamon, gallantmon, susanoomon, apocalymon）は全て ultimate のみで 8 状態。

## 📁 保存先ディレクトリ構造

```
assets/pets/
├── egg/          # たまご（卵段階）
│   └── egg_default_normal.png
│       egg_default_happy.png
│       ...（8パターン）
│
├── baby/         # 幼年期
│   ├── baby_agumon_normal.png
│   ├── baby_agumon_happy.png
│   ├── baby_agumon_sad.png
│   ├── baby_agumon_angry.png
│   ├── baby_agumon_sleeping.png
│   ├── baby_agumon_eating.png
│   ├── baby_agumon_playing.png
│   ├── baby_agumon_battle.png
│   └── （他の種族も同様）
│
├── child/        # 成長期
│   ├── child_greymon_normal.png
│   ├── child_greymon_happy.png
│   └── ...（8パターン × 全種族）
│
├── adult/        # 成熟期
│   ├── adult_metalgreymon_normal.png
│   ├── adult_metalgreymon_happy.png
│   └── ...（8パターン × 全種族）
│
└── ultimate/     # 究極体
    ├── ultimate_wargreymon_normal.png
    ├── ultimate_wargreymon_happy.png
    ├── ultimate_omegamon_normal.png    # 配合限定
    ├── ultimate_alphamon_normal.png    # 配合限定
    └── ...（8パターン × 全種族）
```

---

## 🐾 新規追加ペット一覧（60種以上）

### 成長段階の対応表

| 段階 | Stage名 | 説明 |
|------|---------|------|
| たまご | egg | 孵化前 |
| 幼年期 | baby | 生まれたて |
| 成長期 | child | 子供 |
| 成熟期 | adult | 大人 |
| 究極体 | ultimate | 最終進化 |

---

## 🔥 炎系統（6種）

### 1. Agumon（アグモン）
既存アセット完備（再作成不要）: 旧命名で `adult_agumon_*` のみ存在。幼年期〜成長期は後で追加する場合のみ新規作成。

**拡張特徴**:
- **体色**: 明るいオレンジ色、腹部はクリーム色
- **体格**: 小型恐竜型、直立二足歩行、バランス良い筋肉質
- **顔**: 丸みのある目、小さな角が2本、笑顔がチャーミング
- **爪**: 前足3本、後足3本の鋭い白い爪
- **性格**: 勇敢で好奇心旺盛、仲間思い、少し食いしん坊
- **戦闘スタイル**: 近接格闘＋火炎ブレス、機敏な動き
- **特殊ギミック**: 興奮時に口から小さな火花が漏れる

### 2. Greymon（グレイモン）
既存アセット有り: `adult_greymon_*` 画像あり。child 用は不足しているため必要なら追加作成。

**拡張特徴**:
- **体色**: 濃いオレンジ〜茶色、ストライプ模様が背中に
- **体格**: 大型恐竜型、重量感ある筋肉、agumon の3倍サイズ
- **頭部**: 巨大な角1本（額中央）、鋭い牙、威圧的な目
- **尾**: 太く長い尾で地面を叩くと衝撃波を起こせる
- **装甲**: 肩と背中に硬質プレート状の鱗
- **性格**: 勇敢で誇り高い、仲間を守るためなら命も惜しまない
- **戦闘スタイル**: パワー重視の突進攻撃、口から巨大火炎弾
- **特殊ギミック**: 怒ると角が赤熱化し蒸気を発する

### 3. MetalGreymon（メタルグレイモン）
既存アセット未整備（metalgreymon は未登録）: この種族は新規対象として維持。

**拡張特徴**:
- **体色**: オレンジの生体部分＋シルバー金属パーツの融合
- **体格**: サイボーグ恐竜、左腕が巨大なトライデント砲に改造
- **頭部**: 金属製ヘルメット（一部頭蓋骨を保護）、赤い光学センサー眼
- **胸部**: 金属装甲胸板、中央にエネルギーコア（青発光）
- **背部**: 小型ミサイルポッド×2、翼の名残の金属フレーム
- **性格**: 冷静沈着、戦術的思考、機械と生体の葛藤を内包
- **戦闘スタイル**: 中距離砲撃＋格闘、トライデントからエネルギー砲
- **特殊ギミック**: 砲身が戦闘モード時に展開・多段階チャージ発光

### 4. WarGreymon（ウォーグレイモン）
既存アセット有り: `ultimate_wargreymon_*` 一部揃っているため不足分のみ追加。

**拡張特徴**:
- **体色**: 黄金色の重装甲、下地はオレンジの生体
- **体格**: 人型に近い直立竜人、筋骨隆々、全身が超合金化
- **頭部**: 竜頭＋金色フルフェイスヘルム、V字クレスト、目は青く発光
- **武装**: 両腕にドラモンキラー（巨大爪型武器）、背中に勇気の盾
- **装甲**: 胸部・肩・脚部に分厚いゴールドプレート、関節は可動式
- **性格**: 勇敢で正義感強い、リーダー気質、仲間への信頼厚い
- **戦闘スタイル**: 超速接近戦、ドラモンキラーで連続斬撃＋ガイアフォース
- **特殊ギミック**: 背中の盾が戦闘時に展開し翼状エネルギーフィールド形成

### 5. Tyrannomon（ティラノモン）
（重複コンセプトにつき差し替え）
### 5. Ignisaur（イグニソール）
- **Stage**: child → adult
- **特徴**: 背中に冷えた黒曜岩プレート、亀裂から橙色の溶岩光。幼体はまだプレートが小さい。
- **属性**: 火
- **差別化ポイント**: 既存“恐竜系”よりマグマ蓄熱ギミック強調、シルエットは低重心・尾先に発光核。
- **保存先**:
  - `assets/pets/child/child_ignisaur_[状態].png`（8枚）
  - `assets/pets/adult/adult_ignisaur_[状態].png`（8枚）

### 6. Volcanisaur（ボルカニソール）
- **Stage**: adult → ultimate
- **特徴**: 甲殻が活火山の環状構造になり、戦闘時は噴気孔から紅煙と微細なガラス質粒子を放出。角は凝固した溶岩ガラス。
- **属性**: 火
- **差別化ポイント**: “鎧”ではなく“地殻/プレート”イメージで機械系・既存恐竜系との差別化。発光は断続的パルス。
- **保存先**:
  - `assets/pets/adult/adult_volcanisaur_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_volcanisaur_[状態].png`（8枚）

---

## ❄️ 氷・水系統（6種）

### 7. Gabumon（ガブモン）
既存アセット有り: `adult_gabumon_*` のみ。baby / child は必要なら追加。

**拡張特徴**:
- **体色**: 青と白のツートン、顔は薄紫色の柔らかい肌
- **体格**: 小型獣型、ずんぐり体型、毛皮を纏った姿
- **被り物**: ガルルモンの毛皮（青白ストライプ）を頭からかぶる習性
- **角**: 毛皮の角部分（実際の角ではない）、取り外し可能
- **目**: 大きく優しい瞳、恥ずかしがりで内気な表情
- **性格**: 内気で恥ずかしがり屋、仲間には忠実、実は勇気ある
- **戦闘スタイル**: 遠距離氷ブレス、防御時は毛皮で身を守る
- **特殊ギミック**: 緊張すると毛皮の中に完全に引っ込む、冷気がリーク

### 8. Garurumon（ガルルモン）
既存アセット有り: `adult_garurumon_*`。child 用不足時のみ追加作成。

**拡張特徴**:
- **体色**: 白とライトブルーの縞模様、腹部は純白
- **体格**: 大型四足獣型、狼のようなシルエット、筋肉質で俊敏
- **毛並み**: ふわふわで長い毛、冷気を含み触ると冷たい
- **顔**: 鋭い青い眼光、長い鼻先、獰猛さと知性の共存
- **爪・牙**: 青白く光る氷結属性の武器、凍傷を与える
- **性格**: 誇り高く孤高、信頼した者には忠誠、群れのリーダー気質
- **戦闘スタイル**: 高速機動戦、氷結ブレス＋爪牙での連撃
- **特殊ギミック**: 走行時に足跡が凍結、遠吠えで周囲に氷霧を発生

### 9. WereGarurumon（ワーガルルモン）
- **Stage**: adult → ultimate
- **特徴**: 人狼型、ジーンズ着用
- **属性**: 水

**拡張特徴**:
- **体色**: 白銀の毛皮、青のストライプが入る獣人型
- **体格**: 直立二足歩行、筋骨隆々の戦士体型、身長2.5m級
- **装束**: 破れたデニムジーンズ、ベルト、野性と文明の融合
- **爪**: 長く鋭い氷結爪、刀のような切れ味
- **顔**: 狼の顔、鋭い牙、知性的な青い瞳
- **性格**: クールで寡黙、戦士の誇り、仲間想いの義理堅さ
- **戦闘スタイル**: 格闘術＋氷爪斬撃、月光下でパワーアップ
- **特殊ギミック**: 戦闘時にジーンズが氷結し防御力上昇、月を見ると遠吠え

- **保存先**:
  - `assets/pets/adult/adult_weregarurumon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_weregarurumon_[状態].png`（8枚）

### 10. MetalGarurumon（メタルガルルモン）　もういる
- **Stage**: ultimate
- **特徴**: 金属製の狼、全身サイボーグ
- **属性**: 水

**拡張特徴**:
- **体色**: シルバー＋濃紺のメタリックボディ、関節部は青発光
- **体格**: 四足獣型サイボーグ、流線型で空力最適化された機体
- **装甲**: 超硬質チタン合金、氷結冷却システム内蔵
- **武装**: 両脇に氷結ミサイルポッド、背部にブースター×4
- **顔**: 狼型ヘッド、赤い光学センサー、鋭い金属製牙
- **性格**: 冷徹で計算高い、忠誠心は高いが感情表現は少ない
- **戦闘スタイル**: 超高速機動＋多弾頭ミサイル、氷結光線
- **特殊ギミック**: ブースター噴射で氷結軌道を残す、全身冷却で霜が付着

- **保存先**:
  - `assets/pets/ultimate/ultimate_metalgarurumon_[状態].png`（8枚）

### 11. Seadramon（シードラモン）
- **Stage**: child → adult
- **特徴**: 海蛇型、長い体
- **属性**: 水

**拡張特徴**:
- **体色**: 青緑色の鱗、腹部は銀白色、虹色の光沢
- **体格**: 長大な海蛇型、全長10m以上、しなやかで筋肉質
- **頭部**: 竜のような顔、長い髭×2、鋭い牙、赤い目
- **背鰭**: 青く透明感ある大きな背びれ、泳ぐ時に波打つ
- **尾**: 魚類風の尾びれ、水中推進力抜群
- **性格**: 気性荒く縄張り意識強い、海の支配者気質
- **戦闘スタイル**: 水中高速移動＋体当たり、水圧砲ブレス
- **特殊ギミック**: 水中で鱗が発光、怒ると背びれを逆立てる

- **保存先**:
  - `assets/pets/child/child_seadramon_[状態].png`（8枚）
  - `assets/pets/adult/adult_seadramon_[状態].png`（8枚）

### 12. MegaSeadramon（メガシードラモン）
- **Stage**: adult → ultimate
- **特徴**: 巨大海蛇、金属の鱗
- **属性**: 水

**拡張特徴**:
- **体色**: 深海青＋メタリックシルバー、鱗が金属装甲化
- **体格**: 超大型海蛇、全長20m以上、重厚で威圧的
- **頭部**: 金属ヘルム装着、額に赤いレンズ状の第三眼
- **装甲**: 全身に金属製クロームデジゾイド鱗、電撃を帯びる
- **背鰭**: 刃物状の金属フィン、カッター武器として機能
- **性格**: 冷酷で容赦ない、深海の覇者、強者への執着
- **戦闘スタイル**: 電撃帯び体当たり、超高圧水流ブレス、締め付け
- **特殊ギミック**: 金属鱗が電磁バリア展開、雷雲召喚能力

- **保存先**:
  - `assets/pets/adult/adult_megaseadramon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_megaseadramon_[状態].png`（8枚）

---

## 👼 光・天使系統（6種）

### 13. Patamon（パタモン）
- **Stage**: baby → child
- **特徴**: 小型、大きな耳、オレンジ色
- **属性**: 光

**拡張特徴**:
- **体色**: クリームオレンジ色、腹部は明るいベージュ
- **体格**: 小型哺乳類風、ずんぐり丸い体型、手足は短い
- **耳**: 超大型の羽ばたく耳（翼代わり）、内側はピンク
- **顔**: つぶらで大きな瞳、小さな鼻、無垢な笑顔
- **尾**: 短く丸い尾、感情で振る
- **性格**: 純粋で天真爛漫、楽観的、正義感強い、少しドジ
- **戦闘スタイル**: 空中機動＋聖なる息吹、癒しの光波
- **特殊ギミック**: 危機時に額から神聖な光輪出現、耳で風を起こす

- **保存先**:
  - `assets/pets/baby/baby_patamon_[状態].png`（8枚）
  - `assets/pets/child/child_patamon_[状態].png`（8枚）

### 14. Angemon（エンジェモン）
既存アセット有り: `adult_angemon_*`。child 用は追加対象。

**拡張特徴**:
- **体色**: 純白の衣装、金色の装飾、肌は健康的なベージュ
- **体格**: 人型天使、均整の取れた筋肉質、身長2m
- **衣装**: 白いローブと金縁のベルト、腰布、足に金ブーツ
- **翼**: 背中に6枚の純白の羽、神聖な光を放つ
- **装備**: 右手に天使の杖（先端に十字）、額に金のサークレット
- **性格**: 正義感強く厳格、優しさと強さの両立、献身的
- **戦闘スタイル**: 杖による聖なる光線、浄化の拳、飛行戦闘
- **特殊ギミック**: 祈ると周囲に癒しのオーラ、悪を前に翼が輝く

### 15. Angewomon（エンジェウーモン）
- **Stage**: adult → ultimate
- **特徴**: 女性型天使、8枚の翼
- **属性**: 光

**拡張特徴**:
- **体色**: 白銀の装束、プラチナブロンドの長髪、透明感ある肌
- **体格**: 女性型天使、優美でスレンダー、しなやかな筋肉
- **衣装**: 白いボディスーツ風装束、金の腰飾り、露出控えめ
- **翼**: 8枚の輝く白翼（上4・下4）、戦闘時に展開
- **装備**: 右手に聖弓、額に金の天使冠、手首に金リング
- **性格**: 慈愛深く優しい、強い意志と勇気、母性的
- **戦闘スタイル**: 聖なる光の矢、浄化の波動、空中支援
- **特殊ギミック**: 翼から光の羽毛が舞う、祈りで天上の光柱

- **保存先**:
  - `assets/pets/adult/adult_angewomon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_angewomon_[状態].png`（8枚）

### 16. Seraphimon（セラフィモン）
既存アセット有り: `ultimate_seraphimon_*` 不足分のみ追加。

**拡張特徴**:
- **体色**: 純白＋金色の重装甲、神々しい輝き
- **体格**: 人型天使戦士、威厳ある堂々たる体格、3m級
- **衣装**: 白金の重装フルアーマー、マントは光の布
- **翼**: 10枚の巨大な光翼、戦闘時に光の軌跡を残す
- **装備**: 両手に聖剣エクスカリバー、額に七つの宝石冠
- **性格**: 高潔で威厳ある、絶対正義、慈悲と裁きの両面
- **戦闘スタイル**: 聖剣斬撃＋天罰の雷、浄化の光柱、飛行突撃
- **特殊ギミック**: 剣を天に掲げると光の柱が降臨、オーラで浮遊

### 17. Gatomon（ゲートモン）
- **Stage**: child → adult
- **特徴**: 白猫型、聖なる指輪
- **属性**: 光
- **保存先**:
  - `assets/pets/child/child_gatomon_[状態].png`（8枚）
  - `assets/pets/adult/adult_gatomon_[状態].png`（8枚）

### 18. MagnaAngemon（マグナエンジェモン）
- **Stage**: adult → ultimate
- **特徴**: 重装天使、兜と鎧
- **属性**: 光
- **保存先**:
  - `assets/pets/adult/adult_magnaangemon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_magnaangemon_[状態].png`（8枚）

---

## 🐛 昆虫系統（5種）

### 19. Tentomon（テントモン）
- **Stage**: baby → child
- **特徴**: テントウムシ型、赤と黒
- **属性**: 雷

**拡張特徴**:
- **体色**: 鮮やかな赤い羽根、黒いドット模様、胴体は黒
- **体格**: 小型昆虫型、丸みを帯びた可愛い体型
- **羽根**: テントウムシ風の2枚羽、飛行時に開閉
- **顔**: 大きな複眼（青緑色）、小さな触角×2
- **手足**: 6本の短い足、前足2本は器用
- **性格**: 好奇心旺盛で明るい、知識欲強い、少しおっちょこちょい
- **戦闘スタイル**: 電撃攻撃、空中機動、触角から雷撃
- **特殊ギミック**: 羽根が静電気でパチパチ発光、充電ポーズ

- **保存先**:
  - `assets/pets/baby/baby_tentomon_[状態].png`（8枚）
  - `assets/pets/child/child_tentomon_[状態].png`（8枚）

### 20. Kabuterimon（カブテリモン）
- **Stage**: child → adult
- **特徴**: カブトムシ型、大きな角
- **属性**: 雷
- **保存先**:
  - `assets/pets/child/child_kabuterimon_[状態].png`（8枚）
  - `assets/pets/adult/adult_kabuterimon_[状態].png`（8枚）

### 21. AtlurKabuterimon（アトラーカブテリモン）
- **Stage**: adult → ultimate
- **特徴**: 巨大カブトムシ、金属の甲殻
- **属性**: 雷
- **保存先**:
  - `assets/pets/adult/adult_atlurkabuterimon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_atlurkabuterimon_[状態].png`（8枚）

### 22. HerculesKabuterimon（ヘラクレスカブテリモン）　敵として
- **Stage**: ultimate
- **特徴**: ヘラクレスオオカブト型、黄金の角
- **属性**: 雷
- **保存先**:
  - `assets/pets/ultimate/ultimate_herculeskabuterimon_[状態].png`（8枚）

### 23. Kuwagamon（クワガーモン）
- **Stage**: child → adult
- **特徴**: クワガタムシ型、巨大な顎
- **属性**: 雷
- **保存先**:
  - `assets/pets/child/child_kuwagamon_[状態].png`（8枚）
  - `assets/pets/adult/adult_kuwagamon_[状態].png`（8枚）

---

## 😈 闇・悪魔系統（6種）

### 24. Devimon（デビモン）
既存アセット有り: `adult_devimon_*`。child 用は追加対象。

**拡張特徴**:
- **体色**: 深い黒＋紫のグラデーション、黒い肌
- **体格**: 痩せ型悪魔人型、長い手足、不気味な美しさ
- **顔**: 黒い仮面状の顔、赤い眼光、邪悪な笑み
- **翼**: 破れた黒いコウモリ翼、静脈模様が赤く光る
- **爪**: 長く鋭い黒爪、毒を帯びる
- **性格**: 狡猾で残酷、誘惑と謀略を好む、闇の化身
- **戦闘スタイル**: 闇の波動、爪撃＋怪力光線、心を侵食
- **特殊ギミック**: 影から出現・消失、怖れを食べるオーラ

### 25. Myotismon（ヴァンデモン）
- **Stage**: adult → ultimate
- **特徴**: 吸血鬼型、マント着用
- **属性**: 闇
- **保存先**:
  - `assets/pets/adult/adult_myotismon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_myotismon_[状態].png`（8枚）

### 26. VenomMyotismon（ヴェノムヴァンデモン）
- **Stage**: ultimate
- **特徴**: 巨大な怪物型、獣化した吸血鬼
- **属性**: 闇
- **保存先**:
  - `assets/pets/ultimate/ultimate_venommyotismon_[状態].png`（8枚）

### 27. Piedmon（ピエモン）　敵に変更
- **Stage**: adult → ultimate
- **特徴**: ピエロ型、4本の剣
- **属性**: 闇
- **保存先**:
  - `assets/pets/adult/adult_piedmon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_piedmon_[状態].png`（8枚）

### 28. Deathmon（デスモン）　作らない
- **Stage**: adult → ultimate
- **特徴**: 死神型、鎌を持つ
- **属性**: 闇
- **保存先**:
  - `assets/pets/adult/adult_deathmon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_deathmon_[状態].png`（8枚）

### 29. Phantomon（ファントモン）敵として
- **Stage**: adult
- **特徴**: 幽霊型、鎖
- **属性**: 闇
- **保存先**:
  - `assets/pets/adult/adult_phantomon_[状態].png`（8枚）

---

## 🦁 獣系統（6種）

### 30. Leomon（レオモン）
既存アセット有り: `adult_leomon_*`。child 用不足時のみ追加作成。

**拡張特徴**:
- **体色**: 黄金色の鬣毛、茶色のたてがみ、白い腹部
- **体格**: 獅子獣人型、直立二足歩行、超筋骨隆々の戦士体型
- **頭部**: 野性的な獅子の顔、立派なたてがみ、鋭い眼光
- **装束**: 革製ベルトとパンツ、戦士の証・黒い手袋
- **武器**: 腰に伽刀「獣王剣」、柄に獅子の紋章
- **性格**: 高潔で騎士道精神、勇敢で誠実、強者の誇り
- **戦闘スタイル**: 剣術＋爪撃、野性と技術の融合、獣王拳
- **特殊ギミック**: 戦闘時にたてがみが逆立ち炎を帯びる、哮えで敵を威圧

### 31. SaberLeomon（サーベルレオモン）
進化ライン例: Leomon (adult) → SaberLeomon (ultimate)
本ガイド簡略化方針により「進化前ステージが既存種（Leomon）で賔える」ため SaberLeomon では **ultimate のみ作成でOK**。
必要ステージ: `ultimate` の 8状態。

**拡張特徴**:
- **体色**: 白銀の毛皮、黒い縞模様、プラチナのたてがみ
- **体格**: 巨大獅子獣人型、leomon の1.5倍サイズ、重厚筋肉
- **牙**: 巨大な剣歯虎の牙、2本が口から突き出る
- **装束**: 金属装甲ベルト、黒皮パンツ、肩にプレートアーマー
- **武器**: 双剣「双牙剣」、刃に雷光を帯びる
- **性格**: 高潔で威厳ある、絶対的な強さと優しさ、王の風格
- **戦闘スタイル**: 双剣斬撃＋雷爪、獲物を狩る速度と力
- **特殊ギミック**: 雷光を纏い哮える、牙が電撃導体として光る

**保存先**:
  - `assets/pets/ultimate/ultimate_saberleomon_[状態].png`（8枚）
（adult_saberleomon_* は不要）

### 32. BanchoLeomon（バンチョーレオモン）敵
- **Stage**: ultimate
- **特徴**: 番長スタイル、学ラン着用
- **属性**: 無
- **保存先**:
  - `assets/pets/ultimate/ultimate_bancholeomon_[状態].png`（8枚）

### 33. Gaomon（ガオモン）敵
- **Stage**: baby → child
- **特徴**: ボクシンググローブを着けた犬
- **属性**: 無
- **保存先**:
  - `assets/pets/baby/baby_gaomon_[状態].png`（8枚）
  - `assets/pets/child/child_gaomon_[状態].png`（8枚）

### 34. MachGaogamon（マッハガオガモン）敵
- **Stage**: child → adult
- **特徴**: 高速犬型、流線型のボディ
- **属性**: 無
- **保存先**:
  - `assets/pets/child/child_machgaogamon_[状態].png`（8枚）
  - `assets/pets/adult/adult_machgaogamon_[状態].png`（8枚）

### 35. MirageGaogamon（ミラージュガオガモン）　敵
- **Stage**: adult → ultimate
- **特徴**: 幻獣型、翼を持つ犬戦士
- **属性**: 無
- **保存先**:
  - `assets/pets/adult/adult_miragegaogamon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_miragegaogamon_[状態].png`（8枚）

---

## 🐲 ドラゴン系統（6種）

### 36. Veemon（ブイモン）
- **Stage**: baby → child
- **特徴**: 小型ドラゴン、青い体
- **属性**: ドラゴン

**拡張特徴**:
- **体色**: 鮮やかなブルー、白い腹部、赤い爪
- **体格**: 小型竜人型、ずんぐり可愛い体型、元気いっぱい
- **頭部**: V字型の白いマークが額に、丸い目、小さな角
- **爪**: 赤い鋭い爪、戦闘時に光る
- **尾**: 太く短い尾、感情で大きく振る
- **性格**: 元気で明るい、勇敢で無邪気、仲間思い
- **戦闘スタイル**: 頭突き＋爪撃、小型ドラゴンブレス
- **特殊ギミック**: 興奮するとVマークが発光、飛び跳ねる

- **保存先**:
  - `assets/pets/baby/baby_veemon_[状態].png`（8枚）
  - `assets/pets/child/child_veemon_[状態].png`（8枚）

### 37. ExVeemon（エクスブイモン）
- **Stage**: child → adult
- **特徴**: 人型ドラゴン、筋肉質
- **属性**: ドラゴン
- **保存先**:
  - `assets/pets/child/child_exveemon_[状態].png`（8枚）
  - `assets/pets/adult/adult_exveemon_[状態].png`（8枚）

### 38. Paildramon（パイルドラモン）
- **Stage**: adult → ultimate
- **特徴**: 半機械ドラゴン、砲塔装備
- **属性**: ドラゴン
- **保存先**:
  - `assets/pets/adult/adult_paildramon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_paildramon_[状態].png`（8枚）

### 39. Imperialdramon（インペリアルドラモン）なし
- **Stage**: ultimate
- **特徴**: 巨大ドラゴン騎士、槍を持つ
- **属性**: ドラゴン
- **保存先**:
  - `assets/pets/ultimate/ultimate_imperialdramon_[状態].png`（8枚）

### 40. Dorumon（ドルモン）敵
- **Stage**: baby → child
- **特徴**: 紫色の小型獣竜
- **属性**: ドラゴン
- **保存先**:
  - `assets/pets/baby/baby_dorumon_[状態].png`（8枚）
  - `assets/pets/child/child_dorumon_[状態].png`（8枚）

### 41. Dorugoramon（ドルゴラモン）敵
- **Stage**: child → adult
- **特徴**: 翼竜型、金属の翼
- **属性**: ドラゴン
- **保存先**:
  - `assets/pets/child/child_dorugoramon_[状態].png`（8枚）
  - `assets/pets/adult/adult_dorugoramon_[状態].png`（8枚）

---

## 🤖 機械系統（5種）

### 42. Hagurumon（ハグルモン）
- **Stage**: baby → child
- **特徴**: 歯車型、回転する
- **属性**: 機械

**拡張特徴**:
- **体色**: シルバー・ガンメタル、一部青銅色の酸化色
- **体格**: 円盤状歯車、2枚の歯車が噶合した形
- **顔**: 中央の歯車に単眼（赤いレンズ）、小さな口
- **機構**: 常時回転、カチカチ音を立てる
- **移動**: 浮遊しながら回転、重力無視
- **性格**: 単純で機械的、計算好き、秩序を愛する
- **戦闘スタイル**: 回転攻撃、歯車射出、電撃パルス
- **特殊ギミック**: 高速回転でドリル化、他の歯車と噶合でパワーアップ

- **保存先**:
  - `assets/pets/baby/baby_hagurumon_[状態].png`（8枚）
  - `assets/pets/child/child_hagurumon_[状態].png`（8枚）

### 43. Guardromon（ガードロモン）
- **Stage**: child → adult
- **特徴**: ロボット型、防御重視
- **属性**: 機械
- **保存先**:
  - `assets/pets/child/child_guardromon_[状態].png`（8枚）
  - `assets/pets/adult/adult_guardromon_[状態].png`（8枚）

### 44. Andromon（アンドロモン）
- **Stage**: adult → ultimate
- **特徴**: アンドロイド型、ミサイル装備
- **属性**: 機械
- **保存先**:
  - `assets/pets/adult/adult_andromon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_andromon_[状態].png`（8枚）

### 45. Machinedramon（ムゲンドラモン）いらない
- **Stage**: ultimate
- **特徴**: 機械ドラゴン、巨大砲塔
- **属性**: 機械
- **保存先**:
  - `assets/pets/ultimate/ultimate_machinedramon_[状態].png`（8枚）

### 46. Cyberdramon（サイバードラモン）いらない
- **Stage**: adult → ultimate
- **特徴**: サイボーグドラゴン、ブレード装備
- **属性**: 機械
- **保存先**:
  - `assets/pets/adult/adult_cyberdramon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_cyberdramon_[状態].png`（8枚）

---

## 🌿 植物系統（4種）以下いらない

### 47. Palmon（パルモン）
- **Stage**: baby → child
- **特徴**: 植物型、花の頭
- **属性**: 森

**拡張特徴**:
- **体色**: 鮮やかな緑色の体、ピンクの花びらが頭
- **体格**: 植物・妖精型、小柄で可愛い体型
- **頭部**: 大きなピンクの花（チューリップ風）、緑の葉が縁取り
- **顔**: 花の中心に可愛い顔、大きな瞳
- **手**: 蔓のような緑の触手・紐、柔軟で器用
- **性格**: 優しく穏やか、自然を愛する、少し恥ずかしがり
- **戦闘スタイル**: 蔓で縛る、毒粉攻撃、回復魔法
- **特殊ギミック**: 太陽を浴びると花が開く、生命エネルギー放出

- **保存先**:
  - `assets/pets/baby/baby_palmon_[状態].png`（8枚）
  - `assets/pets/child/child_palmon_[状態].png`（8枚）

### 48. Togemon（トゲモン）
- **Stage**: child → adult
- **特徴**: サボテン型、ボクシンググローブ
- **属性**: 森
- **保存先**:
  - `assets/pets/child/child_togemon_[状態].png`（8枚）
  - `assets/pets/adult/adult_togemon_[状態].png`（8枚）

### 49. Lillymon（リリモン）
- **Stage**: adult → ultimate
- **特徴**: 妖精型、花のドレス
- **属性**: 森
- **保存先**:
  - `assets/pets/adult/adult_lillymon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_lillymon_[状態].png`（8枚）

### 50. Rosemon（ロゼモン）
- **Stage**: ultimate
- **特徴**: 薔薇の女王、鞭を持つ
- **属性**: 森
- **保存先**:
  - `assets/pets/ultimate/ultimate_rosemon_[状態].png`（8枚）

---

## 🧙 妖精・魔法系統（4種）

### 51. Wizardmon（ウィザーモン）
- **Stage**: child → adult
- **特徴**: 魔法使い型、杖と帽子
- **属性**: 魔法

**拡張特徴**:
- **体色**: 紫と黒のローブ、銀の装飾、顔は白い仮面
- **体格**: 人型魔術師、細身で神秘的な体型
- **衣装**: 長いローブ（紫基調）、黒いマント、銀のベルト
- **帽子**: 尖った魔法使い帽（紫）、星のマーク
- **杖**: 長い魔法の杖、先端に水晶球（青緑発光）
- **性格**: 知的で神秘的、忠実で優しい、犠牲的精神
- **戦闘スタイル**: 魔法攻撃（雷・炎・氷）、幻術、支援魔法
- **特殊ギミック**: 杖を振ると魔法陣出現、ローブが風になびく

- **保存先**:
  - `assets/pets/child/child_wizardmon_[状態].png`（8枚）
  - `assets/pets/adult/adult_wizardmon_[状態].png`（8枚）

### 52. Mysticmon（ミスティモン）
- **Stage**: adult → ultimate
- **特徴**: 魔術師型、古代魔法使用
- **属性**: 魔法
- **保存先**:
  - `assets/pets/adult/adult_mysticmon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_mysticmon_[状態].png`（8枚）

### 53. Sorcerymon（ソーサリモン）
- **Stage**: adult
- **特徴**: 魔導士型、複数の杖
- **属性**: 魔法
- **保存先**:
  - `assets/pets/adult/adult_sorcerymon_[状態].png`（8枚）

### 54. Beelzemon（ベルゼモン）
- **Stage**: adult → ultimate
- **特徴**: 魔王型、バイクと銃
- **属性**: 闇・魔法
- **保存先**:
  - `assets/pets/adult/adult_beelzemon_[状態].png`（8枚）
  - `assets/pets/ultimate/ultimate_beelzemon_[状態].png`（8枚）

---

## ⭐ 配合限定ペット（10種）- 全て究極体
配合限定は 5 種に集約。全て **ultimate のみ** 作成。

| 番号 | 種族 | 配合 | 属性 | コンセプト |
|------|------|------|------|------------|
| 55 | Omegamon | WarGreymon × MetalGarurumon | 火・水 | 絆統合の双腕騎士 |
| 56 | Alphamon | Omegamon × (任意究極体) | 光・無 | 秩序と王格 |
| 57 | Susanoomon | Seraphimon × 任意にするBanchoLeomon | 光・武 | 神話融合戦士 |
| 58 | Gallantmon | WarGreymon × Seraphimon | 火・光 | 炎と聖の槍盾騎士 |
| 59 | Apocalymon | Omegamon × Alphamon | 全属性 | 終焉・最終目標 |

### 共通ファイル命名
`assets/pets/ultimate/ultimate_<species>_<state>.png`

### 各 8 状態 詳細ポーズ指示

| 状態 | Omegamon | Alphamon | Susanoomon | Gallantmon | Apocalymon |
|------|----------|----------|------------|------------|------------|
| normal | 剣と砲を下げ正面半身 | 聖剣を前に垂直保持 | 10小剣を背面収納 | 槍縦持ち盾横 | 上半球静止下半触手静止 |
| happy | 剣を軽く振り砲口発光 | マントを少し広げ光粒 | 小剣が輪を描く | 盾に光反射 | 触手で光球を弄る |
| sad | 片腕下げ青側暗め | マント閉じ気味頭少し下 | 剣の光量低下 | 槍先少し下げる | 顔部光量低下影強調 |
| angry | 剣赤炎 砲青霜同時閃光 | 聖剣発光・目ハイライト | 雷紋＋炎紋浮遊 | 盾展開 槍突き前傾 | 触手広げ中心暗黒渦 |
| sleeping | 剣砲を交差し休止 | 剣を地面に立て祈る姿 | 小剣収納正座 | 槍と盾を並べ半眼閉じ | 下半触手巻き上半目閉じ |
| eating | コア状エネルギー吸収 | 光の欠片を掌へ集める | 勾玉/神酒風エネルギー摂取 | 聖なる果実を片手 | 触手で小惑星捕食 |
| playing | 剣回転と砲虹粒子 | ミニ紋章を指で回す | 小剣が螺旋回転 | 槍回し足運び軽快 | 触手で球体ジャグリング |
| battle | 前傾クロス腕:剣前砲後 | 魔法陣足元→剣へ収束 | 10剣扇状展開全身発光 | 槍突き直前＋盾光壁 | 闇エネルギー拡散+触手全展開 |

### カラーパレット推奨
| 種族 | メイン | サブ | エフェクト |
|-------|-------|------|-----------|
| Omegamon | 白 | 青/橙 | 炎(橙)＋冷気(青) |
| Alphamon | 黒 | 金/緑 | 聖紋光(淡金) |
| Susanoomon | 紺 | 金/朱 | 雷(黄)＋風(薄白) |
| Gallantmon | 赤 | 白/金 | 聖光(白)＋炎(橙) |
| Apocalymon | 暗紫 | 灰/緑 | 闇渦(黒)＋多色断片 |

### 制作最小セット確認チェック
1. 8状態揃う
2. 背景透過
3. 種族ごとに彩度/光源一貫
4. battle は他状態よりコントラスト 15–20% 増
5. sad/sleeping は彩度 10% 減・光量控えめ

---

## 🎨 画像仕様

### サイズ
- **推奨サイズ**: 256×256 px または 512×512 px
- **フォーマット**: PNG（透過背景推奨）
- **解像度**: 高解像度（Retina対応）

### デザインガイドライン
- **背景**: 透明または白背景
- **スタイル**: アニメ調、デジモン風
- **表情**: 8つの状態それぞれで明確に区別できること
- **サイズ感**: キャラクターが画像の80%程度を占める

### 表情・ポーズの違い

| 状態 | 表情 | ポーズ | 色調 |
|------|------|--------|------|
| normal | 通常の顔 | 立っている | 標準 |
| happy | 笑顔、目がキラキラ | ジャンプ、手を上げる | 明るめ |
| sad | 涙目、下を向く | しょんぼり座る | 暗め |
| angry | 怒り顔、眉吊り上げ | 威嚇ポーズ | 赤み強め |
| sleeping | 目を閉じる、Zzz | 横になる、座って寝る | 柔らかい色 |
| eating | 口を開ける | 食べ物を持つ | 温かみのある色 |
| playing | 楽しそうな顔 | 走る、跳ねる | 鮮やか |
| battle | 真剣な顔、鋭い目 | 攻撃ポーズ | コントラスト強め |

---

## 📋 チェックリスト

各ペットごとに以下を確認してください：

- [ ] 8パターン全て作成済み
- [ ] ファイル名が正しい（`{stage}_{species}_{状態}.png`）
- [ ] 保存先ディレクトリが正しい
- [ ] 画像サイズが統一されている
- [ ] 透過背景または白背景
- [ ] 各状態の違いが明確

---

## 🔄 作業の流れ

1. **種族選択**: 上記リストから作成するペットを選ぶ
2. **8パターン作成**: normal → happy → sad → angry → sleeping → eating → playing → battle
3. **命名**: `{stage}_{species}_{状態}.png`形式で保存
4. **配置**: 対応するstageフォルダに配置
5. **確認**: ゲーム内で表示確認

---

## ⚠️ 重要な注意事項

1. **species名は小文字**: ファイル名の`{species}`部分は必ず小文字（例: `wargreymon`）
2. **状態名は固定**: `normal`, `happy`, `sad`, `angry`, `sleeping`, `eating`, `playing`, `battle`の8種類のみ
3. **stage名も固定**: `egg`, `baby`, `child`, `adult`, `ultimate`のみ
4. **配合限定ペットは全てultimate**: 配合限定ペットは全て究極体なので`ultimate`フォルダのみ

---

## 🎮 システム連携について

### 戦闘システム
全てのペット（新規60種含む）は自動的に戦闘可能です：
- バトル画面で`battle`状態の画像を表示
- 各ペットの種族に応じてステータス自動設定
- スキル継承システムで多様な戦術が可能

### 育成システム
全てのペットで以下が可能：
- 食事: `eating`画像表示
- 遊び: `playing`画像表示
- 睡眠: `sleeping`画像表示
- トレーニング: `happy`や`angry`で反応
- 進化: stage昇格時に自動的に画像切り替え

### 表情変化
ペットの状態に応じて自動的に画像が切り替わります：
- 空腹 → `sad`
- 満腹 → `happy`
- バトル中 → `battle`
- 夜間 → `sleeping`
- 餌やり中 → `eating`

---

## 📊 優先度

作業の優先順位：

### 最優先（Tier 1）
配合限定ペット（究極体のみ、各8枚）:
- Omegamon, Alphamon, Imperialdramon PM, Gallantmon, Susanoomon

### 高優先（Tier 2）
主力進化ライン（合計80枚程度）:
- Agumon系（baby→child→adult→ultimate）
- Gabumon系（baby→child→adult→ultimate）
- Patamon系（baby→child→adult→ultimate）

### 中優先（Tier 3）
サブ進化ライン（各系統40枚程度）:
- 昆虫系、獣系、ドラゴン系

### 低優先（Tier 4）
バリエーション種族:
- 機械系、植物系、妖精系

---

## 🧪 オリジナル拡張種族案（追加特徴）

既存IPライク名称との差別化と独自世界観強化のため、以下のオリジナル種族を追加候補として定義。全て「1種族 = 1ステージ」方針を踏襲。

| species | stage | attribute | concept | visual cues |
|---------|-------|-----------|---------|-------------|
| ignisaur | child→adult | 火 | 冷えた黒曜岩と内部マグマ | 背面プレート発光ライン |
| volcanisaur | adult→ultimate | 火 | 生きた噴火環状甲殻 | 肩リング噴気 + パルス発光 |
| aquaphin | adult | 水 | イルカ＋細身竜ハイブリッド | 半透明ヒレ＋水滴粒子 |
| frostlance | ultimate | 水/氷 | 氷結蛇騎士 | 結晶ランス＋透過尾ひれ |
| lumifox | adult | 光 | 夜光性聖獣狐 | 尾先と耳が柔光グラデ |
| shadeimp | adult | 闇 | トリックスター影精 | 半陰影ボディ＋浮遊眼紋 |
| gearwisp | adult | 機械/魔法 | 魔力駆動浮遊歯車精 | 回転ギア輪＋魔法紋発光 |
| thornmaiden | ultimate | 植物 | 荊棘王妃/守護者 | 薔薇冠＋蔓マント |
| sparktorrent | adult→ultimate | 雷 | 嵐を蓄える甲虫 | 背部コンデンサ発光脈絡 |
| runesage | ultimate | 魔法 | 古代浮遊石碑ゴーレム | ルーン循環光路 |

### 画像制作追加ガイド（オリジナル種族）
- カラーパレットは最大 6 色 + エフェクト 2 色まで（視認性確保）
- 差別化属性: 火=内発光オレンジ、光=外縁ソフト白、闇=内側コア暗紫、雷=線状黄シアン混合、氷=低彩度シアン＋白、植物=深緑＋アクセント花色。
- battle 状態は能力演出（例: volcanisaur 噴煙、gearwisp 歯車高速回転）必須。
- playing 状態は“形状ギミック”を強調（ignisaur 尾核スピン、lumifox 尾光粒子追いかけなど）。

### 命名例（オリジナル）
```
assets/pets/adult/adult_lumifox_happy.png
assets/pets/ultimate/ultimate_thornmaiden_battle.png
assets/pets/adult/adult_gearwisp_playing.png
```

### 優先度再補足（追加種族込み）
- まず既存リストの不足ステート補完 → Tier 1/2 完了後にオリジナル着手。
- オリジナルはビジュアル多様性とブランディング強化目的で段階投入。

---

---

## 💾 最終確認

全ての画像作成後、以下のコマンドで確認してください：

```powershell
# 画像ファイル数確認
Get-ChildItem -Path "assets/pets" -Filter "*.png" -Recurse | Measure-Object

# 期待値: 約480枚（60種 × 8パターン）
```

---

**これで新規ペット用の画像作成準備が完了です！**  
ご質問があればお気軽にどうぞ！ 🎨✨
