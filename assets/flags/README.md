# 国旗画像アセット

このディレクトリには、国別タブで使用する国旗画像を配置します。

## ファイル命名規則

国コード（小文字）+ `.png` の形式で保存してください。

例:
- `us.png` - アメリカ
- `jp.png` - 日本
- `gb.png` - イギリス
- `de.png` - ドイツ
- `fr.png` - フランス
- `cn.png` - 中国
- `kr.png` - 韓国
- `in.png` - インド
- `br.png` - ブラジル
- `au.png` - オーストラリア
- `ca.png` - カナダ
- `it.png` - イタリア
- `es.png` - スペイン
- `mx.png` - メキシコ
- `ru.png` - ロシア
- `nl.png` - オランダ
- `ar.png` - アルゼンチン
- `za.png` - 南アフリカ
- `tr.png` - トルコ
- `se.png` - スウェーデン
- `no.png` - ノルウェー

## 推奨サイズ

- 画像サイズ: 128x128px または 256x256px (正方形)
- フォーマット: PNG (透過背景推奨)
- ファイルサイズ: 各10KB以下推奨

## pubspec.yaml への追加

画像を配置後、`pubspec.yaml` の `flutter` セクションに以下を追加してください:

```yaml
flutter:
  assets:
    - assets/flags/
```

## 使用方法

CountryTabEnhancedウィジェットで自動的に読み込まれます。
画像がない場合は、現在のグラデーション背景がフォールバックとして表示されます。
