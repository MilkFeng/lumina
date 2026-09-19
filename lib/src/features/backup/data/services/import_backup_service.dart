import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/platform/platform.dart';
import 'package:lumina/src/core/widgets/progress_dialog.dart';
import 'package:lumina/src/core/storage/app_storage_constants.dart';
import 'package:lumina/src/features/library/data/book_manifest_repository.dart';
import 'package:lumina/src/features/library/data/shelf_book_repository.dart';
import 'package:lumina/src/features/backup/data/services/backup_folder_resolver.dart';
import 'package:lumina/src/features/library/data/services/import_file_pipeline.dart';
import 'package:path/path.dart' as p;

import 'package:lumina/src/features/library/domain/book_manifest.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/features/library/domain/shelf_group.dart';
import 'package:lumina/src/core/storage/app_storage.dart';

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

/// Result of a library import operation.
sealed class ImportResult {
  const ImportResult();
}

/// Import completed successfully. [importedBooks] is the count of books processed.
final class ImportSuccess extends ImportResult {
  final int importedBooks;
  const ImportSuccess({required this.importedBooks});
}

/// Import failed with [message].
final class ImportFailure extends ImportResult {
  final String message;
  const ImportFailure(this.message);
}

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

String _importResultToMessage(ImportResult? result, String currentFileName) {
  if (result == null) {
    return 'Import "$currentFileName" in progress...';
  } else if (result is ImportSuccess) {
    return 'Import "$currentFileName" completed successfully.';
  } else if (result is ImportFailure) {
    return 'Import "$currentFileName" failed: ${result.message}.';
  } else {
    return 'Unknown import result.';
  }
}

ProgressLogType _importResultToLogType(ImportResult? result) {
  if (result == null) {
    return ProgressLogType.info;
  } else if (result is ImportSuccess) {
    return ProgressLogType.success;
  } else if (result is ImportFailure) {
    return ProgressLogType.error;
  } else {
    return ProgressLogType.info;
  }
}

/// Snapshot of the restore progress emitted by [ImportBackupService.restoreLibrary].
class BackupImportProgress extends ProgressLog {
  BackupImportProgress({
    required this.current,
    required this.total,
    required this.currentFileName,
    this.result,
  }) : super(
         _importResultToMessage(result, currentFileName),
         _importResultToLogType(result),
       );

  /// Number of books fully processed so far.
  final int current;

  /// Total number of books to restore.
  final int total;

  /// Title (or hash) of the book currently being processed.
  final String currentFileName;

  /// Populated once a book finishes restoring ([ImportSuccess]), or on the
  /// final event of an aborted restore ([ImportFailure]). A `null` value means
  /// the book is still being processed.
  final ImportResult? result;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Zero-memory overhead library restore service.
///
/// Mirrors the folder structure produced by [ExportBackupService]:
/// ```
/// lumina-backup-{timestamp}/
///   ├── books/         ← .epub files (one per book)
///   ├── covers/        ← cover images
///   ├── manifests/     ← {hash}.json (serialised BookManifest)
///   └── shelf.json     ← ShelfBook list + ShelfGroup list
/// ```
///
/// A restore is a **full replacement**, never a merge: the library that is
/// currently on the device is cleared (database rows plus `books/` and
/// `covers/`) and then rebuilt from the backup. This is what makes the result
/// identical to the state that was exported, and it removes every chance of a
/// backup row colliding with a local one.
///
/// Memory profile:
///   Physical files (.epub, covers) are restored with [File.copy] — a
///   kernel-level operation that never loads file bytes into the Dart heap.
///   Only the JSON payloads (shelf.json + individual manifest files) are
///   materialised in memory, and those are small by design.
class ImportBackupService {
  final ShelfBookRepository _shelfBookRepository;
  final BookManifestRepository _bookManifestRepository;
  final FilePickerService _picker;
  final ImportFilePipeline _pipeline;

  ImportBackupService({
    required ShelfBookRepository shelfBookRepository,
    required BookManifestRepository bookManifestRepository,
    required FilePickerService picker,
    required ImportFilePipeline pipeline,
  }) : _shelfBookRepository = shelfBookRepository,
       _bookManifestRepository = bookManifestRepository,
       _picker = picker,
       _pipeline = pipeline;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Replaces the entire library with the contents of [backupPaths], emitting
  /// [BackupImportProgress] events in real time so the UI can display progress.
  ///
  /// **Destructive:** the current library is erased before the backup is
  /// applied, so callers must obtain explicit user confirmation first.
  ///
  /// Order of operations:
  ///   1. `shelf.json` is read and parsed **first** — an unreadable or foreign
  ///      folder can therefore never wipe the user's library.
  ///   2. Every `ShelfBook`, `ShelfGroup` and `BookManifest` row is deleted,
  ///      together with the `books/` and `covers/` directories.
  ///   3. Every book of the backup is copied into internal storage and inserted
  ///      as a brand-new row.
  ///
  /// The final event carries either [ImportSuccess] or [ImportFailure].
  Stream<ProgressLog> restoreLibrary(BackupPaths backupPaths) async* {
    // Helper to emit a completed failure event.
    BackupImportProgress failure(String message) => BackupImportProgress(
      current: 0,
      total: 0,
      currentFileName: '',
      result: ImportFailure(message),
    );

    try {
      // -----------------------------------------------------------------------
      // 1. Read and parse the backup metadata *before* touching anything.
      // -----------------------------------------------------------------------
      yield ProgressLog('Reading backup metadata...', ProgressLogType.info);
      final shelfString = await _pipeline.readText(backupPaths.shelfFile);
      final shelfJson = jsonDecode(shelfString) as Map<String, dynamic>;

      final groupsJson = (shelfJson['groups'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final booksJson = (shelfJson['books'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // Books whose files are missing from the folder cannot be restored;
      // filtering them here keeps the progress totals honest.
      final restorableBooks = booksJson
          .where(
            (m) => backupPaths.bookPaths.containsKey(m['fileHash'] as String),
          )
          .toList();

      // Refuse to clear the library for a backup that holds no usable book.
      if (booksJson.isNotEmpty && restorableBooks.isEmpty) {
        yield failure(
          'None of the ${booksJson.length} books in this backup has files in the folder',
        );
        return;
      }

      // -----------------------------------------------------------------------
      // 2. Wipe the current library: database rows and physical files.
      // -----------------------------------------------------------------------
      yield ProgressLog(
        'Clearing the current library before restoring '
        '${restorableBooks.length} books...',
        ProgressLogType.warning,
      );
      await _clearCurrentLibrary();

      // -----------------------------------------------------------------------
      // 3. Restore groups as-is; Isar assigns fresh ids.
      // -----------------------------------------------------------------------
      if (groupsJson.isNotEmpty) {
        yield ProgressLog('Restoring shelf groups...', ProgressLogType.info);
        for (final groupMap in groupsJson) {
          await _shelfBookRepository.saveGroup(_mapToShelfGroup(groupMap));
        }
        yield ProgressLog('Groups restored.', ProgressLogType.info);
      }

      // -----------------------------------------------------------------------
      // 4. Ensure internal storage directories exist.
      // -----------------------------------------------------------------------
      final internalBooksDir = await Directory(
        p.join(AppStorage.documentsPath, AppStorageConstants.booksDir),
      ).create(recursive: true);

      final internalCoversDir = await Directory(
        p.join(AppStorage.documentsPath, AppStorageConstants.coversDir),
      ).create(recursive: true);

      // -----------------------------------------------------------------------
      // 5. Restore books one-by-one, yielding progress; insert each immediately.
      //    A single corrupt book only produces a warning: the previous library
      //    is already gone, so aborting would leave the user with even less.
      // -----------------------------------------------------------------------
      yield ProgressLog('Restoring books...', ProgressLogType.info);
      int restoredCount = 0;
      int failedCount = 0;

      for (final bookMap in restorableBooks) {
        final hash = bookMap['fileHash'] as String;
        final title = (bookMap['title'] as String?)?.trim();
        final displayName = (title != null && title.isNotEmpty) ? title : hash;
        final pathsForBook = backupPaths.bookPaths[hash]!;

        // Yield “processing this book” before doing any heavy I/O.
        yield BackupImportProgress(
          current: restoredCount,
          total: restorableBooks.length,
          currentFileName: displayName,
        );

        try {
          // -- A. Copy the EPUB ----------------------------------------------
          final destEpub = File(p.join(internalBooksDir.path, '$hash.epub'));
          if (!destEpub.existsSync()) {
            final cachedEpub = await _pipeline.cacheFile(pathsForBook.epubPath);
            await cachedEpub.copy(destEpub.path);
            await _pipeline.cleanCache(cachedEpub);
          }

          // -- B. Copy the cover ---------------------------------------------
          String? restoredCoverPath;
          if (pathsForBook.coverPath != null) {
            try {
              final coverBytes = await _pipeline.readBytes(
                pathsForBook.coverPath!,
              );
              final coverFileName = pathsForBook.coverPath!.name;
              final destCover = File(
                p.join(internalCoversDir.path, coverFileName),
              );
              await destCover.writeAsBytes(coverBytes);
              restoredCoverPath =
                  '${AppStorageConstants.coversDir}/$coverFileName';
            } catch (e) {
              debugPrint('[RestoreLibrary] Cover failed for $hash: $e');
              yield ProgressLog(
                'Warning: Failed to restore cover for "$displayName", skipping cover.',
                ProgressLogType.warning,
              );
            }
          }

          // -- C. Insert the manifest ----------------------------------------
          final manifestString = await _pipeline.readText(
            pathsForBook.manifestPath,
          );
          final manifestMap = jsonDecode(manifestString) as Map<String, dynamic>;
          await _bookManifestRepository.saveManifest(
            _mapToBookManifest(manifestMap),
          );

          // -- D. Insert the shelf book --------------------------------------
          await _shelfBookRepository.saveBook(
            _mapToShelfBook(
              bookMap,
              filePath: '${AppStorageConstants.booksDir}/$hash.epub',
              coverPath: restoredCoverPath,
            ),
          );

          restoredCount++;
          debugPrint(
            '[RestoreLibrary] Restored "$displayName" '
            '($restoredCount/${restorableBooks.length}).',
          );

          yield BackupImportProgress(
            current: restoredCount,
            total: restorableBooks.length,
            currentFileName: displayName,
            result: ImportSuccess(importedBooks: restoredCount),
          );
        } catch (e, st) {
          failedCount++;
          debugPrint(
            '[RestoreLibrary] Failed to restore "$displayName": $e\n$st',
          );
          yield ProgressLog(
            'Warning: Failed to restore "$displayName": $e',
            ProgressLogType.warning,
          );
        }
      }

      // Every book failed: the library is empty now, so say so loudly instead
      // of reporting a successful restore of nothing.
      if (restoredCount == 0 && failedCount > 0) {
        yield failure('No book could be restored from this backup');
        return;
      }

      debugPrint(
        '[RestoreLibrary] Restore complete. '
        'Restored: $restoredCount, failed: $failedCount.',
      );
      yield ProgressLog(
        restorableBooks.isEmpty
            ? 'Restore completed: the backup contains an empty library.'
            : (failedCount == 0
                  ? 'Restore completed: $restoredCount books restored.'
                  : 'Restore completed: $restoredCount books restored, '
                        '$failedCount failed.'),
        failedCount == 0 ? ProgressLogType.success : ProgressLogType.warning,
      );
    } on FormatException catch (e) {
      debugPrint('[RestoreLibrary] JSON parse error: $e');
      yield failure('Failed to parse backup data: ${e.message}');
    } catch (e, st) {
      debugPrint('[RestoreLibrary] Unexpected error: $e\n$st');
      yield failure('Restore failed: $e');
    } finally {
      // Release all security-scoped resource accesses held by the native iOS
      // picker plugin.  This is a no-op on Android; calling it unconditionally
      // keeps the code simple and guarantees no resource leaks on iOS even if
      // the restore fails or is cancelled.
      await _picker.releaseIosAccess();
    }
  }

  /// Deletes every trace of the current library.
  ///
  /// Database rows are cleared first. Failures while removing physical files
  /// stay non-fatal: the restore rewrites every file it references, and the
  /// storage cleanup service sweeps the leftovers later.
  Future<void> _clearCurrentLibrary() async {
    await _shelfBookRepository.clearAll();
    await _bookManifestRepository.clearAll();

    for (final dirName in const [
      AppStorageConstants.booksDir,
      AppStorageConstants.coversDir,
    ]) {
      final dir = Directory(p.join(AppStorage.documentsPath, dirName));
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        await dir.create(recursive: true);
      } catch (e) {
        debugPrint('[RestoreLibrary] Failed to reset $dirName: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Reverse-mapping helpers (JSON → domain objects)
  // ---------------------------------------------------------------------------

  /// Deserialises a [ShelfGroup] from its JSON map.
  /// The `id` field is intentionally omitted — Isar assigns a fresh one when
  /// the group is inserted into the just-cleared database.
  ShelfGroup _mapToShelfGroup(Map<String, dynamic> m) {
    return ShelfGroup()
      ..name = m['name'] as String
      ..creationDate = m['creationDate'] as int
      ..updatedAt = m['updatedAt'] as int;
  }

  /// Deserialises a [ShelfBook] from its JSON map.
  ///
  /// [filePath] and [coverPath] are injected from the just-copied files rather
  /// than taken from JSON, because the JSON deliberately excludes them (they
  /// are device-specific absolute paths).
  ShelfBook _mapToShelfBook(
    Map<String, dynamic> m, {
    required String? filePath,
    required String? coverPath,
  }) {
    return ShelfBook()
      ..fileHash = m['fileHash'] as String
      ..filePath = filePath
      ..coverPath = coverPath
      ..title = m['title'] as String
      ..authors = (m['authors'] as List<dynamic>).cast<String>()
      ..description = m['description'] as String?
      ..subjects = (m['subjects'] as List<dynamic>).cast<String>()
      ..totalChapters = m['totalChapters'] as int
      ..epubVersion = m['epubVersion'] as String
      ..importDate = m['importDate'] as int
      ..currentChapterIndex = m['currentChapterIndex'] as int? ?? 0
      ..readingProgress = (m['readingProgress'] as num? ?? 0.0).toDouble()
      ..chapterScrollPosition = (m['chapterScrollPosition'] as num?)?.toDouble()
      ..lastOpenedDate = m['lastOpenedDate'] as int?
      ..groupName = m['groupName'] as String?
      ..updatedAt = m['updatedAt'] as int
      ..direction = m['direction'] as int? ?? 0;
  }

  /// Deserialises a full [BookManifest] (including all embedded objects).
  BookManifest _mapToBookManifest(Map<String, dynamic> m) {
    return BookManifest()
      ..fileHash = m['fileHash'] as String
      ..opfRootPath = m['opfRootPath'] as String
      ..epubVersion = m['epubVersion'] as String
      ..lastUpdated = DateTime.parse(m['lastUpdated'] as String)
      ..spine = (m['spine'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapToSpineItem)
          .toList()
      ..toc = (m['toc'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapToTocItem)
          .toList()
      ..manifest = (m['manifest'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapToManifestItem)
          .toList();
  }

  SpineItem _mapToSpineItem(Map<String, dynamic> m) {
    return SpineItem(
      index: m['index'] as int,
      // In SpineItem, `href` is a plain String (file path relative to OPF root).
      href: m['href'] as String,
      idref: m['idref'] as String,
      linear: m['linear'] as bool? ?? true,
      properties: m['properties'] as String?,
    );
  }

  Href _mapToHref(Map<String, dynamic> m) {
    return Href()
      ..path = m['path'] as String
      ..anchor = m['anchor'] as String? ?? 'top';
  }

  ManifestItem _mapToManifestItem(Map<String, dynamic> m) {
    return ManifestItem()
      ..id = m['id'] as String
      ..href = _mapToHref(m['href'] as Map<String, dynamic>)
      ..mediaType = m['mediaType'] as String
      ..properties = m['properties'] as String?;
  }

  TocItem _mapToTocItem(Map<String, dynamic> m) {
    return TocItem()
      ..id = m['id'] as int
      ..label = m['label'] as String
      ..href = _mapToHref(m['href'] as Map<String, dynamic>)
      ..depth = m['depth'] as int
      ..spineIndex = m['spineIndex'] as int? ?? -1
      ..parentId = m['parentId'] as int
      ..children = (m['children'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapToTocItem)
          .toList();
  }
}
