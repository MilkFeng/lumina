import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/services/toast_service.dart';
import '../../library/domain/book_manifest.dart';
import './image_viewer.dart';
import './book_session.dart';
import './reader_webview.dart';
import './control_panel.dart';
import '../data/services/epub_stream_service_provider.dart';
import 'epub_webview_handler.dart';
import '../data/reader_scripts.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Services
  late final EpubWebViewHandler _webViewHandler;
  late final BookSession _bookSession;

  // State
  final GlobalKey<ReaderWebViewState> _webViewKey =
      GlobalKey<ReaderWebViewState>();

  late final AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  Uint8List? _screenshotData;
  bool _isAnimating = false;
  bool _isForwardAnimation = true;
  bool _isWebViewLoading = true;

  bool _showControls = false;
  int _currentSpineItemIndex = 0;

  // Pagination
  int _currentPageInChapter = 0;
  int _totalPagesInChapter = 1;
  double? _initialProgressToRestore;

  bool _updatingTheme = false;

  double _webviewWidth = 0;
  double _webviewHeight = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _webViewHandler = EpubWebViewHandler(
      streamService: ref.read(epubStreamServiceProvider),
    );
    _bookSession = BookSession(fileHash: widget.fileHash);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBook();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
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

    _updateWebViewTheme();
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

  void _handleTapZone(double globalDx) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 0) return;

    final ratio = globalDx / width;
    if (ratio < 0.2) {
      if (_showControls) {
        _toggleControls();
        return;
      }
      _performPageTurn(false);
    } else if (ratio > 0.8) {
      if (_showControls) {
        _toggleControls();
        return;
      }
      _performPageTurn(true);
    } else {
      _toggleControls();
    }
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

  String _getAnchorsForSpine(String spinePath) {
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
    await _webViewKey.currentState?.jumpToLastPageOfFrame('prev');

    await _webViewKey.currentState?.cycleFrames('prev');

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
    await _webViewKey.currentState?.jumpToPageFor('prev', 0);

    await _webViewKey.currentState?.cycleFrames('prev');

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

    await _webViewKey.currentState?.jumpToPageFor('next', 0);

    await _webViewKey.currentState?.cycleFrames('next');
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
      await _webViewKey.currentState?.loadFrame(
        'next',
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
      await _webViewKey.currentState?.loadFrame(
        'prev',
        url,
        _getAnchorsForSpine(prevSpinePath),
      );
    }
  }

  Future<void> _loadCarousel([String anchor = 'top']) async {
    if (_bookSession.spine.isEmpty || _webViewKey.currentState == null) return;
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
    await _webViewKey.currentState?.loadFrame(
      'curr',
      currUrl,
      _getAnchorsForSpine(currentSpinePath),
    );

    // Load previous chapter if exists
    if (prevIndex != null) {
      final prevUrl = _getSpineItemUrl(prevIndex);
      final prevSpinePath = _bookSession.spine[prevIndex].href;
      await _webViewKey.currentState?.loadFrame(
        'prev',
        prevUrl,
        _getAnchorsForSpine(prevSpinePath),
      );
    }

    // Load next chapter if exists
    if (nextIndex != null) {
      final nextUrl = _getSpineItemUrl(nextIndex);
      final nextSpinePath = _bookSession.spine[nextIndex].href;
      await _webViewKey.currentState?.loadFrame(
        'next',
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

    await _webViewKey.currentState?.jumpToPage(pageIndex);
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

  Future<void> _performPageTurn(bool isNext) async {
    if (_isAnimating || _webViewKey.currentState == null) return;

    if (isNext) {
      if (_currentPageInChapter >= _totalPagesInChapter - 1 &&
          _currentSpineItemIndex >= _bookSession.spine.length - 1) {
        ToastService.showError(AppLocalizations.of(context)!.lastPageOfBook);
        return;
      }
    } else {
      if (_currentPageInChapter <= 0 && _currentSpineItemIndex <= 0) {
        ToastService.showError(AppLocalizations.of(context)!.firstPageOfBook);
        return;
      }
    }

    _isAnimating = true;
    Uint8List? screenshot;
    try {
      screenshot = await _webViewKey.currentState!.takeScreenshot(
        screenshotConfiguration: ScreenshotConfiguration(
          compressFormat: CompressFormat.JPEG,
          quality: 80,
        ),
      );
    } catch (_) {
      screenshot = null;
    }

    if (screenshot == null) {
      _isAnimating = false;
      if (isNext) {
        await _nextPage();
      } else {
        await _previousPage();
      }
      return;
    }

    if (!mounted) {
      _isAnimating = false;
      return;
    }

    // preload the image
    await precacheImage(MemoryImage(screenshot), context);

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
    if (isNext) {
      await _nextPage();
    } else {
      await _previousPage();
    }

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

  @override
  Widget build(BuildContext context) {
    if (!_bookSession.isLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: RepaintBoundary(child: _buildTocDrawer()),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: RepaintBoundary(child: _buildReaderBody()),
      ),
    );
  }

  /// Build TOC drawer
  Widget _buildTocDrawer() {
    return TocDrawer(
      book: _bookSession.book!,
      toc: _bookSession.toc,
      activeTocItems: _resolveActiveItems(),
      onTocItemSelected: _navigateToTocItem,
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

  Future<void> _updateWebViewTheme() async {
    if (_webViewKey.currentState == null) return;

    setState(() {
      _updatingTheme = true;
    });

    final colorScheme = Theme.of(context).colorScheme;

    final sketelonCss = generateSkeletonStyle(
      colorScheme.surface,
      colorScheme.onSurface,
    );

    final iframeCss = generatePaginationCss(
      _webviewWidth,
      _webviewHeight,
      colorScheme.onSurface,
    );

    await _webViewKey.currentState?.replaceStyles(sketelonCss, iframeCss);

    setState(() {
      _updatingTheme = false;
    });
  }

  /// Resolve active TOC item by TOC ID (used for scroll-based highlighting)
  Set<TocItem> _resolveActiveItems() {
    return _bookSession.resolveActiveItems(_currentSpineItemIndex);
  }

  /// Handle image long-press event from WebView
  void _handleImageLongPress(String imageUrl) {
    if (!_bookSession.isLoaded) return;

    ImageViewer.handleImageLongPress(
      context,
      imageUrl: imageUrl,
      webViewHandler: _webViewHandler,
      epubPath: _bookSession.book!.filePath!,
      fileHash: widget.fileHash,
    );
  }

  /// Build reader body with WebView interception
  Widget _buildReaderBody() {
    final activeItems = _resolveActiveItems();
    final activateTocTitle = activeItems.isNotEmpty
        ? activeItems.last.label
        : _bookSession.book!.title;

    return Stack(
      children: [
        _buildRenderer(),
        ControlPanel(
          showControls: _showControls,
          title: _bookSession.spine.isEmpty
              ? _bookSession.book!.title
              : activateTocTitle,
          currentSpineItemIndex: _currentSpineItemIndex,
          totalSpineItems: _bookSession.spine.length,
          currentPageInChapter: _currentPageInChapter,
          totalPagesInChapter: _totalPagesInChapter,
          onBack: () {
            _saveProgress();
            context.pop();
          },
          onOpenDrawer: _openDrawer,
          onPreviousPage: () => _performPageTurn(false),
          onFirstPage: () => _goToPage(0),
          onNextPage: () => _performPageTurn(true),
          onLastPage: () => _goToPage(_totalPagesInChapter - 1),
          onPreviousChapter: _previousSpineItemFirstPage,
          onNextChapter: _nextSpineItem,
        ),
      ],
    );
  }

  Widget _buildRenderer() {
    return Positioned.fill(
      child: Stack(
        children: [
          if (_screenshotData != null && _isAnimating && !_isForwardAnimation)
            Positioned.fill(child: _buildScreenshotContainer(_screenshotData!)),
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            _handleTapZone(details.globalPosition.dx);
          },
          onHorizontalDragEnd: (details) {
            if (_isAnimating) return;
            final velocity = details.primaryVelocity ?? 0;

            if (velocity < -200) {
              _performPageTurn(true);
            } else if (velocity > 200) {
              _performPageTurn(false);
            }
          },
          onLongPressStart: (details) async {
            const padding = 16.0;

            final localX = details.localPosition.dx - padding;
            final localY = details.localPosition.dy - padding;

            if (localX < 0 ||
                localY < 0 ||
                localX > _webviewWidth ||
                localY > _webviewHeight) {
              return;
            }

            await _webViewKey.currentState?.checkElementAt(localX, localY);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(alignment: AlignmentGeometry.center, child: child),
          ),
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
            bookSession: _bookSession,
            webViewHandler: _webViewHandler,
            fileHash: widget.fileHash,
            width: viewWidth,
            height: viewHeight,
            surfaceColor: maskColor,
            onSurfaceColor: Theme.of(context).colorScheme.onSurface,
            isLoading: _isWebViewLoading || _updatingTheme,
            callbacks: ReaderWebViewCallbacks(
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
                  await _webViewKey.currentState?.restoreScrollPosition(ratio);
                }
              },
              onPageChanged: (pageIndex) {
                setState(() {
                  _currentPageInChapter = pageIndex;
                });
                _saveProgress();
              },
              onTapLeft: () {
                if (_showControls) {
                  _toggleControls();
                  return;
                }
                _performPageTurn(false);
              },
              onTapRight: () {
                if (_showControls) {
                  _toggleControls();
                  return;
                }
                _performPageTurn(true);
              },
              onTapCenter: () {
                _toggleControls();
              },
              onReveal: (scrollPosition) {
                if (mounted) {
                  setState(() {
                    _isWebViewLoading = false;
                  });
                }
                _saveProgress();
              },
              onRenderComplete: () async {
                _saveProgress();
              },
              onScrollAnchors: _handleScrollAnchors,
              onImageLongPress: _handleImageLongPress,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenshotContainer(Uint8List screenshot) {
    return _buildContentWrapper(
      Image.memory(
        screenshot,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}
