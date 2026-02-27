import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

import '../data/book_session.dart';
import '../data/epub_webview_handler.dart';
import './reader_webview.dart';
import 'page_turn/page_turn.dart';

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

  Future<void> updateTheme(EpubTheme theme) async {
    await _rendererState?._updateTheme(theme);
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
  final Function(String innerHtml, Rect rect) onFootnoteTap;
  final Function(String url, Rect rect) onLinkTap;
  final bool Function(String url, Rect rect) shouldHandleLinkTap;
  final bool shouldShowWebView;
  final EpubTheme initializeTheme;

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
    required this.onFootnoteTap,
    required this.onLinkTap,
    required this.shouldHandleLinkTap,
    required this.shouldShowWebView,
    required this.initializeTheme,
  });

  bool get isVertical {
    return bookSession.direction == 1;
  }

  @override
  State<ReaderRenderer> createState() => _ReaderRendererState();
}

class _ReaderRendererState extends State<ReaderRenderer>
    with TickerProviderStateMixin {
  final GlobalKey _webViewKey = GlobalKey();
  final ReaderWebViewController _webViewController = ReaderWebViewController();

  late final AndroidPageTurnSession _androidPageTurnSession;
  late final IOSPageTurnSession _iosPageTurnSession;

  late EpubTheme _currentTheme;

  EdgeInsets _addSafeAreaToPadding(EdgeInsets basePadding) {
    final safePaddings = MediaQuery.paddingOf(context);
    return EdgeInsets.fromLTRB(
      basePadding.left + safePaddings.left,
      basePadding.top + safePaddings.top,
      basePadding.right + safePaddings.right,
      basePadding.bottom + safePaddings.bottom,
    );
  }

  EpubTheme _addSafeAreaToThemePadding(EpubTheme theme) {
    final newPadding = _addSafeAreaToPadding(theme.padding);
    return theme.copyWith(padding: newPadding);
  }

  Future<void> _updateTheme(EpubTheme theme) async {
    _currentTheme = theme;
    await _webViewController.updateTheme(
      theme.copyWith(padding: _addSafeAreaToPadding(theme.padding)),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller._attachState(this);
    _androidPageTurnSession = AndroidPageTurnSession(
      vsync: this,
      duration: const Duration(
        milliseconds: AppTheme.defaultAnimationDurationMs,
      ),
    );
    _iosPageTurnSession = IOSPageTurnSession();
    _currentTheme = widget.initializeTheme;
  }

  @override
  void dispose() {
    widget.controller._attachState(null);
    _androidPageTurnSession.dispose();
    super.dispose();
  }

  Future<void> _performPageTurn(bool isNext) async {
    if (!widget.canPerformPageTurn(isNext)) return;

    if (Platform.isAndroid) {
      await _androidPageTurnSession.perform(
        webViewController: _webViewController,
        isNext: isNext,
        isVertical: widget.isVertical,
        onPerformPageTurn: widget.onPerformPageTurn,
        setState: setState,
        isMounted: () => mounted,
      );
    } else {
      await _iosPageTurnSession.perform(
        isNext: isNext,
        isVertical: widget.isVertical,
        onPerformPageTurn: widget.onPerformPageTurn,
      );
    }
  }

  void _handleTap(TapUpDetails details) {
    if (widget.showControls) {
      widget.onToggleControls();
      return;
    } else {
      _webViewController.checkTapElementAt(
        details.globalPosition.dx,
        details.globalPosition.dy,
      );
    }
  }

  void _handleTapZone(double x, double y) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 0) return;

    final ratio = x / width;
    if (ratio < 0.3) {
      if (widget.showControls) {
        widget.onToggleControls();
        return;
      }
      if (widget.isVertical) {
        _performPageTurn(true);
      } else {
        _performPageTurn(false);
      }
    } else if (ratio > 0.7) {
      if (widget.showControls) {
        widget.onToggleControls();
        return;
      }
      if (widget.isVertical) {
        _performPageTurn(false);
      } else {
        _performPageTurn(true);
      }
    } else {
      widget.onToggleControls();
    }
  }

  Future<void> _handleHorizontalDragEnd(DragEndDetails details) async {
    if (widget.showControls) {
      return;
    }
    final velocity = details.primaryVelocity ?? 0;

    if (velocity < -200) {
      if (widget.isVertical) {
        await _performPageTurn(false);
      } else {
        await _performPageTurn(true);
      }
    } else if (velocity > 200) {
      if (widget.isVertical) {
        await _performPageTurn(true);
      } else {
        await _performPageTurn(false);
      }
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
        onTapUp: widget.shouldShowWebView ? _handleTap : null,
        onHorizontalDragEnd: widget.shouldShowWebView
            ? _handleHorizontalDragEnd
            : null,
        onLongPressStart: widget.shouldShowWebView
            ? _handleLongPressStart
            : null,
        child: Platform.isAndroid
            ? _androidPageTurnSession.buildAnimatedContainer(
                context,
                _buildWebView(),
                _buildScreenshotContainer,
              )
            : _iosPageTurnSession.buildAnimatedContainer(
                context,
                _buildWebView(),
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
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: Offset.zero,
          ),
        ],
        color: _currentTheme.surfaceColor,
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
        initializeTheme: _addSafeAreaToThemePadding(widget.initializeTheme),
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
          onTap: _handleTapZone,
          onFootnoteTap: widget.onFootnoteTap,
          onLinkTap: widget.onLinkTap,
          shouldHandleLinkTap: widget.shouldHandleLinkTap,
        ),
        shouldShowWebView: widget.shouldShowWebView,
        coverRelativePath: widget.bookSession.book?.coverPath,
        direction: widget.bookSession.direction,
      ),
    );
  }

  Widget _buildScreenshotContainer(ui.Image? screenshot) {
    if (screenshot == null) {
      return _buildContentWrapper(Container(color: _currentTheme.surfaceColor));
    }
    return _buildContentWrapper(RawImage(image: screenshot, fit: BoxFit.cover));
  }
}
