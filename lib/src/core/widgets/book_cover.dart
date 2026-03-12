import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../providers/cover_file_provider.dart';

/// Book cover widget with Riverpod-based caching and gapless playback.
/// Parent should handle clipping with ClipRRect if rounded corners are needed.
class BookCover extends ConsumerWidget {
  final String? relativePath;
  final BorderRadius radius;
  final bool enableBorder;
  final int cacheHeight;
  static const int globalCacheHeight = 900;

  const BookCover({
    super.key,
    required this.relativePath,
    this.radius = BorderRadius.zero,
    this.enableBorder = true,
    this.cacheHeight = globalCacheHeight,
  });

  bool _isWellImageFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the cover file provider (cached by Riverpod)
    final coverFileAsync = ref.watch(coverFileProvider(relativePath));

    bool isWellImage = _isWellImageFile(relativePath ?? '');
    if (!isWellImage) {
      // If the file is not a well-known image type, show a placeholder with an icon
      return _buildPlaceholder(context);
    }

    return coverFileAsync.when(
      loading: () => _buildPlaceholder(context, showIcon: false),
      error: (error, stack) => _buildPlaceholder(context, showIcon: false),
      data: (file) {
        if (file == null) {
          return _buildPlaceholder(context);
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: enableBorder
                ? Border.all(color: Theme.of(context).dividerColor, width: 1)
                : null,
          ),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            cacheHeight: cacheHeight,
            // Prevent white flash during Hero transitions and rebuilds
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }

              return AnimatedOpacity(
                opacity: frame == null ? 0.0 : 1.0,
                duration: const Duration(
                  milliseconds: AppTheme.defaultLongAnimationDurationMs,
                ),
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(context, showIcon: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, {bool showIcon = true}) {
    return AspectRatio(
      aspectRatio: 210 / 297,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: enableBorder
              ? Border.all(color: Theme.of(context).dividerColor, width: 1)
              : null,
        ),
        constraints: BoxConstraints(
          maxHeight: cacheHeight.toDouble(),
          maxWidth: cacheHeight.toDouble() * (210 / 297),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!showIcon) {
              return const SizedBox.shrink();
            }
            final maxSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final iconSize = maxSize * 0.35;
            return Center(
              child: Icon(
                Icons.menu_book_outlined,
                size: iconSize,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
    );
  }
}
