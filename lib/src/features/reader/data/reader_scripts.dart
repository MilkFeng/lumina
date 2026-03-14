import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';
import 'package:lumina/src/web/web_assets.dart';

String colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
}

/// Skeleton HTML containing 3 iframes for prev/curr/next chapters
String generateSkeletonHtml(
  double viewWidth,
  double viewHeight,
  EpubTheme theme,
  int direction,
) {
  final safeWidth = viewWidth.floor();
  final safeHeight = viewHeight.floor();

  final colorScheme = theme.colorScheme;
  final primaryColor = theme.overridePrimaryColor ?? colorScheme.primary;

  final initialConfigJson = jsonEncode({
    'safeWidth': safeWidth,
    'safeHeight': safeHeight,
    'padding': {'top': theme.padding.top, 'left': theme.padding.left},
    'direction': direction,
    'theme': {
      'zoom': theme.zoom,
      'paginationCss': kPaginationCss,
      'shouldOverrideTextColor': theme.shouldOverrideTextColor,
      'primaryColor': colorToHex(primaryColor),
      'primaryContainerColor': colorToHex(colorScheme.primaryContainer),
      'surfaceColor': colorToHex(colorScheme.surface),
      'onSurfaceColor': colorToHex(colorScheme.onSurface),
      'onSurfaceVariantColor': colorToHex(colorScheme.onSurfaceVariant),
      'outlineVariantColor': colorToHex(colorScheme.outlineVariant),
      'surfaceContainerColor': colorToHex(colorScheme.surfaceContainer),
      'surfaceContainerHighColor': colorToHex(colorScheme.surfaceContainerHigh),
      'fontFileName': theme.fontFileName,
      'overrideFontFamily': theme.overrideFontFamily,
    },
  });

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style id="skeleton-style">
    $kSkeletonCss
  </style>
  <script id="skeleton-script">
    $kControllerJs
  </script>
  <script id="skeleton-variable-script">
    const initialConfig = $initialConfigJson;
    window.addEventListener('DOMContentLoaded', () => {
      window.api.init(initialConfig);
    });
  </script>
</head>
<body>
  <div id="frame-container">
    <iframe id="frame-prev" sandbox="allow-same-origin" scrolling="no" style="z-index: 1; opacity: 0;"></iframe>
    <iframe id="frame-curr" sandbox="allow-same-origin" scrolling="no" style="z-index: 2; opacity: 1;"></iframe>
    <iframe id="frame-next" sandbox="allow-same-origin" scrolling="no" style="z-index: 1; opacity: 0;"></iframe>
  </div>
</body>
</html>
''';
}
