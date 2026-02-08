import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/shelf_book.dart';
import '../data/repositories/shelf_book_repository_provider.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/expandable_text.dart';
import '../../../../l10n/app_localizations.dart';

part 'book_detail_screen.g.dart';

/// Provider to fetch a single book by file hash
@riverpod
Future<ShelfBook?> bookDetail(BookDetailRef ref, String fileHash) async {
  final repository = ref.watch(shelfBookRepositoryProvider);
  return await repository.getBookByHash(fileHash);
}

/// Book Detail Screen - Shows detailed information about a book
class BookDetailScreen extends ConsumerWidget {
  final String bookId; // Actually fileHash now

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch book data using fileHash
    final bookAsync = ref.watch(bookDetailProvider(bookId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorBody(context, error.toString()),
        data: (book) {
          if (book == null) {
            return _buildErrorBody(
              context,
              AppLocalizations.of(context)!.bookNotFound,
            );
          }
          return _buildBookDetail(context, ref, book);
        },
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.error,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookDetail(BuildContext context, WidgetRef ref, ShelfBook book) {
    // V2: coverPath is already absolute
    final coverPath = book.coverPath;

    // Format reading progress
    final progressPercent = (book.readingProgress * 100).toStringAsFixed(2);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Cover Image with Hero Animation
            Align(
              alignment: Alignment.centerLeft,
              child: Hero(
                tag: 'book-cover-${book.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 200,
                    height: 300,
                    child: BookCover(relativePath: coverPath),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              book.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w400,
                fontFamily: AppTheme.fontFamilyContent,
              ),
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 12),

            // Author
            Text(
              book.author,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontFamily: AppTheme.fontFamilyContent,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),

            // Description (if available)
            if (book.description != null && book.description!.isNotEmpty) ...[
              const SizedBox(height: 24),
              ExpandableText(
                text: book.description!,
                maxLines: 4,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: AppTheme.fontFamilyContent,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Reading Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    book.readingProgress > 0
                        ? AppLocalizations.of(
                            context,
                          )!.progressPercent(progressPercent)
                        : AppLocalizations.of(context)!.notStarted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metadata
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                _buildMetadataChip(
                  context,
                  AppLocalizations.of(
                    context,
                  )!.chaptersCount(book.totalChapters),
                ),
                _buildMetadataChip(
                  context,
                  AppLocalizations.of(context)!.epubVersion(book.epubVersion),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Read Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/read/${book.fileHash}').then((value) {
                    ref.invalidate(bookDetailProvider(bookId));
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  book.readingProgress > 0
                      ? AppLocalizations.of(context)!.continueReading
                      : AppLocalizations.of(context)!.startReading,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
