import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

enum ReaderSettingThemeMode {
  light,
  dark,

  // More themes
  eyeCare,
  darkEyeCare,
}

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
  final ReaderSettingThemeMode themeMode;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final ReaderLinkHandling linkHandling;
  final bool handleIntraLink;

  const ReaderSettings({
    this.zoom = 1.0,
    this.followAppTheme = true,
    this.themeMode = ReaderSettingThemeMode.light,
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
    ReaderSettingThemeMode? themeMode,
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
      themeMode: themeMode ?? this.themeMode,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      linkHandling: linkHandling ?? this.linkHandling,
      handleIntraLink: handleIntraLink ?? this.handleIntraLink,
    );
  }

  EpubTheme toEpubTheme({required ColorScheme appColorScheme}) {
    const kOverridePrimaryColorForDark = Color(0xFF7B9CAE);

    ColorScheme colorScheme;
    bool shouldOverrideTextColor = true;
    Color? overridePrimaryColor;

    if (followAppTheme) {
      colorScheme = appColorScheme;
      if (appColorScheme.brightness == Brightness.light) {
        shouldOverrideTextColor = false;
      } else {
        overridePrimaryColor = kOverridePrimaryColorForDark;
      }
    } else {
      if (themeMode == ReaderSettingThemeMode.eyeCare) {
        colorScheme = AppTheme.eyeCareColorScheme;
      } else if (themeMode == ReaderSettingThemeMode.darkEyeCare) {
        colorScheme = AppTheme.darkEyeCareColorScheme;
      } else if (themeMode == ReaderSettingThemeMode.dark) {
        colorScheme = AppTheme.darkColorScheme;
        overridePrimaryColor = kOverridePrimaryColorForDark;
      } else {
        colorScheme = AppTheme.lightColorScheme;
        shouldOverrideTextColor = false; // Light theme uses default text color
      }
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
}
