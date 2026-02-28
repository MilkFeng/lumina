import 'package:flutter/material.dart';

/// Notion-like Minimalist Theme for Lumina Reader
/// Philosophy: Content-first, monochrome, no shadows, serif typography
class AppTheme {
  AppTheme._();

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
    surfaceContainerHigh: Color(0xFFFAFAF9),
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
    surfaceContainerHigh: Color(0xFF202020),
    onSurfaceVariant: Color(0xFF9B9A97),
    outline: Color(0xFF373737),
    outlineVariant: Color(0xFF2A2A2A),
  );

  static const ColorScheme eyeCareColorScheme = ColorScheme.light(
    primary: Color(0xFFAD7B46),
    onPrimary: Colors.white,
    secondary: Color(0xFF8A7359),
    onSecondary: Colors.white,
    error: Color(0xFFB85D5D),
    onError: Colors.white,
    surface: Color(0xFFF4ECD8),
    onSurface: Color(0xFF433422),
    surfaceContainerHighest: Color(0xFFDFD5BD),
    surfaceContainerHigh: Color(0xFFE9E0CB),
    onSurfaceVariant: Color(0xFF867A68),
    outline: Color(0xFFBCAE98),
    outlineVariant: Color(0xFFD3C5A9),
  );

  static const ColorScheme darkEyeCareColorScheme = ColorScheme.dark(
    primary: Color(0xFF967250),
    onPrimary: Color(0xFF1E140A),
    secondary: Color(0xFF75675A),
    onSecondary: Color(0xFF1C1A18),
    error: Color(0xFF9E5656),
    onError: Color(0xFF1C1A18),
    surface: Color(0xFF1C1A18),
    onSurface: Color(0xFFC2B8AD),
    surfaceContainerHighest: Color(0xFF383430),
    surfaceContainerHigh: Color(0xFF2A2724),
    onSurfaceVariant: Color(0xFF90867C),
    outline: Color(0xFF6B625A),
    outlineVariant: Color(0xFF4A4540),
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
          fontSize: 20,
          fontWeight: FontWeight.w500,
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
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
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

    final baseWithFontAndColor = baseTextTheme.apply(
      bodyColor: mainColor,
      displayColor: mainColor,
    );

    return baseWithFontAndColor;
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
