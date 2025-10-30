import 'package:flutter/material.dart';
import 'country_news_screen.dart';
import 'trending_screen.dart';
import '../utils/constants.dart';
import '../widgets/country_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('世界のニュースを日本語で読む')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: '国名で検索',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      final code = countryCodes[value.trim().toLowerCase()];
                      if (code != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CountryNewsScreen(
                                countryCode: code, countryName: value),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 2,
                    children: countryCodes.entries.map((entry) {
                      return CountryTab(name: entry.key, code: entry.value);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 2,
            child: TrendingScreen(),
          ),
        ],
      ),
    );
  }
}
