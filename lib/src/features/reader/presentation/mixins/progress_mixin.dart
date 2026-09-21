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

  void saveProgress() {
    bookSession.saveProgress(
      currentChapterIndex: currentSpineItemIndex,
      currentPageInChapter: currentPageInChapter,
      totalPagesInChapter: totalPagesInChapter,
      scrollRatio: isScrollMode ? chapterScrollRatio : null,
    );
  }
}
