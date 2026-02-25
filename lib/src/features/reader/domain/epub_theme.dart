import 'package:flutter/material.dart';

class EpubTheme {
  final Color surfaceColor;
  final Color? onSurfaceColor;
  final EdgeInsets padding;

  EpubTheme({
    required this.surfaceColor,
    this.onSurfaceColor,
    required this.padding,
  });

  EpubTheme copyWith({
    Color? surfaceColor,
    Color? onSurfaceColor,
    EdgeInsets? padding,
  }) {
    return EpubTheme(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
      padding: padding ?? this.padding,
    );
  }
}
