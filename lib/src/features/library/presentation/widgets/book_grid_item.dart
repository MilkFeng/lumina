import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/shelf_book.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../application/bookshelf_notifier.dart';

/// Book grid item widget - displays a single book in the grid
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
              // Book Cover
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BookCover(
                      relativePath: book.coverPath,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Book Title
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),

              // Book Author
              if (book.author.isNotEmpty)
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),

              // Reading Progress Indicator
              if (book.readingProgress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(
                    value: book.readingProgress,
                    minHeight: 2,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
            ],
          ),

          // Selection Checkbox
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check : null,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),

          // Finished Badge
          if (book.isFinished)
            Positioned(
              top: 8,
              left: 8,
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
      // Navigate to book detail
      context.push('/book/${book.fileHash}');
    }
  }
}

/// Empty library placeholder
class EmptyLibraryPlaceholder extends StatelessWidget {
  final VoidCallback onImportTap;

  const EmptyLibraryPlaceholder({super.key, required this.onImportTap});

  @override
  Widget build(BuildContext context) {
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
              'Your library is empty',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first book to get started',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onImportTap,
              icon: const Icon(Icons.add),
              label: const Text('Import Book'),
            ),
          ],
        ),
      ),
    );
  }
}
