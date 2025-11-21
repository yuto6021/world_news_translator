import 'package:flutter/material.dart';

/// 国別タブをおしゃれに表示するウィジェット（グラデーション背景+国コードバッジ）
class CountryTabEnhanced extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onTap;
  final bool isSelected;

  const CountryTabEnhanced({
    super.key,
    required this.name,
    required this.code,
    required this.onTap,
    this.isSelected = false,
  });

  LinearGradient _getGradient(String countryCode) {
    // 国ごとに異なるグラデーション配色
    switch (countryCode.toUpperCase()) {
      case 'US':
        return const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF3b82f6), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'GB':
        return const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFFef4444), Color(0xFFffffff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'JP':
        return const LinearGradient(
          colors: [Color(0xFFffffff), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'DE':
        return const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFFef4444), Color(0xFFfbbf24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'FR':
        return const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFFffffff), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'CN':
        return const LinearGradient(
          colors: [Color(0xFFdc2626), Color(0xFFfbbf24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'KR':
        return const LinearGradient(
          colors: [Color(0xFFffffff), Color(0xFF1e3a8a), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'IN':
        return const LinearGradient(
          colors: [Color(0xFFf97316), Color(0xFFffffff), Color(0xFF22c55e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'BR':
        return const LinearGradient(
          colors: [Color(0xFF22c55e), Color(0xFFfbbf24), Color(0xFF1e3a8a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'AU':
        return const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFFdc2626), Color(0xFFffffff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'CA':
        return const LinearGradient(
          colors: [Color(0xFFdc2626), Color(0xFFffffff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'IT':
        return const LinearGradient(
          colors: [Color(0xFF22c55e), Color(0xFFffffff), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ES':
        return const LinearGradient(
          colors: [Color(0xFFdc2626), Color(0xFFfbbf24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'MX':
        return const LinearGradient(
          colors: [Color(0xFF22c55e), Color(0xFFffffff), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'RU':
        return const LinearGradient(
          colors: [Color(0xFFffffff), Color(0xFF1e3a8a), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          gradient: _getGradient(code),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(isSelected ? 0.2 : 0.3),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 国コードバッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  code.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 国名
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
