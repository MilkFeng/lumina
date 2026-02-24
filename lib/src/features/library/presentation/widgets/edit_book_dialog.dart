import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/library/application/bookshelf_notifier.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/features/library/presentation/book_detail_screen.dart';

/// Private dialog widget for editing book metadata.
class EditBookDialog extends ConsumerStatefulWidget {
  final ShelfBook book;
  final String bookId;
  final WidgetRef ref;

  const EditBookDialog({
    super.key,
    required this.book,
    required this.bookId,
    required this.ref,
  });

  @override
  ConsumerState<EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends ConsumerState<EditBookDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorsController = TextEditingController(
      text: widget.book.authors.join(', '),
    );
    _descriptionController = TextEditingController(
      text: widget.book.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final newTitle = _titleController.text.trim();
      final newAuthors = _authorsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final newDescription = _descriptionController.text.trim();

      // Mutate the Isar object fields directly (no copyWith on Isar collections)
      final book = widget.book;
      book.title = newTitle.isNotEmpty ? newTitle : book.title;
      book.authors = newAuthors.isNotEmpty ? newAuthors : book.authors;
      book.author = book.authors.isNotEmpty ? book.authors.first : book.author;
      book.description = newDescription.isEmpty ? null : newDescription;
      book.updatedAt = DateTime.now().millisecondsSinceEpoch;

      final result = await ref.read(shelfBookRepositoryProvider).saveBook(book);

      result.fold(
        (error) {
          if (mounted) {
            ToastService.showError(
              AppLocalizations.of(context)!.bookSaveFailed(error),
            );
          }
        },
        (_) {
          // Invalidate providers to refresh the UI
          widget.ref.invalidate(bookDetailProvider(widget.bookId));
          widget.ref.read(bookshelfNotifierProvider.notifier).refresh();

          if (mounted) {
            ToastService.showSuccess(AppLocalizations.of(context)!.bookSaved);
            context.pop();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.bookSaveFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.editBook),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.title),
              textInputAction: TextInputAction.next,
              style: AppTheme.contentTextStyle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorsController,
              decoration: InputDecoration(
                labelText: l10n.authors,
                helperText: l10n.authorsTooltip,
              ),
              textInputAction: TextInputAction.next,
              style: AppTheme.contentTextStyle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.bookDescription),
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              style: AppTheme.contentTextStyle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => context.pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
