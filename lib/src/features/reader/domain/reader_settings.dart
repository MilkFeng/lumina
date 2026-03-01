import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme_settings.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

/// Controls how the reader handles external link taps.
enum ReaderLinkHandling {
  /// Show a confirmation dialog before opening external links.
  ask,

  /// Open external links directly without asking.
  always,

  /// Ignore external link taps entirely.
  never,
}

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

  EpubTheme toEpubTheme({required ColorScheme appColorScheme}) {
    ColorScheme colorScheme;
    bool shouldOverrideTextColor = true;
    Color? overridePrimaryColor;

    if (followAppTheme) {
      colorScheme = appColorScheme;
      final index = AppThemeSettings.allColorSchemes.indexOf(appColorScheme);
      overridePrimaryColor = AppThemeSettings.allOverridePrimaryColors[index];
      shouldOverrideTextColor =
          AppThemeSettings.allShouldOverrideTextColor[index];
    } else {
      final schemes = AppThemeSettings.allColorSchemes;
      final index = themeIndex.clamp(0, schemes.length - 1);
      colorScheme = schemes[index];
      overridePrimaryColor = AppThemeSettings.allOverridePrimaryColors[index];
      shouldOverrideTextColor =
          AppThemeSettings.allShouldOverrideTextColor[index];
    }

    return EpubTheme(
      zoom: zoom,
      shouldOverrideTextColor: shouldOverrideTextColor,
      colorScheme: colorScheme,
      overridePrimaryColor: overridePrimaryColor,
      padding: EdgeInsets.only(
        top: marginTop,
        bottom: marginBottom,
        left: marginLeft,
        right: marginRight,
      ),
    );
  }

  /// The [ColorScheme] currently selected from [AppThemeSettings.allColorSchemes].
  ColorScheme get currentColorScheme {
    final schemes = AppThemeSettings.allColorSchemes;
    return schemes[themeIndex.clamp(0, schemes.length - 1)];
  }
}
