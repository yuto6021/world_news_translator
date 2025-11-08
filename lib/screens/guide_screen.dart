import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使い方ガイド')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('ホーム画面',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 画面上部の検索バーで全記事の横断検索ができます'),
            Text('• 右上の設定アイコンからアプリの設定画面を開けます'),
            Text('• タブ: ニュース / 国別 / 天気 / お気に入り / コメント / タイムカプセル'),
            Text('• ニュース一覧は下方向スクロールで自動的に続きをロード（無限スクロール）'),
            Text('• 下にスワイプして離すと最新情報を再取得（プルダウン更新）'),
            SizedBox(height: 12),
            Text('検索機能',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 検索バーに直接キーワードを入力して検索'),
            Text('• 検索履歴は最大20件まで保存され、タップで再検索可能'),
            Text('• 検索結果は関連度順に表示されます'),
            SizedBox(height: 12),
            Text('国別ニュース',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 10カ国のニュースを国旗付きのカードで表示'),
            Text('• 各国カードをタップすると、その国のニュース一覧を表示'),
            Text('• 記事は自動で日本語に翻訳されます'),
            SizedBox(height: 12),
            Text('天気情報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 世界の主要都市の天気予報を表示'),
            Text('• 時差を考慮した現地時間も表示'),
            SizedBox(height: 12),
            Text('タイムカプセル',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 気になる記事を未来の日付を指定して保存'),
            Text('• 保存時に設定した日付になると記事が公開'),
            Text('• 保存済み記事は公開前/公開済みで分類表示'),
            SizedBox(height: 12),
            Text('便利な機能',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• お気に入り記事の保存と管理'),
            Text('• 記事へのコメント投稿と閲覧'),
            Text('• ダークモード対応のテーマ切替'),
            Text('• 翻訳方式の選択（DeepL / 簡易翻訳）'),
            Text('• 読み込み中はスケルトン表示で待機時間を軽減'),
            Text('• 記事詳細の共有ボタンからSNS等へURLとタイトルを共有'),
            Text('• トレンド一覧のカラーラベルで記事の重要度を視覚的に把握'),
          ],
        ),
      ),
    );
  }
}
