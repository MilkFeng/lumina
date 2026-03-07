part of '../reader_screen.dart';

mixin _FootnoteMixin on ConsumerState<ReaderScreen> {
  // === Borrowed state (provided by _ReaderScreenState fields) ===
  OverlayEntry? get footnoteOverlayEntry;
  set footnoteOverlayEntry(OverlayEntry? v);

  GlobalKey<FootnotePopupOverlayState> get footnoteKey;

  bool get isClosingFootnote;
  set isClosingFootnote(bool v);

  EpubWebViewHandler get webViewHandler;

  BookSession get bookSession;

  // === Cross-mixin: _ThemeMixin ===
  EpubTheme getEpubTheme();

  void handleFootnoteTap(String innerHtml, Rect rect, String baseUrl) {
    removeFootnoteOverlay();
    final overlayState = Overlay.of(context);
    final baseUri = Uri.tryParse(baseUrl);
    setState(() {
      footnoteOverlayEntry = OverlayEntry(
        builder: (context) => FootnotePopupOverlay(
          key: footnoteKey,
          anchorRect: rect,
          rawHtml: innerHtml,
          onDismiss: () => removeFootnoteOverlay(),
          epubTheme: getEpubTheme(),
          baseUrl: baseUri,
          webViewHandler: webViewHandler,
          epubPath: bookSession.book!.filePath!,
          fileHash: widget.fileHash,
        ),
      );
    });
    overlayState.insert(footnoteOverlayEntry!);
  }

  Future<void> removeFootnoteOverlay({bool animate = true}) async {
    if (footnoteOverlayEntry == null || isClosingFootnote) return;

    if (animate) {
      isClosingFootnote = true;
      if (footnoteKey.currentState != null) {
        await footnoteKey.currentState!.playReverseAnimation();
      }
    }

    footnoteOverlayEntry?.remove();
    setState(() {
      footnoteOverlayEntry = null;
      isClosingFootnote = false;
    });
  }
}
