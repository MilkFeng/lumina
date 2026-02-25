import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/detail/presentation/book_detail_screen.dart';
import '../../../library/domain/shelf_book.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/expandable_text.dart';
import '../../../../../l10n/app_localizations.dart';

/// Read-only detail view for a single [ShelfBook].
///
/// Displays cover, title, authors, description, reading progress, metadata
/// chips, and a read/continue button. Tapping the cover or the button
/// navigates to the reader and then invalidates [bookDetailProvider].
class BookDetailViewBody extends ConsumerWidget {
  final ShelfBook book;
  final String bookId;

  const BookDetailViewBody({
    super.key,
    required this.book,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progressPercent = (book.readingProgress * 100).toStringAsFixed(2);

    void navigateToReader() {
      context.push('/read/${book.fileHash}').then((_) {
        ref.invalidate(bookDetailProvider(bookId));
      });
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with Hero animation — tapping opens the reader.
            Align(
              alignment: Alignment.centerLeft,
              child: Hero(
                tag: 'book-cover-${book.id}',
                child: GestureDetector(
                  onTap: navigateToReader,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: BookCover(
                      relativePath: book.coverPath,
                      radius: BorderRadius.circular(8),
                    ),
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

            // Authors
            if (book.authors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                book.authors.join(l10n.spliter),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  fontFamily: AppTheme.fontFamilyContent,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.left,
              ),
            ],

            // Description
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

            // Reading progress badge
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
                        ? l10n.progressPercent(progressPercent)
                        : l10n.notStarted,
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

            // Metadata chips
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                _MetadataChip(label: l10n.chaptersCount(book.totalChapters)),
                _MetadataChip(label: l10n.epubVersion(book.epubVersion)),
                _MetadataChip(label: directionToString(book.direction)),
              ],
            ),

            const SizedBox(height: 40),

            // Read / Continue reading button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: navigateToReader,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  book.readingProgress > 0
                      ? l10n.continueReading
                      : l10n.startReading,
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
}

/// Small outlined chip used to display a single piece of book metadata.
class _MetadataChip extends StatelessWidget {
  final String label;

  const _MetadataChip({required this.label});

  @override
  Widget build(BuildContext context) {
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
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
      ),
    );
  }
}
