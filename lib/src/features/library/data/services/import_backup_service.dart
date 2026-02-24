import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/features/library/application/progress_log.dart';
import 'package:lumina/src/features/library/data/book_manifest_repository.dart';
import 'package:lumina/src/features/library/data/shelf_book_repository.dart';
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

  final ShelfBookRepository _shelfBookRepository;
  final BookManifestRepository _bookManifestRepository;
  final UnifiedImportService _importService;

  ImportBackupService({
    required ShelfBookRepository shelfBookRepository,
    required BookManifestRepository bookManifestRepository,
    required UnifiedImportService importService,
  }) : _shelfBookRepository = shelfBookRepository,
       _bookManifestRepository = bookManifestRepository,
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
        await _mergeGroup(groups);
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
        final destEpub = File(p.join(internalBooksDir.path, '$hash.epub'));
        if (!destEpub.existsSync()) {
          final importableEpub = await _importService.processEpub(
            pathsForBook.epubPath,
          );
          await importableEpub.cacheFile.copy(destEpub.path);
          await _importService.cleanCache(importableEpub.cacheFile);
        }

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
        final manifestString = await _importService.processPlainFile(
          pathsForBook.manifestPath,
        );
        final manifestMap = jsonDecode(manifestString) as Map<String, dynamic>;
        final manifest = _mapToBookManifest(manifestMap);
        await _mergeManifest(manifest);

        // -- D. Build ShelfBook and upsert immediately --
        final book = _mapToShelfBook(
          bookMap,
          filePath: '$_kBooksDir/$hash.epub',
          coverPath: restoredCoverPath,
        );
        await _mergeBook(book);

        importedCount++;
        debugPrint(
          '[ImportBackup] Upserted "$displayName" ($importedCount/${booksJson.length}).',
        );

        yield BackupImportProgress(
          current: importedCount,
          total: booksJson.length,
          currentFileName: displayName,
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
    } finally {
      // Release all security-scoped resource accesses held by the native iOS
      // picker plugin.  This is a no-op on Android; calling it unconditionally
      // keeps the code simple and guarantees no resource leaks on iOS even if
      // the import fails or is cancelled.
      await _importService.releaseIosAccess();
    }
  }

  Future<void> _mergeGroup(List<ShelfGroup> backupGroups) async {
    for (final backupGroup in backupGroups) {
      final existingGroup = await _shelfBookRepository.getGroupByName(
        backupGroup.name,
      );

      if (existingGroup == null) {
        await _shelfBookRepository.createGroup(name: backupGroup.name);
      } else {
        if (backupGroup.updatedAt > existingGroup.updatedAt) {
          backupGroup.id = existingGroup.id;
          await _shelfBookRepository.saveGroup(backupGroup);
        }
      }
    }
  }

  Future<void> _mergeManifest(BookManifest backupManifest) async {
    final existingManifest = await _bookManifestRepository.getManifestByHash(
      backupManifest.fileHash,
    );

    if (existingManifest == null) {
      await _bookManifestRepository.saveManifest(backupManifest);
    } else {
      if (backupManifest.lastUpdated.isAfter(existingManifest.lastUpdated)) {
        await _bookManifestRepository.saveManifest(backupManifest);
      }
    }
  }

  Future<void> _mergeBook(ShelfBook backupBook) async {
    final existingBook = await _shelfBookRepository.getBookByHash(
      backupBook.fileHash,
    );
    if (existingBook == null) {
      await _shelfBookRepository.saveBook(backupBook);
    } else {
      // merge `currentChapterIndex` and `readingProgress` by `lastOpenedDate`
      if (backupBook.lastOpenedDate != null &&
          existingBook.lastOpenedDate != null) {
        if (backupBook.lastOpenedDate! > existingBook.lastOpenedDate!) {
          existingBook.currentChapterIndex = backupBook.currentChapterIndex;
          existingBook.readingProgress = backupBook.readingProgress;
        }
      }

      // For other fields, use `updatedAt` as the source of truth. This means
      // that if the backup's metadata is newer, it will overwrite the existing
      // book's metadata (title, authors, description, etc.) but keep the
      // existing reading progress.
      if (backupBook.updatedAt > existingBook.updatedAt) {
        backupBook.id = existingBook.id;
        if (backupBook.coverPath == null && existingBook.coverPath != null) {
          backupBook.coverPath = existingBook.coverPath;
        }
        await _shelfBookRepository.saveBook(backupBook);
      } else {
        if (!backupBook.isDeleted && existingBook.isDeleted) {
          backupBook.id = existingBook.id;
          backupBook.isDeleted = false;
          await _shelfBookRepository.saveBook(backupBook);
        }
      }
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
      ..lastSyncedDate = m['lastSyncedDate'] as int?
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
