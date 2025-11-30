import 'package:flutter/material.dart';
import '../services/bestiary_service.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = BestiaryService.getAll();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'boss':
        return Colors.red;
      case 'secret_boss':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String _elementEmoji(String? e) {
    switch (e) {
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'grass':
        return '🌿';
      case 'electric':
        return '⚡';
      case 'ice':
        return '❄️';
      case 'dark':
        return '🌑';
      case 'light':
        return '✨';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('敵図鑑'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(
              child: Text('まだ遭遇した敵がいません'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = entries[i];
              final name = e['name'] as String? ?? '???';
              final element = e['element'] as String? ?? 'normal';
              final type = e['type'] as String? ?? 'normal';
              final encounters = e['encounters'] as int? ?? 0;
              final defeats = e['defeats'] as int? ?? 0;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _typeColor(type).withOpacity(0.15),
                    child: Text(
                      _elementEmoji(element),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor(type).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: _typeColor(type).withOpacity(0.5)),
                        ),
                        child: Text(
                          type == 'boss'
                              ? 'BOSS'
                              : type == 'secret_boss'
                                  ? 'SECRET'
                                  : 'ENEMY',
                          style: TextStyle(
                            color: _typeColor(type),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('遭遇: $encounters  勝利: $defeats',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
