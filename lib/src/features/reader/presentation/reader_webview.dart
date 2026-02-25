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

/// Controller for ReaderWebView that provides methods to control the WebView
class ReaderWebViewController {
  _ReaderWebViewState? _webViewState;

  bool get isAttached => _webViewState != null;

  void _attachState(_ReaderWebViewState? state) {
    _webViewState = state;
  }

  // JavaScript wrapper methods
  Future<void> jumpToLastPageOfFrame(String frame) async {
    await _webViewState?._jumpToLastPageOfFrame(frame);
  }

  Future<void> cycleFrames(String direction) async {
    await _webViewState?._cycleFrames(direction);
  }

  Future<void> jumpToPageFor(String frame, int pageIndex) async {
    await _webViewState?._jumpToPageFor(frame, pageIndex);
  }

  Future<void> loadFrame(String frame, String url, String anchors) async {
    await _webViewState?._loadFrame(frame, url, anchors);
  }

  Future<void> jumpToPage(int pageIndex) async {
    await _webViewState?._jumpToPage(pageIndex);
  }

  Future<void> restoreScrollPosition(double ratio) async {
    await _webViewState?._restoreScrollPosition(ratio);
  }

  Future<void> checkElementAt(double x, double y) async {
    await _webViewState?._checkElementAt(x, y);
  }

  Future<void> checkTapElementAt(double x, double y) async {
    await _webViewState?._checkTapElementAt(x, y);
  }

  Future<ui.Image?> takeScreenshot() async {
    return await _webViewState?._takeScreenshot();
  }

  Future<void> updateTheme(EpubTheme theme) async {
    await _webViewState?._updateTheme(theme);
  }
}

final InAppWebViewSettings defaultSettings = InAppWebViewSettings(
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
  disableVerticalScroll: true,
  supportZoom: false,
  useHybridComposition: false,
  resourceCustomSchemes: [EpubWebViewHandler.virtualScheme],
);

/// Callbacks for WebView events
class ReaderWebViewCallbacks {
  final Function() onInitialized;
  final Function(int totalPages) onPageCountReady;
  final Function(int pageIndex) onPageChanged;
  final VoidCallback onRendererInitialized;
  final Function(List<String> anchors) onScrollAnchors;
  final Function(String imageUrl, Rect rect) onImageLongPress;
  final Function(double x, double y) onTap;
  final Function(String innerHtml, Rect rect) onFootnoteTap;

  const ReaderWebViewCallbacks({
    required this.onInitialized,
    required this.onPageCountReady,
    required this.onPageChanged,
    required this.onRendererInitialized,
    required this.onScrollAnchors,
    required this.onImageLongPress,
    required this.onTap,
    required this.onFootnoteTap,
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
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  final GlobalKey _repaintKey = GlobalKey();

  InAppWebViewController? _controller;
  HeadlessInAppWebView? _headlessWebView;
  bool _isHeadlessInitialized = false;

  bool _isSubsequentLoad = false;

  late EpubTheme _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initializeTheme;
    widget.controller._attachState(this);
  }

  @override
  void didUpdateWidget(covariant ReaderWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoading && widget.isLoading) {
      setState(() {
        _isSubsequentLoad = true;
      });
    }
  }

  void _initHeadlessWebViewIfNeeded(double width, double height) {
    if (_isHeadlessInitialized) return;

    _headlessWebView = HeadlessInAppWebView(
      initialData: _generateInitialData(width, height),
      initialSettings: defaultSettings,
      shouldInterceptRequest: _shouldInterceptRequest,
      onLoadResourceWithCustomScheme: _onLoadResourceWithCustomScheme,
      shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
      onWebViewCreated: _onWebViewCreated,
      onLoadStop: _onLoadStop,
    );

    _headlessWebView?.run();
    _isHeadlessInitialized = true;
  }

  // JavaScript methods
  Future<void> _evaluateJavascript(String source) async {
    await _controller?.evaluateJavascript(source: source);
  }

  Future<void> _jumpToLastPageOfFrame(String frame) async {
    await _evaluateJavascript("window.reader.jumpToLastPageOfFrame('$frame')");
  }

  Future<void> _cycleFrames(String direction) async {
    await _evaluateJavascript("window.reader.cycleFrames('$direction')");
  }

  Future<void> _jumpToPageFor(String frame, int pageIndex) async {
    await _evaluateJavascript(
      "window.reader.jumpToPageFor('$frame', $pageIndex)",
    );
  }

  Future<void> _loadFrame(String frame, String url, String anchors) async {
    await _evaluateJavascript(
      "window.reader.loadFrame('$frame', '$url', $anchors)",
    );
  }

  Future<void> _jumpToPage(int pageIndex) async {
    await _evaluateJavascript('window.reader.jumpToPage($pageIndex)');
  }

  Future<void> _restoreScrollPosition(double ratio) async {
    await _evaluateJavascript('window.reader.restoreScrollPosition($ratio)');
  }

  Future<void> _checkElementAt(double x, double y) async {
    await _evaluateJavascript("window.reader.checkElementAt($x, $y)");
  }

  Future<void> _checkTapElementAt(double x, double y) async {
    await _evaluateJavascript("window.reader.checkTapElementAt($x, $y)");
  }

  InAppWebViewInitialData _generateInitialData(double width, double height) {
    return InAppWebViewInitialData(
      data: generateSkeletonHtml(
        width,
        height,
        _currentTheme,
        widget.direction,
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
                child: widget.shouldShowWebView
                    ? InAppWebView(
                        headlessWebView: _headlessWebView,
                        initialData: _generateInitialData(width, height),
                        initialSettings: defaultSettings,
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
                  duration: const Duration(
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
                              child: BookCover(
                                relativePath: widget.coverRelativePath,
                                enableBorder: false,
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
      handlerName: 'onRendererInitialized',
      callback: (args) async {
        await Future.delayed(const Duration(milliseconds: 100));
        widget.callbacks.onRendererInitialized();
        debugPrint('WebView: Renderer Initialized');
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
        widget.callbacks.onFootnoteTap(innerHtml, rect);
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
    final width = MediaQuery.of(context).size.width - theme.padding.horizontal;
    final height = MediaQuery.of(context).size.height - theme.padding.vertical;

    _currentTheme = theme;
    final ColorScheme colorScheme = theme.colorScheme;
    await _evaluateJavascript("""window.reader.updateTheme(
      $width,
      $height,
      ${theme.padding.top},
      ${theme.padding.left},
      ${theme.padding.right},
      ${theme.padding.bottom},
      ${theme.zoom},
      '${colorToHex(colorScheme.surface)}',
      '${colorToHex(colorScheme.onSurface)}',
      ${theme.shouldOverrideTextColor},
      '${colorToHex(colorScheme.primary)}',
      '${colorToHex(colorScheme.primaryContainer)}',
      '${colorToHex(colorScheme.onSurfaceVariant)}',
      '${colorToHex(colorScheme.outlineVariant)}',
      '${colorToHex(colorScheme.surfaceContainer)}',
      '${colorToHex(colorScheme.surfaceContainerHigh)}'
    )""");
  }
}
