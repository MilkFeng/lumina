import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';

/// Determines which ThemeMode the app uses.
enum AppThemeMode { system, light, dark }

/// Selects one of the available light-mode color schemes.
enum AppLightThemeVariant { standard, eyeCare, matcha }

/// Selects one of the available dark-mode color schemes.
enum AppDarkThemeVariant { standard, eyeCare, matcha }

/// Persistent settings that control the app-wide color theme and
/// (optionally) the dark/light variant applied to library, detail and
/// about screens.
class AppThemeSettings {
  final AppThemeMode themeMode;
  final AppLightThemeVariant lightVariant;
  final AppDarkThemeVariant darkVariant;

  const AppThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.lightVariant = AppLightThemeVariant.standard,
    this.darkVariant = AppDarkThemeVariant.standard,
  });

  AppThemeSettings copyWith({
    AppThemeMode? themeMode,
    AppLightThemeVariant? lightVariant,
    AppDarkThemeVariant? darkVariant,
  }) {
    return AppThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      lightVariant: lightVariant ?? this.lightVariant,
      darkVariant: darkVariant ?? this.darkVariant,
    );
  }

  /// Maps to Flutter's [ThemeMode] for use in [MaterialApp].
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// The [ColorScheme] used when the app is in light mode.
  ColorScheme get lightColorScheme {
    switch (lightVariant) {
      case AppLightThemeVariant.standard:
        return AppTheme.lightColorScheme;
      case AppLightThemeVariant.eyeCare:
        return AppTheme.eyeCareColorScheme;
      case AppLightThemeVariant.matcha:
        return AppTheme.matchaLightColorScheme;
    }
  }

  /// The [ColorScheme] used when the app is in dark mode.
  ColorScheme get darkColorScheme {
    switch (darkVariant) {
      case AppDarkThemeVariant.standard:
        return AppTheme.darkColorScheme;
      case AppDarkThemeVariant.eyeCare:
        return AppTheme.darkEyeCareColorScheme;
      case AppDarkThemeVariant.matcha:
        return AppTheme.matchaDarkColorScheme;
    }
  }

  /// [ThemeData] built from the chosen light scheme.
  ThemeData get lightTheme => AppTheme.buildTheme(lightColorScheme);

  /// [ThemeData] built from the chosen dark scheme.
  ThemeData get darkTheme => AppTheme.buildTheme(darkColorScheme);

  /// Returns the color scheme that is actually active at runtime, given the
  /// current [platformBrightness].
  ColorScheme resolvedColorScheme(Brightness platformBrightness) {
    final effectiveBrightness = switch (themeMode) {
      AppThemeMode.system => platformBrightness,
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
    };
    return effectiveBrightness == Brightness.dark
        ? darkColorScheme
        : lightColorScheme;
  }

  /// Maps a [AppLightThemeVariant] to its corresponding [ColorScheme].
  static ColorScheme lightColorSchemeFor(AppLightThemeVariant variant) =>
      switch (variant) {
        AppLightThemeVariant.standard => AppTheme.lightColorScheme,
        AppLightThemeVariant.eyeCare => AppTheme.eyeCareColorScheme,
        AppLightThemeVariant.matcha => AppTheme.matchaLightColorScheme,
      };

  /// Maps a [AppDarkThemeVariant] to its corresponding [ColorScheme].
  static ColorScheme darkColorSchemeFor(AppDarkThemeVariant variant) =>
      switch (variant) {
        AppDarkThemeVariant.standard => AppTheme.darkColorScheme,
        AppDarkThemeVariant.eyeCare => AppTheme.darkEyeCareColorScheme,
        AppDarkThemeVariant.matcha => AppTheme.matchaDarkColorScheme,
      };

  /// Ordered list of every available [ColorScheme] for the reader theme picker.
  /// The list index is persisted as an integer to represent the chosen theme.
  static List<ColorScheme> get allColorSchemes => [
    AppTheme.lightColorScheme,
    AppTheme.darkColorScheme,
    AppTheme.eyeCareColorScheme,
    AppTheme.darkEyeCareColorScheme,
    AppTheme.matchaLightColorScheme,
    AppTheme.matchaDarkColorScheme,
  ];

  /// For reader themes that use a custom primary color in dark mode, this provides
  /// a parallel list of the override primary color (or null if no override needed)
  static List<Color?> get allOverridePrimaryColors => [
    null, // standard light
    const Color(0xFF7B9CAE), // standard dark
    null, // eye care light
    null, // eye care dark
    null, // matcha light
    null, // matcha dark
  ];

  static List<bool> get allShouldOverrideTextColor => [
    false, // standard light
    true, // standard dark
    false, // eye care light
    false, // eye care dark
    false, // matcha light
    false, // matcha dark
  ];
}
