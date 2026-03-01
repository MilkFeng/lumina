import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/core/theme/color_schemes.dart';

/// Determines which ThemeMode the app uses.
enum AppThemeMode { system, light, dark }

/// Selects one of the available light-mode color schemes.
enum AppLightThemeVariant { standard, eyeCare, matcha }

/// Selects one of the available dark-mode color schemes.
enum AppDarkThemeVariant { standard, eyeCare, matcha }

/// A single source of truth for every selectable theme in the app.
///
/// Enum declaration order is stable and defines the persisted [index] used by
/// [ReaderSettings.themeIndex] — never reorder or remove values.
enum LuminaThemePreset {
  // index 0
  standardLight(
    colorSchemeGetter: kLightColorScheme,
    shouldOverrideTextColor: false,
    overridePrimaryColor: null,
  ),
  // index 1
  standardDark(
    colorSchemeGetter: kDarkColorScheme,
    shouldOverrideTextColor: true,
    overridePrimaryColor: Color(0xFF7B9CAE),
  ),
  // index 2
  eyeCareLight(
    colorSchemeGetter: kEyeCareColorScheme,
    shouldOverrideTextColor: true,
    overridePrimaryColor: null,
  ),
  // index 3
  eyeCareDark(
    colorSchemeGetter: kDarkEyeCareColorScheme,
    shouldOverrideTextColor: true,
    overridePrimaryColor: null,
  ),
  // index 4
  matchaLight(
    colorSchemeGetter: kMatchaLightColorScheme,
    shouldOverrideTextColor: true,
    overridePrimaryColor: null,
  ),
  // index 5
  matchaDark(
    colorSchemeGetter: kMatchaDarkColorScheme,
    shouldOverrideTextColor: true,
    overridePrimaryColor: null,
  );

  const LuminaThemePreset({
    required ColorScheme colorSchemeGetter,

    /// For reader themes only: whether the preset's text color is guaranteed to be
    /// legible against the background. If false, the reader will not override the
    /// EPUB's default text color, allowing it to fall back to a readable color if
    /// the preset's default text color happens to be unreadable against the background.
    /// This is necessary for themes like standardLight where the default text color (black)
    /// would be unreadable against the light background of some EPUBs.
    required this.shouldOverrideTextColor,

    /// For reader themes only: a single accent color to use in place of the EPUB's default
    /// accent color. This is necessary for themes like standardDark where the default accent
    /// color (bright blue) would be unreadable against the dark background.
    required this.overridePrimaryColor,
  }) : colorScheme = colorSchemeGetter;

  final ColorScheme colorScheme;
  final bool shouldOverrideTextColor;
  final Color? overridePrimaryColor;

  /// Safely resolves a persisted integer back to a [LuminaThemePreset].
  /// Falls back to [standardLight] for out-of-range values.
  static LuminaThemePreset fromIndex(int index) {
    final values = LuminaThemePreset.values;
    if (index < 0 || index >= values.length) return standardLight;
    return values[index];
  }
}

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
        return kLightColorScheme;
      case AppLightThemeVariant.eyeCare:
        return kEyeCareColorScheme;
      case AppLightThemeVariant.matcha:
        return kMatchaLightColorScheme;
    }
  }

  /// The [ColorScheme] used when the app is in dark mode.
  ColorScheme get darkColorScheme {
    switch (darkVariant) {
      case AppDarkThemeVariant.standard:
        return kDarkColorScheme;
      case AppDarkThemeVariant.eyeCare:
        return kDarkEyeCareColorScheme;
      case AppDarkThemeVariant.matcha:
        return kMatchaDarkColorScheme;
    }
  }

  /// [ThemeData] built from the chosen light scheme, with [LuminaThemeExtension] injected.
  ThemeData get lightTheme => AppTheme.buildTheme(lightColorScheme).copyWith(
    extensions: [LuminaThemeExtension(preset: lightPresetFor(lightVariant))],
  );

  /// [ThemeData] built from the chosen dark scheme, with [LuminaThemeExtension] injected.
  ThemeData get darkTheme => AppTheme.buildTheme(darkColorScheme).copyWith(
    extensions: [LuminaThemeExtension(preset: darkPresetFor(darkVariant))],
  );

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
      lightPresetFor(variant).colorScheme;

  /// Maps a [AppDarkThemeVariant] to its corresponding [ColorScheme].
  static ColorScheme darkColorSchemeFor(AppDarkThemeVariant variant) =>
      darkPresetFor(variant).colorScheme;

  /// Maps a [AppLightThemeVariant] to its [LuminaThemePreset].
  static LuminaThemePreset lightPresetFor(AppLightThemeVariant variant) =>
      switch (variant) {
        AppLightThemeVariant.standard => LuminaThemePreset.standardLight,
        AppLightThemeVariant.eyeCare => LuminaThemePreset.eyeCareLight,
        AppLightThemeVariant.matcha => LuminaThemePreset.matchaLight,
      };

  /// Maps a [AppDarkThemeVariant] to its [LuminaThemePreset].
  static LuminaThemePreset darkPresetFor(AppDarkThemeVariant variant) =>
      switch (variant) {
        AppDarkThemeVariant.standard => LuminaThemePreset.standardDark,
        AppDarkThemeVariant.eyeCare => LuminaThemePreset.eyeCareDark,
        AppDarkThemeVariant.matcha => LuminaThemePreset.matchaDark,
      };
}

/// A [ThemeExtension] that injects the active [LuminaThemePreset] into the
/// widget tree, making it accessible via [Theme.of(context).extension<LuminaThemeExtension>()].
class LuminaThemeExtension extends ThemeExtension<LuminaThemeExtension> {
  const LuminaThemeExtension({required this.preset});

  final LuminaThemePreset preset;

  @override
  LuminaThemeExtension copyWith({LuminaThemePreset? preset}) =>
      LuminaThemeExtension(preset: preset ?? this.preset);

  /// Enums cannot be meaningfully interpolated, so snap at the midpoint.
  @override
  LuminaThemeExtension lerp(covariant LuminaThemeExtension? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
