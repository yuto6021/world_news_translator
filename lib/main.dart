// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'services/reading_mode_service.dart';
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
        // Ensure reading mode prefs loaded early
        ReadingModeService.instance.load();
        return MaterialApp(
          themeMode: mode,
          title: 'World News Translator',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/profile': (_) => const ProfileScreen(),
          },
          home: const KonamiCodeDetector(child: HomeScreen()),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final rm = ReadingModeService.instance;
    final baseFontScale = rm.fontScale.value;
    final lineHeight = rm.lineHeight.value;
    final useAltFont =
        rm.dyslexicFont.value; // could later swap to different font package
    final highContrast = rm.highContrast.value;

    final baseTextStyle = useAltFont
        ? GoogleFonts.notoSerif(fontSize: 15 * baseFontScale)
        : GoogleFonts.notoSans(fontSize: 15 * baseFontScale);

    ColorScheme colorScheme = brightness == Brightness.light
        ? const ColorScheme.light(primary: Colors.indigo)
        : const ColorScheme.dark(primary: Colors.indigo);
    if (highContrast) {
      colorScheme = brightness == Brightness.light
          ? const ColorScheme.highContrastLight(primary: Colors.indigo)
          : const ColorScheme.highContrastDark(primary: Colors.indigo);
    }
    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: TextTheme(
        titleLarge: (useAltFont
                ? GoogleFonts.notoSerif(
                    fontSize: 20 * baseFontScale,
                    fontWeight: FontWeight.bold,
                  )
                : GoogleFonts.notoSans(
                    fontSize: 20 * baseFontScale,
                    fontWeight: FontWeight.bold,
                  ))
            .copyWith(height: lineHeight),
        titleMedium: (useAltFont
                ? GoogleFonts.notoSerif(
                    fontSize: 16 * baseFontScale,
                    fontWeight: FontWeight.w600,
                  )
                : GoogleFonts.notoSans(
                    fontSize: 16 * baseFontScale,
                    fontWeight: FontWeight.w600,
                  ))
            .copyWith(height: lineHeight),
        bodyMedium: baseTextStyle.copyWith(height: lineHeight),
        bodySmall: baseTextStyle.copyWith(
            fontSize: 13 * baseFontScale, height: lineHeight),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF242424),
        foregroundColor: brightness == Brightness.light
            ? Colors.indigo
            : Colors.grey.shade100,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
    );
  }
}
