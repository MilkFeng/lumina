import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/features/library/application/progress_log.dart';
import 'package:path/path.dart' as p;

import '../../domain/book_manifest.dart';
import '../../domain/shelf_book.dart';
import '../../domain/shelf_group.dart';
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

/// Snapshot of the restore progress emitted by [ImportBackupService.importLibraryFromFolder].
class BackupImportProgress extends ProgressLog {
  BackupImportProgress({
    required this.current,
    required this.total,
    required this.currentFileName,
    required this.isCompleted,
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

  /// True when the entire operation is finished (success or failure).
  final bool isCompleted;

  /// Populated only on the final event. Either [ImportSuccess] or [ImportFailure].
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
/// Memory profile:
///   Physical files (.epub, covers) are restored with [File.copy] — a
///   kernel-level operation that never loads file bytes into the Dart heap.
///   Only the JSON payloads (shelf.json + individual manifest files) are
///   materialised in memory, and those are small by design.
class ImportBackupService {
  static const _kBooksDir = 'books';
  static const _kCoversDir = 'covers';

  final Isar _isar;
  final UnifiedImportService _importService;

  ImportBackupService({
    required Isar isar,
    required UnifiedImportService importService,
  }) : _isar = isar,
       _importService = importService;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Restores a library from [backupPaths], emitting [BackupImportProgress]
  /// events in real time so the UI can display a progress indicator.
  ///
  /// The final event always has [BackupImportProgress.isCompleted] == `true`
  /// and its [BackupImportProgress.result] is either [ImportSuccess] or
  /// [ImportFailure].
  Stream<ProgressLog> importLibraryFromFolder(BackupPaths backupPaths) async* {
    // Helper to emit a completed failure event.
    BackupImportProgress failure(String message) => BackupImportProgress(
      current: 0,
      total: 0,
      currentFileName: '',
      isCompleted: true,
      result: ImportFailure(message),
    );

    try {
      // -----------------------------------------------------------------------
      // 1. Read and parse global shelf.json via UnifiedImportService
      // -----------------------------------------------------------------------
      yield ProgressLog('Reading backup metadata...', ProgressLogType.info);
      final shelfString = await _importService.processPlainFile(
        backupPaths.shelfFile,
      );
      final shelfJson = jsonDecode(shelfString) as Map<String, dynamic>;

      final groupsJson = (shelfJson['groups'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final booksJson = (shelfJson['books'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // Emit the initial state so the UI can show indeterminate progress
      // while groups & directories are being set up.
      yield ProgressLog(
        'Preparing to restore ${booksJson.length} books...',
        ProgressLogType.info,
      );

      // -----------------------------------------------------------------------
      // 2. Restore groups (upsert by name to avoid duplicates).
      // -----------------------------------------------------------------------
      yield ProgressLog('Restoring shelf groups...', ProgressLogType.info);

      if (groupsJson.isNotEmpty) {
        final groups = groupsJson.map(_mapToShelfGroup).toList();
        await _isar.writeTxn(() async {
          for (final group in groups) {
            await _isar.shelfGroups.putByName(group);
          }
        });
      }

      yield ProgressLog('Groups restored.', ProgressLogType.info);

      // -----------------------------------------------------------------------
      // 3. Ensure internal storage directories exist.
      // -----------------------------------------------------------------------
      final internalBooksDir = await Directory(
        p.join(AppStorage.documentsPath, _kBooksDir),
      ).create(recursive: true);

      final internalCoversDir = await Directory(
        p.join(AppStorage.documentsPath, _kCoversDir),
      ).create(recursive: true);

      // -----------------------------------------------------------------------
      // 4. Restore books one-by-one, yielding progress; upsert each immediately.
      // -----------------------------------------------------------------------
      yield ProgressLog('Restoring books...', ProgressLogType.info);
      int importedCount = 0;

      for (final bookMap in booksJson) {
        final hash = bookMap['fileHash'] as String;
        final title = (bookMap['title'] as String?)?.trim();
        final displayName = (title != null && title.isNotEmpty) ? title : hash;

        // Yield “processing this book” before doing any heavy I/O.
        yield BackupImportProgress(
          current: importedCount,
          total: booksJson.length,
          currentFileName: displayName,
          isCompleted: false,
        );

        final pathsForBook = backupPaths.bookPaths[hash];
        if (pathsForBook == null) {
          debugPrint(
            '[ImportBackup] Files for book $hash not found in backup paths, skipping.',
          );
          yield ProgressLog(
            'Warning: Files for "$displayName" not found, skipping.',
            ProgressLogType.warning,
          );
          continue;
        }

        // -- A. Process & Copy EPUB --
        final importableEpub = await _importService.processEpub(
          pathsForBook.epubPath,
        );
        final destEpub = File(p.join(internalBooksDir.path, '$hash.epub'));
        await importableEpub.cacheFile.copy(destEpub.path);
        await _importService.cleanCache(importableEpub.cacheFile);

        // -- B. Process & Copy Cover --
        String? restoredCoverPath;
        if (pathsForBook.coverPath != null) {
          try {
            final coverBytes = await _importService.processBinaryFile(
              pathsForBook.coverPath!,
            );
            final coverFileName = pathsForBook.coverPath!.name;
            final destCover = File(
              p.join(internalCoversDir.path, coverFileName),
            );
            await destCover.writeAsBytes(coverBytes);
            restoredCoverPath = '$_kCoversDir/$coverFileName';
          } catch (e) {
            debugPrint('[ImportBackup] Failed to process cover for $hash: $e');
            yield ProgressLog(
              'Warning: Failed to restore cover for "$displayName", skipping cover.',
              ProgressLogType.warning,
            );
          }
        }

        // -- C. Process Manifest JSON --
        BookManifest? manifest;
        try {
          final manifestString = await _importService.processPlainFile(
            pathsForBook.manifestPath,
          );
          final manifestMap =
              jsonDecode(manifestString) as Map<String, dynamic>;
          manifest = _mapToBookManifest(manifestMap);
        } catch (e) {
          debugPrint('[ImportBackup] Failed to process manifest for $hash: $e');
          yield ProgressLog(
            'Warning: Failed to restore metadata for "$displayName", skipping manifest.',
            ProgressLogType.warning,
          );
        }

        // -- D. Build ShelfBook and upsert immediately --
        final book = _mapToShelfBook(
          bookMap,
          filePath: '$_kBooksDir/$hash.epub',
          coverPath: restoredCoverPath,
        );
        await _isar.writeTxn(() async {
          await _isar.shelfBooks.putByFileHash(book);
          if (manifest != null) {
            await _isar.bookManifests.putByFileHash(manifest);
          }
        });
        importedCount++;
        debugPrint(
          '[ImportBackup] Upserted "$displayName" ($importedCount/${booksJson.length}).',
        );

        yield BackupImportProgress(
          current: importedCount,
          total: booksJson.length,
          currentFileName: displayName,
          isCompleted: true,
          result: ImportSuccess(importedBooks: importedCount),
        );
      }

      debugPrint('[ImportBackup] Import complete. Total books: $importedCount');
      yield ProgressLog(
        'Import completed: $importedCount books imported.',
        ProgressLogType.success,
      );
    } on FormatException catch (e) {
      debugPrint('[ImportBackup] JSON parse error: $e');
      yield failure('Failed to parse backup data: ${e.message}');
    } catch (e, st) {
      debugPrint('[ImportBackup] Unexpected error: $e\n$st');
      yield failure('Import failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Reverse-mapping helpers (JSON → domain objects)
  // ---------------------------------------------------------------------------

  /// Deserialises a [ShelfGroup] from its JSON map.
  /// The `id` field is intentionally omitted — Isar assigns it via the `name`
  /// upsert index, preserving the existing row if the group already exists.
  ShelfGroup _mapToShelfGroup(Map<String, dynamic> m) {
    return ShelfGroup()
      ..name = m['name'] as String
      ..creationDate = m['creationDate'] as int
      ..updatedAt = m['updatedAt'] as int
      ..isDeleted = (m['isDeleted'] as bool? ?? false);
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
      ..author = m['author'] as String
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
      ..isFinished = m['isFinished'] as bool? ?? false
      ..groupName = m['groupName'] as String?
      ..isDeleted = m['isDeleted'] as bool? ?? false
      ..updatedAt = m['updatedAt'] as int
      ..lastSyncedDate = m['lastSyncedDate'] as int?;
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
