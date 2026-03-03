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

  double calculateProgressRatio() {
    if (totalPagesInChapter == 0) return 0.0;
    final pageProgress = (currentPageInChapter + 1) / totalPagesInChapter;
    final chapterProgress = currentSpineItemIndex / bookSession.spine.length;
    return (chapterProgress + pageProgress / bookSession.spine.length).clamp(
      0.0,
      1.0,
    );
  }

  void updateProgressDebounced() {
    progressDebouncer?.cancel();
    progressDebouncer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (isWebViewLoading) return;

      final ratio = calculateProgressRatio();
      final newProgress = '${(ratio * 100.0).toStringAsFixed(2)}%';

      if (displayProgress != newProgress) {
        setState(() {
          displayProgress = newProgress;
        });
      }
    });
  }

  Future<void> saveProgress() async {
    await bookSession.saveProgress(
      currentChapterIndex: currentSpineItemIndex,
      currentPageInChapter: currentPageInChapter,
      totalPagesInChapter: totalPagesInChapter,
    );
  }
}
