# World News Translator – 開発者ガイド

Flutter製の世界ニュース翻訳アプリです。NewsAPI v2 から英語記事を取得し、DeepL API もしくは簡易辞書で日本語に翻訳して表示します。本ガイドは開発者視点で、機能構成・依存・拡張ポイントを簡潔にまとめています。

## アーキテクチャ概要

- **Screens** (`lib/screens/`): 画面コンポーネント。`HomeScreen`（13タブ構造）、`TrendingScreen`、`CountryNewsScreen`、`ArticleDetailScreen`、`MapNewsScreen`、`RegistrationScreen`（会員登録）など。
- **Services** (`lib/services/`): ビジネスロジック層。各サービスはシングルトンまたは静的メソッドで実装。
	- `NewsApiService`: 複数APIプロバイダー（GNews, Currents, MediaStack）からニュース取得。レート制限対策実装済み。
	- `TranslationService`: DeepL API + 簡易辞書翻訳（約800語）。メモリキャッシュで効率化。
	- `UserService`: 会員登録・ログイン・ログアウト機能。Web/ネイティブ両対応（SharedPreferences/SQLite）。
	- `OfflineService`: 記事のローカルキャッシュ（SQLite/SharedPreferences）。オフライン対応。
	- `ThemeService`: テーマ切替（ライト/ダーク/システム）、`ValueNotifier` 使用。
	- `FavoritesService`, `TimeCapsuleService`: お気に入りとタイムカプセルの永続化（`SharedPreferences`）。
- **Models** (`lib/models/`): データモデル（`Article`, `Country`, `User`, `NewsInsight`, `Weather`）。
- **Widgets** (`lib/widgets/`): 再利用可能なUIコンポーネント（`NewsCard`, `CountryTab`, `SearchBar`, `FxTicker`、`BreakingNewsBanner`）。

### データフロー
1. **ニュース取得**: `NewsApiService` が3つのAPIプロバイダーをフォールバック方式で呼び出し → JSON取得 → `Article.fromJson()` でモデル化 → `OfflineService` でキャッシュ保存。
2. **翻訳**: UI描画時に `TranslationService.translate()` が日本語化。DeepL優先、失敗時は簡易辞書で補完。セッション中はメモリキャッシュで高速化。
3. **会員情報**: `UserService.register()` でSHA256+saltによるパスワードハッシュ化 → SQLite（ネイティブ）またはSharedPreferences JSON配列（Web）に保存。
4. **永続化**: お気に入り・タイムカプセルは `SharedPreferences` に JSON 保存。記事キャッシュはSQLiteまたはSharedPreferences（Web）。

## 実装済みの主な機能

### 1) 会員登録システム（`UserService` + `RegistrationScreen`）
**目的**: ユーザーアカウント管理とログイン状態の永続化。

**仕組み**:
- **Web対応**: `kIsWeb` フラグで実行環境を判定。Web版では `path_provider` や `sqflite` が使えないため、`SharedPreferences` に JSON配列形式でユーザー情報を保存（キー: `users_json`）。
- **ネイティブ対応**: SQLite データベース `world_news.db` に `users` テーブルを作成（バージョン2で追加）。カラム: `id`, `email`, `display_name`, `password_hash`, `salt`, `created_at`。
- **セキュリティ**: パスワードは平文保存せず、32バイトのランダムsaltを生成し、`sha256(salt:password)` でハッシュ化。
- **自動ログイン**: 登録・ログイン時に `SharedPreferences` の `current_user_id` にユーザーIDを保存。アプリ起動時に自動復元可能。

**検証**:
- メールアドレス: `^[^@]+@[^@]+\.[^@]+` の正規表現でフォーマット確認。
- パスワード: 8文字以上、かつ数字と文字の両方を含む必要あり。
- 確認パスワード: 入力値が一致するかチェック。

実装ファイル: `lib/services/user_service.dart`, `lib/models/user.dart`, `lib/screens/registration_screen.dart`

---

### 2) APIレート制限対策（`NewsApiService`）
**問題**: 複数のニュースAPIプロバイダー（GNews, Currents, MediaStack）が429エラーを返すと、アプリが無限リトライしてコンソールスパムとAPI制限悪化を引き起こす。

**解決策**:
- **クールダウンマップ**: `_rateLimitedUntil[provider]` に次回試行可能時刻（現在時刻+10分）を記録。
- **スキップロジック**: API呼び出し前に `_isRateLimited(provider)` でクールダウン中か確認。該当する場合は試行をスキップ。
- **ログ抑制**: 同じエラーメッセージは30秒に1回のみ出力（`_logOnce()`）。
- **UI通知**: 全プロバイダーがレート制限中の場合は「全APIレート制限中。しばらく待機してください。」の例外をスロー。画面では赤いエラーバナーで表示。
- **補助メソッド**: `configStatus()` で各APIキーの設定状況を返す、`rateLimitRemaining()` で残り時間を取得（未使用だが将来の拡張用）。

実装ファイル: `lib/services/news_api_service.dart` (静的メソッド: `_markRateLimited`, `_isRateLimited`, `_logOnce`)

---

### 3) UI改善（`HomeScreen`）
**背景**: ヘッダーの透明度が高すぎて背景画像と文字が重なり読みづらい。速報バナーがスクロールで消える。

**対策**:
- **ヘッダー透明度アップ**: `_buildFlexibleSpace()` の `LinearGradient` 透明度を増加。スクロール時はダーク0.92、ライト0.95（従来0.7/0.8）。非スクロール時はダーク0.5、ライト0.6（従来0.3/0.4）。
- **速報バナー固定**: `BreakingNewsBanner` を `NestedScrollView` の外側（`Column` の先頭）に配置。スクロールしても画面上部に常駐。

実装ファイル: `lib/screens/home_screen.dart`

---

### 4) 地図ニュースタブ（`MapNewsScreen`）
- 世界地図風のシルエット（`CustomPainter`）上に代表地域カードを配置。
- 地域カード右上にニュース件数バッジを表示（1分キャッシュでAPI負荷抑制）。
- タップで `CountryNewsScreen` に遷移。

実装ファイル: `lib/screens/map_news_screen.dart`

---

### 5) その他UI機能
- **Markets/Search背景画像**: `assets/images/background.jpg` を Stack で表示（エラー時はグラデーション）。
- **FXティッカー**: `widgets/fx_ticker.dart` でスクロールアニメーション。小さいテキストは停止、大きいテキストのみ連続スクロール。
- **ソーシャルフッター**: `widgets/social_footer.dart` で余白を縮小し高さ最適化。

## 依存関係

主要パッケージ:
- **http**: APIリクエスト（ニュース、翻訳、為替レート）
- **shared_preferences**: ローカルストレージ（お気に入り、設定、Web版ユーザー情報）
- **sqflite**: SQLiteデータベース（ネイティブ版のユーザー情報、記事キャッシュ）
- **path_provider**: ファイルパス取得（ネイティブのみ、Web非対応）
- **flutter_dotenv**: 環境変数ロード（`.env` ファイル）
- **google_fonts**: Noto Sans フォント
- **url_launcher**: 外部リンク起動
- **cached_network_image**: 画像キャッシュ
- **crypto**: SHA256ハッシュ（パスワード暗号化）

その他: `intl`, `fl_chart`, `flutter_map`, `latlong2` など。

## 環境変数と API キー

**必須設定**（`.env` ファイル）:
```env
GNEWS_API_KEY=your_gnews_key_here
CURRENTS_API_KEY=your_currents_key_here
MEDIASTACK_API_KEY=your_mediastack_key_here
DEEPL_API_KEY=your_deepl_key_here
```

**注意点**:
- 3つのニュースAPIプロバイダーは優先度順にフォールバック（GNews → Currents → MediaStack）。最低1つは設定が必要。
- DeepL APIキーは翻訳精度向上のため推奨だが、未設定でも簡易辞書翻訳（約800語）で動作。
- `pubspec.yaml` の `assets` に `.env`, `assets/translation_dict.json`, `assets/images/background.jpg` を登録済み。

## ビルド/実行

```powershell
flutter pub get
flutter run
```

Web 実行（Chrome）:

```powershell
flutter run -d chrome
```

静的解析:

```powershell
flutter analyze
```

## 開発Tips/拡張ポイント

### 地域の追加（Map タブ）
- `MapNewsScreen._regions` に `name, countryCode, anchor(0-1正規化)` を追加。
- 必要に応じて `CustomPainter` のシルエット（blob）も調整。

### 翻訳辞書の拡張
- `lib/services/translation_service.dart` の `_tinyDict` に追加、もしくは外部JSONに拡張。
- 現在約800語。小文字で登録し、複数形（-s/-es/-ies）も自動対応。

### 新規APIの追加
- `lib/services/news_api_service.dart` に静的メソッド追加（既存の `fetchArticlesByCountry` に倣う）。
- レート制限対策として `_isRateLimited()` と `_markRateLimited()` を必ず使用。

### テーマ/フォント
- `ThemeService`（`ValueNotifier`）でライト/ダーク/システム切替。
- Google Fonts（Noto Sans）を既定フォントとして利用。

### 会員登録の拡張
- **ログイン画面追加**: `UserService.login()` は実装済み。`LoginScreen` を作成し `TextField` とボタンで呼び出し。
- **プロフィール画面**: `UserService.currentUser()` で現在のユーザー情報取得。表示名、メール、登録日時を表示可能。
- **ログアウト**: `UserService.logout()` で `SharedPreferences` の `current_user_id` をクリア。
- **パスワードリセット**: 現状未実装。メールベースのリセット機能を追加する場合は別途バックエンド連携が必要。

### セキュリティ向上
- **bcrypt導入**: 現在はSHA256+saltだが、より安全な `bcrypt` パッケージへの移行を推奨（コストファクター12を推奨）。
- **後方互換性**: 既存SHA256ハッシュを持つユーザーはログイン時にbcryptへ自動移行する仕組みを検討。

---

## 実装ディテール（重要な部分の深掘り）

### 会員登録の内部動作（`UserService`）

**Web版（`_registerWeb`）**:
1. `SharedPreferences` から `users_json` キーで既存ユーザー配列を取得（JSON文字列）。
2. メールアドレス重複チェック。既存の場合は例外スロー。
3. 32バイトのランダムsalt生成（`Random.secure()` → base64Url）。
4. `sha256(salt:password)` でハッシュ化（`crypto` パッケージ使用）。
5. 新ユーザーを配列に追加し、JSON文字列化して `users_json` に保存。
6. ユーザーIDを `current_user_id` に保存（自動ログイン用）。

**ネイティブ版（`register`）**:
1. `sqflite` で `world_news.db` を開く（バージョン2、`onUpgrade` で `users` テーブル作成）。
2. `SELECT * FROM users WHERE email = ?` で重複チェック。
3. salt生成 → ハッシュ化 → `INSERT INTO users` でレコード追加。
4. 自動採番されたIDを取得し、`current_user_id` に保存。

**セキュリティ考慮**:
- パスワードは平文で保存しない。
- saltは各ユーザーごとに異なるためレインボーテーブル攻撃に強い。
- SHA256は高速だが、bcryptやArgon2の方がブルートフォース攻撃に強い（今後の改善点）。

---

### レート制限対策の内部動作（`NewsApiService`）

**データ構造**:
```dart
static final Map<String, DateTime> _rateLimitedUntil = {};
static final Map<String, DateTime> _lastLogTime = {};
static const Duration _rateLimitSilence = Duration(minutes: 10);
static const Duration _logThrottle = Duration(seconds: 30);
```

**フロー**:
1. `fetchArticlesByCountry()` が呼ばれる。
2. GNews, Currents, MediaStackの順に試行。
3. 各プロバイダー呼び出し前に `_isRateLimited(provider)` で確認:
   - `_rateLimitedUntil[provider]` が存在し、現在時刻より未来なら **スキップ**。
4. APIリクエスト実行。ステータスコード429の場合:
   - `_markRateLimited(provider)` で `_rateLimitedUntil[provider] = 現在時刻 + 10分` を設定。
   - `_logOnce(provider, message)` で30秒に1回のみエラーログ出力。
   - 例外スロー（UI側でキャッチしてエラーバナー表示）。
5. 全プロバイダーがレート制限中またはAPIキー未設定の場合、最終的な例外をスロー。

**効果**:
- 429エラー発生後10分間は該当プロバイダーを自動スキップ。無駄なリクエストとログスパムを防止。
- 他のプロバイダーが利用可能なら自動フォールバック。
- UI側では `NewsApiService.rateLimitRemaining()` で残り時間を表示可能（現在未使用）。

---

### Mapニュースの件数バッジ

**非同期取得とキャッシュ**:
- `_counts[code]` に件数、`_cacheTime[code]` に最終取得時刻を保持。
- `DateTime.now()` との差分が1分未満なら再取得せず既存値を使用。
- 取得失敗時は 0 を格納（バッジは "0" 表示）。

**コンポーネント構造**:
- `MapNewsScreen`（Stateless）→ `_MapNewsBody`（Stateful, `initState`で件数の先行取得）→ 位置計算（`LayoutBuilder`）→ `CustomPainter`で背景描画 → `Positioned`でカード配置。

## アセット

`pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/translation_dict.json
    - assets/images/background.jpg
```## 既知の注意点と今後の改善点

### セキュリティ
- **パスワードハッシュ**: 現在SHA256+saltだが、`bcrypt` または `Argon2` への移行を推奨（ブルートフォース攻撃耐性向上）。
- **APIキー管理**: `.env` ファイルはGitリポジトリに含めない（`.gitignore` に追加済みか確認）。

### Web互換性
- **path_provider, sqflite**: Web版では動作しないため、常に `kIsWeb` でチェック。
- **SharedPreferences**: Web版のストレージ制限（約10MB）に注意。大量のキャッシュ保存は避ける。

### コード品質
- `flutter analyze` の一部 info（`use_build_context_synchronously` など）は改善余地。
- 非同期処理後の `setState()` 前に `mounted` チェックを徹底。

### 機能追加予定
- **記事キャッシュのTTL**: 現在はオフライン時のみ使用。TTL（例: 15分）を設けて定期的なAPI呼び出しを削減。
- **ログイン画面**: `UserService.login()` は実装済みだが、UIは未作成。
- **プロフィール画面**: ユーザー情報表示とログアウトボタン。
- **レート制限UI表示**: 設定画面やエラーメッセージで「残り○分」のカウントダウン表示。

---

## 実績システム・ガチャ・ショップ機能

### 実績システム（`AchievementsService`）
- **永続化**: Hiveを使用（`achievements` Box）。
- **実績データ**: `lib/services/achievements_service.dart` で定義（読書時間、連続ログイン、クイズ、ゲームスコアなど）。
- **レア度**: `common`, `rare`, `epic`, `legendary` の4段階。
- **解除演出**: `AchievementNotifier.show()` でフルスクリーンアニメーション表示（レア度別エフェクト）。
- **実績図鑑**: 3列グリッドレイアウト、50pxアイコン、コンパクトフォント。72/150形式で進捗表示。

### 実績ガチャシステム（`GachaService` + `GachaScreen`）
- **1日1回制限**: `SharedPreferences` の `last_gacha_date` で日付判定（デバッグモードでは制限解除）。
- **レア度抽選**: 重み付き乱数（コモン50%、レア30%、エピック15%、レジェンダリー5%）。
- **チャレンジ生成**: 5種類のランダムチャレンジ（記事読破、ゲームスコア、コメント、お気に入り、クイズ）。
- **24時間制限**: チャレンジは生成から24時間以内に達成する必要あり。
- **UI**: 円形グラデーションボタン（200x200px）、スナックバーで結果表示。
- **デバッグモード**: `_drawGacha()` の制限チェックをコメントアウト済み（何度でも引ける）。

### ショップシステム（`ShopService` + `ShopScreen`）
- **ポイント管理**: `SharedPreferences` の `achievement_points` で管理（初期値1000pt）。
- **ポイント獲得**: 実績解除時にレア度別（コモン10pt、レア30pt、エピック100pt、レジェンダリー300pt）。
- **購入アイテム**:
  - **テーマ**: ハロウィン、クリスマス、桜、オーシャン、ギャラクシー（500-800pt）
  - **ペットアイテム**: デコレーション要素（300-500pt）
  - **その他**: タイムカプセル拡張、ガチャチケット、ヒント（100-500pt）
- **購入済み管理**: `purchased_items` にJSON配列で保存。
- **UI**: 5タブ構造（全て/テーマ/ペット/その他/購入済み）、ポイント残高表示。

### テーマシステム（`ShopService.getActiveThemeColors()` + `main.dart`）
- **購入方法**: ショップで🎨テーマタブからテーマを購入 → 🎁購入済みタブで「適用」ボタン。
- **色データ**: 各テーマに `primary_color` と `accent_color` を定義（16進数カラーコード）。
- **適用方法**: `ShopService.setActiveTheme(id)` で `active_theme` に保存 → アプリ再起動で反映。
- **動的ロード**: `WorldNewsApp` を `StatefulWidget` に変更し、`initState()` でテーマ色をロード。
- **MaterialApp適用**: `_buildTheme(brightness, primaryColor)` でColorSchemeに反映。
- **再起動通知**: テーマ適用後、スナックバーに「再起動」ボタンを表示。

### バッジシステム（`BadgeService`）
- **統計タブ**: 46個のユニークバッジ（記事数、ログイン、ゲーム実績など）。全絵文字重複なし。
- **プロフィールアイコン**: 獲得バッジをプロフィール画像として設定可能（`UserProfileScreen`）。
- **5列グリッド**: バッジ選択モーダルで視覚的に選択。
- **自動解除**: 統計画面の条件判定で自動的に `BadgeService.unlockBadges()` 呼び出し。

### 統計画面のテスト機能
- **テスト実績解除ボタン**: 統計タブに🧪カード追加（4ボタン: コモン/レア/エピック/レジェンダリー）。
- **即時演出確認**: ボタン押下で `AchievementsService.unlock()` → `AchievementNotifier.show()` → スナックバー。
- **実験実績**: `test_common`（🧪）、`test_rare`（⚗️）、`test_epic`（🔬）、`test_legendary`（🏆）。

### 重要な注意点
1. **ガチャボタンが見えない問題**: 
   - 原因: `_canDraw` が `false` で `onTap: null` になっていた。
   - 対策: デバッグモードで制限チェックをコメントアウト、`onTap` を常に有効化。
   - 位置: ホーム画面右上の🎰アイコンから遷移。

2. **テーマが適用されない問題**:
   - 原因: `main.dart` でShopServiceのテーマ色を読み込んでいなかった。
   - 対策: `WorldNewsApp` をStatefulWidgetに変更、`getActiveThemeColors()` で動的ロード。
   - 反映: アプリ再起動が必要（ホットリロードでは不可）。

3. **初期ポイント設定**:
   - テスト段階のため初期値を1000ptに設定済み（`ShopService.getPoints()`）。
   - 本番環境では0ptに戻すことを推奨。

---

3. **初期ポイント設定**:
   - テスト段階のため初期値を1000ptに設定済み（`ShopService.getPoints()`）。
   - 本番環境では0ptに戻すことを推奨。

### デバッグフラグ / 本番切替チェックリスト
開発中と本番ビルドで挙動を変えるべきポイント:
- ガチャ: `_drawGacha()` の制限解除コード（コメントアウトした canDraw チェック）→ 本番では元に戻す。
- 初期ポイント: 1000 → 0 に戻す。
- テスト実績 (🧪) ボタン: 本番ビルドで表示フラグ追加予定（例: `kDebugMode` 判定）。
- ログ出力: NewsAPI のレート制限ログ頻度を本番でさらに抑制する（Sentry導入時は breadcrumbs 化）。
- 例外: 開発中は SnackBar でスタックトレース一部表示、本番ではユーザーフレンドリー文言のみ。

### テーマ拡張の仕組み（Shop連動）
`ShopService.getActiveThemeColors()` が 16進カラー文字列を読み込み → `main.dart` の `_WorldNewsAppState._loadTheme()` が `Color(int.parse(...))` で適用。
今後拡張する場合:
1. `ShopService.getAllItems()` に新テーマ `ShopItem(type: 'theme')` を追加。
2. `data` に `primary_color`, `accent_color`, （拡張）`bg_gradient_start`, `bg_gradient_end`, `elevation_scale` などを追加。
3. `_buildTheme` にアクセントカラー/グラデーション対応を追加（`ColorScheme` の `secondary`）。
4. コンポーネント（AppBar, FAB, Card）にテーマ色/角丸トークンを反映するヘルパを導入。

### 非同期/サービス初期化の推奨順序
1. `WidgetsFlutterBinding.ensureInitialized()`
2. Hive / SharedPreferences などローカル永続化層
3. 可用性に影響するサービス (Achievements, GameScores, ReadingTime)
4. `.env` ロード（翻訳キー依存のため早期）
5. ストリーク更新（起動イベント記録）
6. Theme / ReadingMode ロード（最初のフレームでフォントジャンプ防止）

### 推奨テストスイート（未実装案）
- Unit: `TranslationService` の辞書フォールバック、`NewsApiService._isRateLimited()`
- Widget: 実績解除演出 Overlay が 1つのみ生成されること。
- Golden: テーマ別主要画面（Home / ArticleDetail / Gacha）。
- Integration: ショップ購入 → 再起動 → テーマ反映までのフロー。

### 計測/分析イベント案
| Event | Category | Props |
|-------|----------|-------|
| `article_view` | content | `country`, `source`, `length_ms` |
| `achievement_unlock` | gamification | `id`, `rarity` |
| `gacha_draw` | gamification | `rarity`, `challenge_type` |
| `theme_applied` | personalization | `theme_id` |
| `badge_set_profile` | personalization | `badge_emoji` |
| `shop_purchase` | economy | `item_id`, `item_type`, `price` |
| `read_mode_toggle` | accessibility | `dyslexic_font`, `high_contrast` |

---

## UI/UX 改善ガイドライン（ハイレベル設計原則）
"世界一おしゃれで売れる" を目指すための重点領域:

### 1. ビジュアルデザイン
- トークン化: `design_tokens.dart` を作り、色・余白・角丸・シャドウを一元管理。
- 適応型テーマ: 時間帯（朝/夜）・記事ジャンルで背景グラデーションを切替。
- 余白システム: 4,8,12,16,24,32 のスケールを統一し視覚的一貫性。
- マイクロインタラクション: ホバー（Web）時の軽微なパララックス、ボタン押下時の 120ms スケールアニメ。

### 2. コンテンツ体験
- AI要約: 長文記事へ "要約を読む" (LLM) / "詳細へ展開" の2段階読書。
- 並列翻訳ビュー: 英語原文と日本語訳を上下 or 左右分割で比較。
- ハイライト生成: 翻訳済み本文に固有名詞タグ（国・企業）を色分け表示。
- 音声再生: TTS で通勤中の耳学習、速度調整 (0.8x~1.5x)。

### 3. 個人化/ゲーミフィケーション
- デイリークエスト: "記事3本読む" "コメント1件" などでボーナスポイント。
- シーズンバッジ: 月替り限定バッジ（希少性による回帰誘導）。
- コレクションセット: 国旗セット全部獲得で追加ボーナス。
- モチベーション曲線: 解除間隔が空いたら"次はここを目指そう"ガイドチップ表示。

### 4. アクセシビリティ
- 行間 / フォントサイズ / カラーコントラスト事前プリセット (Comfort / Focus / Dyslexic)。
- スクリーンリーダーラベル：記事カードのアクセス順位最適化（タイトル→要約→操作）。
- モーション軽減: OS設定で `prefers-reduced-motion` の場合パーティクル数を 50% に。

### 5. パフォーマンス
- 翻訳プリフェッチ: スクロール先読み (3~5カード先) をキュー処理。
- Shimmerプレースホルダ: 読み込み中レイアウトシフト排除。
- NewsAPI バッチ: 並列呼び出しを Isolate / compute でパースコスト分離。
- キャッシュインデックス: 最後に読んだ記事カテゴリを優先読み出し。

### 6. 収益化/継続率
- Premium階層: 広告非表示 / 高速翻訳 / AI要約無制限 / 高レアガチャ確率微増。
- 広告最適化: ネイティブカード間 1/8 の頻度 + スクロール後 3秒遅延表示。
- リターン促進: プッシュ通知（朝: 世界要約、夜: ストリーク継続リマインド）。
- Referral: 友達招待で限定バッジ + 双方ポイント付与。

### 7. 計測と改善
- A/B テスト: ガチャ演出時間 2s vs 3s, 要約ボタン配置上 vs 下。
- ヒートマップ: スクロール深度 / 記事クリック率を計測（Web）→ 情報密度最適化。
- Funnel: インストール→初記事閲覧→初実績→初ガチャ→初購入 の離脱率追跡。

### 8. セキュリティ/信頼性
- 翻訳ログを PII 除去後に学習用途へ集約（オプトイン）。
- Crashモニタ: Sentry 導入 + 実績演出や Overlay 起因の例外監視。
- リソース上限: パーティクル最大 250 / 同時 Overlay 1。

---

## 追加機能アイデア（優先度付き）
| 優先 | 機能 | 価値 | 概要 |
|------|------|------|------|
| 高 | AI要約 / 難易度別翻訳 | 時間短縮 | 学習レベル(初級/中級/上級)別語彙で再翻訳 |
| 高 | デイリーダイジェスト通知 | 継続率 | 24時間内人気記事を自動要約して朝配信 |
| 中 | バッジ季節イベント | 再訪 | 月替り限定・コレクション熱を維持 |
| 中 | 並列原文/訳ビュー | 学習 | 語学学習ニーズ強化 |
| 中 | ペット進化x記事ジャンル | 感情的愛着 | ジャンル偏りを可視化し多様性促進 |
| 低 | 難易度アダプティブクイズ | 学習効率 | 正答率に応じて出題レベル調整 |
| 低 | SNSシェアカード生成 | バイラル | 実績解除画像をOG最適化して共有 |

---

## アーキテクチャ原則

メンテナや拡張実装の際は以下を遵守してください:

1. **Services層の責務分離**: ビジネスロジック（API呼び出し、データ変換、永続化）はServicesに集約。UIコンポーネントに直接書かない。
2. **Screens/Widgetsの役割**: 表示とユーザー入力のみ担当。データ取得・保存はServicesに委譲。
3. **Web/ネイティブ分岐**: プラットフォーム固有機能は `kIsWeb` で早期分岐。Webフォールバックを必ず用意。
4. **エラーハンドリング**: `try-catch` で例外をキャッチし、UIでユーザーフレンドリーなメッセージを表示（SnackBarやエラーバナー）。
5. **パフォーマンス**: APIレート制限、キャッシュ、ログ抑制を意識。無駄なリクエストとログスパムを防ぐ。
