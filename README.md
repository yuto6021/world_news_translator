# World News Translator – 開発者ガイド

Flutter製の世界ニュース翻訳アプリです。NewsAPI v2 から英語記事を取得し、DeepL API もしくは簡易辞書で日本語に翻訳して表示します。本ガイドは開発者視点で、機能構成・依存・拡張ポイントを簡潔にまとめています。

## アーキテクチャ概要

- Screens (`lib/screens/`): 画面。`HomeScreen`（タブ）、`TrendingScreen`、`CountryNewsScreen`、`ArticleDetailScreen`、`MapNewsScreen`（地図タブ）。
- Services (`lib/services/`): ビジネスロジック。
	- `NewsApiService`: NewsAPI v2 から記事取得（APIキーは一時的にソース直書き）。
	- `TranslationService`: DeepL + 簡易辞書（約800語）/メモリキャッシュ。
	- `ThemeService`: テーマ切替（`ValueNotifier`）。
	- `FavoritesService`, `TimeCapsuleService`: `SharedPreferences` 永続化。
- Models (`lib/models/`): `Article`, `Country`。
- Widgets (`lib/widgets/`): `NewsCard`, `CountryTab`, `SearchBar`, `FxTicker` など。

### データフロー
1. `NewsApiService` が記事 JSON を取得 → `Article.fromJson()` でモデル化。
2. UI 描画時に `TranslationService.translate()` が日本語化（DeepL→辞書のフォールバック、メモリキャッシュあり）。
3. お気に入り/タイムカプセルは `SharedPreferences` に JSON 保存。

## 実装済みの主な機能（直近）

### 1) 地図ニュースタブ（`MapNewsScreen`）
- 世界地図風のシルエット（`CustomPainter`）上に代表地域カードを配置。
- 地域カード右上にニュース件数バッジを表示。
	- 件数は `NewsApiService.fetchArticlesByCountry(code)` の戻り件数。
	- 1分キャッシュ（`_cacheTime`）で API 負荷を抑制。キャッシュミス時のみ取得。
- アクセシビリティ: `Semantics(label: '${地域名}のニュース')` を付与。
- タップで `CountryNewsScreen` に遷移（`countryCode` で記事一覧）。

実装ファイル: `lib/screens/map_news_screen.dart`

### 2) 背景画像（Markets/Search）
- Markets 画面: Stack + `Image.asset` + overlay。背景 `assets/images/background.jpg`（エラー時はグラデーション）。
- Search 画面: Stack + `Image.asset` + overlay。背景 `assets/images/background.jpg`。
- pubspec の assets に登録済み。

### 3) ティッカー改善（`widgets/fx_ticker.dart`）
- 小さいテキスト幅の場合はアニメーション停止。
- 大きいテキストのみ `Stack + Positioned` で連続スクロール。
- `ClipRect` でオーバーフロー抑止。

### 4) フッター調整（`widgets/social_footer.dart`）
- 余白縮小（padding/spacing）で高さを最適化。

## 依存関係

主要パッケージ:
- http, shared_preferences, flutter_dotenv, google_fonts, url_launcher, cached_network_image, sqflite, path_provider ほか。

## 環境変数と API キー

- `.env` に DeepL API キーを設定（`flutter_dotenv`でロード）。
- NewsAPI キーは当面 `lib/services/news_api_service.dart` に直記載（本番運用では必ず env 化）。
- pubspec の assets には `.env`, 翻訳辞書, 背景画像を登録。

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

- 地域の追加（Map タブ）
	- `MapNewsScreen._regions` に `name, countryCode, anchor(0-1正規化)` を追加。
	- 必要に応じて `CustomPainter` のシルエット（blob）も調整。

- 翻訳辞書の拡張
	- `lib/services/translation_service.dart` の `_tinyDict` に追加、もしくは外部JSONに拡張。

- 新規APIの追加
	- `lib/services/news_api_service.dart` に静的メソッド追加（既存の `fetchArticlesByCountry` に倣う）。

- テーマ/フォント
	- `ThemeService`（`ValueNotifier`）でライト/ダーク/システム切替。
	- Google Fonts（Noto Sans）を既定フォントとして利用。

## 実装ディテール（Mapニュースの件数バッジ）

- 非同期取得とキャッシュ
	- `_counts[code]` に件数、`_cacheTime[code]` に最終取得時刻を保持。
	- `DateTime.now()` との差分が 1 分未満なら再取得せず既存値を使用。
	- 取得失敗時は 0 を格納（バッジは "0" 表示）。

- コンポーネント構造
	- `MapNewsScreen`（Stateless）→ `
		_MapNewsBody`（Stateful, `initState`で件数の先行取得）→ 位置計算（`LayoutBuilder`）→ `CustomPainter`で背景描画 → `Positioned`でカード配置。

## アセット

`pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/translation_dict.json
    - assets/images/background.jpg
```## 既知の注意点

- `NewsApiService` の API キー直書きは開発用。必ず `.env` に移行すること。
- `flutter analyze` の一部 info は改善余地（use_build_context_synchronously など）。必要に応じて `mounted` チェックと呼び出しタイミングを見直す。

---

メンテナや拡張実装の際は、`lib/services/` の責務分離と `Screens/Widgets` の役割（表示/入出力）を崩さないようにしてください。
