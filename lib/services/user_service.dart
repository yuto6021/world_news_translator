import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/user.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  Database? _db;
  static const _prefsCurrentUserId = 'current_user_id';
  static const _prefsUsersJson = 'users_json'; // Web用ユーザー保存

  Future<Database?> _open() async {
    if (kIsWeb) return null; // Web非対応
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'world_news.db');
    _db = await openDatabase(
      dbPath,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT UNIQUE NOT NULL,
              display_name TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              salt TEXT NOT NULL,
              created_at INTEGER NOT NULL
            );
          ''');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
        }
      },
      onCreate: (db, version) async {
        // usersのみ（articlesは OfflineService 側で作成）
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            created_at INTEGER NOT NULL
          );
        ''');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);');
      },
    );
    return _db!;
  }

  Future<User> register(
      String email, String displayName, String password) async {
    if (kIsWeb) {
      return _registerWeb(email, displayName, password);
    }
    final db = await _open();
    // 重複チェック
    final existing =
        await db!.query('users', where: 'email = ?', whereArgs: [email]);
    if (existing.isNotEmpty) {
      throw Exception('既に登録済みのメールです');
    }
    // salt生成
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('users', {
      'email': email,
      'display_name': displayName,
      'password_hash': hash,
      'salt': salt,
      'created_at': now,
    });
    final user = User(
      id: id,
      email: email,
      displayName: displayName,
      passwordHash: hash,
      salt: salt,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsCurrentUserId, id);
    return user;
  }

  Future<User> _registerWeb(
      String email, String displayName, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefsUsersJson) ?? '[]';
    final List<dynamic> users = json.decode(usersJson);
    // 重複チェック
    if (users.any((u) => u['email'] == email)) {
      throw Exception('既に登録済みのメールです');
    }
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = users.isEmpty
        ? 1
        : (users.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b) +
            1);
    final userMap = {
      'id': id,
      'email': email,
      'display_name': displayName,
      'password_hash': hash,
      'salt': salt,
      'created_at': now,
    };
    users.add(userMap);
    await prefs.setString(_prefsUsersJson, json.encode(users));
    await prefs.setInt(_prefsCurrentUserId, id);
    return User.fromMap(userMap);
  }

  Future<User?> login(String email, String password) async {
    if (kIsWeb) {
      return _loginWeb(email, password);
    }
    final db = await _open();
    final rows =
        await db!.query('users', where: 'email = ?', whereArgs: [email]);
    if (rows.isEmpty) return null;
    final map = rows.first;
    final salt = map['salt'] as String;
    final expected = map['password_hash'] as String;
    final actual = _hashPassword(password, salt);
    if (expected != actual) return null;
    final user = User.fromMap(map);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsCurrentUserId, user.id);
    return user;
  }

  Future<User?> _loginWeb(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefsUsersJson) ?? '[]';
    final List<dynamic> users = json.decode(usersJson);
    final userMap = users.firstWhere(
      (u) => u['email'] == email,
      orElse: () => null,
    );
    if (userMap == null) return null;
    final salt = userMap['salt'] as String;
    final expected = userMap['password_hash'] as String;
    final actual = _hashPassword(password, salt);
    if (expected != actual) return null;
    final user = User.fromMap(userMap);
    await prefs.setInt(_prefsCurrentUserId, user.id);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsCurrentUserId);
  }

  Future<User?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_prefsCurrentUserId);
    if (id == null) return null;

    if (kIsWeb) {
      final usersJson = prefs.getString(_prefsUsersJson) ?? '[]';
      final List<dynamic> users = json.decode(usersJson);
      final userMap = users.firstWhere(
        (u) => u['id'] == id,
        orElse: () => null,
      );
      if (userMap == null) return null;
      return User.fromMap(userMap);
    }

    final db = await _open();
    final rows = await db!.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
