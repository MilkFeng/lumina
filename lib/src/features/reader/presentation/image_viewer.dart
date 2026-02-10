import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'epub_webview_handler.dart';
import '../../../core/services/toast_service.dart';

/// A full-screen image viewer with zoom capabilities
class ImageViewer extends StatefulWidget {
  final String imageUrl;
  final EpubWebViewHandler webViewHandler;
  final String epubPath;
  final String fileHash;
  final VoidCallback onClose;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    required this.webViewHandler,
    required this.epubPath,
    required this.fileHash,
    required this.onClose,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();

  /// Static method to handle image long-press event
  static void handleImageLongPress(
    BuildContext context, {
    required String imageUrl,
    required EpubWebViewHandler webViewHandler,
    required String epubPath,
    required String fileHash,
  }) {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Show the image viewer as an overlay
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageViewer(
            imageUrl: imageUrl,
            webViewHandler: webViewHandler,
            epubPath: epubPath,
            fileHash: fileHash,
            onClose: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opacityController;
  late Animation<double> _opacityAnimation;
  Uint8List? _imageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _opacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _opacityController, curve: Curves.easeIn),
    );
    _loadImage();
  }

  @override
  void dispose() {
    _opacityController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      // Parse the image URL and fetch the image data
      final uri = WebUri(widget.imageUrl);

      // Use the WebView handler to fetch the image
      final response = await widget.webViewHandler.handleRequest(
        epubPath: widget.epubPath,
        fileHash: widget.fileHash,
        requestUrl: uri,
      );

      if (response != null && response.data != null) {
        setState(() {
          _imageData = response.data;
          _isLoading = false;
        });
        // Trigger fade-in animation
        _opacityController.reset();
        _opacityController.forward();
      } else {
        // Failed to load image
        if (mounted) {
          ToastService.showError('Failed to load image');
          widget.onClose();
        }
      }
    } catch (e) {
      debugPrint('Error loading zoomed image: $e');
      if (mounted) {
        ToastService.showError('Error loading image');
        widget.onClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Stack(
          children: [
            // Image viewer
            if (_imageData != null)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Container(
                        color: Colors.white,
                        child: Image.memory(_imageData!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.close_outlined,
                  color: Colors.white,
                  size: 32,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                ),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
