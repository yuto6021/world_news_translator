# World News Translator - AI Agent Instructions

## アーキテクチャ概要

Flutter製のニュース翻訳アプリ。NewsAPIから英語の世界ニュースを取得し、DeepL APIまたは簡易翻訳で日本語に変換して表示。

### コアコンポーネント

- **Screens** (`lib/screens/`): 画面コンポーネント。主要画面はHomeScreen（タブ構造）、TrendingScreen、CountryNewsScreen、ArticleDetailScreen
- **Services** (`lib/services/`): ビジネスロジック層。各サービスはシングルトンまたは静的メソッドで実装
  - `NewsApiService`: NewsAPI v2からニュース取得（APIキーハードコード）
  - `TranslationService`: DeepL APIによる翻訳 + フォールバック用簡易辞書翻訳（約800語）
  - `ThemeService`: テーマ管理（ValueNotifier使用）
  - `FavoritesService`, `TimeCapsuleService`: SharedPreferencesでローカル永続化
- **Models** (`lib/models/`): データモデル（Article, Country）
- **Widgets** (`lib/widgets/`): 再利用可能なUIコンポーネント（NewsCard, CountryTab, SearchBar）

### データフロー

1. NewsAPIからJSON取得 → Article.fromJson()でパース
2. ArticleをUI表示時にTranslationServiceで日本語化（キャッシュあり）
3. お気に入り・タイムカプセルはSharedPreferencesに保存（JSON形式）

## 開発ワークフロー

```bash
# 環境セットアップ
flutter pub get

# 開発実行（ホットリロード対応）
flutter run

# ビルド
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web

# 静的解析
flutter analyze
```

### APIキー管理

- `.env`ファイルでDeepL APIキーを管理（`flutter_dotenv`使用）
- NewsAPI キーは`news_api_service.dart`に直接記載（本番では要変更）

## プロジェクト固有の規約

### UI構造パターン

- **NestedScrollView + TabBarView**: HomeScreenの標準構造（SliverAppBar使用）
- **カード＋スクロール**: ほとんどの画面はCard内にコンテンツ、外側にListViewまたはSingleChildScrollView
- **Semantics必須**: アクセシビリティ対応のため、タップ可能な要素にはSemantics widgetでラベル付与

例（CountryTab）:
```dart
Semantics(
  label: '日本のニュース',
  child: CountryTab(name: "日本", code: "jp"),
)
```

### サービスパターン

- **静的メソッド中心**: NewsApiService, TranslationServiceは状態を持たない静的メソッド
- **シングルトン**: ThemeService.instance のようにインスタンス管理が必要なものはシングルトン
- **非同期処理**: すべてのAPI呼び出しはFuture<T>を返す。エラーハンドリングは呼び出し側で実装

### 翻訳システム

TranslationServiceは2段階フォールバック:
1. DeepL API（優先、設定で有効化）
2. 簡易辞書翻訳（_tinyDict約800語、大文字小文字無視＋複数形対応）

キャッシュは`_cache`マップでセッション中保持。設定画面から手動クリア可能。

### 状態管理

- **ValueNotifier**: テーマ管理（ThemeService）
- **StatefulWidget**: 画面ごとの一時的な状態（タブ選択、スクロール位置など）
- **SharedPreferences**: お気に入り、タイムカプセル、検索履歴、設定の永続化

### スタイリング

- **Google Fonts**: `google_fonts`パッケージでNoto Sans使用
- **テーマ切替**: ライト/ダーク/システム対応（ThemeService経由）
- **グラデーション背景**: HomeScreenはLinearGradient（indigo系）

## 重要ファイル

- `lib/main.dart`: アプリエントリーポイント、テーマ設定
- `lib/screens/home_screen.dart`: メイン画面（タブ構造、検索バー、設定ボタン）
- `lib/services/translation_service.dart`: 翻訳ロジック（568行、辞書データ含む）
- `lib/services/news_api_service.dart`: NewsAPI連携
- `lib/widgets/news_card.dart`: ニュース記事カードUI（お気に入りボタン付き）

## よくある変更パターン

### 新しいタブを追加

1. `home_screen.dart`の`_tabs`配列に追加
2. 新しいScreenクラスを`lib/screens/`に作成
3. TabBarViewのchildren配列に追加

### 翻訳辞書を拡張

`translation_service.dart`の`_tinyDict`に単語を追加（小文字で登録）。または外部JSONファイル化を検討。

### 新しいAPIエンドポイント追加

`news_api_service.dart`に静的メソッドを追加。既存パターン（fetchArticlesByCountry）に従う。

## 依存関係

主要パッケージ:
- `http`: API通信
- `shared_preferences`: ローカルストレージ
- `flutter_dotenv`: 環境変数管理
- `google_fonts`: フォント
- `url_launcher`: 外部リンク

## デバッグのヒント

- 翻訳が表示されない → DeepL APIキーを`.env`で確認、または簡易翻訳へフォールバック
- ニュースが取得できない → NewsAPI キーの有効性確認、ネットワーク接続確認
- レイアウトオーバーフロー → Expanded/Flexibleの使用、スクロール可能な親widgetの確認
