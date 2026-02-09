import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../../../core/services/toast_service.dart';
import '../../library/domain/shelf_book.dart';
import '../../library/domain/book_manifest.dart';
import '../../library/data/repositories/shelf_book_repository_provider.dart';
import '../../library/data/repositories/book_manifest_repository_provider.dart';
import '../data/services/epub_stream_service_provider.dart';
import 'epub_webview_handler.dart';
import '../data/reader_scripts.dart';
import './toc_drawer.dart';
import '../../../../l10n/app_localizations.dart';

/// Reader Screen V2 - Stream-from-Zip Architecture
/// Reads EPUB directly from compressed file without extraction
class ReaderScreen extends ConsumerStatefulWidget {
  final String fileHash; // Changed from bookId to fileHash

  const ReaderScreen({super.key, required this.fileHash});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey _webViewKey = GlobalKey();

  Timer? _longPressTimer;

  // Services
  late final EpubWebViewHandler _webViewHandler;

  // State
  ShelfBook? _book;
  BookManifest? _manifest;
  InAppWebViewController? _webViewController;

  late final AnimationController _animController;
  late final AnimationController _imageOpacityController;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _slideAnimation2;
  late Animation<double> _imageOpacityAnimation;
  Uint8List? _screenshotData;
  Uint8List? _screenshotData2;
  bool _isAnimating = false;
  bool _isForwardAnimation = true;
  bool _isWebViewLoading = true;

  bool _showControls = false;
  int _currentSpineItemIndex = 0;
  List<SpineItem> _spineItems = [];

  // Image viewer state
  String? _zoomedImageUrl;
  Uint8List? _zoomedImageData;
  bool _loadingZoomedImage = false;

  // TOC Synchronization: Pre-calculated lookup maps
  final Map<String, List<String>> _spineToAnchorsMap = {};

  // Use previous spine item's last toc item as fallback
  final List<TocItem> _TocItemFallback = [];
  Set<String> _activeAnchors = {};

  final List<TocItem> _flatToc = [];
  final Map<Href, int> _hrefToTocIndexMap = {};

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _imageOpacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
    _slideAnimation2 = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
    _imageOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageOpacityController, curve: Curves.easeIn),
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBook();
      }
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _imageOpacityController.dispose();
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

  /// STEP 4.1: Load ShelfBook + BookManifest from database
  Future<void> _loadBook() async {
    try {
      // Load ShelfBook
      final shelfBookRepo = ref.read(shelfBookRepositoryProvider);
      final book = await shelfBookRepo.getBookByHash(widget.fileHash);
      if (book == null) {
        if (mounted) {
          ToastService.showError(AppLocalizations.of(context)!.bookNotFound);
          context.pop();
        }
        return;
      }

      // Load BookManifest
      final manifestRepo = ref.read(bookManifestRepositoryProvider);
      final manifest = await manifestRepo.getManifestByHash(widget.fileHash);
      if (manifest == null) {
        if (mounted) {
          ToastService.showError(
            AppLocalizations.of(context)!.bookManifestNotFound,
          );
          context.pop();
        }
        return;
      }

      setState(() {
        _book = book;
        _manifest = manifest;
        _spineItems = manifest.spine;
        _currentSpineItemIndex = book.currentChapterIndex;
        _initialProgressToRestore = book.chapterScrollPosition;
      });

      // Pre-calculate TOC lookup maps for O(1) synchronization
      _preprogress();
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.errorLoadingBook(e.toString()),
        );
        context.pop();
      }
    }
  }

  void _preprogress() {
    _flatToc.clear();
    _hrefToTocIndexMap.clear();
    _spineToAnchorsMap.clear();

    void processItem(TocItem item) {
      item.id = _flatToc.length;
      _flatToc.add(item);
      _hrefToTocIndexMap[item.href] = item.id;

      final filePath = item.href.path;
      final anchorId = item.href.anchor;
      _spineToAnchorsMap.putIfAbsent(filePath, () => []).add(anchorId);

      for (final child in item.children) {
        processItem(child);
      }
    }

    for (final item in _manifest!.toc) {
      processItem(item);
    }

    TocItem toc = TocItem()
      ..label = _book!.title
      ..href = (Href()
        ..path = ''
        ..anchor = 'top')
      ..id = -1;
    _TocItemFallback.clear();
    for (final spineItem in _spineItems) {
      final anchors = _spineToAnchorsMap[spineItem.href] ?? [];
      _TocItemFallback.add(toc);
      if (anchors.isNotEmpty) {
        final lastHref = Href()
          ..path = spineItem.href
          ..anchor = anchors.last;
        toc = _hrefToTocIndexMap[lastHref] != null
            ? _flatToc[_hrefToTocIndexMap[lastHref]!]
            : toc;
      }
    }
  }

  /// STEP 4.2: Save progress using ShelfBookRepository
  Future<void> _saveProgress() async {
    if (_book == null || _manifest == null) return;

    double? scrollPosition;
    if (_webViewController != null && _totalPagesInChapter > 0) {
      scrollPosition = _currentPageInChapter / _totalPagesInChapter;
    }

    var progress = 0.0;
    if (_spineItems.isNotEmpty) {
      final delta = 1.0 / _spineItems.length;
      progress = (_currentSpineItemIndex + 1) / _spineItems.length;
      if (_totalPagesInChapter > 0) {
        progress -= delta;
        progress +=
            delta * ((_currentPageInChapter + 1) / _totalPagesInChapter);
      }
    }

    final shelfBookRepo = ref.read(shelfBookRepositoryProvider);
    await shelfBookRepo.updateProgress(
      bookId: _book!.id,
      currentChapterIndex: _currentSpineItemIndex,
      progress: progress,
      scrollPosition: scrollPosition,
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
    if (index < 0 || index >= _spineItems.length) return;

    setState(() {
      _currentSpineItemIndex = index;
      _currentPageInChapter = 0; // Reset to first page of new chapter
      _initialProgressToRestore = null;
    });

    await _loadCarousel(anchor);
    _saveProgress();
  }

  Href? _findFirstValidHref(TocItem item) {
    if (item.href.path.isNotEmpty) {
      return item.href;
    }

    if (item.children.isNotEmpty) {
      for (final child in item.children) {
        final found = _findFirstValidHref(child);
        if (found != null) {
          return found;
        }
      }
    }

    return null;
  }

  String _getAnchorsForSpine(String spinePath) {
    final anchors = _spineToAnchorsMap[spinePath] ?? [];
    final jsonAnchors = anchors.map((a) => '"$a"').join(',');
    return '[$jsonAnchors]';
  }

  /// Inject TOC anchor whitelist into JS for the given spine file
  /// This is called when a frame is loaded with a new chapter
  void _handleScrollAnchors(List<String> anchorIds) {
    setState(() {
      _activeAnchors = anchorIds.toSet();
    });
  }

  Future<void> _previousSpineItem() async {
    if (_currentSpineItemIndex <= 0) {
      ToastService.showError(AppLocalizations.of(context)!.firstChapterOfBook);
      return;
    }
    await _webViewController?.evaluateJavascript(
      source: "jumpToLastPageOfFrame('prev')",
    );

    await _webViewController?.evaluateJavascript(source: "cycleFrames('prev')");

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
    await _webViewController?.evaluateJavascript(
      source: "jumpToPageFor('prev', 0)",
    );

    await _webViewController?.evaluateJavascript(source: "cycleFrames('prev')");

    setState(() {
      _currentSpineItemIndex--;
      _currentPageInChapter = 0;
      _initialProgressToRestore = null;
    });

    _preloadPreviousOf(_currentSpineItemIndex);
    _saveProgress();
  }

  Future<void> _nextSpineItem() async {
    if (_currentSpineItemIndex >= _spineItems.length - 1) {
      ToastService.showError(AppLocalizations.of(context)!.lastChapterOfBook);
      return;
    }

    await _webViewController?.evaluateJavascript(
      source: "jumpToPageFor('next', 0)",
    );

    await _webViewController?.evaluateJavascript(source: "cycleFrames('next')");
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
    if (nextIndex < _spineItems.length) {
      // Note: SpineItem.href is a String, not an Href object with anchor
      // End anchors come from TOC, not spine
      final url = _getSpineItemUrl(nextIndex);
      final nextSpinePath = _spineItems[nextIndex].href;
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('next', '$url', ${_getAnchorsForSpine(nextSpinePath)})",
      );
    }
  }

  Future<void> _preloadPreviousOf(int currentIndex) async {
    final prevIndex = currentIndex - 1;
    if (prevIndex >= 0) {
      final url = _getSpineItemUrl(prevIndex);
      // Note: SpineItem.href is a String, not an Href object with anchor
      final prevSpinePath = _spineItems[prevIndex].href;
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('prev', '$url', ${_getAnchorsForSpine(prevSpinePath)})",
      );
    }
  }

  Future<void> _loadCarousel([String anchor = 'top']) async {
    if (_spineItems.isEmpty || _webViewController == null) return;
    if (mounted) {
      setState(() {
        _isWebViewLoading = true;
      });
    }

    // Get paths for current, previous, and next chapters
    final currIndex = _currentSpineItemIndex;
    final prevIndex = currIndex > 0 ? currIndex - 1 : null;
    final nextIndex = currIndex < _spineItems.length - 1 ? currIndex + 1 : null;

    // Load current chapter
    final currUrl = _getSpineItemUrl(currIndex, anchor);
    final currentSpinePath = _spineItems[currIndex].href;
    // Note: End anchors come from TOC mapping, not spine directly
    await _webViewController?.evaluateJavascript(
      source:
          "loadFrame('curr', '$currUrl', ${_getAnchorsForSpine(currentSpinePath)})",
    );

    // Load previous chapter if exists
    if (prevIndex != null) {
      final prevUrl = _getSpineItemUrl(prevIndex);
      final prevSpinePath = _spineItems[prevIndex].href;
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('prev', '$prevUrl', ${_getAnchorsForSpine(prevSpinePath)})",
      );
    }

    // Load next chapter if exists
    if (nextIndex != null) {
      final nextUrl = _getSpineItemUrl(nextIndex);
      final nextSpinePath = _spineItems[nextIndex].href;
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('next', '$nextUrl', ${_getAnchorsForSpine(nextSpinePath)})",
      );
    }
  }

  String _getSpineItemUrl(int index, [String anchor = 'top']) {
    // Create Href object from spine item's href string
    final href = Href()
      ..path = _spineItems[index].href
      ..anchor = anchor;
    return EpubWebViewHandler.getFileUrl(widget.fileHash, href);
  }

  Future<void> _goToPage(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= _totalPagesInChapter) return;

    setState(() {
      _currentPageInChapter = pageIndex;
    });

    await _webViewController?.evaluateJavascript(
      source: 'jumpToPage($pageIndex)',
    );
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
    if (_isAnimating || _webViewController == null) return;

    if (isNext) {
      if (_currentPageInChapter >= _totalPagesInChapter - 1 &&
          _currentSpineItemIndex >= _spineItems.length - 1) {
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
      screenshot = await _webViewController!.takeScreenshot(
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

      if (isNext) {
        _screenshotData2 = screenshot;
        _slideAnimation2 =
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
        _screenshotData = screenshot;
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
          _screenshotData2 = null;
        });
      }
      _animController.reset();
      _isAnimating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_book == null || _manifest == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(),
      );
    }

    return PopScope(
      canPop: _zoomedImageData == null && !_loadingZoomedImage,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _closeImageViewer();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        drawer: RepaintBoundary(child: _buildTocDrawer()),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: RepaintBoundary(child: _buildReaderBody()),
        ),
      ),
    );
  }

  /// Build TOC drawer
  Widget _buildTocDrawer() {
    return TocDrawer(
      book: _book!,
      toc: _manifest!.toc,
      activeTocItems: _resolveActiveItems(),
      onTocItemSelected: _navigateToTocItem,
    );
  }

  Future<void> _navigateToTocItem(TocItem item) async {
    final targetHref = _findFirstValidHref(item);

    if (targetHref == null) {
      ToastService.showError(AppLocalizations.of(context)!.chapterHasNoContent);
      return;
    }

    // Find spine index by matching href path
    final index = _spineItems.indexWhere((s) => s.href == targetHref.path);

    if (index != -1) {
      await _navigateToSpineItem(index, targetHref.anchor);
    } else {
      debugPrint(
        "Warning: Chapter with href ${targetHref.path} not found in spine.",
      );
    }
  }

  Future<void> _updateWebViewTheme() async {
    if (_webViewController == null) return;

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

    await _webViewController?.evaluateJavascript(
      source: "replaceStyles(`$sketelonCss`, `$iframeCss`);",
    );

    setState(() {
      _updatingTheme = false;
    });
  }

  Set<Href> _generateActivatedHrefKeys() {
    final path = _spineItems[_currentSpineItemIndex].href;
    return _activeAnchors
        .map(
          (anchor) => Href()
            ..path = path
            ..anchor = anchor,
        )
        .toSet();
  }

  /// Resolve active TOC item by TOC ID (used for scroll-based highlighting)
  Set<TocItem> _resolveActiveItems() {
    final activeHrefKeys = _generateActivatedHrefKeys();
    final activeItems = activeHrefKeys
        .map((href) {
          final tocIndex = _hrefToTocIndexMap[href];
          if (tocIndex != null && tocIndex >= 0 && tocIndex < _flatToc.length) {
            return _flatToc[tocIndex];
          } else {
            return null;
          }
        })
        .whereType<TocItem>()
        .toSet();
    if (activeItems.isEmpty && _TocItemFallback.isNotEmpty) {
      activeItems.add(_TocItemFallback[_currentSpineItemIndex]);
    }
    return activeItems;
  }

  /// Handle image long-press event from WebView
  Future<void> _handleImageLongPress(String imageUrl) async {
    if (_book == null) return;

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _zoomedImageUrl = imageUrl;
      _loadingZoomedImage = true;
      _zoomedImageData = null;
    });

    try {
      // Parse the image URL and fetch the image data
      final uri = WebUri(imageUrl);

      // Use the existing WebView handler to fetch the image
      final response = await _webViewHandler.handleRequest(
        epubPath: _book!.filePath!,
        fileHash: widget.fileHash,
        requestUrl: uri,
      );

      if (response != null && response.data != null) {
        setState(() {
          _zoomedImageData = response.data;
          _loadingZoomedImage = false;
        });
        // Trigger fade-in animation
        _imageOpacityController.reset();
        _imageOpacityController.forward();
      } else {
        // Failed to load image
        setState(() {
          _zoomedImageUrl = null;
          _loadingZoomedImage = false;
        });
        if (mounted) {
          ToastService.showError('Failed to load image');
        }
      }
    } catch (e) {
      debugPrint('Error loading zoomed image: $e');
      setState(() {
        _zoomedImageUrl = null;
        _loadingZoomedImage = false;
      });
      if (mounted) {
        ToastService.showError('Error loading image');
      }
    }
  }

  /// Close the image viewer
  void _closeImageViewer() {
    setState(() {
      _zoomedImageUrl = null;
      _zoomedImageData = null;
      _loadingZoomedImage = false;
    });
  }

  /// STEP 4.4: Build reader body with WebView interception
  Widget _buildReaderBody() {
    final activeItems = _resolveActiveItems();
    final activateTocTitle = activeItems.isNotEmpty
        ? activeItems.last.label
        : _TocItemFallback[_currentSpineItemIndex].label;

    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            children: [
              if (_screenshotData != null)
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
              if (_screenshotData2 != null)
                Positioned.fill(
                  child: SlideTransition(
                    position: _slideAnimation2,
                    child: _buildScreenshotContainer(_screenshotData2!),
                  ),
                ),
            ],
          ),
        ),

        // Top Bar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: _showControls ? 0 : -100,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _showControls ? 1.0 : 0.0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 8,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_outlined),
                    onPressed: () {
                      _saveProgress();
                      context.pop();
                    },
                  ),
                  Expanded(
                    child: Text(
                      _spineItems.isEmpty ? _book!.title : activateTocTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamilyContent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),

        // Bottom Bar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: _showControls ? 0 : -100,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _showControls ? 1.0 : 0.0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.list_outlined),
                    onPressed: _openDrawer,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onLongPressStart: _currentSpineItemIndex > 0
                            ? (_) {
                                HapticFeedback.selectionClick();
                                _previousSpineItemFirstPage();
                                _longPressTimer = Timer.periodic(
                                  const Duration(milliseconds: 800),
                                  (timer) {
                                    HapticFeedback.selectionClick();
                                    _previousSpineItemFirstPage();
                                  },
                                );
                              }
                            : null,
                        onLongPressEnd: (_) {
                          _longPressTimer?.cancel();
                        },
                        onLongPressCancel: () {
                          _longPressTimer?.cancel();
                        },
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left_outlined),
                          onPressed:
                              (_currentSpineItemIndex > 0 ||
                                  _currentPageInChapter > 0)
                              ? () => _performPageTurn(false)
                              : null,
                          onLongPress: null,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _spineItems.isEmpty
                                ? '0/0'
                                : '${_currentSpineItemIndex + 1}/${_spineItems.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_totalPagesInChapter > 1)
                            Text(
                              'Page ${_currentPageInChapter + 1}/$_totalPagesInChapter',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),

                      GestureDetector(
                        onLongPressStart:
                            _currentSpineItemIndex < _spineItems.length - 1
                            ? (_) {
                                HapticFeedback.selectionClick();
                                _nextSpineItem();
                                _longPressTimer = Timer.periodic(
                                  const Duration(milliseconds: 800),
                                  (timer) {
                                    HapticFeedback.selectionClick();
                                    _nextSpineItem();
                                  },
                                );
                              }
                            : null,
                        onLongPressEnd: (_) {
                          _longPressTimer?.cancel();
                        },
                        onLongPressCancel: () {
                          _longPressTimer?.cancel();
                        },
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right_outlined),
                          onPressed:
                              (_currentSpineItemIndex <
                                      _spineItems.length - 1 ||
                                  _currentPageInChapter <
                                      _totalPagesInChapter - 1)
                              ? () => _performPageTurn(true)
                              : null,
                          onLongPress: null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),

        if (_zoomedImageUrl != null && !_loadingZoomedImage)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeImageViewer,
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Stack(
                  children: [
                    // Image viewer
                    if (_zoomedImageData != null)
                      Positioned.fill(
                        child: FadeTransition(
                          opacity: _imageOpacityAnimation,
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(0),
                            constrained: true,
                            child: Center(
                              child: Image.memory(
                                _zoomedImageData!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Close button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: SafeArea(
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_outlined,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 10),
                            ],
                            size: 32,
                          ),
                          onPressed: _closeImageViewer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebViewStack() {
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

            await _webViewController?.evaluateJavascript(
              source: "checkElementAt($localX, $localY);",
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewWidth = constraints.maxWidth;
                final viewHeight = constraints.maxHeight;
                final maskColor = Theme.of(context).colorScheme.surface;

                _webviewWidth = viewWidth;
                _webviewHeight = viewHeight;

                return Stack(
                  children: [
                    InAppWebView(
                      key: _webViewKey,
                      initialData: InAppWebViewInitialData(
                        data: generateSkeletonHtml(
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.onSurface,
                        ),
                        baseUrl: WebUri(EpubWebViewHandler.getBaseUrl()),
                      ),
                      initialSettings: EpubWebViewHandler.defaultSettings,
                      onLongPressHitTestResult: (controller, hitTestResult) {
                        if (hitTestResult.type ==
                            InAppWebViewHitTestResultType.IMAGE_TYPE) {
                          final imageUrl = hitTestResult.extra;
                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            _handleImageLongPress(imageUrl);
                          }
                        }
                      },
                      shouldInterceptRequest: (controller, request) async {
                        return await _webViewHandler.handleRequest(
                          epubPath: _book!.filePath!,
                          fileHash: widget.fileHash,
                          requestUrl: request.url,
                        );
                      },
                      onLoadResourceWithCustomScheme:
                          (controller, request) async {
                            return await _webViewHandler
                                .handleRequestWithCustomScheme(
                                  epubPath: _book!.filePath!,
                                  fileHash: widget.fileHash,
                                  requestUrl: request.url,
                                );
                          },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
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
                        _webViewController = controller;

                        // JavaScript handlers
                        controller.addJavaScriptHandler(
                          handlerName: 'onPageCountReady',
                          callback: (args) async {
                            if (args.isNotEmpty && args[0] is int) {
                              setState(() {
                                _totalPagesInChapter = args[0] as int;
                                if (_currentPageInChapter >=
                                    _totalPagesInChapter) {
                                  _currentPageInChapter =
                                      _totalPagesInChapter - 1;
                                }
                              });
                              if (_initialProgressToRestore != null) {
                                final ratio = _initialProgressToRestore ?? 0.0;
                                _initialProgressToRestore = null;
                                await _webViewController?.evaluateJavascript(
                                  source: 'restoreScrollPosition($ratio)',
                                );
                              }
                            }
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onGoToPage',
                          callback: (args) {
                            if (args.isNotEmpty && args[0] is int) {
                              setState(() {
                                _currentPageInChapter = args[0] as int;
                              });
                              _saveProgress();
                            }
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onTapLeft',
                          callback: (args) {
                            if (_showControls) {
                              _toggleControls();
                              return;
                            }
                            _performPageTurn(false);
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onTapRight',
                          callback: (args) {
                            if (_showControls) {
                              _toggleControls();
                              return;
                            }
                            _performPageTurn(true);
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onTapCenter',
                          callback: (args) {
                            _toggleControls();
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onReveal',
                          callback: (args) async {
                            if (mounted) {
                              setState(() {
                                _isWebViewLoading = false;
                              });
                            }
                            _saveProgress();
                            debugPrint('WebView: RenderComplete');
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onRenderComplete',
                          callback: (args) async {
                            await Future.delayed(
                              const Duration(milliseconds: 50),
                            );
                            await _webViewController?.evaluateJavascript(
                              source: "reveal();",
                            );
                            _saveProgress();
                            debugPrint('WebView: RenderComplete');
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onScrollAnchors',
                          callback: (args) {
                            if (args.isEmpty) return;
                            final List<String> anchors = List<String>.from(
                              args[0] as List,
                            );
                            _handleScrollAnchors(anchors);
                          },
                        );

                        controller.addJavaScriptHandler(
                          handlerName: 'onImageLongPress',
                          callback: (args) {
                            if (args.isNotEmpty && args[0] is String) {
                              final imageUrl = args[0] as String;
                              _handleImageLongPress(imageUrl);
                            }
                          },
                        );
                      },
                      onLoadStop: (controller, url) async {
                        await controller.evaluateJavascript(
                          source: generateControllerJs(
                            viewWidth,
                            viewHeight,
                            Theme.of(context).colorScheme.onSurface,
                          ),
                        );
                        if (_manifest != null) {
                          await _loadCarousel();
                        }
                      },
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !_isWebViewLoading && !_updatingTheme,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          opacity: _isWebViewLoading || _updatingTheme
                              ? 1.0
                              : 0.0,
                          child: Container(color: maskColor),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenshotContainer(Uint8List screenshot) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.memory(
            screenshot,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
