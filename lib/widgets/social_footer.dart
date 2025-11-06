import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.facebook, size: iconSize),
            onPressed: () => _launchUrl('https://facebook.com/'),
            tooltip: 'Facebook',
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.twitter, size: iconSize),
            onPressed: () => _launchUrl('https://twitter.com/'),
            tooltip: 'Twitter',
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.instagram, size: iconSize),
            onPressed: () => _launchUrl('https://instagram.com/'),
            tooltip: 'Instagram',
          ),
        ],
      ),
    );
  }
}
