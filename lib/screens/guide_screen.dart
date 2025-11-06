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
            Text('基本',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• タブ: ニュース / お気に入り / コメント / 国別 / タイムカプセル'),
            SizedBox(height: 12),
            Text('検索',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 上部の検索画面でキーワードを入力して検索します。'),
            Text('• 検索ワードは履歴として最大20件保存され、チップをタップして再検索できます。'),
            SizedBox(height: 12),
            Text('翻訳',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 記事詳細で自動的に日本語訳を取得します（設定で自動翻訳のON/OFFが可能）。'),
            Text('• DeepL に接続できない場合は簡易翻訳（キーワード置換）にフォールバックします。'),
            SizedBox(height: 12),
            Text('タイムカプセル',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 記事詳細で「タイムカプセルに保存」を押すと、解禁日を選んで保存できます。'),
            Text('• 設定のタイムカプセル画面で公開済み / 未公開の一覧が見られます。'),
            SizedBox(height: 12),
            Text('お気に入り',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 記事カードからお気に入りに追加できます。設定で全削除が可能です。'),
            SizedBox(height: 20),
            Text('その他',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 設定画面からテーマやホバー効果、翻訳キャッシュのクリアなどが行えます。'),
          ],
        ),
      ),
    );
  }
}
