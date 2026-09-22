part of '../reader_screen.dart';

mixin _ProgressMixin on ConsumerState<ReaderScreen> {
  // === Borrowed state (provided by _ReaderScreenState fields) ===
  int get totalPagesInChapter;

  int get currentPageInChapter;

  int get currentSpineItemIndex;

  BookSession get bookSession;

  bool get isWebViewLoading;

  String get displayProgress;
  set displayProgress(String v);

  Timer? get progressDebouncer;
  set progressDebouncer(Timer? v);

  bool get isScrollMode;

  double get chapterScrollRatio;

  _PendingModeSwitch? get pendingModeSwitch;
  set pendingModeSwitch(_PendingModeSwitch? v);

  // === Cross-mixin: _PageNavigationMixin ===
  Future<void> goToPage(int pageIndex);

  void updateProgressDebounced() {
    progressDebouncer?.cancel();
    progressDebouncer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (isWebViewLoading) return;

      // Scroll mode has no pages to count, so the badge shows how far into the
      // chapter the reader is instead.
      final pageInChapterStr = isScrollMode
          ? '${(chapterScrollRatio * 100).round()}%'
          : '${currentPageInChapter + 1}/$totalPagesInChapter';

      if (displayProgress != pageInChapterStr) {
        setState(() {
          displayProgress = pageInChapterStr;
        });
      }
    });
  }

  /// Persists the reading position.
  ///
  /// [scrollMode] is the layout mode the position is read in, and defaults to
  /// the one on screen.  A layout-mode switch passes the mode it is leaving:
  /// the build that follows the switch is what updates the mode on screen, and
  /// the position being saved there still belongs to the mode it came from.
  void saveProgress({bool? scrollMode}) {
    final scrolling = scrollMode ?? isScrollMode;

    bookSession.saveProgress(
      currentChapterIndex: currentSpineItemIndex,
      currentPageInChapter: currentPageInChapter,
      totalPagesInChapter: totalPagesInChapter,
      scrollRatio: scrolling ? chapterScrollRatio : null,
    );
  }

  /// The position of the chapter on screen, as a fraction of that chapter, read
  /// in the layout mode [scrollMode].
  ///
  /// A fraction is the one measure the two layout modes agree on — it is what
  /// the web engine restores a frame from (`Renderer.applyPositionRatio`) — but
  /// they divide the chapter up differently.  Scrolling measures it against the
  /// chapter's scrollable length; paginated measures it against the boundaries
  /// *between* pages, of which a chapter of `n` pages has `n - 1`.  The
  /// fraction that gets persisted, `page / totalPages`, counts the pages
  /// themselves instead, and restoring from it puts the reader half a page
  /// early.
  double chapterRatio({required bool scrollMode}) {
    if (scrollMode) return chapterScrollRatio;

    final lastPage = totalPagesInChapter - 1;
    return lastPage > 0 ? currentPageInChapter / lastPage : 0;
  }

  /// Records where the reader is, for the frame load a layout-mode switch is
  /// about to perform.
  ///
  /// A switch replaces the whole WebView — the Android composition mode is
  /// fixed when the view is created, see `ReaderWebView` — and the load that
  /// follows it restores a position.  Left to itself that would be
  /// [BookSession.initialScrollPosition], the position the book was *opened*
  /// at, because the position reached since then only exists in the reader's
  /// own state; it is captured here before the engine that reports it goes
  /// away.
  ///
  /// [fromScrollMode] names the mode being left, which is the one still holding
  /// that position.  [toPaginated] says whether the mode being switched to
  /// counts pages, whose number only the chapter itself knows — see
  /// [settleModeSwitch].
  void capturePositionForModeSwitch({
    required bool fromScrollMode,
    required bool toPaginated,
  }) {
    // Nothing to carry across while a chapter is still loading: there is no
    // position on screen yet, and the load already under way comes back to the
    // stored one by itself.
    if (isWebViewLoading) return;

    pendingModeSwitch = _PendingModeSwitch(
      ratio: chapterRatio(scrollMode: fromScrollMode),
      toPaginated: toPaginated,
    );

    // The engine is about to be torn down, which is the last moment at which
    // the position it reports can be persisted.
    saveProgress(scrollMode: fromScrollMode);
  }

  /// Takes the position captured by [capturePositionForModeSwitch], if the load
  /// that is starting is the one following a switch.
  ///
  /// Cleared as it is read: it belongs to that load alone.
  _PendingModeSwitch? takePendingModeSwitch() {
    final pending = pendingModeSwitch;
    pendingModeSwitch = null;
    return pending;
  }

  /// Lands the reader on the page that holds the position of a switch that has
  /// just loaded.
  ///
  /// The engine restores a paginated chapter from a fraction of its page count,
  /// which is a page further on than the fraction the position was read in (see
  /// [chapterRatio]) — past text the reader has not read yet.  How many pages
  /// the chapter holds is only known once it has laid itself out, so the page
  /// is settled here, right after the load, while the loading layer still
  /// covers the page.
  Future<void> settleModeSwitch(_PendingModeSwitch pending) async {
    if (!pending.toPaginated || !mounted) return;

    final lastPage = totalPagesInChapter - 1;
    if (lastPage <= 0) return;

    // The page whose top sits at or above the position, rather than the nearest
    // one: reading a line twice beats skipping it.  The nudge keeps a position
    // that came from a page boundary exactly on that page, which floating-point
    // division does not guarantee on its own.
    final page = (pending.ratio * lastPage + 1e-9).floor().clamp(0, lastPage);

    if (page != currentPageInChapter) {
      await goToPage(page);
    }
  }
}

/// The reading position a layout-mode switch has to come back to.
class _PendingModeSwitch {
  const _PendingModeSwitch({required this.ratio, required this.toPaginated});

  /// The position, as a fraction of the chapter that was on screen; see
  /// [_ProgressMixin.chapterRatio].
  final double ratio;

  /// Whether the mode being switched to counts pages.
  final bool toPaginated;
}
