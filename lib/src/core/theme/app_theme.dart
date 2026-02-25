import 'package:flutter/material.dart';

/// Notion-like Minimalist Theme for Lumina Reader
/// Philosophy: Content-first, monochrome, no shadows, serif typography
class AppTheme {
  AppTheme._();

  // Font Family - Elegant Serif for a literary feel
  static const String _fontFamily = 'AppSerif';

  // Content Font Family - Slightly softer serif for body text
  static const String fontFamilyContent = 'AppSerifContent';
  static const TextStyle contentTextStyle = TextStyle(
    fontFamily: fontFamilyContent,
    fontWeight: FontWeight.w400,
  );

  static const List<String> _defaultFallback = [
    "AppSerifContent",
    "Songti SC",
    "STSong",
    "Noto Serif CJK SC",
    "Source Han Serif SC",
    'SimSun',
    'serif',
  ];

  static const int defaultAnimationDurationMs = 250;
  static const int defaultLongAnimationDurationMs = 320;
  static const int defaultPresentationDurationMs = 3 * 1000; // 3 seconds

  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: Color(0xFF2F3437),
    onPrimary: Colors.white,
    secondary: Color(0xFFF1F1EF),
    onSecondary: Color(0xFF2F3437),
    error: Color(0xFFEB5757),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF2F3437),
    surfaceContainerHighest: Color(0xFFF7F7F5),
    onSurfaceVariant: Color(0xFF787774),
    outline: Color(0xFFE9E9E7),
    outlineVariant: Color(0xFFF3F3F2),
  );

  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: Color(0xFFEBEBEA),
    onPrimary: Color(0xFF191919),
    secondary: Color(0xFF2F2F2F),
    onSecondary: Color(0xFFEBEBEA),
    error: Color(0xFFFF7369),
    onError: Colors.white,
    surface: Color(0xFF191919),
    onSurface: Color(0xFFD4D4D4),
    surfaceContainerHighest: Color(0xFF252525),
    onSurfaceVariant: Color(0xFF9B9A97),
    outline: Color(0xFF373737),
    outlineVariant: Color(0xFF2A2A2A),
  );

  static ColorScheme colorSchemeForBrightness(Brightness brightness) {
    return brightness == Brightness.light ? lightColorScheme : darkColorScheme;
  }

  /// Light Theme
  static ThemeData get lightTheme {
    return _buildTheme(lightColorScheme);
  }

  /// Dark Theme - Optional monochrome variant
  static ThemeData get darkTheme {
    return _buildTheme(darkColorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final notionRadius = BorderRadius.circular(4.0);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: colorScheme.surface,
      pageTransitionsTheme: pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: notionRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: notionRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: notionRadius,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: notionRadius),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline, width: 1),
          shape: RoundedRectangleBorder(borderRadius: notionRadius),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: notionRadius,
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      textTheme: _buildTextTheme(colorScheme),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final brightness = colorScheme.brightness;
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    final baseWithFont = baseTextTheme.apply(
      fontFamily: _fontFamily,
      fontFamilyFallback: _defaultFallback,
    );

    final mainColor = colorScheme.primary;
    final mutedColor = colorScheme.onSurfaceVariant;

    return baseWithFont.copyWith(
      displayLarge: baseWithFont.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: mainColor,
      ),
      displayMedium: baseWithFont.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: mainColor,
      ),
      displaySmall: baseWithFont.displaySmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: mainColor,
      ),
      headlineLarge: baseWithFont.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: mainColor,
      ),
      headlineMedium: baseWithFont.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600, // SemiBold
        color: mainColor,
      ),
      headlineSmall: baseWithFont.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      titleLarge: baseWithFont.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      titleMedium: baseWithFont.titleMedium?.copyWith(
        fontWeight: FontWeight.w500, // Medium
        color: mainColor,
      ),
      titleSmall: baseWithFont.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: mainColor,
      ),
      bodyLarge: baseWithFont.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: mainColor,
      ),
      bodyMedium: baseWithFont.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: mainColor,
      ),
      bodySmall: baseWithFont.bodySmall?.copyWith(
        fontWeight: FontWeight.w300,
        color: mutedColor,
      ),
      labelLarge: baseWithFont.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: mainColor,
      ),
    );
  }

  static PageTransitionsTheme get pageTransitionsTheme {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );
  }
}
