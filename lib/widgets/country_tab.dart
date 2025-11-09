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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 78, // 親のSizedBox(80)に収まるよう少し小さめ
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.indigo.shade700.withOpacity(0.55),
                  Colors.indigo.shade900.withOpacity(0.65),
                ]
              : [
                  Colors.indigo.shade200.withOpacity(0.55),
                  Colors.indigo.shade400.withOpacity(0.65),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.indigo.shade200 : Colors.indigo.shade600)
              .withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          child: Row(
            children: [
              if (flag.isNotEmpty)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.85),
                        Colors.white.withOpacity(0.55),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(flag, style: const TextStyle(fontSize: 26)),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 0.8),
                      ),
                      child: Text(
                        code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: Colors.white.withOpacity(0.9),
                        ),
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
