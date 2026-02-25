import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/library/application/bookshelf_notifier.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'package:lumina/src/features/library/data/services/storage_cleanup_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/shelf_book.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/expandable_text.dart';
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
    // Check if changed
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
        if (didPop) return; // Already handled by the framework.
        if (_isEditing) {
          await _handleCancelEdit(isPop: true, book: book);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          // Leading: back arrow in view mode, close icon in edit mode.
          leading: _isEditing
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSaving
                      ? null
                      : () => _handleCancelEdit(isPop: false, book: book),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back_outlined),
                  onPressed: () => context.pop(),
                ),
          // Actions: save indicator/check in edit mode, share/edit in view mode.
          actions: _isEditing
              ? [
                  IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: AppLocalizations.of(context)!.save,
                    onPressed: book != null ? () => _save(book) : null,
                  ),
                ]
              : [
                  if (book != null)
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: AppLocalizations.of(context)!.shareEpub,
                      onPressed: () => _shareEpub(context, book),
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
          child: _bookDetailContent(context),
        ),
      ),
    );
  }

  Widget _bookDetailContent(BuildContext context) {
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));
    return bookAsync.when(
      loading: () {
        if (widget.initialBook != null) {
          return _isEditing
              ? _buildEditBody(context, widget.initialBook!)
              : _buildViewBody(context, widget.initialBook!);
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) => _buildErrorBody(context, error.toString()),
      data: (book) {
        if (book == null) {
          return _buildErrorBody(
            context,
            AppLocalizations.of(context)!.bookNotFound,
          );
        }
        return _isEditing
            ? _buildEditBody(context, book)
            : _buildViewBody(context, book);
      },
    );
  }

  // --------------------------------------------------------------------------
  // Edit body
  // --------------------------------------------------------------------------

  Widget _buildEditBody(BuildContext context, ShelfBook book) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image remains read-only in edit mode.
            Align(
              alignment: Alignment.centerLeft,
              child: Hero(
                tag: 'book-cover-${book.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: BookCover(relativePath: book.coverPath),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.title,
                errorText: _titleError,
              ),
              onChanged: (value) {
                _checkTitleError(value);
              },
              textInputAction: TextInputAction.next,
              style: AppTheme.contentTextStyle,
              maxLines: null,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
              ],
            ),

            const SizedBox(height: 16),

            // Authors field
            TextField(
              controller: _authorsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.authors,
                helperText: AppLocalizations.of(context)!.authorsTooltip,
              ),
              textInputAction: TextInputAction.next,
              style: AppTheme.contentTextStyle,
              maxLines: null,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
              ],
            ),

            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.bookDescription,
              ),
              minLines: 5,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              style: AppTheme.contentTextStyle,
            ),

            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // View body
  // --------------------------------------------------------------------------

  Widget _buildViewBody(BuildContext context, ShelfBook book) {
    final coverPath = book.coverPath;
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
                child: GestureDetector(
                  onTap: () {
                    context.push('/read/${book.fileHash}').then((_) {
                      ref.invalidate(bookDetailProvider(widget.bookId));
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: BookCover(relativePath: coverPath),
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
                book.authors.join(AppLocalizations.of(context)!.spliter),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  fontFamily: AppTheme.fontFamilyContent,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.left,
              ),
            ],

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

            // Metadata chips
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
                _buildMetadataChip(context, directionToString(book.direction)),
              ],
            ),

            const SizedBox(height: 40),

            // Read / Continue Reading button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/read/${book.fileHash}').then((_) {
                    ref.invalidate(bookDetailProvider(widget.bookId));
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

  // --------------------------------------------------------------------------
  // Shared helpers
  // --------------------------------------------------------------------------

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
                fontFamily: AppTheme.fontFamilyContent,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
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
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
      ),
    );
  }

  /// Copies the EPUB source file to a sanitised temporary path, shares it via
  /// the platform share sheet, then deletes the temporary file in a
  /// try-finally block to prevent stale cache accumulation.
  Future<void> _shareEpub(BuildContext context, ShelfBook book) async {
    final service = ref.read(storageCleanupServiceProvider);

    File? tempFile;
    try {
      final sourcePath = '${AppStorage.documentsPath}${book.filePath}';
      tempFile = await service.saveTempFileForSharing(
        File(sourcePath),
        book.title,
      );

      final params = ShareParams(
        subject: book.title,
        files: [XFile(tempFile.path, mimeType: 'application/epub+zip')],
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.shareEpubFailed(e.toString()),
        );
      }
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  void _checkTitleError(String value) {
    if (value.trim().isEmpty) {
      setState(() => _titleError = AppLocalizations.of(context)!.titleRequired);
    } else if (_titleError != null) {
      setState(() => _titleError = null);
    }
  }
}
