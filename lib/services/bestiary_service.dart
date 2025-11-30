import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BestiaryService {
  static const String _key = 'bestiary_entries';

  static Future<Map<String, dynamic>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return {};
    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(data));
  }

  static Future<void> recordEncounter({
    required String name,
    required String element,
    required String type,
  }) async {
    final data = await _load();
    final entry = Map<String, dynamic>.from((data[name] ?? {}) as Map);
    entry['name'] = name;
    entry['element'] = element;
    entry['type'] = type;
    entry['encounters'] = (entry['encounters'] ?? 0) + 1;
    entry['defeats'] = (entry['defeats'] ?? 0);
    entry['firstSeenAt'] =
        entry['firstSeenAt'] ?? DateTime.now().toIso8601String();
    data[name] = entry;
    await _save(data);
  }

  static Future<void> recordDefeat({
    required String name,
    required String element,
    required String type,
  }) async {
    final data = await _load();
    final entry = Map<String, dynamic>.from((data[name] ?? {}) as Map);
    entry['name'] = name;
    entry['element'] = element;
    entry['type'] = type;
    entry['encounters'] = (entry['encounters'] ?? 0) + 1;
    entry['defeats'] = (entry['defeats'] ?? 0) + 1;
    entry['firstSeenAt'] =
        entry['firstSeenAt'] ?? DateTime.now().toIso8601String();
    data[name] = entry;
    await _save(data);
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final data = await _load();
    return data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      ..sort((a, b) => (b['defeats'] ?? 0).compareTo(a['defeats'] ?? 0));
  }

  static Future<Map<String, dynamic>?> getEntry(String name) async {
    final data = await _load();
    if (!data.containsKey(name)) return null;
    return Map<String, dynamic>.from(data[name] as Map);
  }
}
