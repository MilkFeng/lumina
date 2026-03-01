import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/library/application/bookshelf_notifier.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'package:lumina/src/features/detail/presentation/book_detail_helpers.dart';
import 'package:lumina/src/features/detail/presentation/widgets/book_detail_edit_body.dart';
import 'package:lumina/src/features/detail/presentation/widgets/book_detail_view_body.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../library/domain/shelf_book.dart';
import '../../../../l10n/app_localizations.dart';

part 'book_detail_screen.g.dart';

/// Actions available in the unsaved-changes confirmation dialog.
enum _DiscardAction { save, discard, cancel }

/// Provider to fetch a single book by file hash.
@riverpod
Future<ShelfBook?> bookDetail(BookDetailRef ref, String fileHash) async {
  final repository = ref.watch(shelfBookRepositoryProvider);
  return await repository.getBookByHash(fileHash);
}

/// Book Detail Screen - Shows detailed information about a book, with support
/// for inline editing of title, authors, and description.
class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId; // fileHash
  final ShelfBook? initialBook; // Optional initial data for instant display

  const BookDetailScreen({super.key, required this.bookId, this.initialBook});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  // --------------------------------------------------------------------------
  // Editing state
  // --------------------------------------------------------------------------
  bool _isEditing = false;
  bool _isSaving = false;
  String? _titleError;

  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _authorsController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Edit mode helpers
  // --------------------------------------------------------------------------

  /// Populates controllers with current book data and switches to edit mode.
  void _enterEditMode(ShelfBook book) {
    _titleController.text = book.title;
    _authorsController.text = book.authors.join(', ');
    _descriptionController.text = book.description ?? '';
    _checkTitleError(book.title);
    setState(() => _isEditing = true);
  }

  /// Switches back to view mode without saving.
  void _exitEditMode() {
    setState(() => _isEditing = false);
  }

  /// Updates [_titleError] based on whether [value] is blank.
  void _checkTitleError(String value) {
    if (value.trim().isEmpty) {
      setState(() => _titleError = AppLocalizations.of(context)!.titleRequired);
    } else if (_titleError != null) {
      setState(() => _titleError = null);
    }
  }

  /// Persists edits to the repository and refreshes relevant providers.
  Future<void> _save(ShelfBook book) async {
    if (_isSaving) return;

    // Validate required fields before hitting the repository.
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ToastService.showError(AppLocalizations.of(context)!.titleRequired);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newAuthors = _authorsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final newDescription = _descriptionController.text.trim();

      // Mutate the Isar object fields directly (no copyWith on Isar collections).
      book.title = newTitle.isNotEmpty ? newTitle : book.title;
      book.authors = newAuthors;
      book.author = book.authors.isNotEmpty ? book.authors.first : "";
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
          ref.invalidate(bookDetailProvider(widget.bookId));
          ref.read(bookshelfNotifierProvider.notifier).refresh();

          if (mounted) {
            ToastService.showSuccess(AppLocalizations.of(context)!.bookSaved);
            _exitEditMode();
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

  // --------------------------------------------------------------------------
  // Discard confirmation dialog
  // --------------------------------------------------------------------------

  /// Shows a modal dialog asking the user what to do with unsaved changes.
  ///
  /// [isPop] indicates whether this was triggered by a system back gesture; if
  /// the user chooses Discard in that case the method calls [context.pop()]
  /// itself.
  Future<bool> _handleCancelEdit({
    required bool isPop,
    required ShelfBook? book,
  }) async {
    // Skip the dialog if nothing has changed.
    final newAuthors = _authorsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final hasChanges =
        _titleController.text.trim() != (book?.title ?? '') ||
        newAuthors.join(', ') != (book?.authors.join(', ') ?? '') ||
        _descriptionController.text.trim() != (book?.description ?? '');

    if (!hasChanges) {
      _exitEditMode();
      return false;
    }

    final action = await showDialog<_DiscardAction>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.unsavedChangesTitle),
          content: Text(l10n.unsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_DiscardAction.cancel),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_DiscardAction.discard),
              child: Text(l10n.discard),
            ),
            if (book != null)
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(_DiscardAction.save),
                child: Text(l10n.save),
              ),
          ],
        );
      },
    );

    switch (action) {
      case _DiscardAction.discard:
        _exitEditMode();
        if (isPop && mounted) context.pop();
        return true;

      case _DiscardAction.save:
        if (book != null) await _save(book);
        return false;

      case _DiscardAction.cancel:
      case null:
        return false;
    }
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final routeAnimation = ModalRoute.of(context)?.animation;
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));
    final book = bookAsync.valueOrNull;

    return PopScope(
      // Prevent the system from popping the route while in edit mode.
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isEditing) {
          await _handleCancelEdit(isPop: true, book: book);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: _isEditing
              ? Theme.of(context).colorScheme.surfaceContainer
              : Theme.of(context).colorScheme.surface,
          // Leading: back arrow in view mode, close icon in edit mode.
          leading: _isEditing
              ? IconButton(
                  icon: const Icon(Icons.close_outlined),
                  onPressed: _isSaving
                      ? null
                      : () => _handleCancelEdit(isPop: false, book: book),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back_outlined),
                  onPressed: () => context.pop(),
                ),
          // Actions: save check in edit mode; share + edit in view mode.
          title: _isEditing
              ? Text(AppLocalizations.of(context)!.editBook)
              : null,
          actions: _isEditing
              ? [
                  IconButton(
                    icon: const Icon(Icons.check_outlined),
                    tooltip: AppLocalizations.of(context)!.save,
                    onPressed: book != null ? () => _save(book) : null,
                  ),
                ]
              : [
                  if (book != null)
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: AppLocalizations.of(context)!.shareEpub,
                      onPressed: () => shareEpub(context, book, ref),
                    ),
                  if (book != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: AppLocalizations.of(context)!.editBook,
                      onPressed: () => _enterEditMode(book),
                    ),
                ],
        ),
        body: AnimatedBuilder(
          animation: routeAnimation ?? const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            final isTransitioning = (routeAnimation?.value ?? 1.0) < 1.0;
            return AbsorbPointer(absorbing: isTransitioning, child: child);
          },
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));
    return bookAsync.when(
      loading: () {
        if (widget.initialBook != null) {
          return _bodyForBook(context, widget.initialBook!);
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, _) => _buildErrorBody(context, error.toString()),
      data: (book) {
        if (book == null) {
          return _buildErrorBody(
            context,
            AppLocalizations.of(context)!.bookNotFound,
          );
        }
        return _bodyForBook(context, book);
      },
    );
  }

  /// Returns the edit or view body depending on the current [_isEditing] flag.
  Widget _bodyForBook(BuildContext context, ShelfBook book) {
    if (_isEditing) {
      return BookDetailEditBody(
        book: book,
        titleController: _titleController,
        authorsController: _authorsController,
        descriptionController: _descriptionController,
        titleError: _titleError,
        onTitleChanged: _checkTitleError,
      );
    }
    return BookDetailViewBody(book: book, bookId: widget.bookId);
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
