// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_service.dart';
import 'widgets/konami_code_detector.dart';

Future<void> main() async {
  // .envファイルの読み込み（APIキーなど）
  await dotenv.load();

  runApp(const WorldNewsApp());
}

class WorldNewsApp extends StatelessWidget {
  const WorldNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, ThemeMode mode, _) {
        return MaterialApp(
          themeMode: mode,
          title: 'World News Translator',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: Colors.white,
            textTheme: TextTheme(
              titleLarge: GoogleFonts.notoSans(
                  fontSize: 20, fontWeight: FontWeight.bold),
              titleMedium: GoogleFonts.notoSans(
                  fontSize: 16, fontWeight: FontWeight.w600),
              bodyMedium: GoogleFonts.notoSans(fontSize: 15),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: Color(0xFF1A1A1A),
            cardColor: Color(0xFF242424),
            textTheme: TextTheme(
              titleLarge: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              titleMedium: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              bodyMedium: GoogleFonts.notoSans(
                  fontSize: 15, color: Colors.grey.shade300),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              backgroundColor: Color(0xFF242424),
              foregroundColor: Colors.grey.shade100,
              elevation: 0,
            ),
          ),
          home: const KonamiCodeDetector(
            child: HomeScreen(),
          ),
        );
      },
    );
  }
}
