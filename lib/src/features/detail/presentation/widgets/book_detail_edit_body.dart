import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../library/domain/shelf_book.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../../l10n/app_localizations.dart';

/// Inline-editing form for a [ShelfBook].
///
/// Displays the cover (read-only) followed by editable fields for title,
/// authors, and description. All [TextEditingController]s are owned by the
/// parent state; this widget is purely presentational.
class BookDetailEditBody extends StatelessWidget {
  final ShelfBook book;
  final TextEditingController titleController;
  final TextEditingController authorsController;
  final TextEditingController descriptionController;

  /// Validation error message shown below the title field, or null when valid.
  final String? titleError;

  /// Called every time the title field value changes so the parent can
  /// update [titleError] in response.
  final ValueChanged<String> onTitleChanged;

  const BookDetailEditBody({
    super.key,
    required this.book,
    required this.titleController,
    required this.authorsController,
    required this.descriptionController,
    required this.titleError,
    required this.onTitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image — read-only, keeps the Hero tag alive.
            Align(
              alignment: Alignment.centerLeft,
              child: Hero(
                tag: 'book-cover-${book.id}',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: BookCover(
                    relativePath: book.coverPath,
                    radius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title (required)
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n.title,
                errorText: titleError,
              ),
              onChanged: onTitleChanged,
              textInputAction: TextInputAction.next,
              maxLines: null,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
              ],
            ),

            const SizedBox(height: 16),

            // Authors (comma-separated)
            TextField(
              controller: authorsController,
              decoration: InputDecoration(
                labelText: l10n.authors,
                helperText: l10n.authorsTooltip,
              ),
              textInputAction: TextInputAction.next,
              maxLines: null,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
              ],
            ),

            const SizedBox(height: 16),

            // Description (multi-line, optional)
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: l10n.bookDescription),
              minLines: 5,
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }
}
