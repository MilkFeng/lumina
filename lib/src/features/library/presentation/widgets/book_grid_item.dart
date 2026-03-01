import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/shelf_book.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../application/bookshelf_notifier.dart';

/// Book grid item widget – displays a single book in the grid.
/// Appearance branches into three helpers based on [viewMode].
class BookGridItem extends ConsumerWidget {
  final ShelfBook book;
  final bool isSelectionMode;
  final bool isSelected;
  final ViewMode viewMode;
  final VoidCallback? onLongPress;

  const BookGridItem({
    super.key,
    required this.book,
    required this.isSelectionMode,
    required this.isSelected,
    required this.viewMode,
    this.onLongPress,
  });

  // ─── public build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      onLongPress: onLongPress,
      child: RepaintBoundary(
        child: Stack(
          children: [
            // Main mode-specific layout
            switch (viewMode) {
              ViewMode.relaxed => _buildRelaxed(context),
              ViewMode.compact => Positioned.fill(
                child: _buildCompact(context),
              ),
            },

            // Selection checkbox (top-left, all modes)
            if (isSelectionMode)
              Positioned(top: 8, left: 8, child: _buildCheckbox(context)),
          ],
        ),
      ),
    );
  }

  // ─── mode helpers ─────────────────────────────────────────────────────────

  /// Relaxed: cover + title + author + progress bar.
  Widget _buildRelaxed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCoverStack(context, fit: StackFit.expand)),
        const SizedBox(height: 12),
        Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        if (book.author.isNotEmpty)
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        if (book.readingProgress > 0 && !book.isDeleted)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: book.readingProgress,
                minHeight: 3,
              ),
            ),
          ),
      ],
    );
  }

  /// Compact: cover only, title gradient overlay + frosted progress badge.
  Widget _buildCompact(BuildContext context) {
    return _buildCoverStack(
      context,
      fit: StackFit.expand,
      extras: [
        // Bottom gradient + title
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(6),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 32, 6, 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    const Shadow(
                      color: Colors.black54,
                      blurRadius: 2.0,
                      offset: Offset(0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Progress badge (top-right)
        _buildProgressBadge(context),
      ],
    );
  }

  // ─── shared cover stack ───────────────────────────────────────────────────

  Widget _buildCoverStack(
    BuildContext context, {
    List<Widget> extras = const [],
    StackFit fit = StackFit.loose,
  }) {
    final maskAndExtras = Stack(
      fit: StackFit.expand,
      children: [
        // Selection colour overlay
        if (isSelectionMode)
          Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withAlpha(102)
                  : Theme.of(context).colorScheme.onSurface.withAlpha(51),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ...extras,
      ],
    );

    return Hero(
      transitionOnUserGestures: true,
      tag: 'book-cover-${book.id}',
      flightShuttleBuilder:
          (
            BuildContext flightContext,
            Animation<double> animation,
            HeroFlightDirection flightDirection,
            BuildContext fromHeroContext,
            BuildContext toHeroContext,
          ) {
            final bool isPush = flightDirection == HeroFlightDirection.push;
            final RenderBox? libraryBox =
                (isPush ? fromHeroContext : toHeroContext).findRenderObject()
                    as RenderBox?;
            final RenderBox? detailBox =
                (isPush ? toHeroContext : fromHeroContext).findRenderObject()
                    as RenderBox?;

            final Rect libraryRect = libraryBox != null
                ? (libraryBox.localToGlobal(Offset.zero) & libraryBox.size)
                : Rect.zero;
            final Rect detailRect = detailBox != null
                ? (detailBox.localToGlobal(Offset.zero) & detailBox.size)
                : Rect.zero;

            final RectTween trajectoryTween = RectTween(
              begin: libraryRect,
              end: detailRect,
            );

            final double statusBarHeight = MediaQuery.paddingOf(
              flightContext,
            ).top;
            final double libraryAppBarBottom =
                statusBarHeight + kToolbarHeight + 48.0;
            final double detailAppBarBottom = statusBarHeight + kToolbarHeight;

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final libraryOpacity = (1.0 - animation.value).clamp(0.0, 1.0);

                final currentRadius = BorderRadius.lerp(
                  BorderRadius.circular(6),
                  BorderRadius.circular(8),
                  animation.value,
                )!;

                final Rect currentRect =
                    trajectoryTween.evaluate(animation) ?? Rect.zero;
                final double currentGlobalY = currentRect.top;

                final double currentCeilingY =
                    libraryAppBarBottom +
                    (detailAppBarBottom - libraryAppBarBottom) *
                        animation.value;

                final double clipAmount = (currentCeilingY - currentGlobalY)
                    .clamp(0.0, double.infinity);

                final contentWidget = Stack(
                  fit: StackFit.expand,
                  children: [
                    BookCover(
                      relativePath: book.coverPath,
                      radius: currentRadius,
                    ),

                    Opacity(
                      opacity: libraryOpacity,
                      child: Material(
                        type: MaterialType.transparency,
                        child: maskAndExtras,
                      ),
                    ),
                  ],
                );

                return ClipRect(
                  clipper: _TopClipper(clipAmount),
                  child: contentWidget,
                );
              },
            );
          },
      child: Stack(
        fit: fit,
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: BookCover(
              relativePath: book.coverPath,
              radius: BorderRadius.circular(6),
            ),
          ),
          Positioned.fill(child: maskAndExtras),
        ],
      ),
    );
  }

  // ─── badge helpers ────────────────────────────────────────────────────────

  /// Frosted-glass percentage badge (comfortable / compact modes).
  Widget _buildProgressBadge(BuildContext context) {
    if (book.readingProgress <= 0 || book.isFinished || isSelectionMode) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 8,
      right: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.8),
          child: Text(
            '${(book.readingProgress * 100).toStringAsFixed(2)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(
              Icons.check_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
    );
  }

  // ─── tap handler ──────────────────────────────────────────────────────────

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (isSelectionMode) {
      ref.read(bookshelfNotifierProvider.notifier).toggleItemSelection(book);
    } else {
      final notifier = ref.read(bookshelfNotifierProvider.notifier);
      context.push('/book/${book.fileHash}', extra: book).then((_) {
        notifier.reloadQuietly();
      });
    }
  }
}

class _TopClipper extends CustomClipper<Rect> {
  final double clipAmount;

  _TopClipper(this.clipAmount);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, clipAmount, size.width, size.height);
  }

  @override
  bool shouldReclip(_TopClipper oldClipper) =>
      oldClipper.clipAmount != clipAmount;
}
