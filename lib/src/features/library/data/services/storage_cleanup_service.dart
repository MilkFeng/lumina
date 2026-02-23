import 'dart:io';

import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/features/library/data/services/export_backup_service.dart';
import 'package:path/path.dart' as p;

import 'package:lumina/src/core/storage/app_storage.dart';
import '../shelf_book_repository.dart';

/// Service that scans physical storage directories and removes files
/// that have no corresponding database record (orphan files).
class StorageCleanupService {
  static const String _kBooksDir = 'books';
  static const String _kCoversDir = 'covers';

  static const String _kShareDir = 'share';

  final ShelfBookRepository _shelfBookRepo;
  final ExportBackupService _exportBackupService;

  StorageCleanupService({
    required ShelfBookRepository shelfBookRepo,
    required ExportBackupService exportBackupService,
  }) : _shelfBookRepo = shelfBookRepo,
       _exportBackupService = exportBackupService;

  /// Scans [books/] and [covers/] inside [AppStorage.documentsPath] and
  /// deletes every file whose name (without extension) is not present in the
  /// database.
  ///
  /// Returns the total number of files deleted.
  Future<int> cleanOrphanFiles() async {
    // Collect all hashes that are known to the database (including
    // soft-deleted records so we don't accidentally wipe them).
    final validHashes = await _shelfBookRepo.getAllFileHashes();

    int deletedCount = 0;
    deletedCount += await _cleanDirectory(
      p.join(AppStorage.documentsPath, _kBooksDir),
      validHashes,
    );
    deletedCount += await _cleanDirectory(
      p.join(AppStorage.documentsPath, _kCoversDir),
      validHashes,
    );
    return deletedCount;
  }

  Future<void> cleanCacheFiles() async {
    await _exportBackupService.clearCache();

    final cacheManager = ImportCacheManager();
    await cacheManager.clearAll();
  }

  Future<void> cleanShareFiles() async {
    final shareDir = Directory('${AppStorage.tempPath}/$_kShareDir');
    if (await shareDir.exists()) {
      await shareDir.delete(recursive: true);
    }
  }

  Future<File> saveTempFileForSharing(File sourceFile, String title) async {
    final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final tempDir = Directory('${AppStorage.tempPath}/$_kShareDir');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final tempPath = '${tempDir.path}/$sanitizedTitle.epub';
    final tempFile = File(tempPath);
    await sourceFile.copy(tempFile.path);
    return tempFile;
  }

  /// Iterates [dirPath], deletes any [File] whose name (without extension)
  /// is absent from [validHashes], and returns the number of files removed.
  Future<int> _cleanDirectory(String dirPath, Set<String> validHashes) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;

    int deleted = 0;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final nameWithoutExt = p.basenameWithoutExtension(entity.path);
      if (!validHashes.contains(nameWithoutExt)) {
        try {
          await entity.delete();
          deleted++;
        } on FileSystemException {
          // File is locked or otherwise inaccessible – skip silently.
        }
      }
    }
    return deleted;
  }
}
