# 育成ゲーム（ペット）システム強化設計

## 概要
ペット育成をニュース閲覧習慣とリンクさせ、長期的なやり込み要素を実現。ジャンル多様性・感情的愛着・コレクション欲求を喚起し、継続的なエンゲージメントを向上。

---

## 1. デザイントークン導入（`design_tokens.dart`）

### 目的
色・余白・フォントサイズ・角丸・シャドウなど、デザインシステムを一元管理。テーマ拡張と一貫したUI実装を効率化。

### 構造
```dart
// lib/design_tokens.dart
class DesignTokens {
  // Spacing (8pt grid)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Elevation (Shadow)
  static const double elevation1 = 2.0;  // Cards
  static const double elevation2 = 4.0;  // Buttons
  static const double elevation3 = 8.0;  // Modals
  static const double elevation4 = 16.0; // Overlay

  // Font Sizes
  static const double fontCaption = 12.0;
  static const double fontBody = 14.0;
  static const double fontTitle = 18.0;
  static const double fontHeading = 24.0;
  static const double fontDisplay = 32.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // Theme-aware colors (resolved via BuildContext or ThemeData)
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
}
```

### 利用例
```dart
Container(
  margin: EdgeInsets.all(DesignTokens.space16),
  padding: EdgeInsets.symmetric(
    horizontal: DesignTokens.space24,
    vertical: DesignTokens.space12,
  ),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    color: DesignTokens.surface(context),
  ),
  child: Text(
    'Hello',
    style: TextStyle(fontSize: DesignTokens.fontBody),
  ),
)
```

---

## 3. 個人化/ゲーミフィケーション強化

### デイリークエストシステム
**目的**: 短期ゴール設定でログイン動機強化。

**仕様**:
- 毎日0時(UTC)にリセット
- 3種類のミッション（記事3本読む、コメント1件、ゲーム1プレイ）
- 各達成で +50pt、全達成ボーナス +50pt（計200pt/日）
- UI: ホーム画面上部に横スクロールカード（進捗バー付き）

**実装パターン**:
```dart
// lib/services/daily_quest_service.dart
class DailyQuest {
  final String id;
  final String title;
  final String icon;
  final int target;
  int progress = 0;
  int reward = 50;
}

class DailyQuestService {
  static Future<List<DailyQuest>> getQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString('daily_quest_reset');
    final now = DateTime.now().toUtc();
    
    if (lastReset == null || !_isSameDay(DateTime.parse(lastReset), now)) {
      // Reset & generate new quests
      await _resetQuests();
    }
    
    return _loadQuests();
  }
  
  static Future<void> incrementProgress(String questId) async {
    // SharedPreferences key: 'daily_quest_{questId}_progress'
    // Check completion → award points → notify UI
  }
}
```

### シーズン限定バッジ
**目的**: 希少性と期間限定性でコレクション欲求刺激。

**仕組み**:
- 毎月1日に新バッジ追加（季節イベント: 桜🌸、夏祭り🎐、ハロウィン🎃、クリスマス🎄など）
- 解除条件: その月内に特定実績達成 or 記事10本読む
- 月末に未取得バッジはロック（次年度再登場）
- UI: 統計画面に「今月の限定バッジ」セクション（カウントダウン表示）

### コレクションセット
**目的**: 長期目標と達成感の複層化。

**例**:
- **世界の国旗セット**: 5大陸全ての記事を各10本読む（20個のバッジ）→ 完了で「グローバル探検家🌍」レジェンダリー実績
- **ゲームマスターセット**: 全ゲームでExcellent以上 → 「コンプリートゲーマー🎮」
- **時間帯読書セット**: 朝/昼/夜に各30日ログイン → 「24時間ニュースジャンキー☕🍔🌙」

---

## 4. ペット育成ゲームの大幅強化

### 現状の課題
- ペット進化は記事数のみで単調
- ジャンル多様性が視覚化されない
- 感情的愛着が薄い

### 強化内容

#### A. ジャンル別ステータス（多次元成長）
**仕様**:
- ペットに5つのステータス: ビジネス💼、テクノロジー🖥️、エンターテインメント🎬、スポーツ⚽、国際政治🌏
- 記事ジャンルに応じてステータスUP（例: ビジネス記事 → 💼+1）
- 各ステータス MAX 100、レベル20ごとにビジュアル変化（バッジ、オーラなど）
- バランス型（全均等）vs 特化型（1つ極振り）の育成戦略

**UI**: 
- レーダーチャート（pentagon）でステータス可視化
- タップで詳細（各ジャンル読破数、推移グラフ）

#### B. 親密度システム
**目的**: 毎日の触れ合いで愛着形成。

**仕組み**:
- 親密度 0～100、毎日のアクション（記事読む、ゲームプレイ、餌やり）で +1～5
- 親密度レベル: 知人（0-20）→ 友達（21-40）→ 親友（41-60）→ 相棒（61-80）→ 運命の仲間（81-100）
- レベルアップで特別アニメーション + 限定アイテム解禁
- 1日放置で -2（最低0）、3日連続放置で「寂しそう」演出

**UI**:
- ペット画面中央にハート型ゲージ
- タップでモーションアニメ（喜び/元気/眠い）

#### C. ペットスキル＆アクティビティ
**スキル例**:
- **翻訳ブースト**: 親密度50で解禁、翻訳速度20%UP
- **ポイントボーナス**: 親密度70で解禁、実績ポイント+10%
- **ラッキーガチャ**: 親密度90で解禁、ガチャレア率微増（5→6%）

**アクティビティ**:
- **餌やり**: 1日1回、ランダムで好物（ニュースジャンルごと異なる）→ 親密度+5
- **お散歩**: 記事読破数に応じて歩数カウント、100歩ごとに小報酬
- **おしゃべり**: ランダムメッセージ表示（「今日はビジネスニュース読もう！」など）

#### D. ペットバリエーション（複数体育成）
**目的**: コレクション＋戦略的育成。

**仕様**:
- 初期ペット: たまご🥚（ランダムで3種から選択: ドラゴン🐲、フェニックス🔥、ユニコーン🦄）
- ショップで追加ペット購入（1000pt）
- 最大5体まで育成可能
- 各ペットに得意ジャンル（例: ドラゴンはビジネス成長+20%）
- アクティブペット切替で異なるスキル適用

#### E. ペット図鑑
**UI**: 実績図鑑と同様の3列グリッド
**内容**:
- 全ペット種（20種類計画: 基本5 + レア10 + レジェンダリー5）
- 解除条件表示（影状態）
- 進化段階ごとにイラスト（卵→子供→成体→究極）

#### F. ペット対戦モード（PvE/PvP）
**PvE**:
- ニュースクイズのペット版（ペットのステータスで難易度調整）
- 勝利報酬: 専用アイテム、経験値ブースト

**PvP（将来実装）**:
- フレンドのペットと非同期バトル（ステータス比較）
- ランキング＋シーズン報酬

---

## 実装スキーマ案

### PetModel
```dart
class Pet {
  final String id;
  final String name;
  final String type; // dragon, phoenix, unicorn
  int level; // 0-100
  int intimacy; // 0-100
  Map<String, int> stats; // {business: 20, tech: 15, ...}
  DateTime lastFed;
  DateTime createdAt;
  bool isActive;
  
  // Computed
  int get totalReadings => stats.values.reduce((a, b) => a + b);
  String get evolutionStage {
    if (level < 10) return 'egg';
    if (level < 30) return 'child';
    if (level < 70) return 'adult';
    return 'ultimate';
  }
}
```

### PetService
```dart
class PetService {
  static Future<List<Pet>> getAllPets() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('pets') ?? '[]';
    return (jsonDecode(json) as List).map((e) => Pet.fromJson(e)).toList();
  }
  
  static Future<void> feedPet(String petId) async {
    // Check 1日1回制限
    // 好物ボーナス判定（記事ジャンル分析）
    // 親密度+5
    // アニメーション表示
  }
  
  static Future<void> incrementStat(String petId, String genre) async {
    // genre → stat mapping (business → 💼)
    // stat += 1
    // level check (10ごとに進化演出)
  }
  
  static Future<void> updateIntimacy(String petId, int delta) async {
    // intimacy += delta (0-100でクランプ)
    // レベルアップ判定
  }
}
```

### UI実装
**ペット画面リニューアル**:
```dart
// lib/screens/pet_screen.dart
class PetScreen extends StatefulWidget {
  // タブ: マイペット / 図鑑 / ショップ
  // マイペット: 3D風アニメーション（Lottie or Rive）+ ステータスレーダー + アクションボタン（餌/散歩/おしゃべり）
  // 図鑑: GridView 3列、影表示
  // ショップ: 新ペット購入、アクセサリ、スキンなど
}
```

---

## 実装優先度
| 優先 | 機能 | 工数 | 価値 |
|------|------|------|------|
| 高 | デザイントークン導入 | 小 | 全体統一、拡張性 |
| 高 | ジャンル別ステータス | 中 | ペット差別化、習慣可視化 |
| 高 | 親密度システム | 中 | 愛着形成、継続率 |
| 中 | デイリークエスト | 中 | 短期目標、ポイント獲得 |
| 中 | 複数ペット育成 | 大 | コレクション、戦略性 |
| 低 | ペット対戦モード | 大 | 競争要素、ソーシャル |
| 低 | シーズン限定バッジ | 小 | 希少性、イベント感 |

---

## 計測指標
- ペット画面訪問率（DAU比）
- 平均親密度レベル
- ジャンル多様性指数（5ジャンルの標準偏差）
- 餌やり実行率（1日1回機会に対する実行率）
- 複数ペット所有率（2体以上保有ユーザー比率）
- ペット関連課金率（ショップ購入）

---

## 参考ゲーム
- **Tamagotchi**: 親密度、餌やり、放置デメリット
- **Pokémon GO**: 複数体育成、進化、図鑑コンプ
- **Neko Atsume**: 放置型、多様性、コレクション
- **Habitica**: 習慣トラッキング、RPG成長

ペット育成を単なるオマケではなく、ニュース閲覧のコア体験と統合することで、長期的なエンゲージメントを最大化します。
