import 'package:flutter/material.dart';

class EpubTheme {
  final double zoom;
  final bool shouldOverrideTextColor;
  final ColorScheme colorScheme;
  final EdgeInsets padding;

  EpubTheme({
    required this.zoom,
    required this.shouldOverrideTextColor,
    required this.colorScheme,
    required this.padding,
  });

  bool get isDark => colorScheme.brightness == Brightness.dark;

  Color get surfaceColor => colorScheme.surface;

  EpubTheme copyWith({
    double? zoom,
    bool? shouldOverrideTextColor,
    ColorScheme? colorScheme,
    EdgeInsets? padding,
  }) {
    return EpubTheme(
      zoom: zoom ?? this.zoom,
      shouldOverrideTextColor:
          shouldOverrideTextColor ?? this.shouldOverrideTextColor,
      colorScheme: colorScheme ?? this.colorScheme,
      padding: padding ?? this.padding,
    );
  }
}
