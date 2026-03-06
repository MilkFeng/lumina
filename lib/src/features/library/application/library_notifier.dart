import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/features/library/application/progress_log.dart';
import 'package:lumina/src/features/library/data/services/import_backup_service_provider.dart';
import 'package:lumina/src/features/library/data/services/unified_import_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../domain/shelf_book.dart';
import '../domain/book_type.dart';
import '../data/repositories/shelf_book_repository_provider.dart';
import '../data/services/epub_import_service_provider.dart';
import '../data/services/pdf_import_service_provider.dart';

part 'library_notifier.g.dart';

enum ImportStatus { processing, success, failed }

class ImportProgress extends ProgressLog {
  final int totalCount;
  final int currentCount;
  final String currentFileName;
  final ImportStatus status;
  final String? errorMessage;
  final ShelfBook? book;

  ImportProgress({
    required this.totalCount,
    required this.currentCount,
    required this.currentFileName,
    required this.status,
    this.errorMessage,
    this.book,
  }) : super(
         status == ImportStatus.failed
             ? errorMessage ?? 'Unknown error'
             : (status == ImportStatus.success
                   ? 'Imported: ${book?.title}'
                   : 'Processing: $currentFileName'),
         status == ImportStatus.failed
             ? ProgressLogType.error
             : (status == ImportStatus.success
                   ? ProgressLogType.success
                   : ProgressLogType.info),
       );
}

/// State for library operations (updated for ShelfBook)
sealed class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<ShelfBook> books;
  LibraryLoaded(this.books);
}

class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);
}

/// Notifier for managing library operations with dependency injection
@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  @override
  Future<LibraryState> build() async {
    return await _loadBooks();
  }

  /// Load all books from database
  Future<LibraryState> _loadBooks() async {
    try {
      final repository = ref.read(shelfBookRepositoryProvider);
      final books = await repository.getAllBooks();
      return LibraryLoaded(books);
    } catch (e) {
      return LibraryError('Failed to load books: $e');
    }
  }

  /// Import a new book from file
  Future<Either<String, ShelfBook>> importBook(File file) async {
    state = const AsyncValue.loading();

    try {
      final importService = ref.read(epubImportServiceProvider);
      // Single call to import service handles everything
      final importResult = await importService.importBook(file);

      if (importResult.isLeft()) {
        final error = importResult.getLeft().toNullable()!;
        state = AsyncValue.data(LibraryError(error));
        return left(error);
      }

      final book = importResult.getRight().toNullable()!;

      // Reload books to update UI
      state = await AsyncValue.guard(() => _loadBooks());

      return right(book);
    } catch (e) {
      final error = 'Import failed: $e';
      state = AsyncValue.data(LibraryError(error));
      return left(error);
    }
  }

  Stream<ProgressLog> importLibraryFromFolder(BackupPaths backupPaths) async* {
    yield ProgressLog(
      'Starting import from folder: ${backupPaths.rootPath}',
      ProgressLogType.info,
    );

    final importService = ref.read(importBackupServiceProvider);

    try {
      await for (final progress in importService.importLibraryFromFolder(
        backupPaths,
      )) {
        yield progress;
      }
    } catch (e) {
      yield ProgressLog(
        'Failed to import from folder: $e',
        ProgressLogType.error,
      );
      debugPrint('Import from folder error: $e');
    }

    yield ProgressLog(
      'Import from folder completed. Refreshing library...',
      ProgressLogType.success,
    );
    await refresh();
  }

  /// Stream pipeline to process files one by one: Cache -> Import -> Clean.
  /// This prevents OOM and storage issues when importing massive folders.
  Stream<ProgressLog> importPipelineStream(List<PlatformPath> paths) async* {
    yield ProgressLog(
      'Starting import of ${paths.length} books',
      ProgressLogType.info,
    );
    final totalCount = paths.length;
    if (totalCount == 0) return;

    final unifiedImportService = ref.read(unifiedImportServiceProvider);
    final epubImportService = ref.read(epubImportServiceProvider);
    final pdfImportService = ref.read(pdfImportServiceProvider);

    int currentCount = 0;

    for (final path in paths) {
      ImportableEpub? importable;
      String currentFileName = '';

      try {
        currentFileName = path.name;

        // 1. Notify UI that caching is done and actual import is starting
        yield ImportProgress(
          totalCount: totalCount,
          currentCount: currentCount,
          currentFileName: currentFileName,
          status: ImportStatus.processing,
        );

        yield ProgressLog(
          'Processing file $currentFileName ($currentCount of $totalCount)',
          ProgressLogType.info,
        );

        // 2. Detect file type and route to appropriate import service
        final fileType = FileTypeDetector.detectTypeFromPath(path.name);
        final Either<String, ShelfBook> result;

        if (fileType == BookType.pdf) {
          // PDF import: Use PDF-specific import service
          result = await pdfImportService.importPdfFromPath(path);
        } else {
          // EPUB import: Cache the file from URI to local temp directory
          importable = await unifiedImportService.processEpub(path);

          // 3. Import the EPUB book and wait for the Either result
          result = await epubImportService.importBook(importable.cacheFile);
        }

        // 4. Notify UI of success or failure for this file
        yield result.fold(
          (errorMessage) => ImportProgress(
            totalCount: totalCount,
            currentCount: currentCount,
            currentFileName: currentFileName,
            status: ImportStatus.failed,
            errorMessage: errorMessage,
          ),
          (book) => ImportProgress(
            totalCount: totalCount,
            currentCount: currentCount,
            currentFileName: currentFileName,
            status: ImportStatus.success,
            book: book,
          ),
        );
      } catch (e) {
        // Handle unexpected errors during the caching or stream reading phase
        yield ImportProgress(
          totalCount: totalCount,
          currentCount: currentCount,
          currentFileName: currentFileName,
          status: ImportStatus.failed,
          errorMessage: 'Pipeline error: $e',
        );
      } finally {
        // 5. CRITICAL: Always clean up the temporary cache file IMMEDIATELY
        // (Only for EPUBs - PDFs are handled by their own import service)
        if (importable != null) {
          try {
            await unifiedImportService.cleanCache(importable.cacheFile);
          } catch (cleanError) {
            debugPrint('Failed to clean cache file: $cleanError');
          }
        }
        currentCount++;
      }
    }

    // 6. After all files are processed, refresh the book list to update UI
    yield ProgressLog(
      'Import completed. Refreshing library...',
      ProgressLogType.success,
    );
    await refresh();
  }

  /// Refresh book list
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _loadBooks());
  }

  /// Delete a book (removes .epub/.pdf file, cover, database records, and passwords)
  Future<Either<String, bool>> deleteBook(int bookId) async {
    try {
      debugPrint('LibraryNotifier.deleteBook called for bookId: $bookId');
      final repository = ref.read(shelfBookRepositoryProvider);

      // Get book BEFORE soft-deleting (so it's still accessible)
      final book = await repository.getBookById(bookId);
      if (book == null) {
        debugPrint('LibraryNotifier.deleteBook: Book not found');
        return left('Book not found');
      }

      debugPrint('LibraryNotifier.deleteBook: Found book "${book.title}", type=${book.bookType}, isPasswordProtected=${book.isPasswordProtected}');

      // Soft-delete first; only proceed with file cleanup when confirmed.
      final result = await repository.softDeleteBook(bookId);
      if (result.isLeft()) {
        debugPrint('LibraryNotifier.deleteBook: Soft delete failed');
        return left(result.getLeft().toNullable()!);
      }
      if (result.getRight().toNullable() == false) {
        debugPrint('LibraryNotifier.deleteBook: Soft delete returned false');
        return left('Delete failed');
      }

      debugPrint('LibraryNotifier.deleteBook: Soft delete succeeded');

      // Remove physical files + manifest record (use appropriate service for book type)
      final Either<String, bool> deleteResult;
      if (book.bookType == BookType.pdf) {
        debugPrint('LibraryNotifier.deleteBook: Calling PDF import service deleteBook');
        final pdfImportService = ref.read(pdfImportServiceProvider);
        deleteResult = await pdfImportService.deleteBook(book);
      } else {
        debugPrint('LibraryNotifier.deleteBook: Calling EPUB import service deleteBook');
        final epubImportService = ref.read(epubImportServiceProvider);
        deleteResult = await epubImportService.deleteBook(book);
      }

      if (deleteResult.isLeft()) {
        debugPrint('LibraryNotifier.deleteBook: Import service deleteBook failed: ${deleteResult.getLeft().toNullable()}');
        return left(deleteResult.getLeft().toNullable()!);
      }

      debugPrint('LibraryNotifier.deleteBook: Import service deleteBook succeeded');

      // Refresh list only after everything has succeeded.
      await refresh();

      debugPrint('LibraryNotifier.deleteBook: Completed successfully');
      return right(true);
    } catch (e) {
      debugPrint('LibraryNotifier.deleteBook: Exception caught: $e');
      return left('Delete failed: $e');
    }
  }

  /// Update book group
  Future<Either<String, bool>> updateGroup({
    required int bookId,
    String? groupName,
  }) async {
    try {
      final repository = ref.read(shelfBookRepositoryProvider);
      final result = await repository.updateBookGroup(
        bookId: bookId,
        groupName: groupName,
      );

      if (result.isRight()) {
        await refresh();
      }

      return result;
    } catch (e) {
      return left('Update category failed: $e');
    }
  }
}
