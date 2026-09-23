import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/core/widgets/book_cover.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

import '../data/book_session.dart';
import '../data/epub_webview_handler.dart';
import '../data/reader_scripts.dart';
import 'package:lumina/src/web/api/webview_bridge.dart';
import 'package:lumina/src/web/api/lumina_api.dart';

/// Controller for ReaderWebView that provides methods to control the WebView
class ReaderWebViewController {
  _ReaderWebViewState? _webViewState;

  bool get isAttached => _webViewState != null;

  void _attachState(_ReaderWebViewState? state) {
    _webViewState = state;
  }

  // JavaScript wrapper methods
  Future<int?> jumpToLastPageOfFrame(String frame) async {
    return await _webViewState?._jumpToLastPageOfFrame(frame);
  }

  Future<int?> cycleFrames(String direction) async {
    return await _webViewState?._cycleFrames(direction);
  }

  Future<int?> jumpToPageFor(String frame, int pageIndex) async {
    return await _webViewState?._jumpToPageFor(frame, pageIndex);
  }

  Future<int?> loadFrame(
    String frame,
    String url,
    String anchors,
    String properties, {
    double? initialScrollRatio,
  }) async {
    return await _webViewState?._loadFrame(
      frame,
      url,
      anchors,
      properties,
      initialScrollRatio: initialScrollRatio,
    );
  }

  Future<void> jumpToPage(int pageIndex) async {
    await _webViewState?._jumpToPage(pageIndex);
  }

  /// Scrolls by roughly one screenful, in scroll mode.
  ///
  /// A one-shot command used by the volume keys; the page does the scrolling.
  Future<void> scrollByViewport(bool isNext) async {
    await _webViewState?._scrollByViewport(isNext);
  }

  Future<void> checkLongPressElementAt(double x, double y) async {
    await _webViewState?._checkLongPressElementAt(x, y);
  }

  Future<void> checkTapElementAt(double x, double y) async {
    await _webViewState?._checkTapElementAt(x, y);
  }

  Future<ui.Image?> takeScreenshot() async {
    return await _webViewState?._takeScreenshot();
  }

  Future<void> waitForRender() async {
    await _webViewState?._waitForRender();
  }

  Future<void> updateTheme(EpubTheme theme) async {
    await _webViewState?._updateTheme(theme);
  }

  Future<void> waitForEvent(int token, [int timeoutMs = 10000]) async {
    await _webViewState?._bridge.waitForEvent(token, timeoutMs);
  }

  Future<void> waitForEvents(List<int> tokens, [int timeoutMs = 10000]) async {
    await _webViewState?._bridge.waitForEvents(tokens, timeoutMs);
  }
}

/// Builds the reader WebView settings for a given layout mode.
///
/// The two modes differ in two ways.
///
/// **Composition.**  Paginated mode must stay on the virtual display, because
/// the Android page-turn animation screenshots the WebView through
/// `RepaintBoundary.toImage()` and hybrid composition renders into a separate
/// surface that the boundary cannot capture.  Scroll mode has no screenshot
/// path and uses hybrid composition instead.
///
/// **Who scrolls.**  Paginated mode keeps native scrolling off: Flutter owns
/// the page-turn gesture and drives every offset with `jumpToPage`.  Scroll
/// mode does the opposite — the chapter scrolls itself with the browser's own
/// scroller, because pushing an offset in from Flutter costs a platform-channel
/// round-trip per frame and lags behind the finger.  Only the vertical axis is
/// handed over; the horizontal one stays pinned, which is what
/// `disableHorizontalScroll` does on both platforms.
InAppWebViewSettings readerWebViewSettings({required bool scrollMode}) =>
    InAppWebViewSettings(
      disableContextMenu: true,
      disableLongPressContextMenuOnLinks: true,
      selectionGranularity: SelectionGranularity.CHARACTER,
      transparentBackground: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      useShouldInterceptRequest: true,
      useOnLoadResource: false,
      useShouldOverrideUrlLoading: true,
      javaScriptEnabled: true,
      disableHorizontalScroll: true,
      disableVerticalScroll: !scrollMode,
      supportZoom: false,
      useHybridComposition: false,
      resourceCustomSchemes: [EpubWebViewHandler.virtualScheme],
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
      overScrollMode: OverScrollMode.NEVER,
    );

/// Settings used by the WebView pre-warm in `main.dart` and by paginated mode.
final InAppWebViewSettings defaultSettings = readerWebViewSettings(
  scrollMode: false,
);

/// Callbacks for WebView events
class ReaderWebViewCallbacks {
  final Function() onInitialized;
  final Function(int totalPages) onPageCountReady;
  final Function(int pageIndex) onPageChanged;
  final Function(List<String> anchors) onScrollAnchors;

  /// Reports where the page scrolled itself to: the current offset and the
  /// largest one the chapter allows, both in CSS pixels.
  final Function(double offset, double maxOffset) onScrollProgress;

  /// Reports that the page stopped scrolling, which is when reading progress is
  /// worth persisting.
  final Function() onScrollSettled;
  final Function(String imageUrl, Rect rect) onImageLongPress;
  final Function(double x, double y) onTap;
  final Function(String innerHtml, Rect rect, String baseUrl) onFootnoteTap;
  final Function(String url) onLinkTap;
  final bool Function(String url) shouldHandleLinkTap;

  const ReaderWebViewCallbacks({
    required this.onInitialized,
    required this.onPageCountReady,
    required this.onPageChanged,
    required this.onScrollAnchors,
    required this.onScrollProgress,
    required this.onScrollSettled,
    required this.onImageLongPress,
    required this.onTap,
    required this.onFootnoteTap,
    required this.onLinkTap,
    required this.shouldHandleLinkTap,
  });
}

/// WebView widget for reading EPUB content
class ReaderWebView extends StatefulWidget {
  final BookSession bookSession;
  final EpubWebViewHandler webViewHandler;
  final String fileHash;
  final ReaderWebViewCallbacks callbacks;
  final EpubTheme initializeTheme;
  final bool isLoading;
  final ReaderWebViewController controller;
  final VoidCallback? onWebViewCreated;
  final bool shouldShowWebView;
  final String? coverRelativePath;
  final int direction;

  /// Whether the chapter is laid out as one continuous scrollable column.
  ///
  /// Toggling this recreates the WebView, because the Android composition mode
  /// is baked into the platform view at creation time.
  final bool scrollMode;

  const ReaderWebView({
    super.key,
    required this.bookSession,
    required this.webViewHandler,
    required this.fileHash,
    required this.callbacks,
    required this.initializeTheme,
    required this.isLoading,
    required this.controller,
    this.onWebViewCreated,
    required this.shouldShowWebView,
    this.coverRelativePath,
    required this.direction,
    required this.scrollMode,
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  final GlobalKey _repaintKey = GlobalKey();

  InAppWebViewController? _controller;
  HeadlessInAppWebView? _headlessWebView;
  bool _isHeadlessInitialized = false;

  /// Whether the visible platform view still has to wait for the pre-warm of the
  /// current layout mode to start before it can be created.
  ///
  /// The visible WebView attaches the pre-warmed engine, and it can only do that
  /// once that engine is running: a platform view created before then builds a
  /// WebView of its own instead — which, right after a layout-mode change, is a
  /// WebView created in the same frame its predecessor is torn down, and one
  /// that never gets painted.  See [_ReaderWebViewState.build] and
  /// [_startHeadlessWebView].
  bool _isWaitingForHeadless = true;

  bool _isSubsequentLoad = false;

  late EpubTheme _currentTheme;

  final WebViewBridge _bridge = WebViewBridge();
  late final LuminaApi _api = LuminaApi(_bridge);

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initializeTheme;
    widget.controller._attachState(this);
  }

  @override
  void didUpdateWidget(covariant ReaderWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollMode != widget.scrollMode) {
      _recreateWebView();
    }
    if (!oldWidget.isLoading && widget.isLoading) {
      setState(() {
        _isSubsequentLoad = true;
      });
    }
  }

  @override
  void dispose() {
    widget.controller._attachState(null);
    _disposeWebView();
    super.dispose();
  }

  /// Tears the WebView down so that the next build recreates it.
  ///
  /// The Android platform-view composition mode is fixed when the view is
  /// created, so switching layout mode has to go through a full recreation —
  /// see [readerWebViewSettings].
  void _disposeWebView() {
    _bridge.detach();
    _controller = null;
    _headlessWebView?.dispose();
    _headlessWebView = null;
    _isHeadlessInitialized = false;
  }

  /// Recreates the WebView for the layout mode that was just switched to.
  ///
  /// The replacement cannot be created in this frame: a platform view built in
  /// the same frame as its predecessor's teardown is never painted — the page
  /// loads, runs and reports its chapters, but stays invisible — and the fresh
  /// pre-warm it would have to attach to has not started yet in that frame
  /// either.  Holding the visible view back until that pre-warm is running
  /// reproduces the sequence of the reader's first open, which is the one that
  /// paints.  The empty frame in between shows the theme surface, exactly like
  /// the loading layer that follows it.
  void _recreateWebView() {
    _disposeWebView();
    _isWaitingForHeadless = true;
    // No `setState`: this runs from `didUpdateWidget`, in the build that is
    // already on its way.
  }

  void _initHeadlessWebViewIfNeeded(double width, double height) {
    if (_isHeadlessInitialized) return;

    _headlessWebView = HeadlessInAppWebView(
      initialData: _generateInitialData(width, height),
      initialSettings: readerWebViewSettings(scrollMode: widget.scrollMode),
      shouldInterceptRequest: _shouldInterceptRequest,
      onLoadResourceWithCustomScheme: _onLoadResourceWithCustomScheme,
      shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
      onWebViewCreated: _onWebViewCreated,
      onLoadStop: _onLoadStop,
    );

    _isHeadlessInitialized = true;
    _isWaitingForHeadless = true;
    unawaited(_startHeadlessWebView());
  }

  /// Starts the pre-warm and releases the visible WebView once it runs.
  ///
  /// The timeout is a safety net: an engine that cannot be started must not
  /// leave the reader on an empty page, and the visible WebView still works
  /// without a pre-warm to attach to.
  Future<void> _startHeadlessWebView() async {
    final headless = _headlessWebView;
    if (headless == null) return;

    try {
      await headless.run().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('ReaderWebView: WebView pre-warm failed: $e');
    }

    if (!mounted || !identical(headless, _headlessWebView)) {
      // Torn down or replaced while it was starting: the `dispose()` of that
      // moment could do nothing, because the engine was not running yet.
      await headless.dispose();
      return;
    }

    setState(() {
      _isWaitingForHeadless = false;
    });
  }

  Future<void> _waitForWebviewRender() async {
    if (_controller == null) return;
    await _api.waitForRender();
  }

  Future<void> _waitForRender() async {
    await _waitForWebviewRender();
  }

  Future<int> _jumpToLastPageOfFrame(String frame) =>
      _api.jumpToLastPageOfFrame(frame);

  Future<int> _cycleFrames(String direction) => _api.cycleFrames(direction);

  Future<int> _jumpToPageFor(String frame, int pageIndex) =>
      _api.jumpToPageFor(frame, pageIndex);

  Future<int> _loadFrame(
    String frame,
    String url,
    String anchors,
    String properties, {
    double? initialScrollRatio,
  }) => _api.loadFrame(
    frame,
    url,
    anchors,
    properties,
    initialScrollRatio: initialScrollRatio,
  );

  Future<void> _jumpToPage(int pageIndex) => _api.jumpToPage(pageIndex);

  Future<void> _scrollByViewport(bool isNext) => _api.scrollByViewport(isNext);

  Future<void> _checkLongPressElementAt(double x, double y) =>
      _api.checkLongPressElementAt(x, y);

  Future<void> _checkTapElementAt(double x, double y) =>
      _api.checkTapElementAt(x, y);

  InAppWebViewInitialData _generateInitialData(double width, double height) {
    return InAppWebViewInitialData(
      data: generateSkeletonHtml(
        width,
        height,
        _currentTheme,
        widget.direction,
        scrollMode: widget.scrollMode,
      ),
      baseUrl: WebUri(EpubWebViewHandler.getBaseUrl()),
    );
  }

  Future<WebResourceResponse?> _shouldInterceptRequest(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    return await widget.webViewHandler.handleRequest(
      epubPath: widget.bookSession.book!.filePath!,
      fileHash: widget.fileHash,
      requestUrl: request.url,
    );
  }

  Future<CustomSchemeResponse?> _onLoadResourceWithCustomScheme(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    return await widget.webViewHandler.handleRequestWithCustomScheme(
      epubPath: widget.bookSession.book!.filePath!,
      fileHash: widget.fileHash,
      requestUrl: request.url,
    );
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final uri = navigationAction.request.url!;
    if (uri.scheme == 'data') {
      return NavigationActionPolicy.ALLOW;
    }
    if (EpubWebViewHandler.isEpubRequest(uri)) {
      return NavigationActionPolicy.ALLOW;
    }
    return NavigationActionPolicy.CANCEL;
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    _bridge.attach(controller);
    _setupJavaScriptHandlers(controller);
    widget.onWebViewCreated?.call();
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    widget.callbacks.onInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - _currentTheme.padding.horizontal;
        final height = constraints.maxHeight - _currentTheme.padding.vertical;
        _initHeadlessWebViewIfNeeded(width, height);

        return Stack(
          children: [
            RepaintBoundary(
              key: _repaintKey,
              child: AbsorbPointer(
                // While paginated the WebView must not be hit at all: Flutter
                // claims every gesture.  In scroll mode it has to be reachable,
                // because that is what lets the chapter scroll itself — the
                // gesture arena hands a drag to the platform view as soon as
                // Flutter does not claim it.  See `ReaderRenderer` for the
                // gestures Flutter keeps.
                absorbing: !widget.scrollMode,
                // The platform view cannot be built before the pre-warm it
                // attaches to is running; see [_isWaitingForHeadless].
                child: widget.shouldShowWebView && !_isWaitingForHeadless
                    ? InAppWebView(
                        key: ValueKey(widget.scrollMode),
                        headlessWebView: _headlessWebView,
                        initialData: _generateInitialData(width, height),
                        initialSettings: readerWebViewSettings(
                          scrollMode: widget.scrollMode,
                        ),
                        shouldInterceptRequest: _shouldInterceptRequest,
                        onLoadResourceWithCustomScheme:
                            _onLoadResourceWithCustomScheme,
                        shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
                        onWebViewCreated: _onWebViewCreated,
                        onLoadStop: _onLoadStop,
                      )
                    : Container(color: _currentTheme.surfaceColor),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !widget.isLoading && widget.shouldShowWebView,
                child: AnimatedOpacity(
                  duration: (widget.isLoading || !widget.shouldShowWebView)
                      ? Duration.zero
                      : const Duration(
                          milliseconds: AppTheme.defaultAnimationDurationMs,
                        ),
                  curve: Curves.easeOut,
                  opacity: (widget.isLoading || !widget.shouldShowWebView)
                      ? 1.0
                      : 0.0,
                  child: Container(
                    color: _currentTheme.surfaceColor,
                    child: _isSubsequentLoad
                        ? null
                        : Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.4,
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                              ),
                              child: Theme(
                                data: _currentTheme.themeData,
                                child: BookCover(
                                  relativePath: widget.coverRelativePath,
                                  radius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'onPageCountReady',
      callback: (args) async {
        if (args.isNotEmpty && args[0] is int) {
          widget.callbacks.onPageCountReady(args[0] as int);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onPageChanged',
      callback: (args) {
        if (args.isNotEmpty && args[0] is int) {
          widget.callbacks.onPageChanged(args[0] as int);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onScrollAnchors',
      callback: (args) {
        if (args.isEmpty) return;
        final List<String> anchors = List<String>.from(args[0] as List);
        widget.callbacks.onScrollAnchors(anchors);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onScrollProgress',
      callback: (args) {
        if (args.length < 2) return;
        widget.callbacks.onScrollProgress(
          (args[0] as num).toDouble(),
          (args[1] as num).toDouble(),
        );
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onScrollSettled',
      callback: (args) {
        widget.callbacks.onScrollSettled();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onTap',
      callback: (args) {
        if (args.isEmpty) return;
        final x = (args[0] as num).toDouble();
        final y = (args[1] as num).toDouble();
        widget.callbacks.onTap(x, y);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onFootnoteTap',
      callback: (args) {
        if (args.isEmpty) return;
        final innerHtml = args[0] as String;
        final rect = Rect.fromLTWH(
          (args[1] as num).toDouble(),
          (args[2] as num).toDouble(),
          (args[3] as num).toDouble(),
          (args[4] as num).toDouble(),
        );
        final baseUrl = args.length > 5 && args[5] is String
            ? args[5] as String
            : '';
        widget.callbacks.onFootnoteTap(innerHtml, rect, baseUrl);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onLinkTap',
      callback: (args) {
        if (args.isEmpty) return;
        final url = args[0] as String;
        final x = (args[1] as num).toDouble();
        final y = (args[2] as num).toDouble();
        if (widget.callbacks.shouldHandleLinkTap(url)) {
          widget.callbacks.onLinkTap(url);
        } else {
          widget.callbacks.onTap(x, y);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onImageLongPress',
      callback: (args) {
        if (args.length >= 5 && args[0] is String) {
          final imageUrl = args[0] as String;
          final rect = Rect.fromLTWH(
            (args[1] as num).toDouble(),
            (args[2] as num).toDouble(),
            (args[3] as num).toDouble(),
            (args[4] as num).toDouble(),
          );
          widget.callbacks.onImageLongPress(imageUrl, rect);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onViewportResize',
      callback: (args) {
        _updateTheme(_currentTheme);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onEventFinished',
      callback: (args) {
        if (args.isNotEmpty) {
          _bridge.resolveToken(args[0] as int);
        }
      },
    );
  }

  Future<ui.Image?> _takeScreenshot() async {
    if (Platform.isAndroid) {
      // for Android
      final BuildContext? context = _repaintKey.currentContext;
      if (context == null) return null;

      final RenderRepaintBoundary? boundary =
          context.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      return image;
    } else {
      throw UnimplementedError(
        'Do not use screenshot on iOS, it may cause performance issues.',
      );
    }
  }

  Future<void> _updateTheme(EpubTheme theme) async {
    if (_controller == null) return;
    final width = MediaQuery.of(context).size.width - theme.padding.horizontal;
    final height = MediaQuery.of(context).size.height - theme.padding.vertical;
    _currentTheme = theme;
    await _api.updateTheme(
      width,
      height,
      theme.toThemeMap(),
      scrollMode: widget.scrollMode,
    );
  }
}
