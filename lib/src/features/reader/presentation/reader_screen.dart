import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../../../core/services/toast_service.dart';
import '../../library/domain/shelf_book.dart';
import '../../library/domain/book_manifest.dart';
import '../../library/data/shelf_book_repository.dart';
import '../../library/data/book_manifest_repository.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Repositories
  final _shelfBookRepo = ShelfBookRepository();
  final _manifestRepo = BookManifestRepository();

  final GlobalKey _webViewKey = GlobalKey();

  Timer? _longPressTimer;

  // Services
  late final EpubWebViewHandler _webViewHandler;

  // State
  ShelfBook? _book;
  BookManifest? _manifest;
  InAppWebViewController? _webViewController;

  late final AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _slideAnimation2;
  Uint8List? _screenshotData;
  Uint8List? _screenshotData2;
  bool _isAnimating = false;
  bool _isForwardAnimation = true;
  bool _isWebViewLoading = true;

  bool _showControls = false;
  int _currentChapterIndex = 0;
  List<TocItem> _flatChapters = [];

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
    _webViewHandler = EpubWebViewHandler();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
    _slideAnimation2 = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
    WidgetsBinding.instance.addObserver(this);
    _loadBook();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
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

  /// STEP 4.1: Load ShelfBook + BookManifest from database
  Future<void> _loadBook() async {
    try {
      // Load ShelfBook
      final book = await _shelfBookRepo.getBookByHash(widget.fileHash);
      if (book == null) {
        if (mounted) {
          ToastService.showError(AppLocalizations.of(context)!.bookNotFound);
          context.pop();
        }
        return;
      }

      // Load BookManifest
      final manifest = await _manifestRepo.getManifestByHash(widget.fileHash);
      if (manifest == null) {
        if (mounted) {
          ToastService.showError(
            AppLocalizations.of(context)!.bookManifestNotFound,
          );
          context.pop();
        }
        return;
      }

      // Flatten TOC
      final flatChapters = manifest.toc
          .expand((item) => item.flatten())
          .where((item) => item.href.path.isNotEmpty)
          .toList();

      setState(() {
        _book = book;
        _manifest = manifest;
        _flatChapters = flatChapters;
        _currentChapterIndex = book.currentChapterIndex;
        _initialProgressToRestore = book.chapterScrollPosition;
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

  /// STEP 4.2: Save progress using ShelfBookRepository
  Future<void> _saveProgress() async {
    if (_book == null || _manifest == null) return;

    double? scrollPosition;
    if (_webViewController != null && _totalPagesInChapter > 0) {
      scrollPosition = _currentPageInChapter / _totalPagesInChapter;
    }

    var progress = 0.0;
    if (_flatChapters.isNotEmpty) {
      final delta = 1.0 / _flatChapters.length;
      progress = (_currentChapterIndex + 1) / _flatChapters.length;
      if (_totalPagesInChapter > 0) {
        progress -= delta;
        progress +=
            delta * ((_currentPageInChapter + 1) / _totalPagesInChapter);
      }
    }

    await _shelfBookRepo.updateProgress(
      bookId: _book!.id,
      currentChapterIndex: _currentChapterIndex,
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

  void _navigateToChapter(int index) {
    if (index < 0 || index >= _flatChapters.length) return;

    setState(() {
      _currentChapterIndex = index;
      _currentPageInChapter = 0; // Reset to first page of new chapter
      _initialProgressToRestore = null;
    });

    _loadCarousel();
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

  Future<void> _previousChapter() async {
    if (_currentChapterIndex <= 0) {
      ToastService.showError(AppLocalizations.of(context)!.firstChapterOfBook);
      return;
    }
    await _webViewController?.evaluateJavascript(
      source: "jumpToLastPageOfFrame('prev')",
    );

    await _webViewController?.evaluateJavascript(source: "cycleFrames('prev')");

    setState(() {
      _currentChapterIndex--;
      _initialProgressToRestore = null;
    });
    _preloadPreviousOf(_currentChapterIndex);
    _saveProgress();
  }

  Future<void> _previousChapterFirstPage() async {
    if (_currentChapterIndex <= 0) {
      ToastService.showError(AppLocalizations.of(context)!.firstChapterOfBook);
      return;
    }
    await _webViewController?.evaluateJavascript(
      source: "jumpToPageFor('prev', 0)",
    );

    await _webViewController?.evaluateJavascript(source: "cycleFrames('prev')");

    setState(() {
      _currentChapterIndex--;
      _currentPageInChapter = 0;
      _initialProgressToRestore = null;
    });
    _preloadPreviousOf(_currentChapterIndex);
    _saveProgress();
  }

  Future<void> _nextChapter() async {
    if (_currentChapterIndex >= _flatChapters.length - 1) {
      ToastService.showError(AppLocalizations.of(context)!.lastChapterOfBook);
      return;
    }

    await _webViewController?.evaluateJavascript(
      source: "jumpToPageFor('next', 0)",
    );

    await _webViewController?.evaluateJavascript(source: "cycleFrames('next')");
    setState(() {
      _currentChapterIndex++;
      _currentPageInChapter = 0;
      _initialProgressToRestore = null;
    });

    _preloadNextOf(_currentChapterIndex);
    _saveProgress();
  }

  Future<void> _preloadNextOf(int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < _flatChapters.length) {
      String? endAnchor;
      if (nextIndex + 1 < _flatChapters.length) {
        endAnchor = _flatChapters[nextIndex + 1].href.anchor;
      }

      final url = _getChapterUrl(nextIndex);
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('next', '$url', ${endAnchor != null ? "'$endAnchor'" : 'null'})",
      );
    }
  }

  Future<void> _preloadPreviousOf(int currentIndex) async {
    final prevIndex = currentIndex - 1;
    if (prevIndex >= 0) {
      final url = _getChapterUrl(prevIndex);
      var endAnchor = _flatChapters[currentIndex].href.anchor;
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('prev', '$url', ${endAnchor != null ? "'$endAnchor'" : 'null'})",
      );
    }
  }

  Future<void> _loadCarousel() async {
    if (_flatChapters.isEmpty || _webViewController == null) return;
    if (mounted) {
      setState(() {
        _isWebViewLoading = true;
      });
    }

    // Get paths for current, previous, and next chapters
    final currIndex = _currentChapterIndex;
    final prevIndex = currIndex > 0 ? currIndex - 1 : null;
    final nextIndex = currIndex < _flatChapters.length - 1
        ? currIndex + 1
        : null;

    // Load current chapter
    final currUrl = _getChapterUrl(currIndex);
    String? endAnchor;
    if (nextIndex != null) {
      endAnchor = _flatChapters[nextIndex].href.anchor;
    }
    await _webViewController?.evaluateJavascript(
      source:
          "loadFrame('curr', '$currUrl', ${endAnchor != null ? "'$endAnchor'" : 'null'})",
    );

    // Load previous chapter if exists
    if (prevIndex != null) {
      final prevUrl = _getChapterUrl(prevIndex);
      final endAnchor = _flatChapters[currIndex].href.anchor;
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('prev', '$prevUrl', ${endAnchor != null ? "'$endAnchor'" : 'null'})",
      );
    }

    // Load next chapter if exists
    if (nextIndex != null) {
      final nextUrl = _getChapterUrl(nextIndex);
      var endAnchor = _flatChapters[nextIndex].href.anchor;
      if (nextIndex + 1 < _flatChapters.length) {
        endAnchor = _flatChapters[nextIndex + 1].href.anchor;
      }
      await _webViewController?.evaluateJavascript(
        source:
            "loadFrame('next', '$nextUrl', ${endAnchor != null ? "'$endAnchor'" : 'null'})",
      );
    }
  }

  String _getChapterUrl(int index) {
    return EpubWebViewHandler.getFileUrl(
      widget.fileHash,
      _flatChapters[index].href,
    );
  }

  void _goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _totalPagesInChapter) return;

    setState(() {
      _currentPageInChapter = pageIndex;
    });

    _webViewController?.evaluateJavascript(source: 'jumpToPage($pageIndex)');
    _saveProgress();
  }

  void _nextPage() {
    if (_currentPageInChapter < _totalPagesInChapter - 1) {
      _goToPage(_currentPageInChapter + 1);
    } else {
      _nextChapter();
    }
    _saveProgress();
  }

  void _previousPage() {
    if (_currentPageInChapter > 0) {
      _goToPage(_currentPageInChapter - 1);
    } else {
      _previousChapter();
    }
    _saveProgress();
  }

  Future<void> _performPageTurn(bool isNext) async {
    if (_isAnimating || _webViewController == null) return;

    if (isNext) {
      if (_currentPageInChapter >= _totalPagesInChapter - 1 &&
          _currentChapterIndex >= _flatChapters.length - 1) {
        ToastService.showError(AppLocalizations.of(context)!.lastPageOfBook);
        return;
      }
    } else {
      if (_currentPageInChapter <= 0 && _currentChapterIndex <= 0) {
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
        _nextPage();
      } else {
        _previousPage();
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
      _nextPage();
    } else {
      _previousPage();
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
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
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
      book: _book!,
      toc: _manifest!.toc,
      currentChapterIndex: _currentChapterIndex,
      onTocItemSelected: _navigateToTocItem,
    );
  }

  void _navigateToTocItem(TocItem item) {
    final targetHref = _findFirstValidHref(item);

    if (targetHref == null) {
      ToastService.showError(AppLocalizations.of(context)!.chapterHasNoContent);
      return;
    }

    final index = _flatChapters.indexWhere((c) => c.href == targetHref);

    if (index != -1) {
      _navigateToChapter(index);
    } else {
      debugPrint(
        "Warning: Chapter with href $targetHref not found in flat list.",
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

  /// STEP 4.4: Build reader body with WebView interception
  Widget _buildReaderBody() {
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
                      _flatChapters.isEmpty
                          ? 'Loading...'
                          : _flatChapters[_currentChapterIndex].label,
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
                        onLongPressStart: _currentChapterIndex > 0
                            ? (_) {
                                HapticFeedback.selectionClick();
                                _previousChapterFirstPage();
                                _longPressTimer = Timer.periodic(
                                  const Duration(milliseconds: 800),
                                  (timer) {
                                    HapticFeedback.selectionClick();
                                    _previousChapterFirstPage();
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
                              (_currentChapterIndex > 0 ||
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
                            _flatChapters.isEmpty
                                ? '0/0'
                                : '${_currentChapterIndex + 1}/${_flatChapters.length}',
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
                            _currentChapterIndex < _flatChapters.length - 1
                            ? (_) {
                                HapticFeedback.selectionClick();
                                _nextChapter();
                                _longPressTimer = Timer.periodic(
                                  const Duration(milliseconds: 800),
                                  (timer) {
                                    HapticFeedback.selectionClick();
                                    _nextChapter();
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
                              (_currentChapterIndex <
                                      _flatChapters.length - 1 ||
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
                      initialSettings: InAppWebViewSettings(
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
                        resourceCustomSchemes: [
                          EpubWebViewHandler.virtualScheme,
                        ],
                      ),
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
                                await _webViewController?.evaluateJavascript(
                                  source: 'reveal()',
                                );
                              } else {
                                await _webViewController?.evaluateJavascript(
                                  source: 'reveal()',
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
                          handlerName: 'onRenderComplete',
                          callback: (args) {
                            if (mounted) {
                              setState(() {
                                _isWebViewLoading = false;
                              });
                            }
                            debugPrint('WebView: RenderComplete');
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
    // return Container(color: Colors.blue);

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
