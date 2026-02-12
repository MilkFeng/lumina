import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import './book_session.dart';
import './epub_webview_handler.dart';
import './reader_webview.dart';

class ReaderRendererController {
  final ReaderWebViewController _webViewController = ReaderWebViewController();
  _ReaderRendererState? _rendererState;

  ReaderWebViewController get webViewController => _webViewController;

  void _attachState(_ReaderRendererState? state) {
    _rendererState = state;
  }

  Future<void> performPreviousPageTurn() async {
    await _rendererState?.performPageTurn(false);
  }

  Future<void> performNextPageTurn() async {
    await _rendererState?.performPageTurn(true);
  }

  Future<void> jumpToPage(int pageIndex) async {
    await _webViewController.jumpToPage(pageIndex);
  }

  Future<void> restoreScrollPosition(double ratio) async {
    await _webViewController.restoreScrollPosition(ratio);
  }

  Future<void> checkElementAt(double x, double y) async {
    await _webViewController.checkElementAt(x, y);
  }

  Future<void> jumpToPreviousChapter() async {
    await _webViewController.jumpToLastPageOfFrame('prev');
    await _webViewController.cycleFrames('prev');
  }

  Future<void> jumpToPreviousChapterFirstPage() async {
    await _webViewController.jumpToPageFor('prev', 0);
    await _webViewController.cycleFrames('prev');
  }

  Future<void> jumpToNextChapter() async {
    await _webViewController.jumpToPageFor('next', 0);
    await _webViewController.cycleFrames('next');
  }

  Future<void> preloadCurrentChapter(String url, List<String> anchors) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    await _webViewController.loadFrame('curr', url, anchorsJson);
  }

  Future<void> preloadNextChapter(String url, List<String> anchors) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    await _webViewController.loadFrame('next', url, anchorsJson);
  }

  Future<void> preloadPreviousChapter(String url, List<String> anchors) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    await _webViewController.loadFrame('prev', url, anchorsJson);
  }

  Future<ui.Image?> takeScreenshot() async {
    return _webViewController.takeScreenshot();
  }

  Future<void> updateTheme(Color surfaceColor, Color? onSurfaceColor) async {
    await _webViewController.updateTheme(surfaceColor, onSurfaceColor);
  }
}

class ReaderRenderer extends StatefulWidget {
  final ReaderRendererController controller;
  final BookSession bookSession;
  final EpubWebViewHandler webViewHandler;
  final String fileHash;
  final bool showControls;
  final bool isLoading;
  final bool Function(bool isNext) canPerformPageTurn;
  final Future<void> Function(bool isNext) onPerformPageTurn;
  final VoidCallback onToggleControls;
  final Future<void> Function() onInitialized;
  final Future<void> Function(int totalPages) onPageCountReady;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onReveal;
  final VoidCallback onRenderComplete;
  final ValueChanged<List<String>> onScrollAnchors;
  final ValueChanged<String> onImageLongPress;

  const ReaderRenderer({
    super.key,
    required this.controller,
    required this.bookSession,
    required this.webViewHandler,
    required this.fileHash,
    required this.showControls,
    required this.isLoading,
    required this.canPerformPageTurn,
    required this.onPerformPageTurn,
    required this.onToggleControls,
    required this.onInitialized,
    required this.onPageCountReady,
    required this.onPageChanged,
    required this.onReveal,
    required this.onRenderComplete,
    required this.onScrollAnchors,
    required this.onImageLongPress,
  });

  @override
  State<ReaderRenderer> createState() => _ReaderRendererState();
}

class _ReaderRendererState extends State<ReaderRenderer>
    with TickerProviderStateMixin {
  final GlobalKey _webViewKey = GlobalKey();

  late final AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  ui.Image? _screenshotData;
  bool _isAnimating = false;
  bool _isForwardAnimation = true;

  double _webviewWidth = 0;
  double _webviewHeight = 0;

  @override
  void initState() {
    super.initState();
    widget.controller._attachState(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
  }

  @override
  void dispose() {
    widget.controller._attachState(null);
    _animController.dispose();
    super.dispose();
  }

  Future<void> performPageTurn(bool isNext) async {
    if (_isAnimating) return;
    if (!widget.canPerformPageTurn(isNext)) return;

    _isAnimating = true;
    ui.Image? screenshot;
    try {
      screenshot = await widget.controller.takeScreenshot();
    } catch (e) {
      debugPrint('Error taking screenshot: $e');
      screenshot = null;
    }

    if (screenshot == null) {
      _isAnimating = false;
      await widget.onPerformPageTurn(isNext);
      return;
    }

    if (!mounted) {
      _isAnimating = false;
      return;
    }

    setState(() {
      _isForwardAnimation = isNext;
      _screenshotData = screenshot;

      if (isNext) {
        _slideAnimation =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(
              CurvedAnimation(
                parent: _animController,
                curve: Curves.easeInCubic,
              ),
            );
      } else {
        _slideAnimation =
            Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animController,
                curve: Curves.easeInCubic,
              ),
            );
      }
    });

    _animController.reset();
    await widget.onPerformPageTurn(isNext);

    if (!mounted) {
      _isAnimating = false;
      return;
    }

    try {
      await _animController.forward();
    } finally {
      if (mounted) {
        setState(() {
          _screenshotData = null;
        });
      }
      _animController.reset();
      _isAnimating = false;
    }
  }

  void _handleTapZone(double globalDx) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 0) return;

    final ratio = globalDx / width;
    if (ratio < 0.2) {
      if (widget.showControls) {
        widget.onToggleControls();
        return;
      }
      performPageTurn(false);
    } else if (ratio > 0.8) {
      if (widget.showControls) {
        widget.onToggleControls();
        return;
      }
      performPageTurn(true);
    } else {
      widget.onToggleControls();
    }
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    const padding = 16.0;

    final localX = details.localPosition.dx - padding;
    final localY = details.localPosition.dy - padding;

    if (localX < 0 ||
        localY < 0 ||
        localX > _webviewWidth ||
        localY > _webviewHeight) {
      return;
    }

    await widget.controller.checkElementAt(localX, localY);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          _handleTapZone(details.globalPosition.dx);
        },
        onHorizontalDragEnd: (details) {
          if (_isAnimating) return;
          final velocity = details.primaryVelocity ?? 0;

          if (velocity < -200) {
            performPageTurn(true);
          } else if (velocity > 200) {
            performPageTurn(false);
          }
        },
        onLongPressStart: _handleLongPressStart,
        child: Stack(
          children: [
            if (_screenshotData != null && _isAnimating && !_isForwardAnimation)
              Positioned.fill(
                child: _buildScreenshotContainer(_screenshotData!),
              ),
            Positioned.fill(
              child: SlideTransition(
                position: _isAnimating && !_isForwardAnimation
                    ? _slideAnimation
                    : const AlwaysStoppedAnimation(Offset.zero),
                child: _buildWebViewStack(),
              ),
            ),
            if (_screenshotData != null && _isAnimating && _isForwardAnimation)
              Positioned.fill(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildScreenshotContainer(_screenshotData!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentWrapper(Widget child) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
        color: Theme.of(context).colorScheme.surface,
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(alignment: AlignmentGeometry.center, child: child),
        ),
      ),
    );
  }

  Widget _buildWebViewStack() {
    return _buildContentWrapper(
      LayoutBuilder(
        builder: (context, constraints) {
          final viewWidth = constraints.maxWidth;
          final viewHeight = constraints.maxHeight;
          final maskColor = Theme.of(context).colorScheme.surface;

          _webviewWidth = viewWidth;
          _webviewHeight = viewHeight;

          return ReaderWebView(
            key: _webViewKey,
            bookSession: widget.bookSession,
            webViewHandler: widget.webViewHandler,
            fileHash: widget.fileHash,
            width: viewWidth,
            height: viewHeight,
            surfaceColor: maskColor,
            onSurfaceColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurface
                : null,
            isLoading: widget.isLoading,
            controller: widget.controller.webViewController,
            callbacks: ReaderWebViewCallbacks(
              onInitialized: () async {
                await widget.onInitialized();
              },
              onPageCountReady: (totalPages) async {
                await widget.onPageCountReady(totalPages);
              },
              onPageChanged: widget.onPageChanged,
              onTapLeft: () {
                if (widget.showControls) {
                  widget.onToggleControls();
                  return;
                }
                performPageTurn(false);
              },
              onTapRight: () {
                if (widget.showControls) {
                  widget.onToggleControls();
                  return;
                }
                performPageTurn(true);
              },
              onTapCenter: () {
                widget.onToggleControls();
              },
              onReveal: widget.onReveal,
              onRenderComplete: widget.onRenderComplete,
              onScrollAnchors: widget.onScrollAnchors,
              onImageLongPress: widget.onImageLongPress,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenshotContainer(ui.Image screenshot) {
    return _buildContentWrapper(RawImage(image: screenshot, fit: BoxFit.cover));
  }
}
