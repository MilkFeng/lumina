import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lumina/src/core/platform/platform.dart';
import 'package:lumina/src/core/widgets/progress_dialog.dart';
import 'package:lumina/src/features/library/data/services/epub_import_service_provider.dart';
import 'package:lumina/src/features/library/data/services/import_file_pipeline_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/shelf_book_repository_provider.dart';
import '../domain/shelf_book.dart';
import 'bookshelf_notifier.dart';

part 'library_notifier.g.dart';

enum ImportStatus { processing, success, failed }

/// Progress event emitted for each book while an import batch runs.
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

/// Drives the book import batch and exposes it to the library UI.
///
/// This notifier deliberately holds **no UI state**: the shelf renders from
/// `bookshelfProvider`, and the import dialog renders from the stream returned
/// by [importPipelineStream]. It exists to give that stream a `Ref` that
/// survives its many async gaps, which is also why it must stay alive — with
/// the default `autoDispose` the provider would be torn down as soon as no
/// widget is listening (for example while the import progress dialog is the
/// only thing on screen), and every later `ref.read` inside the generator would
/// throw "Cannot use the Ref ... after it has been disposed".
///
/// Restoring a backup lives in
/// `features/backup/application/backup_notifier.dart` instead, so that the
/// library feature never depends on the backup feature.
@Riverpod(keepAlive: true)
class LibraryNotifier extends _$LibraryNotifier {
  @override
  void build() {}

  /// Stream pipeline to process files one by one: Cache → Import → Clean.
  /// This prevents OOM and storage issues when importing massive folders.
  Stream<ProgressLog> importPipelineStream(List<PlatformPath> paths) async* {
    yield ProgressLog(
      'Starting import of ${paths.length} books',
      ProgressLogType.info,
    );
    final totalCount = paths.length;
    if (totalCount == 0) return;

    final pipeline = ref.read(importFilePipelineProvider);
    final epubImportService = ref.read(epubImportServiceProvider);

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

        // 2. Cache the file from URI to local temp directory
        importable = await pipeline.cacheFileWithHash(path);

        yield ProgressLog(
          'Processing file $currentFileName ($currentCount of $totalCount)',
          ProgressLogType.info,
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
            await pipeline.cleanCache(importable.cacheFile);
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
    await ref.read(bookshelfProvider.notifier).refresh();
  }

  /// Imports a book from a local [file].
  Future<Either<String, ShelfBook>> importBook(File file) async {
    try {
      final importService = ref.read(epubImportServiceProvider);
      final importResult = await importService.importBook(file);

      if (importResult.isLeft()) {
        return left(importResult.getLeft().toNullable()!);
      }

      final book = importResult.getRight().toNullable()!;
      await ref.read(bookshelfProvider.notifier).refresh();

      return right(book);
    } catch (e) {
      return left('Import failed: $e');
    }
  }

  /// Deletes a book: database records plus its `.epub` and cover files.
  Future<Either<String, bool>> deleteBook(int bookId) async {
    try {
      final repository = ref.read(shelfBookRepositoryProvider);
      final importService = ref.read(epubImportServiceProvider);

      final book = await repository.getBookById(bookId);
      if (book == null) {
        return left('Book not found');
      }

      // Remove the database record, manifest record and physical files.
      final deleteResult = await importService.deleteBook(book);
      if (deleteResult.isLeft()) {
        return left(deleteResult.getLeft().toNullable()!);
      }

      // Refresh only after everything has succeeded.
      await ref.read(bookshelfProvider.notifier).refresh();

      return right(true);
    } catch (e) {
      return left('Delete failed: $e');
    }
  }

  /// Moves a book into [groupName], or to the root level when it is null.
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
        await ref.read(bookshelfProvider.notifier).refresh();
      }

      return result;
    } catch (e) {
      return left('Update category failed: $e');
    }
  }
}
