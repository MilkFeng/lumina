import 'dart:async';
import 'dart:io';

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
import '../../../core/providers/cover_file_provider.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/widgets/book_cover.dart';
import '../data/book_cover_edit_service.dart';
import '../../library/domain/shelf_book.dart';
import '../../../../l10n/app_localizations.dart';

part 'book_detail_screen.g.dart';

/// Actions available in the unsaved-changes confirmation dialog.
enum _DiscardAction { save, discard, cancel }

/// Provider to fetch a single book by file hash.
@riverpod
Future<ShelfBook?> bookDetail(Ref ref, String fileHash) async {
  final repository = ref.watch(shelfBookRepositoryProvider);
  return await repository.getBookByHash(fileHash);
}

/// Book Detail Screen - Shows detailed information about a book, with support
/// for inline editing of cover, title, authors, and description.
class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId; // fileHash
  final ShelfBook? initialBook; // Optional initial data for instant display

  const BookDetailScreen({super.key, required this.bookId, this.initialBook});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // Editing state
  // --------------------------------------------------------------------------
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPickingCover = false;
  File? _coverDraft;
  ImageProvider? _draftCoverImage;
  ImageProvider? _savedCoverImage;
  final _coverService = BookCoverEditService();
  String? _titleError;

  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _descriptionController;

  // Animates the AppBar background color between surface and surfaceContainer.
  late final AnimationController _colorController;
  late final Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _authorsController = TextEditingController();
    _descriptionController = TextEditingController();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 0.0, // 0 = view mode (surface), 1 = edit mode (surfaceContainer)
    );
    _colorAnimation = CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    if (!_isSaving) unawaited(_coverService.discard(_coverDraft));
    _titleController.dispose();
    _authorsController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
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
    _colorController.forward();
    setState(() => _isEditing = true);
  }

  /// Switches back to view mode without saving.
  void _exitEditMode() {
    final draft = _coverDraft;
    _coverDraft = null;
    _draftCoverImage = null;
    unawaited(_coverService.discard(draft));
    _colorController.reverse();
    setState(() => _isEditing = false);
  }

  Future<void> _pickCover() async {
    if (_isSaving || _isPickingCover) return;
    setState(() => _isPickingCover = true);
    final result = await _coverService.pickCover();
    final draft = result.getRight().toNullable();
    if (!mounted || !_isEditing) {
      await _coverService.discard(draft);
      return;
    }
    try {
      if (result.isLeft()) {
        ToastService.showError(AppLocalizations.of(context)!.coverPickFailed);
      } else if (draft != null) {
        final image = ResizeImage.resizeIfNeeded(
          null,
          BookCover.globalCacheHeight,
          MemoryImage(await draft.readAsBytes()),
        );
        if (!mounted) {
          await _coverService.discard(draft);
          return;
        }
        Object? imageError;
        // Keep the current cover visible until the new preview has a decoded frame.
        await precacheImage(
          image,
          context,
          onError: (error, _) => imageError = error,
        );
        if (imageError != null) throw imageError!;
        if (!mounted || !_isEditing) {
          await _coverService.discard(draft);
          return;
        }
        final previous = _coverDraft;
        setState(() {
          _coverDraft = draft;
          _draftCoverImage = image;
        });
        unawaited(_coverService.discard(previous));
      }
    } catch (_) {
      await _coverService.discard(draft);
      if (mounted) {
        ToastService.showError(AppLocalizations.of(context)!.coverPickFailed);
      }
    } finally {
      if (mounted) setState(() => _isPickingCover = false);
    }
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
    if (_isSaving || _isPickingCover) return;

    // Validate required fields before hitting the repository.
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ToastService.showError(AppLocalizations.of(context)!.titleRequired);
      return;
    }

    setState(() => _isSaving = true);

    final newAuthors = _authorsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final newDescription = _descriptionController.text.trim();

    // Snapshot original values so we can roll back if the save fails,
    // keeping the in-memory Isar object consistent with the database.
    final originalTitle = book.title;
    final originalAuthors = List<String>.from(book.authors);
    final originalDescription = book.description;
    final originalUpdatedAt = book.updatedAt;
    final originalCoverPath = book.coverPath;
    final repository = ref.read(shelfBookRepositoryProvider);
    final draft = _coverDraft;
    var committed = false;

    try {
      book.title = newTitle;
      book.authors = newAuthors;
      book.description = newDescription.isEmpty ? null : newDescription;
      book.updatedAt = DateTime.now().millisecondsSinceEpoch;

      final result = draft == null
          ? await repository.saveBook(book)
          : await _coverService.saveCover(
              draft: draft,
              fileHash: book.fileHash,
              persist: (relativePath) {
                book.coverPath = relativePath;
                return repository.saveBook(book);
              },
            );

      committed = result.isRight();
      if (committed && draft != null) {
        // The persisted file has the same bytes; reuse its decoded preview when
        // leaving edit mode instead of waiting for another file lookup and decode.
        _savedCoverImage = _draftCoverImage;
        final cover = File('${AppStorage.documentsPath}${book.coverPath}');
        await FileImage(cover).evict();
        await ResizeImage.resizeIfNeeded(
          null,
          BookCover.globalCacheHeight,
          FileImage(cover),
        ).evict();
        if (mounted) ref.invalidate(coverFileProvider(book.coverPath));
        if (originalCoverPath != null && originalCoverPath != book.coverPath) {
          await _coverService.discard(
            File(
              '${AppStorage.documentsPath}${Uri.decodeFull(originalCoverPath)}',
            ),
          );
        }
      }

      result.fold(
        (error) {
          // Roll back the in-memory mutation so the object stays consistent with DB.
          book.title = originalTitle;
          book.authors = originalAuthors;
          book.description = originalDescription;
          book.updatedAt = originalUpdatedAt;
          book.coverPath = originalCoverPath;
          if (mounted) {
            ToastService.showError(
              AppLocalizations.of(context)!.bookSaveFailed(error),
            );
          }
        },
        (_) {
          if (mounted) {
            ref.invalidate(bookDetailProvider(widget.bookId));
            ref.read(bookshelfProvider.notifier).refresh();
            ToastService.showSuccess(AppLocalizations.of(context)!.bookSaved);
            _exitEditMode();
          }
        },
      );
    } catch (e) {
      if (!committed) {
        // Roll back the in-memory mutation so the object stays consistent with DB.
        book.title = originalTitle;
        book.authors = originalAuthors;
        book.description = originalDescription;
        book.updatedAt = originalUpdatedAt;
        book.coverPath = originalCoverPath;
        if (mounted) {
          ToastService.showError(
            AppLocalizations.of(context)!.bookSaveFailed(e.toString()),
          );
        }
      } else {
        // Refresh failures must not undo metadata already committed to the database.
        debugPrint('Could not refresh the saved book cover: $e');
        if (mounted) {
          ref.invalidate(coverFileProvider(book.coverPath));
          ref.invalidate(bookDetailProvider(widget.bookId));
          ref.read(bookshelfProvider.notifier).refresh();
          ToastService.showSuccess(AppLocalizations.of(context)!.bookSaved);
          _exitEditMode();
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
      if (!mounted) await _coverService.discard(draft);
    }
  }

  // --------------------------------------------------------------------------
  // Discard confirmation dialog
  // --------------------------------------------------------------------------

  /// Shows a modal dialog asking the user what to do with unsaved changes.
  Future<bool> _handleCancelEdit({required ShelfBook? book}) async {
    if (_isSaving || _isPickingCover) return false;
    // Skip the dialog if nothing has changed.
    final newAuthors = _authorsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final hasChanges =
        _coverDraft != null ||
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

    if (!mounted) return false;

    switch (action) {
      case _DiscardAction.discard:
        _exitEditMode();
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
    final book = bookAsync.value;

    return PopScope(
      // Prevent the system from popping the route while in edit mode.
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isEditing) {
          await _handleCancelEdit(book: book);
        }
      },
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              // Lerp between surface (view) and surfaceContainer (edit).
              backgroundColor: Color.lerp(
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainer,
                _colorAnimation.value,
              ),
              // Leading: back arrow in view mode, close icon in edit mode.
              leading: _isEditing
                  ? IconButton(
                      icon: const Icon(Icons.close_outlined),
                      onPressed: _isSaving || _isPickingCover
                          ? null
                          : () => _handleCancelEdit(book: book),
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
                        onPressed:
                            book != null && !_isSaving && !_isPickingCover
                            ? () => _save(book)
                            : null,
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
                return AbsorbPointer(
                  absorbing: isTransitioning || _isSaving,
                  child: child,
                );
              },
              child: _buildBody(context),
            ),
          );
        },
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
        coverImage: _draftCoverImage ?? _savedCoverImage,
        isPickingCover: _isPickingCover,
        onPickCover: _pickCover,
      );
    }
    return BookDetailViewBody(
      book: book,
      bookId: widget.bookId,
      coverImage: _savedCoverImage,
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
