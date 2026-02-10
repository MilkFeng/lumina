import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import './book_session.dart';
import './epub_webview_handler.dart';
import '../data/reader_scripts.dart';

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
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final VoidCallback onTapCenter;
  final VoidCallback onRenderComplete;
  final Function(List<String> anchors) onScrollAnchors;
  final Function(String imageUrl) onImageLongPress;
  final Function(double? scrollPosition) onReveal;

  const ReaderWebViewCallbacks({
    required this.onInitialized,
    required this.onPageCountReady,
    required this.onPageChanged,
    required this.onTapLeft,
    required this.onTapRight,
    required this.onTapCenter,
    required this.onRenderComplete,
    required this.onScrollAnchors,
    required this.onImageLongPress,
    required this.onReveal,
  });
}

/// WebView widget for reading EPUB content
class ReaderWebView extends StatefulWidget {
  final BookSession bookSession;
  final EpubWebViewHandler webViewHandler;
  final String fileHash;
  final ReaderWebViewCallbacks callbacks;
  final double width;
  final double height;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final bool isLoading;
  final VoidCallback? onWebViewCreated;

  const ReaderWebView({
    super.key,
    required this.bookSession,
    required this.webViewHandler,
    required this.fileHash,
    required this.callbacks,
    required this.width,
    required this.height,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.isLoading,
    this.onWebViewCreated,
  });

  @override
  State<ReaderWebView> createState() => ReaderWebViewState();
}

class ReaderWebViewState extends State<ReaderWebView> {
  final GlobalKey _webViewKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();

  InAppWebViewController? _controller;

  InAppWebViewController? get controller => _controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: InAppWebView(
            key: _webViewKey,
            initialData: InAppWebViewInitialData(
              data: generateSkeletonHtml(
                widget.surfaceColor,
                widget.onSurfaceColor,
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
              return await widget.webViewHandler.handleRequestWithCustomScheme(
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
              await controller.evaluateJavascript(
                source: generateControllerJs(
                  widget.width,
                  widget.height,
                  widget.onSurfaceColor,
                ),
              );
              widget.callbacks.onInitialized();
            },
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
      handlerName: 'onGoToPage',
      callback: (args) {
        if (args.isNotEmpty && args[0] is int) {
          widget.callbacks.onPageChanged(args[0] as int);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onTapLeft',
      callback: (args) {
        widget.callbacks.onTapLeft();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onTapRight',
      callback: (args) {
        widget.callbacks.onTapRight();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onTapCenter',
      callback: (args) {
        widget.callbacks.onTapCenter();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onReveal',
      callback: (args) async {
        double? scrollPosition;
        if (args.isNotEmpty && args[0] is num) {
          scrollPosition = (args[0] as num).toDouble();
        }
        widget.callbacks.onReveal(scrollPosition);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onRenderComplete',
      callback: (args) async {
        await Future.delayed(const Duration(milliseconds: 50));
        await _controller?.evaluateJavascript(source: "reveal();");
        widget.callbacks.onRenderComplete();
        debugPrint('WebView: RenderComplete');
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

  Future<void> evaluateJavascript(String source) async {
    await _controller?.evaluateJavascript(source: source);
  }

  Future<ui.Image?> takeScreenshot() async {
    final BuildContext? context = _repaintKey.currentContext;
    if (context == null) return null;

    final RenderRepaintBoundary? boundary =
        context.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) return null;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    return image;
  }

  // JavaScript wrapper methods
  Future<void> jumpToLastPageOfFrame(String frame) async {
    await evaluateJavascript("jumpToLastPageOfFrame('$frame')");
  }

  Future<void> cycleFrames(String direction) async {
    await evaluateJavascript("cycleFrames('$direction')");
  }

  Future<void> jumpToPageFor(String frame, int pageIndex) async {
    await evaluateJavascript("jumpToPageFor('$frame', $pageIndex)");
  }

  Future<void> loadFrame(String frame, String url, String anchors) async {
    await evaluateJavascript("loadFrame('$frame', '$url', $anchors)");
  }

  Future<void> jumpToPage(int pageIndex) async {
    await evaluateJavascript('jumpToPage($pageIndex)');
  }

  Future<void> restoreScrollPosition(double ratio) async {
    await evaluateJavascript('restoreScrollPosition($ratio)');
  }

  Future<void> replaceStyles(String skeletonCss, String iframeCss) async {
    await evaluateJavascript("replaceStyles(`$skeletonCss`, `$iframeCss`)");
  }

  Future<void> checkElementAt(double x, double y) async {
    await evaluateJavascript("checkElementAt($x, $y)");
  }
}
