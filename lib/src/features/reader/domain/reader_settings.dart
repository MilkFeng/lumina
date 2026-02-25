import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

enum ReaderSettingThemeMode {
  system,
  light,
  dark,

  // More themes
  eyeCare,
  darkEyeCare,
}

class ReaderSettings {
  final double zoom;
  final bool followSystemTheme;
  final ReaderSettingThemeMode themeMode;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  const ReaderSettings({
    this.zoom = 1.0,
    this.followSystemTheme = true,
    this.themeMode = ReaderSettingThemeMode.light,
    this.marginTop = 16.0,
    this.marginBottom = 16.0,
    this.marginLeft = 16.0,
    this.marginRight = 16.0,
  });

  ReaderSettings copyWith({
    double? zoom,
    bool? followSystemTheme,
    ReaderSettingThemeMode? themeMode,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
  }) {
    return ReaderSettings(
      zoom: zoom ?? this.zoom,
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
      themeMode: themeMode ?? this.themeMode,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
    );
  }

  EpubTheme toEpubTheme({required Brightness platformBrightness}) {
    ColorScheme colorScheme;
    bool shouldOverrideTextColor = true;
    if (followSystemTheme) {
      colorScheme = AppTheme.colorSchemeForBrightness(platformBrightness);
      if (platformBrightness == Brightness.light) {
        shouldOverrideTextColor = false; // Light theme uses default text color
      }
    } else {
      if (themeMode == ReaderSettingThemeMode.eyeCare) {
        colorScheme = AppTheme.eyeCareColorScheme;
      } else if (themeMode == ReaderSettingThemeMode.darkEyeCare) {
        colorScheme = AppTheme.darkEyeCareColorScheme;
      } else if (themeMode == ReaderSettingThemeMode.dark) {
        colorScheme = AppTheme.darkColorScheme;
      } else {
        colorScheme = AppTheme.lightColorScheme;
        shouldOverrideTextColor = false; // Light theme uses default text color
      }
    }

    return EpubTheme(
      zoom: zoom,
      shouldOverrideTextColor: shouldOverrideTextColor,
      colorScheme: colorScheme,
      padding: EdgeInsets.only(
        top: marginTop,
        bottom: marginBottom,
        left: marginLeft,
        right: marginRight,
      ),
    );
  }
}
