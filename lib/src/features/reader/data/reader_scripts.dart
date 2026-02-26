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

  return '''
    :root {
      --zoom: ${theme.zoom};
      --safe-width: ${safeWidth}px;
      --safe-height: ${safeHeight}px;
      --padding-top: ${padding.top}px;
      --padding-left: ${padding.left}px;
      --padding-right: ${padding.right}px;
      --padding-bottom: ${padding.bottom}px;
      --reader-overflow-x: ${direction == 1 ? 'hidden' : 'auto'};
      --reader-overflow-y: ${direction == 1 ? 'auto' : 'hidden'};
      
      --background-color: ${colorToHex(colorScheme.surface)};
      --default-text-color: ${colorToHex(colorScheme.onSurface)};

      --primary-color: ${colorToHex(colorScheme.primary)};
      --primary-container: ${colorToHex(colorScheme.primaryContainer)};
      --on-surface-variant: ${colorToHex(colorScheme.onSurfaceVariant)};
      --outline-variant: ${colorToHex(colorScheme.outlineVariant)};
      --surface-container: ${colorToHex(colorScheme.surfaceContainer)};
      --surface-container-high: ${colorToHex(colorScheme.surfaceContainerHigh)};
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

      'backgroundColor': colorToHex(colorScheme.surface),
      'defaultTextColor': colorToHex(colorScheme.onSurface),

      'shouldOverrideTextColor': theme.shouldOverrideTextColor,

      'primaryColor': colorToHex(colorScheme.primary),
      'primaryContainer': colorToHex(colorScheme.primaryContainer),
      'onSurfaceVariant': colorToHex(colorScheme.onSurfaceVariant),
      'outlineVariant': colorToHex(colorScheme.outlineVariant),
      'surfaceContainer': colorToHex(colorScheme.surfaceContainer),
      'surfaceContainerHigh': colorToHex(colorScheme.surfaceContainerHigh),
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
    <iframe id="frame-prev" scrolling="no"></iframe>
    <iframe id="frame-curr" scrolling="no"></iframe>
    <iframe id="frame-next" scrolling="no"></iframe>
  </div>
</body>
</html>
''';
}
