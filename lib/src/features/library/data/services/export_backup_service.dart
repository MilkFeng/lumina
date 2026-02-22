import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../domain/book_manifest.dart';
import '../../domain/shelf_book.dart';
import '../../domain/shelf_group.dart';
import '../book_manifest_repository.dart';
import '../shelf_book_repository.dart';
import 'package:lumina/src/core/storage/app_storage.dart';

/// Result of an export operation.
sealed class ExportResult {
  const ExportResult();
}

/// Export succeeded. [path] is the backup directory (Android only; iOS uses Share Sheet).
final class ExportSuccess extends ExportResult {
  final String? path;
  const ExportSuccess({this.path});
}

/// Export failed with [message].
final class ExportFailure extends ExportResult {
  final String message;
  const ExportFailure(this.message);
}

/// Zero-memory overhead library backup export service.
///
/// Platform strategy:
///   Android — builds the folder directly in the public Downloads directory
///             (/storage/emulated/0/Download/Lumina/) so the user can find it
///             without any further action. No Share Sheet required.
///   iOS     — builds the folder inside the OS-managed temporary directory,
///             then hands it to the native Share Sheet via share_plus.
///             APFS Copy-on-Write means the temporary copy costs virtually no
///             extra disk space.  The temp folder is deleted in `finally`.
///
/// Memory profile:
///   Physical files (.epub, cover images) are transferred with [File.copy]
///   which is a kernel-level operation — no bytes are ever loaded into the
///   Dart heap.  Only the JSON payloads (manifest + shelf metadata) are
///   materialised in memory, and those are small by design.
class ExportBackupService {
  static const _kBooksDir = 'books';
  static const _kCoversDir = 'covers';
  static const _kManifestsDir = 'manifests';
  static const _kShelfFile = 'shelf.json';
  static const _kIOSBackupSubdir = 'backup';

  final ShelfBookRepository _shelfBookRepo;
  final BookManifestRepository _manifestRepo;

  ExportBackupService({
    required ShelfBookRepository shelfBookRepo,
    required BookManifestRepository manifestRepo,
  }) : _shelfBookRepo = shelfBookRepo,
       _manifestRepo = manifestRepo;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Exports the entire library as a self-contained folder.
  ///
  /// Returns [ExportSuccess] with the folder path on Android, or [ExportSuccess]
  /// with null on iOS (the Share Sheet handles delivery).
  /// Returns [ExportFailure] on any unrecoverable error.
  Future<ExportResult> exportLibraryAsFolder({
    Rect? sharePositionOrigin,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupName = 'lumina-backup-$timestamp';
    Directory? targetDir;

    try {
      // -----------------------------------------------------------------------
      // 1. Resolve platform-specific root directory.
      // -----------------------------------------------------------------------
      if (Platform.isAndroid) {
        // Android: write directly to the public Downloads folder so the file
        // manager and other apps can access it without extra permissions.
        targetDir = Directory(
          '/storage/emulated/0/Download/Lumina/$backupName',
        );
      } else {
        // iOS: use the system temporary directory.  Files here survive long
        // enough to be picked up by the Share Sheet, and we delete them in
        // `finally` to avoid wasting space.
        final tempDir = AppStorage.tempPath;
        targetDir = Directory(p.join(tempDir, _kIOSBackupSubdir, backupName));
      }

      // -----------------------------------------------------------------------
      // 2. Create sub-directories.
      // -----------------------------------------------------------------------
      final booksOutDir = await Directory(
        p.join(targetDir.path, _kBooksDir),
      ).create(recursive: true);
      final coversOutDir = await Directory(
        p.join(targetDir.path, _kCoversDir),
      ).create(recursive: true);
      final manifestsOutDir = await Directory(
        p.join(targetDir.path, _kManifestsDir),
      ).create(recursive: true);

      // -----------------------------------------------------------------------
      // 3. Fetch all books and groups from the database.
      // -----------------------------------------------------------------------
      final books = await _shelfBookRepo.getAllBooks();
      final groups = await _shelfBookRepo.getGroups();

      // -----------------------------------------------------------------------
      // 4. Per-book: copy physical files & serialise manifests.
      // -----------------------------------------------------------------------
      for (final book in books) {
        final hash = book.fileHash;

        // -- Copy .epub (zero-memory: kernel copy, no Dart byte buffers) ------
        final epubSrc = File(
          p.join(AppStorage.documentsPath, _kBooksDir, '$hash.epub'),
        );
        if (epubSrc.existsSync()) {
          await epubSrc.copy(p.join(booksOutDir.path, '$hash.epub'));
        } else {
          debugPrint(
            '[ExportBackup] EPUB not found, skipping: ${epubSrc.path}',
          );
        }

        // -- Copy cover image (zero-memory) ------------------------------------
        // Try common extensions; the cover may have been saved as jpg or png.
        bool coverCopied = false;
        for (final ext in ['jpg', 'png', 'jpeg', 'webp']) {
          final coverSrc = File(
            p.join(AppStorage.documentsPath, _kCoversDir, '$hash.$ext'),
          );
          if (coverSrc.existsSync()) {
            await coverSrc.copy(p.join(coversOutDir.path, '$hash.$ext'));
            coverCopied = true;
            break;
          }
        }
        if (!coverCopied) {
          debugPrint('[ExportBackup] Cover not found, skipping: $hash');
        }

        // -- Serialise BookManifest to JSON ------------------------------------
        final manifest = await _manifestRepo.getManifestByHash(hash);
        if (manifest != null) {
          final manifestJson = jsonEncode(_manifestToMap(manifest));
          await File(
            p.join(manifestsOutDir.path, '$hash.json'),
          ).writeAsString(manifestJson);
        } else {
          debugPrint('[ExportBackup] No manifest found for: $hash');
        }
      }

      // -----------------------------------------------------------------------
      // 5. Write shelf.json (ShelfBooks + ShelfGroups).
      // -----------------------------------------------------------------------
      final shelfMap = _shelfToMap(books, groups);
      final shelfJson = jsonEncode(shelfMap);
      await File(p.join(targetDir.path, _kShelfFile)).writeAsString(shelfJson);

      // -----------------------------------------------------------------------
      // 6. Platform-specific delivery.
      // -----------------------------------------------------------------------
      if (Platform.isAndroid) {
        // The folder is already in the public Downloads directory — done.
        debugPrint('[ExportBackup] Android export complete: ${targetDir.path}');
        return ExportSuccess(path: targetDir.path);
      } else {
        // iOS: share the entire folder via the native Share Sheet.
        await Share.shareXFiles(
          [XFile(targetDir.path)],
          subject: 'Lumina Backup',
          sharePositionOrigin: sharePositionOrigin,
        );
        return const ExportSuccess();
      }
    } on FileSystemException catch (e) {
      debugPrint('[ExportBackup] FileSystemException: $e');
      return ExportFailure('File system error: ${e.message}');
    } catch (e, st) {
      debugPrint('[ExportBackup] Unexpected error: $e\n$st');
      return ExportFailure('Export failed: $e');
    } finally {
      // -----------------------------------------------------------------------
      // 7. Cleanup — only on iOS (and other non-Android platforms).
      //    On Android the folder lives in a public directory and must be kept.
      // -----------------------------------------------------------------------
      if (!Platform.isAndroid && targetDir != null) {
        try {
          if (targetDir.existsSync()) {
            await targetDir.delete(recursive: true);
            debugPrint('[ExportBackup] Cleaned up temporary directory.');
          }
        } catch (e) {
          debugPrint('[ExportBackup] Cleanup failed (non-fatal): $e');
        }
      }
    }
  }

  Future<void> clearCache() async {
    if (Platform.isIOS) {
      final tempDir = AppStorage.tempPath;
      final targetDir = Directory(p.join(tempDir, _kIOSBackupSubdir));
      try {
        if (targetDir.existsSync()) {
          await targetDir.delete(recursive: true);
          debugPrint('[ExportBackup] Cache cleared successfully.');
        }
      } catch (e) {
        debugPrint('[ExportBackup] Cache clearing failed: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // JSON Mapping helpers
  // ---------------------------------------------------------------------------

  /// Serialises the entire shelf (books + groups) to a JSON-compatible map.
  Map<String, dynamic> _shelfToMap(
    List<ShelfBook> books,
    List<ShelfGroup> groups,
  ) => {
    'version': 1, // for future-proofing the format
    'books': books.map(_shelfBookToMap).toList(),
    'groups': groups.map(_shelfGroupToMap).toList(),
  };

  /// Serialises [ShelfBook] to a JSON-compatible map.
  ///
  /// Intentionally excludes:
  ///   - [id]         — Isar auto-increment, meaningless outside this device.
  ///   - [filePath]   — Absolute device path; would break on a different device.
  ///   - [coverPath]  — Same reason as filePath.
  Map<String, dynamic> _shelfBookToMap(ShelfBook b) => {
    'fileHash': b.fileHash,
    'title': b.title,
    'author': b.author,
    'authors': b.authors,
    'description': b.description,
    'subjects': b.subjects,
    'totalChapters': b.totalChapters,
    'epubVersion': b.epubVersion,
    'importDate': b.importDate,
    'currentChapterIndex': b.currentChapterIndex,
    'readingProgress': b.readingProgress,
    'chapterScrollPosition': b.chapterScrollPosition,
    'lastOpenedDate': b.lastOpenedDate,
    'isFinished': b.isFinished,
    'groupName': b.groupName,
    'isDeleted': b.isDeleted,
    'updatedAt': b.updatedAt,
    'lastSyncedDate': b.lastSyncedDate,
  };

  /// Serialises [ShelfGroup] to a JSON-compatible map.
  ///
  /// Excludes [id] for the same reason as [ShelfBook].
  Map<String, dynamic> _shelfGroupToMap(ShelfGroup g) => {
    'name': g.name,
    'creationDate': g.creationDate,
    'updatedAt': g.updatedAt,
    'isDeleted': g.isDeleted,
  };

  /// Serialises the full [BookManifest] (and all embedded objects) to a map.
  ///
  /// Excludes [id] — the [fileHash] is the canonical identifier.
  Map<String, dynamic> _manifestToMap(BookManifest m) => {
    'version': 1, // for future-proofing the format
    'fileHash': m.fileHash,
    'opfRootPath': m.opfRootPath,
    'epubVersion': m.epubVersion,
    'lastUpdated': m.lastUpdated.toIso8601String(),
    'spine': m.spine.map(_spineItemToMap).toList(),
    'toc': m.toc.map(_tocItemToMap).toList(),
    'manifest': m.manifest.map(_manifestItemToMap).toList(),
  };

  Map<String, dynamic> _spineItemToMap(SpineItem s) => {
    'index': s.index,
    'href': s.href,
    'idref': s.idref,
    'linear': s.linear,
  };

  Map<String, dynamic> _hrefToMap(Href h) => {
    'path': h.path,
    'anchor': h.anchor,
  };

  Map<String, dynamic> _manifestItemToMap(ManifestItem item) => {
    'id': item.id,
    'href': _hrefToMap(item.href),
    'mediaType': item.mediaType,
    'properties': item.properties,
  };

  Map<String, dynamic> _tocItemToMap(TocItem t) => {
    'id': t.id,
    'label': t.label,
    'href': _hrefToMap(t.href),
    'depth': t.depth,
    'spineIndex': t.spineIndex,
    'parentId': t.parentId,
    'children': t.children.map(_tocItemToMap).toList(),
  };
}
