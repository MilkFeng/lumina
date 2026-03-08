import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:lumina/src/features/reader/data/epub_webview_handler.dart';
import 'package:lumina/src/features/reader/data/reader_scripts.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

class FootnotePopupOverlay extends StatefulWidget {
  final Rect anchorRect;
  final String rawHtml;
  final VoidCallback onDismiss;
  final EpubTheme epubTheme;
  final Uri? baseUrl;
  final String epubPath;
  final String fileHash;
  final EpubWebViewHandler webViewHandler;

  const FootnotePopupOverlay({
    super.key,
    required this.anchorRect,
    required this.rawHtml,
    required this.onDismiss,
    required this.epubTheme,
    this.baseUrl,
    required this.epubPath,
    required this.fileHash,
    required this.webViewHandler,
  });

  @override
  State<FootnotePopupOverlay> createState() => FootnotePopupOverlayState();
}

class FootnotePopupOverlayState extends State<FootnotePopupOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  late bool _slideFromLeft;

  Future<void> playReverseAnimation() async {
    if (mounted) {
      await _animationController.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: AppTheme.defaultAnimationDurationMs,
      ),
    );
    _slideFromLeft = true;
    if (!_animationController.isAnimating &&
        !_animationController.isCompleted) {
      _animationController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    _slideFromLeft = widget.anchorRect.center.dx < (screenWidth / 2);
    _slideAnimation =
        Tween<Offset>(
          begin: Offset(_slideFromLeft ? -1.0 : 1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Uint8List> _fetchEpubImageBytes(String src) async {
    final uri = widget.baseUrl?.resolve(src);
    final webUri = WebUri(uri?.toString() ?? src);
    final response = await widget.webViewHandler.handleRequest(
      epubPath: widget.epubPath,
      fileHash: widget.fileHash,
      requestUrl: webUri,
    );
    if (response != null && response.data != null) {
      final bytes = response.data!;

      final image = await decodeImageFromList(bytes);
      image.dispose();

      if (mounted) {
        await precacheImage(MemoryImage(bytes), context);
      }
      return bytes;
    }
    return Uint8List(0);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    const double minBookmarkWidth = 150;
    final double maxBookmarkWidth = screenSize.width * 0.8;

    final spaceBelow =
        screenSize.height -
        widget.anchorRect.bottom -
        max(safePadding.bottom, 32);
    final spaceAbove = widget.anchorRect.top - safePadding.top;

    final bool showBelow = spaceBelow >= spaceAbove;

    final double calculatedMaxHeight = showBelow
        ? (spaceBelow - safePadding.bottom - 12.0)
        : (spaceAbove - safePadding.top - 12.0);

    final double maxBookmarkHeight = calculatedMaxHeight.clamp(
      100.0,
      screenSize.height * 0.4,
    );

    final double topPosition = showBelow ? widget.anchorRect.bottom + 6.0 : -1;
    final double bottomPosition = !showBelow
        ? (screenSize.height - widget.anchorRect.top) + 6.0
        : -1;

    final borderRadius = BorderRadius.horizontal(
      left: _slideFromLeft ? Radius.zero : const Radius.circular(4),
      right: _slideFromLeft ? const Radius.circular(4) : Radius.zero,
    );

    final isDark = widget.epubTheme.isDark;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: topPosition != -1 ? topPosition : null,
          bottom: bottomPosition != -1 ? bottomPosition : null,
          left: _slideFromLeft ? 0 : null,
          right: !_slideFromLeft ? 0 : null,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: widget.epubTheme.colorScheme.shadow.withAlpha(
                        isDark ? 50 : 25,
                      ),
                      blurRadius: 16,
                      offset: Offset(_slideFromLeft ? 4 : -4, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: maxBookmarkHeight,
                        maxWidth: maxBookmarkWidth,
                        minWidth: minBookmarkWidth,
                      ),
                      decoration: BoxDecoration(
                        color: widget.epubTheme.colorScheme.surfaceContainerHigh
                            .withValues(alpha: 0.75),
                        border: Border(
                          left: !_slideFromLeft
                              ? BorderSide(
                                  color: widget.epubTheme.colorScheme.primary,
                                  width: 4,
                                )
                              : BorderSide.none,
                          right: _slideFromLeft
                              ? BorderSide(
                                  color: widget.epubTheme.colorScheme.primary,
                                  width: 4,
                                )
                              : BorderSide.none,
                          top: BorderSide(
                            color: widget.epubTheme.colorScheme.outlineVariant,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: widget.epubTheme.colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: HtmlWidget(
                          widget.rawHtml,
                          baseUrl: widget.baseUrl,
                          textStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: widget.epubTheme.colorScheme.onSurface,
                                height: 1.6,
                              ),
                          onTapUrl: (url) async {
                            return true;
                          },
                          renderMode: RenderMode.column,
                          onErrorBuilder: (context, element, error) {
                            return Text(
                              'Error loading content',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color:
                                        widget.epubTheme.colorScheme.onSurface,
                                  ),
                            );
                          },
                          customWidgetBuilder: (element) {
                            if (element.localName == 'img') {
                              final src = element.attributes['src'];
                              if (src != null) {
                                return FutureBuilder<Uint8List>(
                                  future: _fetchEpubImageBytes(src),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: widget
                                                .epubTheme
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data!.isNotEmpty) {
                                      return GestureDetector(
                                        onTap: () {
                                          // TODO: Implement image tap to view full size
                                        },
                                        child: Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    }
                                    return Icon(
                                      Icons.broken_image,
                                      color: widget
                                          .epubTheme
                                          .colorScheme
                                          .onSurfaceVariant,
                                    );
                                  },
                                );
                              }
                            }
                            return null;
                          },
                          customStylesBuilder: (element) {
                            Map<String, String> styles = {};
                            final fontSize =
                                _getDefaultFontSizeWithoutScale(
                                  element.localName ?? '',
                                ) *
                                widget.epubTheme.zoom;
                            styles['font-size'] = '${fontSize}px';
                            if (widget.epubTheme.shouldOverrideTextColor) {
                              styles['color'] = colorToHex(
                                widget.epubTheme.colorScheme.onSurface,
                              );
                            }
                            if (element.localName == 'a') {
                              final color =
                                  widget.epubTheme.overridePrimaryColor ??
                                  widget.epubTheme.colorScheme.primary;
                              styles['color'] = colorToHex(color);
                              styles['text-decoration'] = 'none';
                            }
                            if (element.localName == 'ol' ||
                                element.localName == 'ul') {
                              return {'padding-left': '20px', 'margin': '0'};
                            }
                            if (element.localName == 'p') {
                              return {'margin': '0 0 8px 0'};
                            }
                            return styles;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getDefaultFontSizeWithoutScale(String elementName) {
    final fontSize =
        widget.epubTheme.themeData.textTheme.labelMedium?.fontSize ?? 14.0;
    switch (elementName.toLowerCase()) {
      case 'h1':
        return fontSize + 6.0;
      case 'h2':
        return fontSize + 5.0;
      case 'h3':
        return fontSize + 4.0;
      case 'h4':
        return fontSize + 3.0;
      case 'h5':
        return fontSize + 2.0;
      case 'h6':
        return fontSize + 1.0;

      case 'big':
        return fontSize + 2.0;

      case 'p':
      case 'div':
      case 'span':
      case 'a':
      case 'li':
      case 'blockquote':
      case 'pre':
      case 'code':
      case 'kbd':
        return fontSize;

      case 'small':
      case 'sub':
      case 'sup':
      case 'figcaption':
      case 'reference':
        return fontSize > 3.0 ? fontSize - 2.0 : fontSize * 0.75;

      case 'rt':
        return fontSize * 0.5;

      default:
        return fontSize;
    }
  }
}
