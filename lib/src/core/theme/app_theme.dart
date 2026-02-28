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
    tertiary: Color(0xFF5A7A8C),
    onTertiary: Colors.white,
    error: Color(0xFFEB5757),
    onError: Colors.white,
    primaryContainer: Color(0xFFE3E4E6),
    onPrimaryContainer: Color(0xFF111213),
    secondaryContainer: Color(0xFFE8E8E6),
    onSecondaryContainer: Color(0xFF1A1D1E),
    tertiaryContainer: Color(0xFFDDE6EB),
    onTertiaryContainer: Color(0xFF15242C),
    errorContainer: Color(0xFFFDECEC),
    onErrorContainer: Color(0xFF5C1B1B),
    surface: Colors.white,
    onSurface: Color(0xFF2F3437),
    onSurfaceVariant: Color(0xFF787774),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFDFDFD),
    surfaceContainer: Color(0xFFFCFCFB),
    surfaceContainerHigh: Color(0xFFFAFAF9),
    surfaceContainerHighest: Color(0xFFF7F7F5),
    outline: Color(0xFFE9E9E7),
    outlineVariant: Color(0xFFF3F3F2),
    inverseSurface: Color(0xFF2F3437),
    onInverseSurface: Color(0xFFF1F1EF),
    inversePrimary: Color(0xFFD4D4D4),
    scrim: Colors.black,
    shadow: Color(0xFF0F1112),
  );

  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: Color(0xFFEBEBEA),
    onPrimary: Color(0xFF191919),
    secondary: Color(0xFF2F2F2F),
    onSecondary: Color(0xFFEBEBEA),
    tertiary: Color(0xFF89A3B2),
    onTertiary: Color(0xFF0D1D26),
    error: Color(0xFFFF7369),
    onError: Colors.white,
    primaryContainer: Color(0xFF3A3E41),
    onPrimaryContainer: Color(0xFFE3E4E6),
    secondaryContainer: Color(0xFF3C3C3C),
    onSecondaryContainer: Color(0xFFF5F5F5),
    tertiaryContainer: Color(0xFF2B3F4A),
    onTertiaryContainer: Color(0xFFDDE6EB),
    errorContainer: Color(0xFF732B26),
    onErrorContainer: Color(0xFFFFDADB),
    surface: Color(0xFF191919),
    onSurface: Color(0xFFD4D4D4),
    onSurfaceVariant: Color(0xFF9B9A97),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    surfaceContainerLow: Color(0xFF121212),
    surfaceContainer: Color(0xFF1E1E1E),
    surfaceContainerHigh: Color(0xFF202020),
    surfaceContainerHighest: Color(0xFF252525),
    outline: Color(0xFF373737),
    outlineVariant: Color(0xFF2A2A2A),
    inverseSurface: Color(0xFFEBEBEA),
    onInverseSurface: Color(0xFF191919),
    inversePrimary: Color(0xFF2F3437),
    scrim: Colors.black,
    shadow: Colors.black,
  );

  static const ColorScheme eyeCareColorScheme = ColorScheme.light(
    primary: Color(0xFFAD7B46),
    onPrimary: Colors.white,
    secondary: Color(0xFF8A7359),
    onSecondary: Colors.white,
    tertiary: Color(0xFF6A7B59),
    onTertiary: Colors.white,
    error: Color(0xFFB85D5D),
    onError: Colors.white,
    primaryContainer: Color(0xFFEEDCC6),
    onPrimaryContainer: Color(0xFF3A240E),
    secondaryContainer: Color(0xFFE0D2C0),
    onSecondaryContainer: Color(0xFF2A2016),
    tertiaryContainer: Color(0xFFE3EEDA),
    onTertiaryContainer: Color(0xFF1B2610),
    errorContainer: Color(0xFFF9DADA),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF4ECD8),
    onSurface: Color(0xFF433422),
    onSurfaceVariant: Color(0xFF867A68),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFDF8F0),
    surfaceContainer: Color(0xFFEFE4CD),
    surfaceContainerHigh: Color(0xFFE9E0CB),
    surfaceContainerHighest: Color(0xFFDFD5BD),
    outline: Color(0xFFBCAE98),
    outlineVariant: Color(0xFFD3C5A9),
    inverseSurface: Color(0xFF342F2A),
    onInverseSurface: Color(0xFFF4EFEA),
    inversePrimary: Color(0xFFE1B890),
    scrim: Colors.black,
    shadow: Color(0xFF1A140F),
  );

  static const ColorScheme darkEyeCareColorScheme = ColorScheme.dark(
    primary: Color(0xFF967250),
    onPrimary: Color(0xFF1E140A),
    secondary: Color(0xFF75675A),
    onSecondary: Color(0xFF1C1A18),
    tertiary: Color(0xFF869976),
    onTertiary: Color(0xFF1C2610),
    error: Color(0xFF9E5656),
    onError: Color(0xFF1C1A18),
    primaryContainer: Color(0xFF5A3E24),
    onPrimaryContainer: Color(0xFFEEDCC6),
    secondaryContainer: Color(0xFF4A3E31),
    onSecondaryContainer: Color(0xFFE0D2C0),
    tertiaryContainer: Color(0xFF384729),
    onTertiaryContainer: Color(0xFFE3EEDA),
    errorContainer: Color(0xFF733434),
    onErrorContainer: Color(0xFFF9DADA),
    surface: Color(0xFF1C1A18),
    onSurface: Color(0xFFC2B8AD),
    onSurfaceVariant: Color(0xFF90867C),
    surfaceContainerLowest: Color(0xFF0F0E0D),
    surfaceContainerLow: Color(0xFF161513),
    surfaceContainer: Color(0xFF211E1C),
    surfaceContainerHigh: Color(0xFF2A2724),
    surfaceContainerHighest: Color(0xFF383430),
    outline: Color(0xFF6B625A),
    outlineVariant: Color(0xFF4A4540),
    inverseSurface: Color(0xFFEAE3DC),
    onInverseSurface: Color(0xFF342F2A),
    inversePrimary: Color(0xFFAD7B46),
    scrim: Colors.black,
    shadow: Colors.black,
  );

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
