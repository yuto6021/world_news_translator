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
    // 各国の国旗をベースにした実際の配色（より正確に）
    switch (countryCode.toUpperCase()) {
      case 'US': // アメリカ：赤・白・青
        return const LinearGradient(
          colors: [Color(0xFFB22234), Color(0xFFFFFFFF), Color(0xFF3C3B6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'GB': // イギリス：赤・白・青
        return const LinearGradient(
          colors: [Color(0xFF012169), Color(0xFFFFFFFF), Color(0xFFC8102E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'JP': // 日本：白・赤
        return const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFBC002D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'DE': // ドイツ：黒・赤・金
        return const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFFDD0000), Color(0xFFFFCE00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'FR': // フランス：青・白・赤
        return const LinearGradient(
          colors: [Color(0xFF0055A4), Color(0xFFFFFFFF), Color(0xFFEF4135)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'CN': // 中国：赤・黄
        return const LinearGradient(
          colors: [Color(0xFFDE2910), Color(0xFFFFDE00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'KR': // 韓国：白・赤・青
        return const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFC60C30), Color(0xFF003478)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'IN': // インド：オレンジ・白・緑
        return const LinearGradient(
          colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'BR': // ブラジル：緑・黄・青
        return const LinearGradient(
          colors: [Color(0xFF009C3B), Color(0xFFFFDF00), Color(0xFF002776)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'AU': // オーストラリア：赤・白・青
        return const LinearGradient(
          colors: [Color(0xFF00008B), Color(0xFFFFFFFF), Color(0xFFFF0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'CA': // カナダ：赤・白
        return const LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'IT': // イタリア：緑・白・赤
        return const LinearGradient(
          colors: [Color(0xFF009246), Color(0xFFFFFFFF), Color(0xFFCE2B37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ES': // スペイン：赤・黄
        return const LinearGradient(
          colors: [Color(0xFFC60B1E), Color(0xFFFFC400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'MX': // メキシコ：緑・白・赤
        return const LinearGradient(
          colors: [Color(0xFF006847), Color(0xFFFFFFFF), Color(0xFFCE1126)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'RU': // ロシア：白・青・赤
        return const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFF0039A6), Color(0xFFD52B1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'NL': // オランダ：赤・白・青
        return const LinearGradient(
          colors: [Color(0xFFAE1C28), Color(0xFFFFFFFF), Color(0xFF21468B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'AR': // アルゼンチン：空色・白
        return const LinearGradient(
          colors: [Color(0xFF74ACDF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ZA': // 南アフリカ：緑・黄・赤
        return const LinearGradient(
          colors: [Color(0xFF007A4D), Color(0xFFFFB81C), Color(0xFFE03C31)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'TR': // トルコ：赤・白
        return const LinearGradient(
          colors: [Color(0xFFE30A17), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'SE': // スウェーデン：青・黄
        return const LinearGradient(
          colors: [Color(0xFF006AA7), Color(0xFFFECC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'NO': // ノルウェー：赤・白・青
        return const LinearGradient(
          colors: [Color(0xFFBA0C2F), Color(0xFFFFFFFF), Color(0xFF00205B)],
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
              // 国旗画像またはコードバッジ
              _buildFlagOrBadge(),
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

  Widget _buildFlagOrBadge() {
    final flagPath = 'assets/flags/${code.toLowerCase()}.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 28,
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
        child: Image.asset(
          flagPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 画像がない場合はコードバッジにフォールバック
            return Center(
              child: Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 1,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
