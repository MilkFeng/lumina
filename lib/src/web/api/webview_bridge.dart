import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Manages JS↔Dart communication over an [InAppWebViewController].
///
/// Provides token-based async call tracking so that callers can fire a JS
/// method that will eventually invoke `FlutterBridge.onEventFinished(token)`,
/// and await the result on the Dart side via [waitForEvent].
///
/// Typical usage:
/// ```dart
/// // Fire and forget the token; caller awaits separately.
/// final token = await _bridge.call((t) => "window.api.loadFrame($t, ...)");
/// await _bridge.waitForEvent(token);
///
/// // Fire and immediately await.
/// await _bridge.callAndWait((t) => "window.api.jumpToPage($t, $idx)");
/// ```
class WebViewBridge {
  InAppWebViewController? _controller;

  int _currentToken = 0;
  final Map<int, Completer<void>> _completers = {};

  // ─── Controller lifecycle ──────────────────────────────────────────

  /// Attaches a live [InAppWebViewController]. Call this in `onWebViewCreated`.
  void attach(InAppWebViewController controller) {
    _controller = controller;
  }

  /// Detaches the controller and cancels all pending completers.
  void detach() {
    _controller = null;
    for (final completer in _completers.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('WebViewBridge detached'));
      }
    }
    _completers.clear();
  }

  // ─── JS evaluation ─────────────────────────────────────────────────

  /// Evaluates [source] in the WebView. No-ops if no controller is attached.
  Future<void> evaluate(String source) async {
    await _controller?.evaluateJavascript(source: source);
  }

  // ─── Token management ──────────────────────────────────────────────

  /// Allocates a new token and registers a [Completer] for it.
  ///
  /// Embed the returned token in the JS call so JS can resolve it via
  /// `FlutterBridge.onEventFinished(token)`.
  int issueToken() {
    _currentToken++;
    _completers[_currentToken] = Completer<void>();
    return _currentToken;
  }

  /// Called by the `onEventFinished` JS handler to resolve a pending token.
  ///
  /// A [token] of `-1` is a sentinel for fire-and-forget notifications that
  /// do not need to be tracked.
  void resolveToken(int token) {
    if (token == -1) return;
    final completer = _completers.remove(token);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  // ─── Awaiting ──────────────────────────────────────────────────────

  /// Waits for [token] to be resolved, or times out after [timeoutMs] ms.
  Future<void> waitForEvent(int token, [int timeoutMs = 10000]) async {
    final completer = _completers[token];
    if (completer == null) {
      debugPrint('WebViewBridge: no completer for token $token');
      return;
    }
    return completer.future.timeout(
      Duration(milliseconds: timeoutMs),
      onTimeout: () {
        _completers.remove(token);
        debugPrint('WebViewBridge: timeout for token $token');
      },
    );
  }

  /// Waits for all [tokens] to be resolved concurrently.
  Future<void> waitForEvents(List<int> tokens, [int timeoutMs = 10000]) async {
    await Future.wait(tokens.map((t) => waitForEvent(t, timeoutMs)));
  }

  // ─── Convenience helpers ───────────────────────────────────────────

  /// Issues a token, evaluates the JS returned by [source], and returns the
  /// token so the caller can [waitForEvent] later.
  Future<int> call(String Function(int token) source) async {
    final token = issueToken();
    await evaluate(source(token));
    return token;
  }

  /// Issues a token, evaluates the JS returned by [source], and immediately
  /// awaits [waitForEvent] before returning.
  Future<void> callAndWait(
    String Function(int token) source, [
    int timeoutMs = 10000,
  ]) async {
    final token = issueToken();
    await evaluate(source(token));
    await waitForEvent(token, timeoutMs);
  }
}
