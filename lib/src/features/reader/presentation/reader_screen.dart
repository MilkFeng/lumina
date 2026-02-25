import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/presentation/reader_webview.dart';
import '../../../core/services/toast_service.dart';
import '../../library/domain/book_manifest.dart';
import './image_viewer.dart';
import '../data/book_session.dart';
import './reader_renderer.dart';
import './control_panel.dart';
import '../data/services/epub_stream_service_provider.dart';
import '../data/epub_webview_handler.dart';
import './toc_drawer.dart';
import '../../../../l10n/app_localizations.dart';

/// Reads EPUB directly from compressed file without extraction
class ReaderScreen extends ConsumerStatefulWidget {
  final String fileHash; // Changed from bookId to fileHash

  const ReaderScreen({super.key, required this.fileHash});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  late final EpubWebViewHandler _webViewHandler;
  late final BookSession _bookSession;
  final ReaderRendererController _rendererController =
      ReaderRendererController();

  // State
  bool _isWebViewLoading = true;
  bool _updatingTheme = false;
  bool _showControls = false;
  int _currentSpineItemIndex = 0;

  // Pagination
  int _currentPageInChapter = 0;
  int _totalPagesInChapter = 1;
  double? _initialProgressToRestore;

  // WebView visibility control for smoother transitions
  Animation<double>? _routeAnimation;
  bool _shouldShowWebView = false;

  // Image viewer state
  bool _isImageViewerVisible = false;
  String? _currentImageUrl;
  Rect? _currentImageRect;

  ThemeData? _currentTheme;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _webViewHandler = EpubWebViewHandler(
      streamService: ref.read(epubStreamServiceProvider),
    );
    _bookSession = BookSession(fileHash: widget.fileHash);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _loadBook();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ModalRoute.of(context);
      _currentTheme = Theme.of(context);
      if (router != null && router.animation != null) {
        _routeAnimation = router.animation!;
        _routeAnimation?.addStatusListener(_handleRouteAnimationStatus);
      } else {
        _shouldShowWebView = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    _routeAnimation = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveProgress();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update WebView theme when system theme changes
    if (_currentTheme == null || _currentTheme != Theme.of(context)) {
      _currentTheme = Theme.of(context);
      _updateWebViewTheme();
    }
  }

  void _handleRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _shouldShowWebView = true;
      });
      _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
      _routeAnimation = null;
    }
  }

  /// Load ShelfBook + BookManifest from database
  Future<void> _loadBook() async {
    try {
      final loaded = await _bookSession.loadBook(ref);

      if (!loaded) {
        if (mounted) {
          ToastService.showError(AppLocalizations.of(context)!.bookNotFound);
          context.pop();
        }
        return;
      }

      setState(() {
        _currentSpineItemIndex = _bookSession.initialChapterIndex;
        _initialProgressToRestore = _bookSession.initialScrollPosition;
      });
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.errorLoadingBook(e.toString()),
        );
        context.pop();
      }
    }
  }

  /// Save progress using ShelfBookRepository
  Future<void> _saveProgress() async {
    await _bookSession.saveProgress(
      ref,
      currentChapterIndex: _currentSpineItemIndex,
      currentPageInChapter: _currentPageInChapter,
      totalPagesInChapter: _totalPagesInChapter,
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _navigateToSpineItem(int index, [String anchor = 'top']) async {
    if (index < 0 || index >= _bookSession.spine.length) return;

    setState(() {
      _currentSpineItemIndex = index;
      _currentPageInChapter = 0; // Reset to first page of new chapter
      _initialProgressToRestore = null;
    });

    await _loadCarousel(anchor);
    _saveProgress();
  }

  List<String> _getAnchorsForSpine(String spinePath) {
    return _bookSession.getAnchorsForSpine(spinePath);
  }

  /// Inject TOC anchor whitelist into JS for the given spine file
  /// This is called when a frame is loaded with a new chapter
  void _handleScrollAnchors(List<String> anchorIds) {
    setState(() {
      _bookSession.updateActiveAnchors(anchorIds);
    });
  }

  Future<void> _previousSpineItem() async {
    if (_currentSpineItemIndex <= 0) {
      ToastService.showError(AppLocalizations.of(context)!.firstChapterOfBook);
      return;
    }

    await _rendererController.jumpToPreviousChapterLastPage();

    setState(() {
      _currentSpineItemIndex--;
      _initialProgressToRestore = null;
    });

    _preloadPreviousOf(_currentSpineItemIndex);
    _saveProgress();
  }

  Future<void> _previousSpineItemFirstPage() async {
    if (_currentSpineItemIndex <= 0) {
      ToastService.showError(AppLocalizations.of(context)!.firstChapterOfBook);
      return;
    }

    await _rendererController.jumpToPreviousChapterFirstPage();

    setState(() {
      _currentSpineItemIndex--;
      _currentPageInChapter = 0;
      _initialProgressToRestore = null;
    });

    _preloadPreviousOf(_currentSpineItemIndex);
    _saveProgress();
  }

  Future<void> _nextSpineItem() async {
    if (_currentSpineItemIndex >= _bookSession.spine.length - 1) {
      ToastService.showError(AppLocalizations.of(context)!.lastChapterOfBook);
      return;
    }

    await _rendererController.jumpToNextChapter();

    setState(() {
      _currentSpineItemIndex++;
      _currentPageInChapter = 0;
      _initialProgressToRestore = null;
    });

    _preloadNextOf(_currentSpineItemIndex);
    _saveProgress();
  }

  Future<void> _preloadNextOf(int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < _bookSession.spine.length) {
      // Note: SpineItem.href is a String, not an Href object with anchor
      // End anchors come from TOC, not spine
      final url = _getSpineItemUrl(nextIndex);
      final nextSpinePath = _bookSession.spine[nextIndex].href;

      await _rendererController.preloadNextChapter(
        url,
        _getAnchorsForSpine(nextSpinePath),
      );
    }
  }

  Future<void> _preloadPreviousOf(int currentIndex) async {
    final prevIndex = currentIndex - 1;
    if (prevIndex >= 0) {
      final url = _getSpineItemUrl(prevIndex);
      // Note: SpineItem.href is a String, not an Href object with anchor
      final prevSpinePath = _bookSession.spine[prevIndex].href;
      await _rendererController.preloadPreviousChapter(
        url,
        _getAnchorsForSpine(prevSpinePath),
      );
    }
  }

  Future<void> _loadCarousel([String anchor = 'top']) async {
    if (_bookSession.spine.isEmpty) return;
    if (mounted) {
      setState(() {
        _isWebViewLoading = true;
      });
    }

    // Get paths for current, previous, and next chapters
    final currIndex = _currentSpineItemIndex;
    final prevIndex = currIndex > 0 ? currIndex - 1 : null;
    final nextIndex = currIndex < _bookSession.spine.length - 1
        ? currIndex + 1
        : null;

    // Load current chapter
    final currUrl = _getSpineItemUrl(currIndex, anchor);
    final currentSpinePath = _bookSession.spine[currIndex].href;
    // Note: End anchors come from TOC mapping, not spine directly
    await _rendererController.preloadCurrentChapter(
      currUrl,
      _getAnchorsForSpine(currentSpinePath),
    );

    // Load previous chapter if exists
    if (prevIndex != null) {
      final prevUrl = _getSpineItemUrl(prevIndex);
      final prevSpinePath = _bookSession.spine[prevIndex].href;
      await _rendererController.preloadPreviousChapter(
        prevUrl,
        _getAnchorsForSpine(prevSpinePath),
      );
    }

    // Load next chapter if exists
    if (nextIndex != null) {
      final nextUrl = _getSpineItemUrl(nextIndex);
      final nextSpinePath = _bookSession.spine[nextIndex].href;
      await _rendererController.preloadNextChapter(
        nextUrl,
        _getAnchorsForSpine(nextSpinePath),
      );
    }
  }

  String _getSpineItemUrl(int index, [String anchor = 'top']) {
    return _bookSession.getSpineItemUrl(index, anchor);
  }

  Future<void> _goToPage(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= _totalPagesInChapter) return;

    setState(() {
      _currentPageInChapter = pageIndex;
    });

    await _rendererController.jumpToPage(pageIndex);
    _saveProgress();
  }

  Future<void> _nextPage() async {
    if (_currentPageInChapter < _totalPagesInChapter - 1) {
      await _goToPage(_currentPageInChapter + 1);
    } else {
      await _nextSpineItem();
    }
    _saveProgress();
  }

  Future<void> _previousPage() async {
    if (_currentPageInChapter > 0) {
      await _goToPage(_currentPageInChapter - 1);
    } else {
      await _previousSpineItem();
    }
    _saveProgress();
  }

  bool _canPerformPageTurn(bool isNext) {
    if (isNext) {
      if (_currentPageInChapter >= _totalPagesInChapter - 1 &&
          _currentSpineItemIndex >= _bookSession.spine.length - 1) {
        ToastService.showError(AppLocalizations.of(context)!.lastPageOfBook);
        return false;
      }
    } else {
      if (_currentPageInChapter <= 0 && _currentSpineItemIndex <= 0) {
        ToastService.showError(AppLocalizations.of(context)!.firstPageOfBook);
        return false;
      }
    }
    return true;
  }

  Future<void> _handlePageTurn(bool isNext) async {
    if (isNext) {
      await _nextPage();
    } else {
      await _previousPage();
    }
  }

  EpubTheme _buildEpubTheme() {
    return EpubTheme(
      surfaceColor: Theme.of(context).colorScheme.surface,
      onSurfaceColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.onSurface
          : null,
      padding: const EdgeInsets.all(16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_bookSession.isLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(),
      );
    }

    final activeItems = _resolveActiveItems();
    final activateTocTitle = activeItems.isNotEmpty
        ? activeItems.last.label
        : _bookSession.book!.title;

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          drawer: TocDrawer(
            book: _bookSession.book!,
            toc: _bookSession.toc,
            activeTocItems: activeItems,
            onTocItemSelected: _navigateToTocItem,
            onCoverTap: _navigateToFirstTocItemFirstPage,
          ),
          body: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Stack(
              children: [
                ReaderRenderer(
                  controller: _rendererController,
                  bookSession: _bookSession,
                  webViewHandler: _webViewHandler,
                  fileHash: widget.fileHash,
                  showControls: _showControls,
                  isLoading: _isWebViewLoading || _updatingTheme,
                  canPerformPageTurn: _canPerformPageTurn,
                  onPerformPageTurn: _handlePageTurn,
                  onToggleControls: _toggleControls,
                  onInitialized: () async {
                    await _loadCarousel();
                  },
                  onPageCountReady: (totalPages) async {
                    setState(() {
                      _totalPagesInChapter = totalPages;
                      if (_currentPageInChapter >= _totalPagesInChapter) {
                        _currentPageInChapter = _totalPagesInChapter - 1;
                      }
                    });
                    if (_initialProgressToRestore != null) {
                      final ratio = _initialProgressToRestore ?? 0.0;
                      _initialProgressToRestore = null;
                      await _rendererController.restoreScrollPosition(ratio);
                    }
                  },
                  onPageChanged: (pageIndex) {
                    setState(() {
                      _currentPageInChapter = pageIndex;
                    });
                    _saveProgress();
                  },
                  onRendererInitialized: () async {
                    setState(() {
                      _isWebViewLoading = false;
                    });
                    _saveProgress();
                  },
                  onScrollAnchors: _handleScrollAnchors,
                  onImageLongPress: _handleImageLongPress,
                  shouldShowWebView: _shouldShowWebView,
                  initializeTheme: _buildEpubTheme(),
                ),

                ControlPanel(
                  showControls: _showControls,
                  title: _bookSession.spine.isEmpty
                      ? _bookSession.book!.title
                      : activateTocTitle,
                  currentSpineItemIndex: _currentSpineItemIndex,
                  totalSpineItems: _bookSession.spine.length,
                  currentPageInChapter: _currentPageInChapter,
                  totalPagesInChapter: _totalPagesInChapter,
                  direction: _bookSession.book!.direction,
                  onBack: () {
                    _saveProgress();
                    context.pop();
                  },
                  onOpenDrawer: _openDrawer,
                  onPreviousPage: () =>
                      _rendererController.performPreviousPageTurn(),
                  onFirstPage: () => _goToPage(0),
                  onNextPage: () => _rendererController.performNextPageTurn(),
                  onLastPage: () => _goToPage(_totalPagesInChapter - 1),
                  onPreviousChapter: _previousSpineItemFirstPage,
                  onNextChapter: _nextSpineItem,
                ),
              ],
            ),
          ),
        ),

        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_isImageViewerVisible,
            child: AnimatedOpacity(
              duration: const Duration(
                milliseconds: AppTheme.defaultAnimationDurationMs,
              ),
              curve: Curves.easeOut,
              opacity: _isImageViewerVisible ? 1.0 : 0.0,
              child: (_currentImageUrl != null && _currentImageRect != null)
                  ? ImageViewer(
                      imageUrl: _currentImageUrl!,
                      webViewHandler: _webViewHandler,
                      epubPath: _bookSession.book!.filePath!,
                      fileHash: widget.fileHash,
                      onClose: _closeImageViewer,
                      sourceRect: _currentImageRect!,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToTocItem(TocItem item) async {
    final targetHref = _bookSession.findFirstValidHref(item);

    if (targetHref == null) {
      ToastService.showError(AppLocalizations.of(context)!.chapterHasNoContent);
      return;
    }

    // Find spine index by matching href path
    final index = _bookSession.findSpineIndexForTocItem(item);

    if (index != null) {
      await _navigateToSpineItem(index, targetHref.anchor);
    } else {
      debugPrint(
        "Warning: Chapter with href ${targetHref.path} not found in spine.",
      );
    }
  }

  Future<void> _navigateToFirstTocItemFirstPage() async {
    _navigateToSpineItem(0, 'top');
  }

  Future<void> _updateWebViewTheme() async {
    setState(() {
      _updatingTheme = true;
    });

    await _rendererController.updateTheme(_buildEpubTheme());

    setState(() {
      _updatingTheme = false;
    });
  }

  /// Resolve active TOC item by TOC ID (used for scroll-based highlighting)
  Set<TocItem> _resolveActiveItems() {
    return _bookSession.resolveActiveItems(_currentSpineItemIndex);
  }

  void _closeImageViewer() {
    setState(() {
      _isImageViewerVisible = false;
      _currentImageUrl = null;
      _currentImageRect = null;
    });
  }

  /// Handle image long-press event from WebView
  void _handleImageLongPress(String imageUrl, Rect rect) {
    if (!_bookSession.isLoaded) return;

    setState(() {
      _currentImageUrl = imageUrl;
      _currentImageRect = rect;
      _isImageViewerVisible = true;
    });
  }
}
