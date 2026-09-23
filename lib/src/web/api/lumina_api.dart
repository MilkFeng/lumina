import 'dart:convert';

import 'webview_bridge.dart';

/// Typed Dart mirror of the TypeScript `LuminaApi` interface
/// (`web_assets/controller.js/api.ts`).
///
/// Every public method corresponds 1-to-1 with its TypeScript counterpart.
/// The token parameter is managed internally by [WebViewBridge] — callers
/// never touch raw token integers through this class.
///
/// Methods that return `Future<int>` fire the JS call and return a token the
/// caller can later pass to [WebViewBridge.waitForEvent] / [waitForEvents]
/// when it wants to batch-await multiple operations together.
///
/// Methods that return `Future<void>` fire the JS call and await its
/// completion before returning.
class LuminaApi {
  final WebViewBridge _bridge;

  LuminaApi(this._bridge);

  // ─── Token-based (deferred await) ──────────────────────────────────

  /// Loads [url] into the iframe identified by [slot].
  /// [anchors] should be a JSON-encoded list: `'["id1","id2"]'`.
  ///
  /// [initialScrollRatio] is where the frame should start, as a fraction of the
  /// scrollable length in scroll mode and of the page count while paginated.
  /// Restoring a reading position travels with the load instead of following it
  /// as a separate scroll call.
  Future<int> loadFrame(
    String slot,
    String url,
    String anchors,
    String properties, {
    double? initialScrollRatio,
  }) => _bridge.call(
    (t) =>
        "window.api.loadFrame($t, '$slot', '$url', $anchors, $properties, "
        "${initialScrollRatio ?? 'null'})",
  );

  /// Scrolls [slot]'s iframe to [pageIndex] without immediately awaiting.
  Future<int> jumpToPageFor(String slot, int pageIndex) =>
      _bridge.call((t) => "window.api.jumpToPageFor($t, '$slot', $pageIndex)");

  /// Scrolls [slot]'s iframe to its last page without immediately awaiting.
  Future<int> jumpToLastPageOfFrame(String slot) =>
      _bridge.call((t) => "window.api.jumpToLastPageOfFrame($t, '$slot')");

  /// Rotates the iframe triple in [direction] (`'next'` or `'prev'`).
  Future<int> cycleFrames(String direction) =>
      _bridge.call((t) => "window.api.cycleFrames($t, '$direction')");

  // ─── Fire-and-await ────────────────────────────────────────────────

  /// Scrolls the current iframe to [pageIndex] and awaits completion.
  Future<void> jumpToPage(int pageIndex) =>
      _bridge.callAndWait((t) => 'window.api.jumpToPage($t, $pageIndex)', 1000);

  /// Scrolls the current frame by roughly one screenful, in scroll mode.
  ///
  /// Awaiting the returned future means the screenful has landed: the page
  /// animates the scroll itself and keeps reporting its position through
  /// `onScrollProgress`.  [timeoutMs] is a safety net, not a duration — the
  /// page's own animation is what decides when a turn is over.
  Future<void> scrollByViewport(bool isNext, [int timeoutMs = 5000]) =>
      _bridge.callAndWait(
        (t) => "window.api.scrollByViewport($t, '${isNext ? 'next' : 'prev'}')",
        timeoutMs,
      );

  /// Waits for the current frame to finish rendering.
  Future<void> waitForRender() =>
      _bridge.callAndWait((t) => 'window.api.waitForRender($t)', 1000);

  /// Updates the reader theme/layout and awaits completion.
  ///
  /// [theme] must be a JSON-serialisable map produced by `EpubTheme.toMap()`.
  /// [scrollMode] mirrors `InitConfig.scrollMode` on the TypeScript side and
  /// must be re-sent with every theme update, because a layout change and a
  /// mode change both go through the same re-layout path.
  Future<void> updateTheme(
    double viewWidth,
    double viewHeight,
    Map<String, dynamic> theme, {
    required bool scrollMode,
  }) {
    final themeJson = jsonEncode({...theme, 'scrollMode': scrollMode});
    return _bridge.callAndWait(
      (t) => 'window.api.updateTheme($t, $viewWidth, $viewHeight, $themeJson)',
    );
  }

  // ─── Fire-and-forget ───────────────────────────────────────────────

  /// Lands the viewport scroll that is animating, if any, on its target now.
  ///
  /// Fire-and-forget on purpose: the scroll it settles is the one whose
  /// [scrollByViewport] future is already being awaited, and that future is
  /// what says the turn is over.
  Future<void> finishScrollByViewport() =>
      _bridge.evaluate('window.api.finishScrollByViewport()');

  /// Checks whether there is an interactive element (image, etc.) at (x, y).
  Future<void> checkLongPressElementAt(double x, double y) =>
      _bridge.evaluate('window.api.checkLongPressElementAt($x, $y)');

  /// Checks whether the tap at (x, y) hits a link, footnote, or other element.
  Future<void> checkTapElementAt(double x, double y) =>
      _bridge.evaluate('window.api.checkTapElementAt($x, $y)');
}
