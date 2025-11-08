import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/article.dart';

class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  Database? _db;

  Future<Database> _open() async {
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
    final db = await _open();
    await db.delete('articles');
  }
}
