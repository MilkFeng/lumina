import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
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
  static const _kManifestsDir = 'manifests';
  static const _kShelfFile = 'shelf.json';

  /// How many books are upserted per Isar write transaction.
  /// Keeps individual transactions short; rarely matters in practice since
  /// home libraries are typically < 500 books, but it's good hygiene.
  static const _kBatchSize = 50;

  final Isar _isar;

  ImportBackupService({required Isar isar}) : _isar = isar;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Restores a library from the folder at [backupDirPath].
  ///
  /// Returns [ImportSuccess] with the number of books imported, or
  /// [ImportFailure] describing what went wrong.
  Future<ImportResult> importLibraryFromFolder(String backupDirPath) async {
    try {
      // -----------------------------------------------------------------------
      // 1. Validate the backup directory.
      // -----------------------------------------------------------------------
      final backupDir = Directory(backupDirPath);
      if (!backupDir.existsSync()) {
        return const ImportFailure('Backup directory does not exist.');
      }

      final shelfFile = File(p.join(backupDirPath, _kShelfFile));
      if (!shelfFile.existsSync()) {
        return const ImportFailure(
          'Invalid backup folder: shelf.json is missing.',
        );
      }

      // -----------------------------------------------------------------------
      // 2. Parse shelf.json.
      // -----------------------------------------------------------------------
      final shelfJson =
          jsonDecode(await shelfFile.readAsString()) as Map<String, dynamic>;
      final groupsJson = (shelfJson['groups'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final booksJson = (shelfJson['books'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // -----------------------------------------------------------------------
      // 3. Restore groups (upsert by name to avoid duplicates).
      // -----------------------------------------------------------------------
      if (groupsJson.isNotEmpty) {
        final groups = groupsJson.map(_mapToShelfGroup).toList();
        await _isar.writeTxn(() async {
          for (final group in groups) {
            // putByName performs an insert-or-update keyed on the unique `name`
            // index, so re-importing the same backup is idempotent.
            await _isar.shelfGroups.putByName(group);
          }
        });
      }

      // -----------------------------------------------------------------------
      // 4. Ensure internal storage directories exist.
      // -----------------------------------------------------------------------
      final internalBooksDir = await Directory(
        p.join(AppStorage.documentsPath, _kBooksDir),
      ).create(recursive: true);
      final internalCoversDir = await Directory(
        p.join(AppStorage.documentsPath, _kCoversDir),
      ).create(recursive: true);

      // -----------------------------------------------------------------------
      // 5. Restore books in batches.
      // -----------------------------------------------------------------------
      int importedCount = 0;

      for (
        var batchStart = 0;
        batchStart < booksJson.length;
        batchStart += _kBatchSize
      ) {
        final batchEnd = (batchStart + _kBatchSize).clamp(0, booksJson.length);
        final batch = booksJson.sublist(batchStart, batchEnd);

        // Prepare all objects for this batch outside the transaction so that
        // any I/O (file copies, JSON reads) doesn't block the write lock.
        final shelfBooks = <ShelfBook>[];
        final manifests = <BookManifest>[];

        for (final bookMap in batch) {
          final hash = bookMap['fileHash'] as String;

          // -- Copy .epub (zero memory: kernel-level copy) --------------------
          final epubSrc = File(p.join(backupDirPath, _kBooksDir, '$hash.epub'));
          String? restoredFilePath;
          if (epubSrc.existsSync()) {
            final dest = p.join(internalBooksDir.path, '$hash.epub');
            await epubSrc.copy(dest);
            restoredFilePath = dest;
          } else {
            debugPrint(
              '[ImportBackup] EPUB not found in backup, skipping: $hash',
            );
          }

          // -- Copy cover image (zero memory) ---------------------------------
          // Try the same extensions the exporter probes: jpg → png → jpeg → webp
          String? restoredCoverPath;
          for (final ext in ['jpg', 'png', 'jpeg', 'webp']) {
            final coverSrc = File(
              p.join(backupDirPath, _kCoversDir, '$hash.$ext'),
            );
            if (coverSrc.existsSync()) {
              final dest = p.join(internalCoversDir.path, '$hash.$ext');
              await coverSrc.copy(dest);
              restoredCoverPath = dest;
              break;
            }
          }
          if (restoredCoverPath == null) {
            debugPrint(
              '[ImportBackup] Cover not found in backup, skipping: $hash',
            );
          }

          // -- Build ShelfBook and inject restored absolute paths -------------
          // The JSON intentionally omits filePath/coverPath (they are
          // device-specific); we reconstruct them from the just-copied files.
          final book = _mapToShelfBook(
            bookMap,
            filePath: restoredFilePath,
            coverPath: restoredCoverPath,
          );
          shelfBooks.add(book);

          // -- Parse manifest JSON, if available -----------------------------
          final manifestFile = File(
            p.join(backupDirPath, _kManifestsDir, '$hash.json'),
          );
          if (manifestFile.existsSync()) {
            try {
              final manifestMap =
                  jsonDecode(await manifestFile.readAsString())
                      as Map<String, dynamic>;
              manifests.add(_mapToBookManifest(manifestMap));
            } catch (e) {
              debugPrint(
                '[ImportBackup] Failed to parse manifest for $hash: $e',
              );
            }
          } else {
            debugPrint('[ImportBackup] Manifest file not found for: $hash');
          }
        }

        // -- Upsert the entire batch in a single transaction -----------------
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
          '[ImportBackup] Batch ${batchStart ~/ _kBatchSize + 1}: '
          'upserted ${shelfBooks.length} books.',
        );
      }

      debugPrint('[ImportBackup] Import complete. Total books: $importedCount');
      return ImportSuccess(importedBooks: importedCount);
    } on FileSystemException catch (e) {
      debugPrint('[ImportBackup] FileSystemException: $e');
      return ImportFailure('File system error: ${e.message}');
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
