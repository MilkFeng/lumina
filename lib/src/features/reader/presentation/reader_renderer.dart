import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/application/reader_settings_notifier.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';
import 'package:lumina/src/features/reader/domain/reader_settings.dart';

import '../data/book_session.dart';
import '../data/epub_webview_handler.dart';
import './reader_webview.dart';
import 'gestures/eager_tap_gesture_recognizer.dart';
import 'page_turn/page_turn.dart';

class ReaderRendererController {
  _ReaderRendererState? _rendererState;

  bool get isAttached => _rendererState != null;

  EpubTheme? get currentTheme => _rendererState?._currentTheme;

  ReaderWebViewController? get webViewController =>
      _rendererState?._webViewController;

  void _attachState(_ReaderRendererState? state) {
    _rendererState = state;
  }

  Future<void> performPreviousPageTurn() async {
    await webViewController?.waitForRender();
    await _rendererState?._performPageTurn(false);
  }

  Future<void> performNextPageTurn() async {
    await webViewController?.waitForRender();
    await _rendererState?._performPageTurn(true);
  }

  Future<void> jumpToPage(int pageIndex) async {
    await webViewController?.jumpToPage(pageIndex);
  }

  /// Scrolls by roughly one screen, used by the volume keys in scroll mode.
  ///
  /// One-shot: the page scrolls and animates itself, keeping a small overlap so
  /// the line that was at the edge stays visible.
  void scrollByViewport(bool isNext) {
    webViewController?.scrollByViewport(isNext);
  }

  Future<void> jumpToPreviousChapterLastPage() async {
    final token1 = await webViewController?.jumpToLastPageOfFrame('prev');
    final token2 = await webViewController?.cycleFrames('prev');
    final tokens = [token1, token2].whereType<int>().toList();
    await webViewController?.waitForEvents(tokens);
  }

  Future<void> jumpToPreviousChapterFirstPage() async {
    final token1 = await webViewController?.jumpToPageFor('prev', 0);
    final token2 = await webViewController?.cycleFrames('prev');
    final tokens = [token1, token2].whereType<int>().toList();
    await webViewController?.waitForEvents(tokens);
  }

  Future<void> jumpToNextChapter() async {
    final token1 = await webViewController?.jumpToPageFor('next', 0);
    final token2 = await webViewController?.cycleFrames('next');
    final tokens = [token1, token2].whereType<int>().toList();
    await webViewController?.waitForEvents(tokens);
  }

  /// Loads the current chapter, optionally starting it at [initialScrollRatio].
  ///
  /// The position travels with the load: the frame comes up already scrolled,
  /// instead of being moved afterwards by a separate scroll call.
  Future<int?> preloadCurrentChapter(
    String url,
    List<String> anchors,
    String? properties, {
    double? initialScrollRatio,
  }) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    final propertiesList = List<String>.from(properties?.split(' ') ?? []);
    final encodedPropertiesList = propertiesList
        .map((p) => p.replaceAll(':', '-COLON-'))
        .toList();
    final propertiesParam = encodedPropertiesList.map((p) => '"$p"').join(',');
    final propertiesJson = '[$propertiesParam]';
    return await webViewController?.loadFrame(
      'curr',
      url,
      anchorsJson,
      propertiesJson,
      initialScrollRatio: initialScrollRatio,
    );
  }

  Future<int?> preloadNextChapter(
    String url,
    List<String> anchors,
    String? properties,
  ) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    final propertiesList = List<String>.from(properties?.split(' ') ?? []);
    final encodedPropertiesList = propertiesList
        .map((p) => p.replaceAll(':', '-COLON-'))
        .toList();
    final propertiesParam = encodedPropertiesList.map((p) => '"$p"').join(',');
    final propertiesJson = '[$propertiesParam]';
    return await webViewController?.loadFrame(
      'next',
      url,
      anchorsJson,
      propertiesJson,
    );
  }

  Future<int?> preloadPreviousChapter(
    String url,
    List<String> anchors,
    String? properties,
  ) async {
    final anchorsParam = anchors.map((a) => '"$a"').join(',');
    final anchorsJson = '[$anchorsParam]';
    final propertiesList = List<String>.from(properties?.split(' ') ?? []);
    final encodedPropertiesList = propertiesList
        .map((p) => p.replaceAll(':', '-COLON-'))
        .toList();
    final propertiesParam = encodedPropertiesList.map((p) => '"$p"').join(',');
    final propertiesJson = '[$propertiesParam]';
    return await webViewController?.loadFrame(
      'prev',
      url,
      anchorsJson,
      propertiesJson,
    );
  }

  Future<void> updateTheme(EpubTheme theme) async {
    await _rendererState?._updateTheme(theme);
  }

  Future<void> waitForEvents(List<int> tokens) async {
    await webViewController?.waitForEvents(tokens);
  }

  Future<void> waitForEvent(int token) async {
    await webViewController?.waitForEvent(token);
  }
}

class ReaderRenderer extends ConsumerStatefulWidget {
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
  final ValueChanged<List<String>> onScrollAnchors;
  final Function(String imageUrl, Rect rect) onImageLongPress;
  final Function(String innerHtml, Rect rect, String baseUrl) onFootnoteTap;
  final Function(String url) onLinkTap;
  final bool Function(String url) shouldHandleLinkTap;
  final bool shouldShowWebView;
  final EpubTheme initializeTheme;
  final String statusBarLeftContent;
  final String statusBarRightContent;

  /// Whether the chapter scrolls continuously instead of paginating.
  final bool scrollMode;

  /// Reports the chapter scroll fraction on every scrolled frame.
  final ValueChanged<double> onScrollRatioChanged;

  /// Reports that the scroll has come to rest, so progress can be persisted.
  final VoidCallback onScrollSettled;

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
    required this.onScrollAnchors,
    required this.onImageLongPress,
    required this.onFootnoteTap,
    required this.onLinkTap,
    required this.shouldHandleLinkTap,
    required this.shouldShowWebView,
    required this.initializeTheme,
    required this.statusBarLeftContent,
    required this.statusBarRightContent,
    required this.scrollMode,
    required this.onScrollRatioChanged,
    required this.onScrollSettled,
  });

  bool get isVertical {
    return bookSession.direction == 1;
  }

  @override
  ConsumerState<ReaderRenderer> createState() => _ReaderRendererState();
}

class _ReaderRendererState extends ConsumerState<ReaderRenderer>
    with TickerProviderStateMixin {
  final GlobalKey _webViewKey = GlobalKey();
  final ReaderWebViewController _webViewController = ReaderWebViewController();

  late final AndroidPageTurnSession _androidPageTurnSession;
  late final IOSPageTurnSession _iosPageTurnSession;

  late EpubTheme _currentTheme;
  late bool _needPageTurnAnimation;

  EdgeInsets _addSafeAreaToPadding(EdgeInsets basePadding) {
    final safePaddings = MediaQuery.paddingOf(context);
    final safeBottomPadding = max(safePaddings.bottom, 32);
    return EdgeInsets.fromLTRB(
      basePadding.left + safePaddings.left,
      basePadding.top + safePaddings.top,
      basePadding.right + safePaddings.right,
      basePadding.bottom + safeBottomPadding,
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
    _needPageTurnAnimation =
        ref.read(readerSettingsProvider).pageAnimation !=
        ReaderPageAnimation.none;
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
        needAnimation: _needPageTurnAnimation,
        isNext: isNext,
        isVertical: widget.isVertical,
        onPerformPageTurn: widget.onPerformPageTurn,
        setState: setState,
        isMounted: () => mounted,
      );
    } else {
      await _iosPageTurnSession.perform(
        needAnimation: _needPageTurnAnimation,
        isNext: isNext,
        isVertical: widget.isVertical,
        onPerformPageTurn: widget.onPerformPageTurn,
      );
    }
  }

  /// Handles a tap in paginated mode, the one mode where Flutter owns it.
  ///
  /// Scroll mode has no Flutter tap to reach this: the page recognises its own
  /// taps and reports them over the bridge, which lands in [_handleTapZone]
  /// directly.
  void _handleTap(TapUpDetails details) {
    if (widget.showControls) {
      widget.onToggleControls();
    } else if (_androidPageTurnSession.isAnimating ||
        _iosPageTurnSession.isAnimating) {
      _handleTapZone(details.globalPosition.dx, details.globalPosition.dy);
    } else {
      _webViewController.checkTapElementAt(
        details.globalPosition.dx,
        details.globalPosition.dy,
      );
    }
  }

  void _handleTapZone(double x, double y) {
    // Scroll mode has no page-turn zones: scrolling is the only way through a
    // chapter, so any tap on the content just toggles the controls.
    if (widget.scrollMode) {
      widget.onToggleControls();
      return;
    }

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

  /// Handles a long press in paginated mode.
  ///
  /// Scroll mode reports image long presses from the page instead, because a
  /// recogniser that claims the arena there would keep the touch sequence away
  /// from the WebView.
  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    await _webViewController.checkLongPressElementAt(
      details.localPosition.dx,
      details.localPosition.dy,
    );
  }

  /// The recognizers this widget declares.
  ///
  /// Gesture ownership is split by layout mode, and this map is the whole
  /// contract.
  ///
  /// * Paginated: Flutter declares the tap, the long press and the horizontal
  ///   drag.  `ReaderWebView` puts an `AbsorbPointer` over the WebView, so the
  ///   platform view never competes in the arena and these are simply the
  ///   reader's own gestures.
  /// * Scroll mode: Flutter declares *nothing*.  The framework hands a pointer
  ///   sequence to a platform view only when no member of the gesture arena
  ///   claims it, so an empty map is exactly what lets every touch reach the
  ///   page.  Two things depend on that: the chapter scrolls with the browser's
  ///   own scroller, one compositor step per frame, instead of being pushed an
  ///   offset over the platform channel for each of them — and, the part that
  ///   cannot be given up, a touch-down arriving while the chapter is still
  ///   flinging is delivered, which is the only thing that aborts Chromium's
  ///   momentum scroll.  Claiming a tap here would buffer and then drop that
  ///   touch-down, which is why taps, links, footnotes and the image long press
  ///   are recognised inside the page instead and reported back over the bridge
  ///   — see `GestureObserver` in `web_assets/controller.js`.
  Map<Type, GestureRecognizerFactory> get _gestures {
    if (widget.scrollMode) {
      return const <Type, GestureRecognizerFactory>{};
    }

    return <Type, GestureRecognizerFactory>{
      // Not a plain TapGestureRecognizer: a tap is decided by the arena sweep,
      // which goes to whoever joined first.  See
      // `EagerTapGestureRecognizer`.
      EagerTapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<EagerTapGestureRecognizer>(
            () => EagerTapGestureRecognizer(debugOwner: this),
            (instance) {
              instance.onTapUp = widget.shouldShowWebView ? _handleTap : null;
            },
          ),
      LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(debugOwner: this),
            (instance) {
              instance.onLongPressStart = widget.shouldShowWebView
                  ? _handleLongPressStart
                  : null;
            },
          ),
      if (widget.shouldShowWebView)
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(() => HorizontalDragGestureRecognizer(debugOwner: this), (
              instance,
            ) {
              instance.onEnd = _handleHorizontalDragEnd;
            }),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(readerSettingsProvider, (previous, next) {
      if (previous?.pageAnimation != next.pageAnimation) {
        setState(() {
          _needPageTurnAnimation =
              next.pageAnimation != ReaderPageAnimation.none;
        });
      }
    });

    return Positioned.fill(
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: _gestures,
        child: Stack(
          fit: StackFit.expand,
          children: [_buildBody(), _buildBottomStatusBarOverlay()],
        ),
      ),
    );
  }

  Widget _buildBottomStatusBarOverlay() {
    Widget buildBadge(
      String content,
      bool tabular, {
      TextOverflow overflow = TextOverflow.clip,
    }) {
      return Text(
        content,
        overflow: overflow,
        style: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
          shadows: [
            Shadow(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.5),
              blurRadius: 1.0,
              offset: Offset.zero,
            ),
          ],
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      // The badges are decoration and own no gesture, but a `Text` still absorbs
      // the hit test, and this band sits *above* the WebView in the stack.  Left
      // as is, the bottom of the screen would swallow touches in scroll mode,
      // where no Flutter recognizer is left to pick them up — no page scroll, no
      // tap.  Letting them through costs nothing: the badges have no behaviour to
      // lose.
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.only(left: 32, right: 32, bottom: 8),
          constraints: const BoxConstraints(minHeight: 32, maxHeight: 32),
          child: AnimatedOpacity(
            duration: (widget.isLoading || !widget.shouldShowWebView)
                ? Duration.zero
                : const Duration(
                    milliseconds: AppTheme.defaultAnimationDurationMs,
                  ),
            curve: Curves.easeOut,
            opacity: (widget.isLoading || !widget.shouldShowWebView)
                ? 0.0
                : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: buildBadge(
                    widget.statusBarLeftContent,
                    false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                buildBadge(widget.statusBarRightContent, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Platform.isAndroid
        ? _androidPageTurnSession.buildAnimatedContainer(
            context,
            _buildWebView(),
            _buildScreenshotContainer,
          )
        : _iosPageTurnSession.buildAnimatedContainer(context, _buildWebView());
  }

  Widget _buildContentWrapper(Widget child) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(
              alpha: _currentTheme.isDark ? 0.3 : 0.15,
            ),
            blurRadius: 25,
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
          onScrollAnchors: widget.onScrollAnchors,
          onScrollProgress: (offset, maxOffset) {
            // A chapter that fits on one screen has nothing left to read, so it
            // counts as fully scrolled — same as the old offset/width ratio.
            widget.onScrollRatioChanged(
              maxOffset <= 0 ? 1 : (offset / maxOffset).clamp(0.0, 1.0),
            );
          },
          onScrollSettled: widget.onScrollSettled,
          onImageLongPress: widget.onImageLongPress,
          onTap: _handleTapZone,
          onFootnoteTap: widget.onFootnoteTap,
          onLinkTap: widget.onLinkTap,
          shouldHandleLinkTap: widget.shouldHandleLinkTap,
        ),
        shouldShowWebView: widget.shouldShowWebView,
        coverRelativePath: widget.bookSession.book?.coverPath,
        direction: widget.bookSession.direction,
        scrollMode: widget.scrollMode,
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
