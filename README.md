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

## アーキテクチャ原則

メンテナや拡張実装の際は以下を遵守してください:

1. **Services層の責務分離**: ビジネスロジック（API呼び出し、データ変換、永続化）はServicesに集約。UIコンポーネントに直接書かない。
2. **Screens/Widgetsの役割**: 表示とユーザー入力のみ担当。データ取得・保存はServicesに委譲。
3. **Web/ネイティブ分岐**: プラットフォーム固有機能は `kIsWeb` で早期分岐。Webフォールバックを必ず用意。
4. **エラーハンドリング**: `try-catch` で例外をキャッチし、UIでユーザーフレンドリーなメッセージを表示（SnackBarやエラーバナー）。
5. **パフォーマンス**: APIレート制限、キャッシュ、ログ抑制を意識。無駄なリクエストとログスパムを防ぐ。
