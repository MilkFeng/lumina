import 'package:flutter/material.dart';

class EpubTheme {
  final double zoom;
  final ColorScheme colorScheme;
  final EdgeInsets padding;

  EpubTheme({
    required this.zoom,
    required this.colorScheme,
    required this.padding,
  });

  bool get isDark => colorScheme.brightness == Brightness.dark;

  /// Computes a text color that contrasts well with the background color.
  /// If the theme is dark, it returns the `onSurface` color from the color scheme.
  /// If the theme is light, it returns null, allowing the default text color to be
  /// used, which should contrast well with the light background.
  Color? get textColorForWeb => isDark ? colorScheme.onSurface : null;

  Color get surfaceColor => colorScheme.surface;

  EpubTheme copyWith({
    double? zoom,
    ColorScheme? colorScheme,
    EdgeInsets? padding,
  }) {
    return EpubTheme(
      zoom: zoom ?? this.zoom,
      colorScheme: colorScheme ?? this.colorScheme,
      padding: padding ?? this.padding,
    );
  }
}
