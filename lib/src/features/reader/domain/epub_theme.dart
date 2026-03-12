import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/data/reader_scripts.dart';

class EpubTheme {
  final double zoom;
  final bool shouldOverrideTextColor;
  final ColorScheme colorScheme;
  final Color? overridePrimaryColor;
  final EdgeInsets padding;

  /// File name (with extension) of the custom font, or null for epub default.
  final String? fontFileName;

  /// When true, force the custom font on top of the epub's own font rules.
  final bool overrideFontFamily;

  EpubTheme({
    required this.zoom,
    required this.shouldOverrideTextColor,
    required this.colorScheme,
    this.overridePrimaryColor,
    required this.padding,
    this.fontFileName,
    this.overrideFontFamily = false,
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
    Object? fontFileName = _kUnset,
    bool? overrideFontFamily,
  }) {
    return EpubTheme(
      zoom: zoom ?? this.zoom,
      shouldOverrideTextColor:
          shouldOverrideTextColor ?? this.shouldOverrideTextColor,
      colorScheme: colorScheme ?? this.colorScheme,
      overridePrimaryColor: overridePrimaryColor ?? this.overridePrimaryColor,
      padding: padding ?? this.padding,
      fontFileName: identical(fontFileName, _kUnset)
          ? this.fontFileName
          : fontFileName as String?,
      overrideFontFamily: overrideFontFamily ?? this.overrideFontFamily,
    );
  }

  static const Object _kUnset = Object();

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
      'surfaceColor': colorToHex(colorScheme.surface),
      'onSurfaceColor': colorToHex(colorScheme.onSurface),
      'primaryContainerColor': colorToHex(colorScheme.primaryContainer),
      'onSurfaceVariantColor': colorToHex(colorScheme.onSurfaceVariant),
      'outlineVariantColor': colorToHex(colorScheme.outlineVariant),
      'surfaceContainerColor': colorToHex(colorScheme.surfaceContainer),
      'surfaceContainerHighColor': colorToHex(colorScheme.surfaceContainerHigh),

      'overridePrimaryColor': overridePrimaryColor != null
          ? colorToHex(overridePrimaryColor!)
          : null,
      'padding': {'top': padding.top, 'left': padding.left},
      'fontFileName': fontFileName,
      'overrideFontFamily': overrideFontFamily,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EpubTheme &&
        other.zoom == zoom &&
        other.shouldOverrideTextColor == shouldOverrideTextColor &&
        other.colorScheme == colorScheme &&
        other.overridePrimaryColor == overridePrimaryColor &&
        other.padding == padding &&
        other.fontFileName == fontFileName &&
        other.overrideFontFamily == overrideFontFamily;
  }

  @override
  int get hashCode => Object.hash(
    zoom,
    shouldOverrideTextColor,
    colorScheme,
    overridePrimaryColor,
    padding,
    fontFileName,
    overrideFontFamily,
  );
}
