import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/article.dart';

class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  Database? _db;
  static const String _prefsKey = 'offline_articles_v1';

  Future<Database> _open() async {
    // Web では path_provider/sqflite が使えないため、呼び出さない
    if (kIsWeb) {
      throw UnsupportedError('sqflite is not supported on Web');
    }
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'world_news.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE articles(
            url TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            urlToImage TEXT,
            importance REAL,
            savedAt INTEGER NOT NULL
          );
        ''');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_savedAt ON articles(savedAt DESC);');
      },
    );
    return _db!;
  }

  Future<void> upsertArticles(List<Article> articles) async {
    // Web は SharedPreferences に保存
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final List<String> existing = prefs.getStringList(_prefsKey) ?? [];
      // 既存を Map(url->Map) に復元
      final Map<String, Map<String, dynamic>> byUrl = {
        for (final s in existing)
          (json.decode(s) as Map<String, dynamic>)['url'] as String:
              json.decode(s) as Map<String, dynamic>
      };
      for (final a in articles) {
        byUrl[a.url] = {
          'url': a.url,
          'title': a.title,
          'description': a.description,
          'urlToImage': a.urlToImage,
          'importance': a.importance ?? 0.5,
          'savedAt': now,
        };
      }
      // 新しい順に並べ替え、最大件数を制限（例: 200件）
      final sorted = byUrl.values.toList()
        ..sort((a, b) => (b['savedAt'] as int).compareTo(a['savedAt'] as int));
      final limited = sorted.take(200).toList();
      await prefs.setStringList(
          _prefsKey, limited.map((m) => json.encode(m)).toList());
      return;
    }

    // モバイル/デスクトップは SQLite
    final db = await _open();
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final a in articles) {
      batch.insert(
        'articles',
        {
          'url': a.url,
          'title': a.title,
          'description': a.description,
          'urlToImage': a.urlToImage,
          'importance': a.importance ?? 0.5,
          'savedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Article>> getArticles({int limit = 20, int offset = 0}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> existing = prefs.getStringList(_prefsKey) ?? [];
      final List<Map<String, dynamic>> items = existing
          .map((s) => json.decode(s) as Map<String, dynamic>)
          .toList()
        ..sort((a, b) => (b['savedAt'] as int).compareTo(a['savedAt'] as int));
      final slice = items.skip(offset).take(limit);
      return slice
          .map((r) => Article(
                title: r['title'] as String,
                description: r['description'] as String?,
                url: r['url'] as String,
                urlToImage: r['urlToImage'] as String?,
                importance: (r['importance'] as num?)?.toDouble(),
              ))
          .toList();
    }

    final db = await _open();
    final rows = await db.query(
      'articles',
      orderBy: 'savedAt DESC',
      limit: limit,
      offset: offset,
    );
    return rows
        .map((r) => Article(
              title: r['title'] as String,
              description: r['description'] as String?,
              url: r['url'] as String,
              urlToImage: r['urlToImage'] as String?,
              importance: (r['importance'] as num?)?.toDouble(),
            ))
        .toList();
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      return;
    }
    final db = await _open();
    await db.delete('articles');
  }
}
