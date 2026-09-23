part of '../reader_screen.dart';

/// How long to wait before starting the turn that was requested after the one
/// just landed.
///
/// Two turns are two screenfuls, and back-to-back presses have to read as two:
/// starting the second on the very frame the first landed makes them one long
/// jump.  A pause this short is not visible as a pause — it is what keeps the
/// two apart.
const Duration _kScrollTurnGap = Duration(milliseconds: 40);

mixin _PageNavigationMixin on ConsumerState<ReaderScreen> {
  // === Borrowed state (provided by _ReaderScreenState fields) ===
  int get currentPageInChapter;
  set currentPageInChapter(int v);

  int get totalPagesInChapter;
  set totalPagesInChapter(int v);

  int get currentSpineItemIndex;

  /// Whether the chapter is scrolled to its top / bottom; see
  /// `_ProgressMixin.handleScrollProgress`.
  bool get atChapterScrollStart;

  bool get atChapterScrollEnd;

  bool get isScrollMode;

  BookSession get bookSession;

  ReaderRendererController get rendererController;

  // === Cross-mixin: _SpineNavigationMixin ===
  Future<void> nextSpineItem();
  Future<void> previousSpineItem();

  // === Cross-mixin: _ProgressMixin ===
  void updateProgressDebounced();
  void saveProgress();

  // === Cross-mixin: _ThemeMixin ===
  EpubTheme getEpubTheme();

  /// Turns waiting to be scrolled to, oldest first.
  final List<bool> pendingScrollTurns = <bool>[];

  /// Whether [_runScrollTurns] is draining [pendingScrollTurns].
  bool isScrollTurnRunning = false;

  /// Requests a scroll-mode turn: one screenful forward or back.
  ///
  /// Every way of turning in scroll mode comes through here — the volume keys,
  /// the control panel arrows and a tap in the outer third of the page — so
  /// that all of them behave the same, including what happens when they arrive
  /// faster than the page can scroll.
  ///
  /// A turn that arrives while an earlier one is still scrolling does not wait
  /// for it: the screenful in flight is landed on its target immediately, and
  /// the new turn follows after [_kScrollTurnGap].  Presses therefore move the
  /// reader one screenful each instead of being swallowed by an animation that
  /// is still running — and the reader always ends up on a position the
  /// presses added up to.
  void handleScrollTurn(bool isNext) {
    pendingScrollTurns.add(isNext);

    if (isScrollTurnRunning) {
      // The turn in flight is the one this request is interrupting; landing it
      // is what lets the worker pick this one up.
      rendererController.finishScrollByViewport();
      return;
    }

    unawaited(_runScrollTurns());
  }

  Future<void> _runScrollTurns() async {
    isScrollTurnRunning = true;
    try {
      while (pendingScrollTurns.isNotEmpty) {
        final isNext = pendingScrollTurns.removeAt(0);

        // A layout-mode switch or a popped reader makes the rest meaningless.
        if (!mounted || !isScrollMode) {
          pendingScrollTurns.clear();
          return;
        }

        if (_isAtScrollBoundary(isNext)) {
          // There is no screenful left to scroll that way, so the turn belongs
          // to the chapter on the other side of this one — which is the only
          // way on through the book.
          if (isNext) {
            await nextSpineItem();
          } else {
            await previousSpineItem();
          }
        } else {
          await rendererController.scrollByViewport(isNext);
        }

        if (pendingScrollTurns.isNotEmpty) {
          await Future<void>.delayed(_kScrollTurnGap);
        }
      }
    } finally {
      isScrollTurnRunning = false;
    }
  }

  /// Whether the chapter has nowhere left to scroll in [isNext]'s direction.
  ///
  /// Read from the position the page reported, which every turn reports again
  /// as it lands — so a turn that ends on the bottom of the chapter is what
  /// makes the next one a chapter turn.
  bool _isAtScrollBoundary(bool isNext) =>
      isNext ? atChapterScrollEnd : atChapterScrollStart;

  bool canPerformPageTurn(bool isNext) {
    if (isNext) {
      if (currentPageInChapter >= totalPagesInChapter - 1 &&
          currentSpineItemIndex >= bookSession.spine.length - 1) {
        ToastService.showError(
          AppLocalizations.of(context)!.lastPageOfBook,
          theme: getEpubTheme().themeData,
        );
        return false;
      }
    } else {
      if (currentPageInChapter <= 0 && currentSpineItemIndex <= 0) {
        ToastService.showError(
          AppLocalizations.of(context)!.firstPageOfBook,
          theme: getEpubTheme().themeData,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> handlePageTurn(bool isNext) async {
    if (isNext) {
      await nextPage();
    } else {
      await previousPage();
    }
  }

  Future<void> goToPage(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= totalPagesInChapter) return;

    setState(() {
      currentPageInChapter = pageIndex;
    });
    updateProgressDebounced();

    await rendererController.jumpToPage(pageIndex);
    saveProgress();
  }

  Future<void> nextPage() async {
    if (currentPageInChapter < totalPagesInChapter - 1) {
      await goToPage(currentPageInChapter + 1);
    } else {
      await nextSpineItem();
    }
    saveProgress();
  }

  Future<void> previousPage() async {
    if (currentPageInChapter > 0) {
      await goToPage(currentPageInChapter - 1);
    } else {
      await previousSpineItem();
    }
    saveProgress();
  }
}
