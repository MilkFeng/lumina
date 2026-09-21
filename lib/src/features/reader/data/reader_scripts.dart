import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';
import 'package:lumina/src/web/web_assets.dart';

String colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
}

Map<String, dynamic> colorToMap(Color color) {
  return {
    'r': (color.r * 255.0).round().clamp(0, 255),
    'g': (color.g * 255.0).round().clamp(0, 255),
    'b': (color.b * 255.0).round().clamp(0, 255),
    'a': color.a,
  };
}

/// Skeleton HTML containing 3 iframes for prev/curr/next chapters
String generateSkeletonHtml(
  double viewWidth,
  double viewHeight,
  EpubTheme theme,
  int direction, {
  required bool scrollMode,
}) {
  final safeWidth = viewWidth.floor();
  final safeHeight = viewHeight.floor();

  var initialConfigMap = theme.toThemeMap();
  initialConfigMap['safeWidth'] = safeWidth;
  initialConfigMap['safeHeight'] = safeHeight;
  initialConfigMap['direction'] = direction;
  initialConfigMap['scrollMode'] = scrollMode;
  initialConfigMap['paginationCss'] = kPaginationCss;

  final initialConfigJson = jsonEncode(initialConfigMap);

  // Scroll mode scrolls the frame the reader is looking at with the browser's
  // own scroller, so every frame has to allow it: `cycleFrames` turns a chapter
  // by swapping the frames' ids, and the frame promoted to `curr` may well be
  // one that started life as `next`.  Which frame is reachable is decided by
  // `pointer-events` instead (see `skeleton.css`), not by the scrolling mode.
  // The paginated layout drives every offset from script and keeps user
  // scrolling off.
  final frameScrolling = scrollMode ? 'auto' : 'no';

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
    <iframe id="frame-prev" sandbox="allow-same-origin" scrolling="$frameScrolling" style="z-index: 1; opacity: 0;"></iframe>
    <iframe id="frame-curr" sandbox="allow-same-origin" scrolling="$frameScrolling" style="z-index: 2; opacity: 1;"></iframe>
    <iframe id="frame-next" sandbox="allow-same-origin" scrolling="$frameScrolling" style="z-index: 1; opacity: 0;"></iframe>
  </div>
</body>
</html>
''';
}
