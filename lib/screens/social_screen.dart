import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/favorites_service.dart';
import '../models/article.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  bool _public = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _public = p.getBool('social_public') ?? false);
  }

  Future<void> _togglePublic(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('social_public', v);
    setState(() => _public = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👥 ソーシャル')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              value: _public,
              onChanged: _togglePublic,
              title: const Text('保存した記事を公開（ローカル表示）'),
              subtitle: const Text('今はデバイス内表示のみ。将来的にオンライン共有に対応'),
            ),
            const SizedBox(height: 8),
            const Text('今週のトップ5（お気に入りから）',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder<Map<String, Article>>(
                valueListenable: FavoritesService.instance.favorites,
                builder: (context, favs, _) {
                  final list = favs.values.toList().reversed.take(5).toList();
                  if (list.isEmpty)
                    return const Center(child: Text('お気に入りがありません'));
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final a = list[i];
                      return ListTile(
                        title: Text(a.title),
                        subtitle: Text(a.url),
                        trailing: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => Share.share(a.url),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
