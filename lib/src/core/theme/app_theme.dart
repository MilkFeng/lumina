import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/color_schemes.dart';

/// Notion-like Minimalist Theme for Lumina Reader
/// Philosophy: Content-first, monochrome, no shadows, serif typography
class AppTheme {
  AppTheme._();

  static const int defaultAnimationDurationMs = 250;
  static const int defaultLongAnimationDurationMs = 320;
  static const int defaultPresentationDurationMs = 3 * 1000; // 3 seconds

  static ColorScheme get lightColorScheme => kLightColorScheme;
  static ColorScheme get darkColorScheme => kDarkColorScheme;

  static ColorScheme get eyeCareColorScheme => kEyeCareColorScheme;
  static ColorScheme get darkEyeCareColorScheme => kDarkEyeCareColorScheme;

  static ColorScheme get matchaLightColorScheme => kMatchaLightColorScheme;
  static ColorScheme get matchaDarkColorScheme => kMatchaDarkColorScheme;

  static ThemeData buildTheme(ColorScheme colorScheme) {
    final notionRadius = BorderRadius.circular(8.0);
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
