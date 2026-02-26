import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/data/reader_scripts.dart';

class EpubTheme {
  final double zoom;
  final bool shouldOverrideTextColor;
  final ColorScheme colorScheme;
  final Color? overridePrimaryColor;
  final EdgeInsets padding;

  EpubTheme({
    required this.zoom,
    required this.shouldOverrideTextColor,
    required this.colorScheme,
    this.overridePrimaryColor,
    required this.padding,
  });

  bool get isDark => colorScheme.brightness == Brightness.dark;

  Color get surfaceColor => colorScheme.surface;

  ThemeData get themeData => AppTheme.buildTheme(colorScheme);

  EpubTheme copyWith({
    double? zoom,
    bool? shouldOverrideTextColor,
    ColorScheme? colorScheme,
    Color? overridePrimaryColor,
    EdgeInsets? padding,
  }) {
    return EpubTheme(
      zoom: zoom ?? this.zoom,
      shouldOverrideTextColor:
          shouldOverrideTextColor ?? this.shouldOverrideTextColor,
      colorScheme: colorScheme ?? this.colorScheme,
      overridePrimaryColor: overridePrimaryColor ?? this.overridePrimaryColor,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zoom': zoom,
      'shouldOverrideTextColor': shouldOverrideTextColor,

      'primaryColor': colorToHex(colorScheme.primary),
      'onPrimaryColor': colorToHex(colorScheme.onPrimary),
      'secondaryColor': colorToHex(colorScheme.secondary),
      'onSecondaryColor': colorToHex(colorScheme.onSecondary),
      'errorColor': colorToHex(colorScheme.error),
      'onErrorColor': colorToHex(colorScheme.onError),
      'backgroundColor': colorToHex(colorScheme.surface),
      'defaultTextColor': colorToHex(colorScheme.onSurface),
      'primaryContainerColor': colorToHex(colorScheme.primaryContainer),
      'onSurfaceVariantColor': colorToHex(colorScheme.onSurfaceVariant),
      'outlineVariantColor': colorToHex(colorScheme.outlineVariant),
      'surfaceContainerColor': colorToHex(colorScheme.surfaceContainer),
      'surfaceContainerHighColor': colorToHex(colorScheme.surfaceContainerHigh),

      'overridePrimaryColor': overridePrimaryColor != null
          ? colorToHex(overridePrimaryColor!)
          : null,
      'padding': {
        'top': padding.top,
        'left': padding.left,
        'right': padding.right,
        'bottom': padding.bottom,
      },
    };
  }
}
