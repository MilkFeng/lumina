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
  static const int globalCacheHeight = 900;

  const BookCover({
    super.key,
    required this.relativePath,
    this.radius = BorderRadius.zero,
    this.enableBorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the cover file provider (cached by Riverpod)
    final coverFileAsync = ref.watch(coverFileProvider(relativePath));

    return coverFileAsync.when(
      loading: () => _buildPlaceholder(context),
      error: (error, stack) => _buildPlaceholder(context),
      data: (file) {
        if (file == null) {
          return _buildPlaceholder(context);
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: radius),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: enableBorder
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            cacheHeight: globalCacheHeight,
            // Prevent white flash during Hero transitions and rebuilds
            gaplessPlayback: true,
            // Smooth fade-in effect (300ms)
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
              return _buildPlaceholder(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 210 / 297,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[200],
        ),
        child: Center(
          child: Icon(
            Icons.book_outlined,
            size: 48,
            color: isDark ? Colors.grey[700] : Colors.grey,
          ),
        ),
      ),
    );
  }
}
