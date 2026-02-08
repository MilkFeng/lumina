import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/shelf_book.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/bookshelf_notifier.dart';
import '../../../../../l10n/app_localizations.dart';

/// Book grid item widget - displays a single book in the grid
/// This is a dumb/presentational widget that accepts data and callbacks
class BookGridItem extends ConsumerWidget {
  final ShelfBook book;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const BookGridItem({
    super.key,
    required this.book,
    required this.isSelectionMode,
    required this.isSelected,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover with selection overlay
              Expanded(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'book-cover-${book.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: BookCover(relativePath: book.coverPath),
                        ),
                      ),
                    ),
                    // Selection overlay
                    if (isSelectionMode)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(102)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(51),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Book Title
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.contentTextStyle,
              ),

              const SizedBox(height: 4),

              // Book Author
              if (book.author.isNotEmpty)
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.contentTextStyle.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                    fontSize: 12,
                  ),
                ),

              // Reading Progress Indicator
              if (book.readingProgress > 0 && !book.isDeleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: book.readingProgress,
                      minHeight: 3,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(51),
                    ),
                  ),
                ),
            ],
          ),

          // Selection Checkbox
          if (isSelectionMode)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
            ),

          // Finished Badge
          if (book.isFinished && !isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (isSelectionMode) {
      // Toggle selection
      ref.read(bookshelfNotifierProvider.notifier).toggleItemSelection(book);
    } else {
      // Navigate to book detail and reload on return
      context.push('/book/${book.fileHash}').then((_) {
        ref.read(bookshelfNotifierProvider.notifier).reloadQuietly();
      });
    }
  }
}

/// Empty library placeholder
class EmptyLibraryPlaceholder extends StatelessWidget {
  final VoidCallback onImportTap;

  const EmptyLibraryPlaceholder({super.key, required this.onImportTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noBooks,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addYourFirstBook,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onImportTap,
              icon: const Icon(Icons.add),
              label: Text(l10n.importBook),
            ),
          ],
        ),
      ),
    );
  }
}
