// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/pet.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'services/reading_mode_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_service.dart';
import 'widgets/konami_code_detector.dart';
import 'services/streak_service.dart';
import 'services/comments_service.dart';
import 'services/achievements_service.dart';
import 'services/game_scores_service.dart';
import 'services/reading_time_service.dart';
import 'services/shop_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive初期化
  await Hive.initFlutter();
  // Hiveアダプタ登録（PetModel）
  try {
    Hive.registerAdapter(PetModelAdapter());
  } catch (_) {
    // 既に登録済みの場合は無視
  }

  // 各種サービス初期化
  await CommentsService.init();
  await AchievementsService.init();
  await GameScoresService.init();
  await ReadingTimeService.init();

  // .envファイルの読み込み（APIキーなど）
  await dotenv.load();

  // 起動時にストリーク更新
  await StreakService.instance.onAppOpen();

  runApp(const WorldNewsApp());
}

class WorldNewsApp extends StatefulWidget {
  const WorldNewsApp({super.key});

  @override
  State<WorldNewsApp> createState() => _WorldNewsAppState();
}

class _WorldNewsAppState extends State<WorldNewsApp> {
  Color _primaryColor = Colors.indigo;
  Color _accentColor = const Color(0xFFFF4081);

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final colors = await ShopService.getActiveThemeColors();
    setState(() {
      _primaryColor =
          Color(int.parse(colors['primary_color'].replaceFirst('#', '0xFF')));
      _accentColor =
          Color(int.parse(colors['accent_color'].replaceFirst('#', '0xFF')));
    });
  }

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
          theme: _buildTheme(Brightness.light, _primaryColor),
          darkTheme: _buildTheme(Brightness.dark, _primaryColor),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/profile': (_) => const ProfileScreen(),
          },
          home: const KonamiCodeDetector(child: HomeScreen()),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness, Color primaryColor) {
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
        ? ColorScheme.light(primary: primaryColor)
        : ColorScheme.dark(primary: primaryColor);
    if (highContrast) {
      colorScheme = brightness == Brightness.light
          ? ColorScheme.highContrastLight(primary: primaryColor)
          : ColorScheme.highContrastDark(primary: primaryColor);
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
