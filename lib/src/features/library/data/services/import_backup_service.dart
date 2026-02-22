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
  Future<ImportResult> importLibraryFromFolder(BackupPaths backupPaths) async {
    return ImportFailure('Not implemented');
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
