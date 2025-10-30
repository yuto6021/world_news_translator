import 'package:flutter/material.dart';
import '../screens/country_news_screen.dart';

class CountryTab extends StatelessWidget {
  final String name;
  final String code;

  const CountryTab({super.key, required this.name, required this.code});

  String _codeToFlag(String cc) {
    try {
      final upper = cc.toUpperCase();
      if (upper.length != 2) return '';
      return String.fromCharCodes(upper.codeUnits.map((c) => 0x1F1E6 + c - 65));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final flag = _codeToFlag(code);
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CountryNewsScreen(countryCode: code, countryName: name),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (flag.isNotEmpty)
                Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(code.toUpperCase(),
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
