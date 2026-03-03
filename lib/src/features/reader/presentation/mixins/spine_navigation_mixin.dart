part of '../reader_screen.dart';

mixin _SpineNavigationMixin on ConsumerState<ReaderScreen> {
  // === Borrowed state (provided by _ReaderScreenState fields) ===
  BookSession get bookSession;

  ReaderRendererController get rendererController;

  bool get isWebViewLoading;
  set isWebViewLoading(bool v);

  int get currentSpineItemIndex;
  set currentSpineItemIndex(int v);

  double? get initialProgressToRestore;
  set initialProgressToRestore(double? v);

  int get currentPageInChapter;
  set currentPageInChapter(int v);

  // === Cross-mixin: _ProgressMixin ===
  void updateProgressDebounced();
  Future<void> saveProgress();

  // === Cross-mixin: _ThemeMixin ===
  EpubTheme getEpubTheme();

  List<String> getAnchorsForSpine(String spinePath) {
    return bookSession.getAnchorsForSpine(spinePath);
  }

  void handleScrollAnchors(List<String> anchorIds) {
    setState(() {
      bookSession.updateActiveAnchors(anchorIds);
    });
  }

  String getSpineItemUrl(int index, [String anchor = 'top']) {
    return bookSession.getSpineItemUrl(index, anchor);
  }

  Future<void> loadCarousel([
    String anchor = 'top',
    int? overrideSpineIndex,
  ]) async {
    if (bookSession.spine.isEmpty) return;
    if (mounted) {
      setState(() {
        isWebViewLoading = true;
      });
    }

    if (overrideSpineIndex != null &&
        overrideSpineIndex >= 0 &&
        overrideSpineIndex < bookSession.spine.length) {
      currentSpineItemIndex = overrideSpineIndex;
    }
    final currIndex = currentSpineItemIndex;
    final prevIndex = currIndex > 0 ? currIndex - 1 : null;
    final nextIndex = currIndex < bookSession.spine.length - 1
        ? currIndex + 1
        : null;

    final currUrl = getSpineItemUrl(currIndex, anchor);
    final currentSpinePath = bookSession.spine[currIndex].href;
    await rendererController.preloadCurrentChapter(
      currUrl,
      getAnchorsForSpine(currentSpinePath),
    );

    if (prevIndex != null) {
      final prevUrl = getSpineItemUrl(prevIndex);
      final prevSpinePath = bookSession.spine[prevIndex].href;
      await rendererController.preloadPreviousChapter(
        prevUrl,
        getAnchorsForSpine(prevSpinePath),
      );
    }

    if (nextIndex != null) {
      final nextUrl = getSpineItemUrl(nextIndex);
      final nextSpinePath = bookSession.spine[nextIndex].href;
      await rendererController.preloadNextChapter(
        nextUrl,
        getAnchorsForSpine(nextSpinePath),
      );
    }
  }

  Future<void> preloadNextOf(int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < bookSession.spine.length) {
      final url = getSpineItemUrl(nextIndex);
      final nextSpinePath = bookSession.spine[nextIndex].href;
      await rendererController.preloadNextChapter(
        url,
        getAnchorsForSpine(nextSpinePath),
      );
    }
  }

  Future<void> preloadPreviousOf(int currentIndex) async {
    final prevIndex = currentIndex - 1;
    if (prevIndex >= 0) {
      final url = getSpineItemUrl(prevIndex);
      final prevSpinePath = bookSession.spine[prevIndex].href;
      await rendererController.preloadPreviousChapter(
        url,
        getAnchorsForSpine(prevSpinePath),
      );
    }
  }

  Future<void> navigateToSpineItem(int index, [String anchor = 'top']) async {
    if (index < 0 || index >= bookSession.spine.length) return;

    setState(() {
      currentSpineItemIndex = index;
      currentPageInChapter = 0;
      initialProgressToRestore = null;
    });
    updateProgressDebounced();

    await loadCarousel(anchor);
    saveProgress();
  }

  Future<void> previousSpineItem() async {
    if (currentSpineItemIndex <= 0) {
      ToastService.showError(
        AppLocalizations.of(context)!.firstChapterOfBook,
        theme: getEpubTheme().themeData,
      );
      return;
    }

    await rendererController.jumpToPreviousChapterLastPage();

    setState(() {
      currentSpineItemIndex--;
      initialProgressToRestore = null;
    });

    preloadPreviousOf(currentSpineItemIndex);
    saveProgress();
  }

  Future<void> previousSpineItemFirstPage() async {
    if (currentSpineItemIndex <= 0) {
      ToastService.showError(
        AppLocalizations.of(context)!.firstChapterOfBook,
        theme: getEpubTheme().themeData,
      );
      return;
    }

    await rendererController.jumpToPreviousChapterFirstPage();

    setState(() {
      currentSpineItemIndex--;
      currentPageInChapter = 0;
      initialProgressToRestore = null;
    });
    updateProgressDebounced();

    preloadPreviousOf(currentSpineItemIndex);
    saveProgress();
  }

  Future<void> nextSpineItem() async {
    if (currentSpineItemIndex >= bookSession.spine.length - 1) {
      ToastService.showError(
        AppLocalizations.of(context)!.lastChapterOfBook,
        theme: getEpubTheme().themeData,
      );
      return;
    }

    await rendererController.jumpToNextChapter();

    setState(() {
      currentSpineItemIndex++;
      currentPageInChapter = 0;
      initialProgressToRestore = null;
    });
    updateProgressDebounced();

    preloadNextOf(currentSpineItemIndex);
    saveProgress();
  }

  Future<void> navigateToTocItem(TocItem item) async {
    final targetHref = bookSession.findFirstValidHref(item);

    if (targetHref == null) {
      ToastService.showError(
        AppLocalizations.of(context)!.chapterHasNoContent,
        theme: getEpubTheme().themeData,
      );
      return;
    }

    final index = bookSession.findSpineIndexForTocItem(item);

    if (index != null) {
      await navigateToSpineItem(index, targetHref.anchor);
    } else {
      debugPrint(
        'Warning: Chapter with href ${targetHref.path} not found in spine.',
      );
    }
  }

  Future<void> navigateToFirstTocItemFirstPage() async {
    navigateToSpineItem(0, 'top');
  }

  Set<TocItem> resolveActiveItems() {
    return bookSession.resolveActiveItems(currentSpineItemIndex);
  }
}
