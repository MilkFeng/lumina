import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme_settings.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

/// Controls how the reader handles external link taps.
enum ReaderLinkHandling { ask, always, never }

class ReaderSettings {
  final double zoom;
  final bool followAppTheme;

  /// Index into [AppThemeSettings.allColorSchemes] representing the reader theme.
  final int themeIndex;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final ReaderLinkHandling linkHandling;
  final bool handleIntraLink;

  const ReaderSettings({
    this.zoom = 1.0,
    this.followAppTheme = true,
    this.themeIndex = 0,
    this.marginTop = 16.0,
    this.marginBottom = 16.0,
    this.marginLeft = 16.0,
    this.marginRight = 16.0,
    this.linkHandling = ReaderLinkHandling.ask,
    this.handleIntraLink = true,
  });

  ReaderSettings copyWith({
    double? zoom,
    bool? followAppTheme,
    int? themeIndex,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    ReaderLinkHandling? linkHandling,
    bool? handleIntraLink,
  }) {
    return ReaderSettings(
      zoom: zoom ?? this.zoom,
      followAppTheme: followAppTheme ?? this.followAppTheme,
      themeIndex: themeIndex ?? this.themeIndex,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      linkHandling: linkHandling ?? this.linkHandling,
      handleIntraLink: handleIntraLink ?? this.handleIntraLink,
    );
  }

  EpubTheme toEpubTheme(BuildContext context) {
    final appColorScheme = Theme.of(context).colorScheme;
    final appPreset =
        Theme.of(context).extension<LuminaThemeExtension>()?.preset ??
        LuminaThemePreset.standardLight;

    final LuminaThemePreset preset;
    final ColorScheme colorScheme;

    if (followAppTheme) {
      preset = appPreset;
      colorScheme = appColorScheme;
    } else {
      preset = currentPreset;
      colorScheme = currentPreset.colorScheme;
    }

    return EpubTheme(
      zoom: zoom,
      shouldOverrideTextColor: preset.shouldOverrideTextColor,
      colorScheme: colorScheme,
      overridePrimaryColor: preset.overridePrimaryColor,
      padding: EdgeInsets.only(
        top: marginTop,
        bottom: marginBottom,
        left: marginLeft,
        right: marginRight,
      ),
    );
  }

  /// The [LuminaThemePreset] currently selected by [themeIndex].
  LuminaThemePreset get currentPreset =>
      LuminaThemePreset.fromIndex(themeIndex);

  /// The [ColorScheme] currently selected from [LuminaThemePreset].
  ColorScheme get currentColorScheme => currentPreset.colorScheme;
}
