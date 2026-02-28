import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

import '../data/epub_webview_handler.dart';
import '../../../core/services/toast_service.dart';

class ImageViewer extends StatefulWidget {
  final String imageUrl;
  final EpubWebViewHandler webViewHandler;
  final String epubPath;
  final String fileHash;
  final VoidCallback onClose;
  final Rect sourceRect;
  final EpubTheme epubTheme;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    required this.webViewHandler,
    required this.epubPath,
    required this.fileHash,
    required this.onClose,
    required this.sourceRect,
    required this.epubTheme,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  Uint8List? _imageData;
  double? _imageAspectRatio;
  bool _isLoading = true;
  bool _isClosing = false;

  final TransformationController _transformController =
      TransformationController();
  Rect? _dynamicCloseRect;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: AppTheme.defaultAnimationDurationMs,
      ),
    );

    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    _loadImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (_isClosing) return;

    final Size screenSize = MediaQuery.of(context).size;
    final Matrix4 matrix = _transformController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    setState(() {
      _isClosing = true;
      _dynamicCloseRect = Rect.fromLTWH(
        translation.x,
        translation.y,
        screenSize.width * scale,
        screenSize.height * scale,
      );
      _transformController.value = Matrix4.identity();
    });

    await _controller.reverse();

    if (mounted) {
      widget.onClose();
    }
  }

  Future<void> _loadImage() async {
    final themeData = widget.epubTheme.themeData;
    try {
      final uri = WebUri(widget.imageUrl);
      final response = await widget.webViewHandler.handleRequest(
        epubPath: widget.epubPath,
        fileHash: widget.fileHash,
        requestUrl: uri,
      );

      if (response != null && response.data != null) {
        final bytes = response.data!;

        final image = await decodeImageFromList(bytes);
        final aspectRatio = image.width / image.height;
        image.dispose();

        if (mounted) {
          await precacheImage(MemoryImage(bytes), context);
        }

        if (mounted) {
          setState(() {
            _imageData = bytes;
            _imageAspectRatio = aspectRatio;
            _isLoading = false;
          });
        }

        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 10));
        _controller.forward();
      } else {
        HapticFeedback.lightImpact();
        if (mounted) {
          ToastService.showError('Failed to load image', theme: themeData);
          await _handleClose();
        }
      }
    } catch (e) {
      debugPrint('Error loading zoomed image: $e');
      HapticFeedback.lightImpact();
      if (mounted) {
        ToastService.showError('Error loading image', theme: themeData);
        await _handleClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final Rect fullscreenRect = Rect.fromLTWH(
      0,
      0,
      screenSize.width,
      screenSize.height,
    );
    final Rect targetEndRect = _dynamicCloseRect ?? fullscreenRect;

    final themeData = widget.epubTheme.themeData;

    return Theme(
      data: themeData,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handleClose();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = _curve.value;
            final Rect currentRect = Rect.lerp(
              widget.sourceRect,
              targetEndRect,
              t,
            )!;

            final bool isExpanded = t == 1.0;
            final bool canZoom =
                isExpanded && !_isLoading && _imageData != null;

            final double bgOpacity = 0.9 * t;

            return Stack(
              children: [
                if (_imageData != null)
                  GestureDetector(
                    onTap: _handleClose,
                    child: Container(
                      color: themeData.colorScheme.scrim.withValues(
                        alpha: bgOpacity,
                      ),
                    ),
                  ),

                if (_imageData != null)
                  Positioned.fromRect(
                    rect: currentRect,
                    child: GestureDetector(
                      onTap: _handleClose,
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: canZoom
                            ? _buildInteractiveViewer()
                            : Opacity(opacity: t, child: _buildStaticImage()),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the common image widget.
  Widget _buildImageView(Uint8List imageData, double t) {
    if (_imageAspectRatio == null) {
      return const SizedBox();
    }
    final curve = Curves.easeOutQuart.transform(t);

    return Center(
      child: AspectRatio(
        aspectRatio: _imageAspectRatio!,
        child: Container(
          color: Colors.white.withValues(alpha: curve),
          child: Image.memory(
            imageData,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveViewer() {
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(child: _buildImageView(_imageData!, _controller.value)),
    );
  }

  Widget _buildStaticImage() {
    if (_isLoading) {
      return const SizedBox();
    }
    return SizedBox.expand(
      child: _buildImageView(_imageData!, _controller.value),
    );
  }
}
