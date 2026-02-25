import 'package:flutter/material.dart';

class EpubTheme {
  final double zoom;
  final Color surfaceColor;
  final Color? onSurfaceColor;
  final EdgeInsets padding;

  EpubTheme({
    required this.zoom,
    required this.surfaceColor,
    this.onSurfaceColor,
    required this.padding,
  });

  EpubTheme copyWith({
    Color? surfaceColor,
    Color? onSurfaceColor,
    EdgeInsets? padding,
    double? zoom,
  }) {
    return EpubTheme(
      zoom: zoom ?? this.zoom,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
      padding: padding ?? this.padding,
    );
  }
}
