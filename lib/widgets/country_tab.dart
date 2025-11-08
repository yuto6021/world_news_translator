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
      margin: EdgeInsets.zero,
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          height: 80,
          child: Row(
            children: [
              if (flag.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(flag, style: const TextStyle(fontSize: 32)),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
