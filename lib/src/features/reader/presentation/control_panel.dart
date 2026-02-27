import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/application/reader_settings_notifier.dart';
import 'widgets/reader_style_bottom_sheet.dart';

class ControlPanel extends ConsumerStatefulWidget {
  final bool showControls;
  final String title;
  final int currentSpineItemIndex;
  final int totalSpineItems;
  final int currentPageInChapter;
  final int totalPagesInChapter;
  final int direction;
  final VoidCallback onBack;
  final VoidCallback onOpenDrawer;
  final VoidCallback onPreviousPage;
  final VoidCallback onFirstPage;
  final VoidCallback onNextPage;
  final VoidCallback onLastPage;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;

  const ControlPanel({
    super.key,
    required this.showControls,
    required this.title,
    required this.currentSpineItemIndex,
    required this.totalSpineItems,
    required this.currentPageInChapter,
    required this.totalPagesInChapter,
    required this.direction,
    required this.onBack,
    required this.onOpenDrawer,
    required this.onPreviousPage,
    required this.onFirstPage,
    required this.onNextPage,
    required this.onLastPage,
    required this.onPreviousChapter,
    required this.onNextChapter,
  });

  bool get isVertical => direction == 1;

  @override
  ConsumerState<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends ConsumerState<ControlPanel> {
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  bool get _shouldHandleOnPreviousChapter {
    return widget.currentSpineItemIndex > 0 || widget.currentPageInChapter > 0;
  }

  bool get _shouldHandleOnNextChapter {
    return widget.currentSpineItemIndex < widget.totalSpineItems - 1 ||
        (widget.currentSpineItemIndex == widget.totalSpineItems - 1 &&
            widget.currentPageInChapter < widget.totalPagesInChapter - 1);
  }

  bool get _shouldHandleOnLongPressLeft {
    if (widget.isVertical) {
      return _shouldHandleOnNextChapter;
    } else {
      return _shouldHandleOnPreviousChapter;
    }
  }

  bool get _shouldHandleOnLongPressRight {
    if (widget.isVertical) {
      return _shouldHandleOnPreviousChapter;
    } else {
      return _shouldHandleOnNextChapter;
    }
  }

  bool get _shouldHandleOnPreviousPage {
    return widget.currentSpineItemIndex > 0 || widget.currentPageInChapter > 0;
  }

  bool get _shouldHandleOnNextPage {
    return widget.currentSpineItemIndex < widget.totalSpineItems - 1 ||
        widget.currentPageInChapter < widget.totalPagesInChapter - 1;
  }

  bool get _shouldHandleOnPressLeft {
    if (widget.isVertical) {
      return _shouldHandleOnNextPage;
    } else {
      return _shouldHandleOnPreviousPage;
    }
  }

  bool get _shouldHandleOnPressRight {
    if (widget.isVertical) {
      return _shouldHandleOnPreviousPage;
    } else {
      return _shouldHandleOnNextPage;
    }
  }

  void _handlePreviousChapter() {
    if (widget.currentPageInChapter == 0 && widget.currentSpineItemIndex > 0) {
      HapticFeedback.selectionClick();
      widget.onPreviousChapter();
    } else if (widget.currentPageInChapter > 0) {
      HapticFeedback.selectionClick();
      widget.onFirstPage();
    }
  }

  void _handleNextChapter() {
    if (widget.currentSpineItemIndex < widget.totalSpineItems - 1) {
      HapticFeedback.selectionClick();
      widget.onNextChapter();
    } else if (widget.currentSpineItemIndex == widget.totalSpineItems - 1 &&
        widget.currentPageInChapter < widget.totalPagesInChapter - 1) {
      HapticFeedback.selectionClick();
      widget.onLastPage();
    }
  }

  void _handleLongPressLeft() {
    if (widget.isVertical) {
      _handleNextChapter();
    } else {
      _handlePreviousChapter();
    }
  }

  void _handleLongPressRight() {
    if (widget.isVertical) {
      _handlePreviousChapter();
    } else {
      _handleNextChapter();
    }
  }

  void _handleTapLeft() {
    if (widget.isVertical) {
      widget.onNextPage();
    } else {
      widget.onPreviousPage();
    }
  }

  void _handleTapRight() {
    if (widget.isVertical) {
      widget.onPreviousPage();
    } else {
      widget.onNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsNotifierProvider);
    final epubTheme = settings.toEpubTheme(
      platformBrightness: Theme.of(context).colorScheme.brightness,
    );
    final isDark = epubTheme.isDark;
    final themeData = AppTheme.buildTheme(epubTheme.colorScheme);
    return Theme(
      data: themeData,
      child: Stack(
        children: [
          // Top Bar
          AnimatedPositioned(
            duration: const Duration(
              milliseconds: AppTheme.defaultAnimationDurationMs,
            ),
            curve: Curves.easeInOut,
            top: widget.showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(
                milliseconds: AppTheme.defaultAnimationDurationMs,
              ),
              opacity: widget.showControls ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: themeData.colorScheme.surfaceContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 10,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_outlined),
                    onPressed: widget.onBack,
                  ),
                  title: Text(
                    widget.title,
                    style: themeData.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Bar
          AnimatedPositioned(
            duration: const Duration(
              milliseconds: AppTheme.defaultAnimationDurationMs,
            ),
            curve: Curves.easeInOut,
            bottom: widget.showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(
                milliseconds: AppTheme.defaultAnimationDurationMs,
              ),
              opacity: widget.showControls ? 1.0 : 0.0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.surfaceContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 10,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.list_outlined),
                      onPressed: widget.onOpenDrawer,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onLongPressStart: _shouldHandleOnLongPressLeft
                              ? (_) {
                                  _handleLongPressLeft();
                                  _longPressTimer = Timer.periodic(
                                    const Duration(milliseconds: 500),
                                    (timer) {
                                      _handleLongPressLeft();
                                    },
                                  );
                                }
                              : null,
                          onLongPressEnd: (_) {
                            _longPressTimer?.cancel();
                          },
                          onLongPressCancel: () {
                            _longPressTimer?.cancel();
                          },
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left_outlined),
                            onPressed: _shouldHandleOnPressLeft
                                ? _handleTapLeft
                                : null,
                            onLongPress: null,
                            disabledColor: themeData.colorScheme.onSurface
                                .withAlpha(100),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.totalSpineItems == 0
                                  ? '0/0'
                                  : '${widget.currentSpineItemIndex + 1}/${widget.totalSpineItems}',
                              style: themeData.textTheme.displayMedium,
                            ),
                            if (widget.totalPagesInChapter > 1)
                              Text(
                                '${widget.currentPageInChapter + 1}/${widget.totalPagesInChapter}',
                                style: themeData.textTheme.bodyMedium,
                              ),
                          ],
                        ),
                        GestureDetector(
                          onLongPressStart: _shouldHandleOnLongPressRight
                              ? (_) {
                                  _handleLongPressRight();
                                  _longPressTimer = Timer.periodic(
                                    const Duration(milliseconds: 500),
                                    (timer) {
                                      _handleLongPressRight();
                                    },
                                  );
                                }
                              : null,
                          onLongPressEnd: (_) {
                            _longPressTimer?.cancel();
                          },
                          onLongPressCancel: () {
                            _longPressTimer?.cancel();
                          },
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right_outlined),
                            onPressed: _shouldHandleOnPressRight
                                ? _handleTapRight
                                : null,
                            onLongPress: null,
                            disabledColor: themeData.colorScheme.onSurface
                                .withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.brush_outlined),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) {
                            return Consumer(
                              builder: (context, ref, child) {
                                final currentSettings = ref.watch(
                                  readerSettingsNotifierProvider,
                                );
                                final currentEpubTheme = currentSettings
                                    .toEpubTheme(
                                      platformBrightness:
                                          MediaQuery.platformBrightnessOf(
                                            context,
                                          ),
                                    );
                                final activeTheme = AppTheme.buildTheme(
                                  currentEpubTheme.colorScheme,
                                );

                                return Theme(
                                  data: activeTheme,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: activeTheme
                                          .colorScheme
                                          .surfaceContainerLow,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(28),
                                      ),
                                    ),
                                    child: SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Center(
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                top: 24,
                                                bottom: 16,
                                              ),
                                              height: 4,
                                              width: 32,
                                              decoration: BoxDecoration(
                                                color: activeTheme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withAlpha(100),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          const ReaderStyleBottomSheet(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          barrierColor: Colors.black.withAlpha(
                            isDark ? 150 : 80,
                          ),
                          scrollControlDisabledMaxHeightRatio: 0.75,
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
