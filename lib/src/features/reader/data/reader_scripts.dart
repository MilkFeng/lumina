import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';
import 'package:lumina/web_src/reader_assets.dart';

String colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
}

String _generateVariableStyle(
  double viewWidth,
  double viewHeight,
  EpubTheme theme,
  int direction,
) {
  final safeWidth = viewWidth.floor();
  final safeHeight = viewHeight.floor();

  final padding = theme.padding;
  final colorScheme = theme.colorScheme;

  final primaryColor = theme.overridePrimaryColor ?? colorScheme.primary;

  return '''
    :root {
      --lumina-zoom: ${theme.zoom};
      --lumina-safe-width: ${safeWidth}px;
      --lumina-safe-height: ${safeHeight}px;
      --lumina-padding-top: ${padding.top}px;
      --lumina-padding-left: ${padding.left}px;
      --lumina-padding-right: ${padding.right}px;
      --lumina-padding-bottom: ${padding.bottom}px;
      --lumina-reader-overflow-x: ${direction == 1 ? 'hidden' : 'auto'};
      --lumina-reader-overflow-y: ${direction == 1 ? 'auto' : 'hidden'};
      --lumina-primary-color: ${colorToHex(primaryColor)};
      --lumina-primary-container-color: ${colorToHex(colorScheme.primaryContainer)};
      --lumina-surface-color: ${colorToHex(colorScheme.surface)};
      --lumina-on-surface-color: ${colorToHex(colorScheme.onSurface)};
      --lumina-on-surface-variant-color: ${colorToHex(colorScheme.onSurfaceVariant)};
      --lumina-outline-variant-color: ${colorToHex(colorScheme.outlineVariant)};
      --lumina-surface-container-color: ${colorToHex(colorScheme.surfaceContainer)};
      --lumina-surface-container-high-color: ${colorToHex(colorScheme.surfaceContainerHigh)};
    }
  ''';
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

  final variableStyle = _generateVariableStyle(
    viewWidth,
    viewHeight,
    theme,
    direction,
  );

  final colorScheme = theme.colorScheme;
  final primaryColor = theme.overridePrimaryColor ?? colorScheme.primary;

  final initialConfigJson = jsonEncode({
    'safeWidth': safeWidth,
    'safeHeight': safeHeight,
    'padding': {
      'top': theme.padding.top,
      'left': theme.padding.left,
      'right': theme.padding.right,
      'bottom': theme.padding.bottom,
    },
    'direction': direction,
    'theme': {
      'zoom': theme.zoom,
      'paginationCss': kPaginationCss,
      'variableCss': variableStyle,
      'shouldOverrideTextColor': theme.shouldOverrideTextColor,
      'primaryColor': colorToHex(primaryColor),
      'primaryContainerColor': colorToHex(colorScheme.primaryContainer),
      'surfaceColor': colorToHex(colorScheme.surface),
      'onSurfaceColor': colorToHex(colorScheme.onSurface),
      'onSurfaceVariantColor': colorToHex(colorScheme.onSurfaceVariant),
      'outlineVariantColor': colorToHex(colorScheme.outlineVariant),
      'surfaceContainerColor': colorToHex(colorScheme.surfaceContainer),
      'surfaceContainerHighColor': colorToHex(colorScheme.surfaceContainerHigh),
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
  <style id="skeleton-variable-style">
    $variableStyle
  </style>
  <script id="skeleton-script">
    $kControllerJs
  </script>
  <script id="skeleton-variable-script">
    const initialConfig = $initialConfigJson;
    window.addEventListener('DOMContentLoaded', () => {
      window.reader.init(initialConfig);
    });
  </script>
</head>
<body>
  <div id="frame-container">
    <iframe id="frame-prev" scrolling="no" style="z-index: 1; opacity: 0;"></iframe>
    <iframe id="frame-curr" scrolling="no" style="z-index: 2; opacity: 1;"></iframe>
    <iframe id="frame-next" scrolling="no" style="z-index: 1; opacity: 0;"></iframe>
  </div>
</body>
</html>
''';
}
