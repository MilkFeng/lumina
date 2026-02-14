import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  Future<void> evaluateJavascript(String source) async {
    await _webViewState?._evaluateJavascript(source);
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

  Future<void> replaceStyles(String skeletonCss, String iframeCss) async {
    await _webViewState?._replaceStyles(skeletonCss, iframeCss);
  }

  Future<void> checkElementAt(double x, double y) async {
    await _webViewState?._checkElementAt(x, y);
  }

  Future<ui.Image?> takeScreenshot() async {
    return await _webViewState?._takeScreenshot();
  }

  Future<void> updateTheme(
    Color surfaceColor,
    Color? onSurfaceColor,
    EdgeInsets padding,
  ) async {
    await _webViewState?._updateTheme(surfaceColor, onSurfaceColor, padding);
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
  final Function(String imageUrl) onImageLongPress;

  const ReaderWebViewCallbacks({
    required this.onInitialized,
    required this.onPageCountReady,
    required this.onPageChanged,
    required this.onRendererInitialized,
    required this.onScrollAnchors,
    required this.onImageLongPress,
  });
}

/// WebView widget for reading EPUB content
class ReaderWebView extends StatefulWidget {
  final BookSession bookSession;
  final EpubWebViewHandler webViewHandler;
  final String fileHash;
  final ReaderWebViewCallbacks callbacks;
  final Color surfaceColor;
  final Color? onSurfaceColor;
  final EdgeInsets padding;
  final bool isLoading;
  final ReaderWebViewController controller;
  final VoidCallback? onWebViewCreated;

  const ReaderWebView({
    super.key,
    required this.bookSession,
    required this.webViewHandler,
    required this.fileHash,
    required this.callbacks,
    required this.padding,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.isLoading,
    required this.controller,
    this.onWebViewCreated,
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  final GlobalKey _repaintKey = GlobalKey();

  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    widget.controller._attachState(this);
  }

  // JavaScript methods
  Future<void> _evaluateJavascript(String source) async {
    await _controller?.evaluateJavascript(source: source);
  }

  Future<void> _jumpToLastPageOfFrame(String frame) async {
    await _evaluateJavascript("jumpToLastPageOfFrame('$frame')");
  }

  Future<void> _cycleFrames(String direction) async {
    await _evaluateJavascript("cycleFrames('$direction')");
  }

  Future<void> _jumpToPageFor(String frame, int pageIndex) async {
    await _evaluateJavascript("jumpToPageFor('$frame', $pageIndex)");
  }

  Future<void> _loadFrame(String frame, String url, String anchors) async {
    await _evaluateJavascript("loadFrame('$frame', '$url', $anchors)");
  }

  Future<void> _jumpToPage(int pageIndex) async {
    await _evaluateJavascript('jumpToPage($pageIndex)');
  }

  Future<void> _restoreScrollPosition(double ratio) async {
    await _evaluateJavascript('restoreScrollPosition($ratio)');
  }

  Future<void> _replaceStyles(String skeletonCss, String iframeCss) async {
    await _evaluateJavascript("replaceStyles(`$skeletonCss`, `$iframeCss`)");
  }

  Future<void> _checkElementAt(double x, double y) async {
    await _evaluateJavascript("checkElementAt($x, $y)");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: AbsorbPointer(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: generateSkeletonHtml(
                  widget.surfaceColor,
                  widget.onSurfaceColor,
                  widget.padding,
                ),
                baseUrl: WebUri(EpubWebViewHandler.getBaseUrl()),
              ),
              initialSettings: defaultSettings,
              onLongPressHitTestResult: (controller, hitTestResult) {
                if (hitTestResult.type ==
                    InAppWebViewHitTestResultType.IMAGE_TYPE) {
                  final imageUrl = hitTestResult.extra;
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    widget.callbacks.onImageLongPress(imageUrl);
                  }
                }
              },
              shouldInterceptRequest: (controller, request) async {
                return await widget.webViewHandler.handleRequest(
                  epubPath: widget.bookSession.book!.filePath!,
                  fileHash: widget.fileHash,
                  requestUrl: request.url,
                );
              },
              onLoadResourceWithCustomScheme: (controller, request) async {
                return await widget.webViewHandler
                    .handleRequestWithCustomScheme(
                      epubPath: widget.bookSession.book!.filePath!,
                      fileHash: widget.fileHash,
                      requestUrl: request.url,
                    );
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url!;
                if (uri.scheme == 'data') {
                  return NavigationActionPolicy.ALLOW;
                }
                if (EpubWebViewHandler.isEpubRequest(uri)) {
                  return NavigationActionPolicy.ALLOW;
                }
                return NavigationActionPolicy.CANCEL;
              },
              onWebViewCreated: (controller) {
                _controller = controller;
                _setupJavaScriptHandlers(controller);
                widget.onWebViewCreated?.call();
              },
              onLoadStop: (controller, url) async {
                final width = MediaQuery.of(context).size.width;
                final height = MediaQuery.of(context).size.height;
                await controller.evaluateJavascript(
                  source: generateControllerJs(
                    width - widget.padding.horizontal,
                    height - widget.padding.vertical,
                    widget.onSurfaceColor,
                    widget.padding.top,
                    widget.padding.left,
                  ),
                );
                widget.callbacks.onInitialized();
              },
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !widget.isLoading,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              opacity: widget.isLoading ? 1.0 : 0.0,
              child: Container(color: widget.surfaceColor),
            ),
          ),
        ),
      ],
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
      handlerName: 'onImageLongPress',
      callback: (args) {
        if (args.isNotEmpty && args[0] is String) {
          final imageUrl = args[0] as String;
          widget.callbacks.onImageLongPress(imageUrl);
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
      // for iOS, use WebView screenshot method
      final screenshotData = await _controller?.takeScreenshot(
        screenshotConfiguration: ScreenshotConfiguration(
          compressFormat: CompressFormat.JPEG,
          quality: 70,
        ),
      );
      if (screenshotData == null) return null;
      final codec = await ui.instantiateImageCodec(screenshotData);
      final frame = await codec.getNextFrame();
      return frame.image;
    }
  }

  Future<void> _updateTheme(
    Color surfaceColor,
    Color? onSurfaceColor,
    EdgeInsets padding,
  ) async {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final sketelonCss = generateSkeletonStyle(
      surfaceColor,
      onSurfaceColor,
      padding,
    );

    final iframeCss = generatePaginationCss(width, height, onSurfaceColor);

    final js = generateControllerJs(
      width - padding.horizontal,
      height - padding.vertical,
      onSurfaceColor,
      padding.top,
      padding.left,
    );

    await widget.controller.evaluateJavascript(js);
    await widget.controller.replaceStyles(sketelonCss, iframeCss);
  }
}
