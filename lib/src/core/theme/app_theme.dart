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

  static const ColorScheme sepiaColorScheme = ColorScheme.light(
    surface: Color(0xFFF4ECD8),
    onSurface: Color(0xFF433422),
    surfaceContainerHigh: Color(0xFFE9E0CB),
    surfaceContainerHighest: Color(0xFFDFD5BD),
    outlineVariant: Color(0xFFD3C5A9),
    primary: Color(0xFFAD7B46),
    onPrimary: Colors.white,
    secondary: Color(0xFF8A7359),
    onSecondary: Colors.white,
    error: Color(0xFFB85D5D),
    onError: Colors.white,
  );

  static ColorScheme colorSchemeForBrightness(Brightness brightness) {
    return brightness == Brightness.light ? lightColorScheme : darkColorScheme;
  }

  /// Light Theme
  static ThemeData get lightTheme {
    return buildTheme(lightColorScheme);
  }

  /// Dark Theme - Optional monochrome variant
  static ThemeData get darkTheme {
    return buildTheme(darkColorScheme);
  }

  static ThemeData buildTheme(ColorScheme colorScheme) {
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

    final mainColor = colorScheme.onSurface;
    final mutedColor = colorScheme.onSurfaceVariant;
    // final primaryColor = colorScheme.primary;

    final baseWithFontAndColor = baseTextTheme.apply(
      fontFamily: _fontFamily,
      fontFamilyFallback: _defaultFallback,
      bodyColor: mainColor,
      displayColor: mainColor,
    );

    return baseWithFontAndColor.copyWith(
      displayLarge: baseWithFontAndColor.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
      ),
      displayMedium: baseWithFontAndColor.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
      ),
      displaySmall: baseWithFontAndColor.displaySmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: baseWithFontAndColor.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseWithFontAndColor.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600, // SemiBold
      ),
      headlineSmall: baseWithFontAndColor.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseWithFontAndColor.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseWithFontAndColor.titleMedium?.copyWith(
        fontWeight: FontWeight.w500, // Medium
      ),
      titleSmall: baseWithFontAndColor.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseWithFontAndColor.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseWithFontAndColor.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      bodySmall: baseWithFontAndColor.bodySmall?.copyWith(
        fontWeight: FontWeight.w300,
        color: mutedColor,
      ),
      labelLarge: baseWithFontAndColor.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        // color: primaryColor,
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
