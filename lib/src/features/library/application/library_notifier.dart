import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/features/library/application/progress_log.dart';
import 'package:lumina/src/features/library/data/services/unified_import_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../domain/shelf_book.dart';
import '../data/repositories/shelf_book_repository_provider.dart';
import '../data/services/epub_import_service_provider.dart';

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

  /// Import a new book from file
  Stream<ProgressLog> importMultipleBooks(List<ImportableEpub> files) async* {
    yield ProgressLog(
      'Starting import of ${files.length} books',
      ProgressLogType.info,
    );
    final totalCount = files.length;

    if (totalCount == 0) return;

    final importService = ref.read(epubImportServiceProvider);
    int currentCount = 0;

    for (final file in files) {
      currentCount++;
      yield ProgressLog(
        'Processing file ${file.originalName} ($currentCount of $totalCount)',
        ProgressLogType.info,
      );
      final fileName = file.originalName;

      // 1. Notify UI that we're starting to process this file
      yield ImportProgress(
        totalCount: totalCount,
        currentCount: currentCount,
        currentFileName: fileName,
        status: ImportStatus.processing,
      );

      // 2. Import the book and wait for result
      final result = await importService.importBook(file.cacheFile);

      // 3. Notify UI of success or failure for this file
      yield result.fold(
        (errorMessage) => ImportProgress(
          totalCount: totalCount,
          currentCount: currentCount,
          currentFileName: fileName,
          status: ImportStatus.failed,
          errorMessage: errorMessage,
        ),
        (book) => ImportProgress(
          totalCount: totalCount,
          currentCount: currentCount,
          currentFileName: fileName,
          status: ImportStatus.success,
          book: book,
        ),
      );
    }

    // 4. After all files are processed, refresh the book list
    yield ProgressLog(
      'Import completed. Refreshing library...',
      ProgressLogType.success,
    );
    await refresh();
  }

  /// Stream pipeline to process files one by one: Cache -> Import -> Clean.
  /// This prevents OOM and storage issues when importing massive folders.
  Stream<ImportProgress> importPipelineStream(List<PlatformPath> paths) async* {
    final totalCount = paths.length;
    if (totalCount == 0) return;

    final unifiedImportService = ref.read(unifiedImportServiceProvider);
    final epubImportService = ref.read(epubImportServiceProvider);

    int currentCount = 0;

    for (final path in paths) {
      currentCount++;
      ImportableEpub? importable;
      String currentFileName = '';

      try {
        // 1. Cache the file from URI to local temp directory
        importable = await unifiedImportService.processEpub(path);

        // Assuming your ImportableEpub model has originalName property
        // If not, you might need to extract the name from the PlatformPath beforehand
        currentFileName = importable.originalName;

        // 2. Notify UI that caching is done and actual import is starting
        yield ImportProgress(
          totalCount: totalCount,
          currentCount: currentCount,
          currentFileName: currentFileName,
          status: ImportStatus.processing,
        );

        // 3. Import the book and wait for the Either result
        final result = await epubImportService.importBook(importable.cacheFile);

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
        if (importable != null) {
          try {
            await unifiedImportService.cleanCache(importable.cacheFile);
          } catch (cleanError) {
            debugPrint('Failed to clean cache file: $cleanError');
          }
        }
      }
    }

    // 6. After all files are processed, refresh the book list to update UI
    await refresh();
  }

  /// Refresh book list
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _loadBooks());
  }

  /// Delete a book (removes .epub file, cover, and database records)
  Future<Either<String, bool>> deleteBook(int bookId) async {
    try {
      final repository = ref.read(shelfBookRepositoryProvider);
      final importService = ref.read(epubImportServiceProvider);

      // Get book
      final result = await repository.softDeleteBook(bookId);
      if (result.isRight()) {
        await refresh();

        if (result.getRight().toNullable() == false) {
          return left('Delete failed');
        }
      } else {
        return left(result.getLeft().toNullable()!);
      }

      final book = await repository.getBookById(bookId);
      if (book == null) {
        return left('Book not found');
      }

      // Delete using import service (handles files + database)
      final deleteResult = await importService.deleteBook(book);
      if (deleteResult.isLeft()) {
        return left(deleteResult.getLeft().toNullable()!);
      }

      // Refresh list
      await refresh();

      return right(true);
    } catch (e) {
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
