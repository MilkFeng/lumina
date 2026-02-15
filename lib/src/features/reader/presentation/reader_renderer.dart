import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../data/book_session.dart';
import '../data/epub_webview_handler.dart';
import './reader_webview.dart';

class ReaderRendererController {
  _ReaderRendererState? _rendererState;

  bool get isAttached => _rendererState != null;

  ReaderWebViewController? get webViewController =>
      _rendererState?._webViewController;

  void _attachState(_ReaderRendererState? state) {
    _rendererState = state;
  }

  Future<void> performPreviousPageTurn() async {
    await _rendererState?._performPageTurn(false);
  }

  Future<void> performNextPageTurn() async {
    await _rendererState?._performPageTurn(true);
  }

  Future<void> jumpToPage(int pageIndex) async {
    await webViewController?.jumpToPage(pageIndex);
  }

  Future<void> restoreScrollPosition(double ratio) async {
    await webViewController?.restoreScrollPosition(ratio);
  }

  Future<void> jumpToPreviousChapterLastPage() async {
    await webViewController?.jumpToLastPageOfFrame('prev');
    await webViewController?.cycleFrames('prev');
  }

  Future<void> jumpToPreviousChapterFirstPage() async {
    await webViewController?.jumpToPageFor('prev', 0);
    await webViewController?.cycleFrames('prev');
  }

  Future<void> jumpToNextChapter() async {
    await webViewController?.jumpToPageFor('next', 0);
    await webViewController?.cycleFrames('next');
  }

  Future<void> preloadCurrentChapter(String url, List<String> anchors) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    await webViewController?.loadFrame('curr', url, anchorsJson);
  }

  Future<void> preloadNextChapter(String url, List<String> anchors) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    await webViewController?.loadFrame('next', url, anchorsJson);
  }

  Future<void> preloadPreviousChapter(String url, List<String> anchors) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    await webViewController?.loadFrame('prev', url, anchorsJson);
  }

  Future<void> updateTheme(Color surfaceColor, Color? onSurfaceColor) async {
    await webViewController?.updateTheme(
      surfaceColor,
      onSurfaceColor,
      _rendererState!.padding,
    );
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
  final VoidCallback onRendererInitialized;
  final ValueChanged<List<String>> onScrollAnchors;
  final Function(String imageUrl, Rect rect) onImageLongPress;

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
    required this.onRendererInitialized,
    required this.onScrollAnchors,
    required this.onImageLongPress,
  });

  @override
  State<ReaderRenderer> createState() => _ReaderRendererState();
}

class _ReaderRendererState extends State<ReaderRenderer>
    with TickerProviderStateMixin {
  static const MethodChannel _nativePageTurnChannel = MethodChannel(
    'lumina/reader_page_turn',
  );

  final GlobalKey _webViewKey = GlobalKey();
  final ReaderWebViewController _webViewController = ReaderWebViewController();

  late final AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  ui.Image? _screenshotData;
  bool _isAnimating = false;
  bool _isForwardAnimation = true;
  int _androidPageTurnToken = 0;

  EdgeInsets get padding {
    var safePaddings = MediaQuery.paddingOf(context);
    double topPadding = safePaddings.top;
    double leftPadding = safePaddings.left;
    double rightPadding = safePaddings.right;
    double bottomPadding = safePaddings.bottom;

    const padding = 16.0;

    return EdgeInsets.fromLTRB(
      padding + leftPadding,
      padding + topPadding,
      padding + rightPadding,
      padding + bottomPadding,
    );
  }

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
    _screenshotData?.dispose();
    widget.controller._attachState(null);
    _animController.dispose();
    super.dispose();
  }

  Future<void> _performPageTurn(bool isNext) async {
    if (!widget.canPerformPageTurn(isNext)) return;

    if (Platform.isAndroid) {
      await _performAndroidPageTurn(isNext);
      return;
    }

    _isAnimating = true;

    try {
      await _prepareNativePageTurn();
      await widget.onPerformPageTurn(isNext);
      await _animateNativePageTurn(isNext);
    } finally {
      _isAnimating = false;
    }
  }

  Future<void> _performAndroidPageTurn(bool isNext) async {
    final int turnToken = ++_androidPageTurnToken;
    _isAnimating = true;

    if (_animController.isAnimating) {
      _animController.stop();
    }

    ui.Image? screenshot;
    try {
      screenshot = await _webViewController.takeScreenshot();
    } catch (e) {
      debugPrint('Error taking screenshot: $e');
      screenshot = null;
    }

    if (screenshot == null) {
      _screenshotData?.dispose();
      setState(() {
        _screenshotData = null;
      });
      _animController.reset();

      await widget.onPerformPageTurn(isNext);
      if (turnToken == _androidPageTurnToken) {
        _isAnimating = false;
      }
      return;
    }

    if (!mounted || turnToken != _androidPageTurnToken) {
      screenshot.dispose();
      _isAnimating = false;
      return;
    }

    setState(() {
      _isForwardAnimation = isNext;

      _screenshotData?.dispose();
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
      _animController.reset();
    });

    await widget.onPerformPageTurn(isNext);

    if (!mounted || turnToken != _androidPageTurnToken) {
      _isAnimating = false;
      return;
    }

    try {
      await _animController.forward();
    } finally {
      if (turnToken == _androidPageTurnToken) {
        final finishedScreenshot = _screenshotData;
        if (mounted) {
          setState(() {
            _screenshotData = null;
          });
        } else {
          _screenshotData = null;
        }
        finishedScreenshot?.dispose();

        _animController.reset();
        _isAnimating = false;
      }
    }
  }

  Future<void> _prepareNativePageTurn() async {
    if (!Platform.isIOS) return;
    try {
      await _nativePageTurnChannel.invokeMethod<void>('preparePageTurn');
    } on MissingPluginException {
      // no-op for configurations without iOS native channel
    } catch (e) {
      debugPrint('preparePageTurn failed: $e');
    }
  }

  Future<void> _animateNativePageTurn(bool isNext) async {
    if (!Platform.isIOS) return;
    try {
      await _nativePageTurnChannel.invokeMethod<void>('animatePageTurn', {
        'isNext': isNext,
      });
    } on MissingPluginException {
      // no-op for configurations without iOS native channel
    } catch (e) {
      debugPrint('animatePageTurn failed: $e');
    }
  }

  void _handleTapZone(TapUpDetails details) {
    final globalDx = details.globalPosition.dx;

    final width = MediaQuery.of(context).size.width;
    if (width <= 0) return;

    final ratio = globalDx / width;
    if (ratio < 0.2) {
      if (widget.showControls) {
        widget.onToggleControls();
        return;
      }
      _performPageTurn(false);
    } else if (ratio > 0.8) {
      if (widget.showControls) {
        widget.onToggleControls();
        return;
      }
      _performPageTurn(true);
    } else {
      widget.onToggleControls();
    }
  }

  Future<void> _handleHorizontalDragEnd(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity < -200) {
      _performPageTurn(true);
    } else if (velocity > 200) {
      _performPageTurn(false);
    }
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    await _webViewController.checkElementAt(
      details.localPosition.dx,
      details.localPosition.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _handleTapZone,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        onLongPressStart: _handleLongPressStart,
        child: Platform.isAndroid
            ? Stack(
                children: [
                  if (_isAnimating && !_isForwardAnimation)
                    Positioned.fill(
                      child: _buildScreenshotContainer(_screenshotData!),
                    ),
                  Positioned.fill(
                    child: SlideTransition(
                      position: _isAnimating && !_isForwardAnimation
                          ? _slideAnimation
                          : const AlwaysStoppedAnimation(Offset.zero),
                      child: _buildWebView(),
                    ),
                  ),
                  if (_isAnimating && _isForwardAnimation)
                    Positioned.fill(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildScreenshotContainer(_screenshotData!),
                      ),
                    ),
                ],
              )
            : _buildWebView(),
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
      child: Container(alignment: AlignmentGeometry.center, child: child),
    );
  }

  Widget _buildWebView() {
    return _buildContentWrapper(
      ReaderWebView(
        key: _webViewKey,
        bookSession: widget.bookSession,
        webViewHandler: widget.webViewHandler,
        fileHash: widget.fileHash,
        surfaceColor: Theme.of(context).colorScheme.surface,
        onSurfaceColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.onSurface
            : null,
        padding: padding,
        isLoading: widget.isLoading,
        controller: _webViewController,
        callbacks: ReaderWebViewCallbacks(
          onInitialized: () async {
            await widget.onInitialized();
          },
          onPageCountReady: (totalPages) async {
            await widget.onPageCountReady(totalPages);
          },
          onPageChanged: widget.onPageChanged,
          onRendererInitialized: widget.onRendererInitialized,
          onScrollAnchors: widget.onScrollAnchors,
          onImageLongPress: widget.onImageLongPress,
        ),
      ),
    );
  }

  Widget _buildScreenshotContainer(ui.Image? screenshot) {
    if (screenshot == null) {
      return _buildContentWrapper(
        Container(color: Theme.of(context).colorScheme.surface),
      );
    }
    return _buildContentWrapper(RawImage(image: screenshot, fit: BoxFit.cover));
  }
}
