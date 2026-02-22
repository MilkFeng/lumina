import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
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

  /// How many books are upserted per Isar write transaction.
  /// Keeps individual transactions short; rarely matters in practice since
  /// home libraries are typically < 500 books, but it's good hygiene.
  static const _kBatchSize = 50;

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

  /// Restores a library from the folder at [backupDirPath].
  ///
  /// Returns [ImportSuccess] with the number of books imported, or
  /// [ImportFailure] describing what went wrong.
  /// Restores a library from the folder at [backupDirPath].
  ///
  /// Returns [ImportSuccess] with the number of books imported, or
  /// [ImportFailure] describing what went wrong.
  Future<ImportResult> importLibraryFromFolder(BackupPaths backupPaths) async {
    try {
      // -----------------------------------------------------------------------
      // 1. Read and parse global shelf.json via UnifiedImportService
      // -----------------------------------------------------------------------
      final shelfString = await _importService.processPlainFile(
        backupPaths.shelfFile,
      );
      final shelfJson = jsonDecode(shelfString) as Map<String, dynamic>;

      final groupsJson = (shelfJson['groups'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final booksJson = (shelfJson['books'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // -----------------------------------------------------------------------
      // 2. Restore groups (upsert by name to avoid duplicates).
      // -----------------------------------------------------------------------
      if (groupsJson.isNotEmpty) {
        final groups = groupsJson.map(_mapToShelfGroup).toList();
        await _isar.writeTxn(() async {
          for (final group in groups) {
            // putByName performs an insert-or-update keyed on the unique `name`
            await _isar.shelfGroups.putByName(group);
          }
        });
      }

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
      // 4. Restore books in batches.
      // -----------------------------------------------------------------------
      int importedCount = 0;

      for (
        var batchStart = 0;
        batchStart < booksJson.length;
        batchStart += _kBatchSize
      ) {
        final batchEnd = (batchStart + _kBatchSize).clamp(0, booksJson.length);
        final batch = booksJson.sublist(batchStart, batchEnd);

        final shelfBooks = <ShelfBook>[];
        final manifests = <BookManifest>[];

        for (final bookMap in batch) {
          final hash = bookMap['fileHash'] as String;
          final pathsForBook = backupPaths.bookPaths[hash];

          if (pathsForBook == null) {
            debugPrint(
              '[ImportBackup] Files for book $hash not found in backup paths, skipping.',
            );
            continue;
          }

          // -- A. Process & Copy EPUB (Zero Memory OOM Risk) --
          // processEpub will stream the file safely to ImportCacheManager.
          final importableEpub = await _importService.processEpub(
            pathsForBook.epubPath,
          );
          final destEpub = File(p.join(internalBooksDir.path, '$hash.epub'));
          await importableEpub.cacheFile.copy(
            destEpub.path,
          ); // Copy from cache to final destination

          // Optional but recommended: clean up the temporary cache file right away
          await _importService.cleanCache(importableEpub.cacheFile);

          // -- B. Process & Copy Cover (Low Memory) --
          String? restoredCoverPath;
          if (pathsForBook.coverPath != null) {
            try {
              // processBinaryFile loads the small image into Uint8List bytes
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
              debugPrint(
                '[ImportBackup] Failed to process cover for $hash: $e',
              );
            }
          }

          // -- C. Process Manifest JSON (Low Memory) --
          try {
            final manifestString = await _importService.processPlainFile(
              pathsForBook.manifestPath,
            );
            final manifestMap =
                jsonDecode(manifestString) as Map<String, dynamic>;
            manifests.add(_mapToBookManifest(manifestMap));
          } catch (e) {
            debugPrint(
              '[ImportBackup] Failed to process manifest for $hash: $e',
            );
          }

          // -- D. Build ShelfBook and inject restored absolute paths --
          final filePath = '$_kBooksDir/$hash.epub';
          final book = _mapToShelfBook(
            bookMap,
            filePath: filePath,
            coverPath: restoredCoverPath,
          );
          shelfBooks.add(book);
        }

        // -- E. Upsert the entire batch in a single transaction --
        await _isar.writeTxn(() async {
          for (final book in shelfBooks) {
            await _isar.shelfBooks.putByFileHash(book);
          }
          for (final manifest in manifests) {
            await _isar.bookManifests.putByFileHash(manifest);
          }
        });

        importedCount += shelfBooks.length;
        debugPrint(
          '[ImportBackup] Batch ${batchStart ~/ _kBatchSize + 1}: upserted ${shelfBooks.length} books.',
        );
      }

      debugPrint('[ImportBackup] Import complete. Total books: $importedCount');
      return ImportSuccess(importedBooks: importedCount);
    } on FormatException catch (e) {
      debugPrint('[ImportBackup] JSON parse error: $e');
      return ImportFailure('Failed to parse backup data: ${e.message}');
    } catch (e, st) {
      debugPrint('[ImportBackup] Unexpected error: $e\n$st');
      return ImportFailure('Import failed: $e');
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
