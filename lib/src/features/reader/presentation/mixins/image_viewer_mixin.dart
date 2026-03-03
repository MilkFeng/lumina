part of '../reader_screen.dart';

mixin _ImageViewerMixin on ConsumerState<ReaderScreen> {
  // === Borrowed state (provided by _ReaderScreenState fields) ===
  BookSession get bookSession;

  bool get showControls;

  bool get isImageViewerVisible;
  set isImageViewerVisible(bool v);

  String? get currentImageUrl;
  set currentImageUrl(String? v);

  Rect? get currentImageRect;
  set currentImageRect(Rect? v);

  void handleImageLongPress(String imageUrl, Rect rect) {
    if (!bookSession.isLoaded) return;
    if (showControls) return;

    setState(() {
      currentImageUrl = imageUrl;
      currentImageRect = rect;
      isImageViewerVisible = true;
    });
  }

  void closeImageViewer() {
    setState(() {
      isImageViewerVisible = false;
      currentImageUrl = null;
      currentImageRect = null;
    });
  }
}
