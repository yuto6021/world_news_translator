import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class SocialFooter extends StatelessWidget {
  const SocialFooter({super.key});

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 24.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.black.withOpacity(0.55),
                      Colors.indigo.shade900.withOpacity(0.45),
                    ]
                  : [
                      Colors.white.withOpacity(0.70),
                      Colors.indigo.shade50.withOpacity(0.55),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color:
                    (isDark ? Colors.indigo.shade300 : Colors.indigo.shade200)
                        .withOpacity(0.4),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon:
                        const FaIcon(FontAwesomeIcons.facebook, size: iconSize),
                    onPressed: () => _launchUrl('https://facebook.com/'),
                    tooltip: 'Facebook',
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon:
                        const FaIcon(FontAwesomeIcons.twitter, size: iconSize),
                    onPressed: () => _launchUrl('https://twitter.com/'),
                    tooltip: 'Twitter',
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.instagram,
                        size: iconSize),
                    onPressed: () => _launchUrl('https://instagram.com/'),
                    tooltip: 'Instagram',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      (isDark ? Colors.black : Colors.white).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark
                            ? Colors.indigo.shade300
                            : Colors.indigo.shade200)
                        .withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public,
                        size: 18,
                        color: isDark
                            ? Colors.indigo.shade100
                            : Colors.indigo.shade700),
                    const SizedBox(width: 6),
                    Text(
                      '翻訳で広がる視野 – 世界を読む',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: isDark
                            ? Colors.grey.shade100
                            : Colors.indigo.shade700,
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
