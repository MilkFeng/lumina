// lib/src/features/reader/domain/reader_settings.dart
import 'package:flutter/material.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

class ReaderSettings {
  final double zoom;
  final bool followSystemTheme;
  final ThemeMode themeMode;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  const ReaderSettings({
    this.zoom = 1.0,
    this.followSystemTheme = true,
    this.themeMode = ThemeMode.light,
    this.marginTop = 16.0,
    this.marginBottom = 16.0,
    this.marginLeft = 16.0,
    this.marginRight = 16.0,
  });

  ReaderSettings copyWith({
    double? zoom,
    bool? followSystemTheme,
    ThemeMode? themeMode,
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

  EpubTheme toEpubTheme(ColorScheme colorScheme) {
    return EpubTheme(
      surfaceColor: colorScheme.surface,
      onSurfaceColor: colorScheme.onSurface,
      padding: EdgeInsets.only(
        top: marginTop,
        bottom: marginBottom,
        left: marginLeft,
        right: marginRight,
      ),
    );
  }
}
