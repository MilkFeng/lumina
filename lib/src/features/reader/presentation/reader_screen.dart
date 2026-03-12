import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/data/services/volume_control_service.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';
import 'package:lumina/src/features/reader/presentation/widgets/footnot_popup_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../application/reader_settings_notifier.dart';
import '../domain/reader_settings.dart';
import '../../../core/services/toast_service.dart';
import '../../library/domain/book_manifest.dart';
import './image_viewer.dart';
import '../data/book_session.dart';
import './reader_renderer.dart';
import './control_panel.dart';
import '../data/services/epub_stream_service_provider.dart';
import '../../library/data/repositories/shelf_book_repository_provider.dart';
import '../../library/data/repositories/book_manifest_repository_provider.dart';
import '../data/epub_webview_handler.dart';
import './toc_drawer.dart';
import '../../../../l10n/app_localizations.dart';

part 'mixins/spine_navigation_mixin.dart';
part 'mixins/page_navigation_mixin.dart';
part 'mixins/progress_mixin.dart';
part 'mixins/theme_mixin.dart';
part 'mixins/link_handling_mixin.dart';
part 'mixins/image_viewer_mixin.dart';
part 'mixins/footnote_mixin.dart';

/// Reads EPUB directly from compressed file without extraction
class ReaderScreen extends ConsumerStatefulWidget {
  final String fileHash;

  const ReaderScreen({super.key, required this.fileHash});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with
        WidgetsBindingObserver,
        _SpineNavigationMixin,
        _PageNavigationMixin,
        _ProgressMixin,
        _ThemeMixin,
        _LinkHandlingMixin,
        _ImageViewerMixin,
        _FootnoteMixin {
  @override
  late final EpubWebViewHandler webViewHandler;

  @override
  late final BookSession bookSession;

  @override
  final ReaderRendererController rendererController =
      ReaderRendererController();

  // Core UI state
  @override
  bool isWebViewLoading = true;

  @override
  bool showControls = false;

  // WebView visibility control for smoother transitions
  Animation<double>? routeAnimation;
  bool shouldShowWebView = false;

  // Spine navigation state (used by _SpineNavigationMixin)
  @override
  int currentSpineItemIndex = 0;

  // Pagination state (used by _PageNavigationMixin)
  @override
  int currentPageInChapter = 0;
  @override
  int totalPagesInChapter = 1;

  // Progress state (used by _ProgressMixin)
  @override
  String displayProgress = '';
  @override
  Timer? progressDebouncer;

  // Theme state (used by _ThemeMixin)
  @override
  ThemeData? currentTheme;
  @override
  bool updatingTheme = false;
  @override
  Timer? themeUpdateDebouncer;

  // Image viewer state (used by _ImageViewerMixin)
  @override
  bool isImageViewerVisible = false;
  @override
  String? currentImageUrl;
  @override
  Rect? currentImageRect;

  // Footnote state (used by _FootnoteMixin)
  @override
  OverlayEntry? footnoteOverlayEntry;
  @override
  final GlobalKey<FootnotePopupOverlayState> footnoteKey =
      GlobalKey<FootnotePopupOverlayState>();
  @override
  bool isClosingFootnote = false;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  StreamSubscription<String>? volumeSubscription;
  bool tocDrawerOpen = false;
  bool styleDrawerOpen = false;
  AppLifecycleState? lastLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    webViewHandler = EpubWebViewHandler(
      streamService: ref.read(epubStreamServiceProvider),
    );
    bookSession = BookSession(
      fileHash: widget.fileHash,
      shelfBookRepository: ref.read(shelfBookRepositoryProvider),
      manifestRepository: ref.read(bookManifestRepositoryProvider),
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _loadBook();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ModalRoute.of(context);
      if (router != null && router.animation != null) {
        routeAnimation = router.animation!;
        routeAnimation?.addStatusListener(handleRouteAnimationStatus);
      } else {
        shouldShowWebView = true;
      }
    });
    hideBottomNavigationBar();
    setupVolumeControl();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeAnimation?.removeStatusListener(handleRouteAnimationStatus);
    routeAnimation = null;
    themeUpdateDebouncer?.cancel();
    progressDebouncer?.cancel();
    removeFootnoteOverlay(animate: false);
    restoreSystemUI();
    volumeSubscription?.cancel();
    VolumeControlService.disableInterception();
    WakelockPlus.disable();
    bookSession.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      saveProgress();
    }

    lastLifecycleState = state;
    setupVolumeControl();
  }

  void setupVolumeControl() {
    final resume =
        ref.read(readerSettingsNotifierProvider).volumeKeyTurnsPage &&
        !tocDrawerOpen &&
        !styleDrawerOpen &&
        lastLifecycleState == AppLifecycleState.resumed;

    if (resume) {
      VolumeControlService.enableInterception();
      volumeSubscription ??= VolumeControlService.volumeKeyEvents.listen((
        event,
      ) {
        final isVolumeTurnEnabled = ref
            .read(readerSettingsNotifierProvider)
            .volumeKeyTurnsPage;
        if (isVolumeTurnEnabled) {
          if (event == 'up') {
            rendererController.performPreviousPageTurn();
          } else if (event == 'down') {
            rendererController.performNextPageTurn();
          }
        }
      });
    } else {
      VolumeControlService.disableInterception();
    }
  }

  void hideBottomNavigationBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  void restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update WebView theme when system theme changes
    if (currentTheme == null) {
      currentTheme = Theme.of(context);
    } else if (currentTheme?.colorScheme != Theme.of(context).colorScheme) {
      currentTheme = Theme.of(context);
      updateWebViewThemeWithDebounce();
    }
  }

  void handleRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        shouldShowWebView = true;
      });
      routeAnimation?.removeStatusListener(handleRouteAnimationStatus);
      routeAnimation = null;
    }
  }

  /// Load ShelfBook + BookManifest from database
  Future<void> _loadBook() async {
    try {
      final loaded = await bookSession.loadBook();

      if (!loaded) {
        if (mounted) {
          ToastService.showError(AppLocalizations.of(context)!.bookNotFound);
          context.pop();
        }
        return;
      }

      setState(() {
        currentSpineItemIndex = bookSession.initialChapterIndex;
      });
      updateProgressDebounced();
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.errorLoadingBook(e.toString()),
        );
        context.pop();
      }
    }
  }

  void toggleControls() {
    if (showControls) {
      hideBottomNavigationBar();
    } else {
      restoreSystemUI();
    }
    setState(() {
      showControls = !showControls;
    });
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // Block rendering until SharedPreferences (and thus ReaderSettings) are ready.
    final settings = ref.watch(readerSettingsNotifierProvider);
    if (!bookSession.isLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const SizedBox.shrink(),
      );
    }

    final epubTheme = getEpubTheme();
    final isDark = epubTheme.colorScheme.brightness == Brightness.dark;
    final themeData = epubTheme.themeData;

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: themeData.colorScheme.surface,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: themeData.colorScheme.surface,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    ref.listen(readerSettingsNotifierProvider, (previous, next) {
      if (previous != null && previous != next) {
        // If zoom changed, use debounce to avoid excessive WebView reloads while dragging the slider
        if (previous.fontFileName != next.fontFileName ||
            previous.overrideFontFamily != next.overrideFontFamily) {
          updateWebViewTheme();
        } else if (previous.zoom != next.zoom) {
          updateWebViewThemeWithDebounce();
        } else {
          updateWebViewTheme();
        }
      }
    });

    ref.listen(
      readerSettingsNotifierProvider.select((s) => s.volumeKeyTurnsPage),
      (previous, next) {
        if (previous != next) {
          setupVolumeControl();
        }
      },
    );

    final activeItems = resolveActiveItems();
    final activateTocTitle = activeItems.isNotEmpty
        ? activeItems.last.label
        : bookSession.book!.title;
    return PopScope(
      canPop: footnoteOverlayEntry == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (footnoteOverlayEntry != null) {
          removeFootnoteOverlay();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Stack(
          children: [
            Scaffold(
              key: scaffoldKey,
              backgroundColor: epubTheme.colorScheme.surfaceContainer,
              drawer: TocDrawer(
                book: bookSession.book!,
                toc: bookSession.toc,
                activeTocItems: activeItems,
                onTocItemSelected: navigateToTocItem,
                onCoverTap: navigateToFirstTocItemFirstPage,
                themeData: themeData,
              ),
              onDrawerChanged: (isOpened) {
                tocDrawerOpen = isOpened;
                setupVolumeControl();
              },
              body: Container(
                color: epubTheme.surfaceColor,
                child: Stack(
                  children: [
                    ReaderRenderer(
                      controller: rendererController,
                      bookSession: bookSession,
                      webViewHandler: webViewHandler,
                      fileHash: widget.fileHash,
                      showControls: showControls,
                      isLoading: isWebViewLoading || updatingTheme,
                      canPerformPageTurn: canPerformPageTurn,
                      onPerformPageTurn: handlePageTurn,
                      onToggleControls: toggleControls,
                      onInitialized: () async {
                        final ratio = bookSession.initialScrollPosition;
                        await loadCarousel(restoreScrollRatio: ratio);
                      },
                      onPageCountReady: (totalPages) async {
                        setState(() {
                          totalPagesInChapter = totalPages;
                          if (currentPageInChapter >= totalPagesInChapter) {
                            currentPageInChapter = totalPagesInChapter - 1;
                          }
                        });
                        updateProgressDebounced();
                      },
                      onPageChanged: (pageIndex) {
                        setState(() {
                          currentPageInChapter = pageIndex;
                        });
                        updateProgressDebounced();
                        saveProgress();
                      },
                      onScrollAnchors: handleScrollAnchors,
                      onImageLongPress: handleImageLongPress,
                      onFootnoteTap: handleFootnoteTap,
                      onLinkTap: handleLinkTap,
                      shouldHandleLinkTap: shouldHandleLinkTap,
                      shouldShowWebView: shouldShowWebView,
                      initializeTheme: settings.toEpubTheme(context),
                      statusBarLeftContent: activateTocTitle,
                      statusBarRightContent: displayProgress,
                    ),

                    ControlPanel(
                      showControls: showControls,
                      title: bookSession.spine.isEmpty
                          ? bookSession.book!.title
                          : activateTocTitle,
                      currentSpineItemIndex: currentSpineItemIndex,
                      totalSpineItems: bookSession.spine.length,
                      currentPageInChapter: currentPageInChapter,
                      totalPagesInChapter: totalPagesInChapter,
                      direction: bookSession.book!.direction,
                      onBack: () {
                        saveProgress();
                        context.pop();
                      },
                      onOpenDrawer: openDrawer,
                      onPreviousPage: () =>
                          rendererController.performPreviousPageTurn(),
                      onFirstPage: () => goToPage(0),
                      onNextPage: () =>
                          rendererController.performNextPageTurn(),
                      onLastPage: () => goToPage(totalPagesInChapter - 1),
                      onPreviousChapter: previousSpineItemFirstPage,
                      onNextChapter: nextSpineItem,
                      onToggleStyleDrawer: (show) {
                        tocDrawerOpen = show;
                        setupVolumeControl();
                      },
                    ),
                  ],
                ),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isImageViewerVisible,
                child: AnimatedOpacity(
                  duration: const Duration(
                    milliseconds: AppTheme.defaultAnimationDurationMs,
                  ),
                  curve: Curves.easeOut,
                  opacity: isImageViewerVisible ? 1.0 : 0.0,
                  child: (currentImageUrl != null && currentImageRect != null)
                      ? ImageViewer(
                          imageUrl: currentImageUrl!,
                          webViewHandler: webViewHandler,
                          epubPath: bookSession.book!.filePath!,
                          fileHash: widget.fileHash,
                          onClose: closeImageViewer,
                          sourceRect: currentImageRect!,
                          epubTheme: getEpubTheme(),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
