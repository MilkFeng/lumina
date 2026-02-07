import 'package:lumina/src/core/services/epub_import_service.dart';
import 'package:isar/isar.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/sync_snapshot.dart';
import '../../library/domain/shelf_book.dart';
import '../../library/domain/shelf_group.dart';
import '../../../core/database/isar_service.dart';
import 'webdav_service.dart';
import 'sync_config_repository.dart';

/// WebDAV Sync Service with Snapshot-based three-way merge
/// Implements: Pull -> Merge -> Apply -> FileSync -> Push
class WebDavSyncService {
  final WebDavService _webDavService;
  final SyncConfigRepository _configRepository;
  final EpubImportService _epubImportService;

  static const String snapshotFileName = 'snapshot.json';
  static const String booksFolder = 'books';

  WebDavSyncService({
    WebDavService? webDavService,
    SyncConfigRepository? configRepository,
    EpubImportService? epubImportService,
  }) : _webDavService = webDavService ?? WebDavService(),
       _configRepository = configRepository ?? SyncConfigRepository(),
       _epubImportService = epubImportService ?? EpubImportService();

  /// Initialize WebDAV connection from stored config
  Future<Either<String, bool>> initializeFromConfig() async {
    final config = await _configRepository.getConfig();
    if (config == null) {
      return left('Sync not configured');
    }

    return await _webDavService.initialize(
      serverUrl: config.serverUrl,
      username: config.username,
      password: config.password,
      remoteFolderPath: config.remoteFolderPath,
    );
  }

  /// Perform full sync workflow
  /// Returns (successCount, failedCount, errorMessages)
  Future<Either<String, SyncResult>> performFullSync({
    void Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Initializing connection...');

      // Initialize connection
      final initResult = await initializeFromConfig();
      if (initResult.isLeft()) {
        return left(initResult.getLeft().toNullable()!);
      }

      // Ensure remote directories exist
      await _webDavService.ensureRemoteDirectory();

      // STEP 1: Pull
      onProgress?.call('Downloading snapshot...');
      final pullResult = await _pullSnapshot();
      final cloudSnapshot = pullResult.fold(
        (error) => null, // Treat as empty if not found
        (snapshot) => snapshot,
      );

      // STEP 2: Merge
      onProgress?.call('Analyzing changes...');
      final mergeResult = await _mergeWithCloud(cloudSnapshot);

      // STEP 3: Apply
      onProgress?.call('Applying changes...');
      await _applyMergeActions(mergeResult, cloudSnapshot);

      // STEP 4: File Sync
      onProgress?.call('Syncing files...');
      final fileSyncResult = await _syncFiles(
        cloudSnapshot,
        onProgress: onProgress,
      );

      // STEP 5: Push
      onProgress?.call('Uploading snapshot...');
      final pushResult = await _pushSnapshot();
      if (pushResult.isLeft()) {
        return left(
          'Failed to push snapshot: ${pushResult.getLeft().toNullable()}',
        );
      }
      final snapshot = pushResult.getRight().toNullable()!;

      // STEP 6: Cleanup remote deleted books
      onProgress?.call('Cleaning up remote deleted books...');
      final cleanupResult = await _cleanupRemoteDeletedBooks(snapshot);
      if (cleanupResult.isLeft()) {
        debugPrint(
          'Warning: Failed to cleanup remote deleted books: ${cleanupResult.getLeft().toNullable()}',
        );
      }

      // Update last sync time
      await _configRepository.updateLastSync(
        syncDate: DateTime.now(),
        error: null,
      );

      return right(
        SyncResult(
          success: true,
          groupsAdded: mergeResult.groupsToInsert.length,
          groupsUpdated: mergeResult.groupsToUpdate.length,
          groupsDeleted: mergeResult.groupsToDelete.length,
          booksAdded: mergeResult.booksToInsert.length,
          booksUpdated: mergeResult.booksToUpdate.length,
          booksDeleted: mergeResult.booksToDelete.length,
          filesDownloaded: fileSyncResult.downloaded,
          filesUploaded: fileSyncResult.uploaded,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      await _configRepository.updateLastSync(error: e.toString());
      return left('Sync failed: $e');
    }
  }

  /// STEP 1: Pull snapshot from WebDAV
  Future<Either<String, SyncSnapshot>> _pullSnapshot() async {
    final result = await _webDavService.downloadText(snapshotFileName);

    return result.fold((error) => left(error), (jsonString) async {
      try {
        // Parse in isolate to avoid blocking UI
        final snapshot = await compute(_parseSnapshotIsolate, jsonString);
        return right(snapshot);
      } catch (e) {
        return left('Failed to parse snapshot: $e');
      }
    });
  }

  /// STEP 2: Three-way merge logic
  Future<MergeResult> _mergeWithCloud(SyncSnapshot? cloudSnapshot) async {
    final isar = await IsarService.getInstance();

    // Fetch all local data (including deleted)
    final localGroups = await isar.shelfGroups.where().anyId().findAll();
    final localBooks = await isar.shelfBooks.where().anyId().findAll();

    final localGroupMap = {for (var g in localGroups) g.name: g};
    final localBookMap = {for (var b in localBooks) b.fileHash: b};

    final cloudGroupMap = cloudSnapshot != null
        ? {for (var g in cloudSnapshot.groups) g.name: g}
        : <String, SnapshotGroup>{};
    final cloudBookMap = cloudSnapshot != null
        ? {for (var b in cloudSnapshot.books) b.fileHash: b}
        : <String, SnapshotBook>{};

    final result = MergeResult();

    // === Merge Groups ===
    for (final cloudGroup in cloudGroupMap.values) {
      final localGroup = localGroupMap[cloudGroup.name];

      if (localGroup == null) {
        // Cloud New
        if (!cloudGroup.isDeleted) {
          result.groupsToInsert.add(cloudGroup);
        }
      } else {
        // Conflict/Update
        if (cloudGroup.updatedAt > localGroup.updatedAt) {
          if (cloudGroup.isDeleted) {
            result.groupsToDelete.add(cloudGroup);
          } else {
            result.groupsToUpdate.add(cloudGroup);
          }
        }
        // Else: keep local (will be pushed)
      }
    }

    // === Merge Books ===
    for (final cloudBook in cloudBookMap.values) {
      final localBook = localBookMap[cloudBook.fileHash];

      if (localBook == null) {
        // Cloud New
        if (!cloudBook.isDeleted) {
          result.booksToInsert.add(cloudBook);
        }
      } else {
        // Conflict/Update
        if (cloudBook.updatedAt > localBook.updatedAt) {
          if (cloudBook.isDeleted) {
            result.booksToDelete.add(cloudBook);
          } else {
            result.booksToUpdate.add(cloudBook);
          }
        }
        // Else: keep local (will be pushed)
      }
    }

    return result;
  }

  /// STEP 3: Apply merge actions to database (with Double Check)
  Future<void> _applyMergeActions(
    MergeResult result,
    SyncSnapshot? cloudSnapshot,
  ) async {
    final isar = await IsarService.getInstance();

    await isar.writeTxn(() async {
      // Insert new groups
      for (final cloudGroup in result.groupsToInsert) {
        final group = ShelfGroup()
          ..name = cloudGroup.name
          ..creationDate = cloudGroup.creationDate
          ..updatedAt = cloudGroup.updatedAt
          ..isDeleted = cloudGroup.isDeleted;
        await isar.shelfGroups.put(group);
      }

      // Update existing groups (with Double Check)
      for (final cloudGroup in result.groupsToUpdate) {
        final localGroup = await isar.shelfGroups
            .filter()
            .nameEqualTo(cloudGroup.name)
            .findFirst();
        if (localGroup != null) {
          // Double Check: If local was updated after merge calculation, keep local
          if (localGroup.updatedAt > cloudGroup.updatedAt) {
            debugPrint(
              'Double Check: Skipping group ${cloudGroup.name} - '
              'local is newer (${localGroup.updatedAt} > ${cloudGroup.updatedAt})',
            );
            continue;
          }

          localGroup.name = cloudGroup.name;
          localGroup.updatedAt = cloudGroup.updatedAt;
          localGroup.isDeleted = cloudGroup.isDeleted;
          await isar.shelfGroups.put(localGroup);
        }
      }

      // Soft delete groups (with Double Check)
      for (final group in result.groupsToDelete) {
        final localGroup = await isar.shelfGroups
            .filter()
            .nameEqualTo(group.name)
            .findFirst();
        if (localGroup != null) {
          // Double Check: Get the cloud updatedAt for this deletion
          // (we need to track when this delete decision was made)
          // For safety, only delete if local hasn't been modified since merge
          final cloudUpdatedAt =
              cloudSnapshot?.groups
                  .firstWhere(
                    (g) => g.name == group.name,
                    orElse: () => SnapshotGroup(
                      name: '',
                      creationDate: 0,
                      updatedAt: 0,
                      isDeleted: true,
                    ),
                  )
                  .updatedAt ??
              0;

          if (cloudUpdatedAt > 0 && localGroup.updatedAt > cloudUpdatedAt) {
            debugPrint(
              'Double Check: Skipping delete of group ${group.name} - '
              'local was modified after merge decision',
            );
            continue;
          }

          localGroup.isDeleted = true;
          localGroup.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await isar.shelfGroups.put(localGroup);
        }
      }

      // Insert new books (filePath and coverPath are null, will be filled in FileSync)
      for (final cloudBook in result.booksToInsert) {
        final book = ShelfBook()
          ..fileHash = cloudBook.fileHash
          ..groupName = cloudBook.groupName
          ..title = cloudBook.title
          ..author = cloudBook.author
          ..authors = cloudBook.authors
          ..description = cloudBook.description
          ..subjects = cloudBook.subjects
          ..totalChapters = cloudBook.totalChapters
          ..epubVersion = cloudBook.epubVersion
          ..importDate = cloudBook.importDate
          ..lastOpenedDate = cloudBook.lastOpenedDate
          ..currentChapterIndex = cloudBook.currentChapterIndex
          ..readingProgress = cloudBook.readingProgress
          ..chapterScrollPosition = cloudBook.chapterScrollPosition
          ..isFinished = cloudBook.isFinished
          ..updatedAt = cloudBook.updatedAt
          ..isDeleted = cloudBook.isDeleted
          ..filePath =
              null // Will be filled after download
          ..coverPath = null
          ..isDownloading = false;
        await isar.shelfBooks.put(book);
      }

      // Update existing books (with Double Check)
      for (final cloudBook in result.booksToUpdate) {
        final localBook = await isar.shelfBooks
            .filter()
            .fileHashEqualTo(cloudBook.fileHash)
            .findFirst();
        if (localBook != null) {
          // Double Check: If local was updated after merge calculation, keep local
          if (localBook.updatedAt > cloudBook.updatedAt) {
            debugPrint(
              'Double Check: Skipping book ${cloudBook.fileHash} - '
              'local is newer (${localBook.updatedAt} > ${cloudBook.updatedAt})',
            );
            continue;
          }

          localBook.groupName = cloudBook.groupName;
          localBook.title = cloudBook.title;
          localBook.author = cloudBook.author;
          localBook.authors = cloudBook.authors;
          localBook.description = cloudBook.description;
          localBook.subjects = cloudBook.subjects;
          localBook.totalChapters = cloudBook.totalChapters;
          localBook.currentChapterIndex = cloudBook.currentChapterIndex;
          localBook.readingProgress = cloudBook.readingProgress;
          localBook.chapterScrollPosition = cloudBook.chapterScrollPosition;
          localBook.isFinished = cloudBook.isFinished;
          localBook.updatedAt = cloudBook.updatedAt;
          localBook.isDeleted = cloudBook.isDeleted;
          // Keep existing filePath and coverPath
          await isar.shelfBooks.put(localBook);
        }
      }

      // Soft delete books (with Double Check)
      for (final cloudBook in result.booksToDelete) {
        final localBook = await isar.shelfBooks
            .filter()
            .fileHashEqualTo(cloudBook.fileHash)
            .findFirst();
        if (localBook != null) {
          // Double Check: Get the cloud updatedAt for this deletion
          final cloudUpdatedAt =
              cloudSnapshot?.books
                  .firstWhere(
                    (b) => b.fileHash == cloudBook.fileHash,
                    orElse: () => SnapshotBook(
                      fileHash: '',
                      groupName: '',
                      title: '',
                      author: '',
                      authors: [],
                      description: '',
                      subjects: [],
                      totalChapters: 0,
                      epubVersion: '',
                      importDate: 0,
                      lastOpenedDate: 0,
                      currentChapterIndex: 0,
                      readingProgress: 0.0,
                      chapterScrollPosition: 0.0,
                      isFinished: false,
                      updatedAt: 0,
                      isDeleted: true,
                    ),
                  )
                  .updatedAt ??
              0;

          if (cloudUpdatedAt > 0 && localBook.updatedAt > cloudUpdatedAt) {
            debugPrint(
              'Double Check: Skipping delete of book ${cloudBook.fileHash} - '
              'local was modified after merge decision',
            );
            continue;
          }

          localBook.isDeleted = true;
          localBook.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await isar.shelfBooks.put(localBook);
        }
      }
    });
  }

  Future<Set<String>> _getRemoteRealHashes() async {
    final filesResult = await _webDavService.listFilesByPath('books');
    if (filesResult.isLeft()) {
      return {};
    }

    return filesResult
        .getRight()
        .toNullable()!
        .where((f) => f.name != null && f.name!.endsWith('.epub'))
        .map((f) => f.name!.replaceAll('.epub', ''))
        .toSet();
  }

  /// STEP 4: Sync EPUB files (download missing, upload new)
  Future<FileSyncResult> _syncFiles(
    SyncSnapshot? cloudSnapshot, {
    void Function(String)? onProgress,
  }) async {
    int downloaded = 0;
    int uploaded = 0;

    var cloudFileHashes = cloudSnapshot != null
        ? cloudSnapshot.books
              .where((b) => !b.isDeleted)
              .map((b) => b.fileHash)
              .toSet()
        : <String>{};

    final remoteRealFileHashes = await _getRemoteRealHashes();

    cloudFileHashes = cloudFileHashes.intersection(remoteRealFileHashes);

    // Download missing books
    final booksToDownload = await _getBooksNeedingDownload();

    for (int i = 0; i < booksToDownload.length; i++) {
      final book = booksToDownload[i];
      onProgress?.call(
        'Downloading ${i + 1}/${booksToDownload.length}: ${book.title}',
      );

      final downloadResult = await _downloadAndProcessBook(book);
      if (downloadResult.isRight()) {
        downloaded++;
      }
    }

    // Upload new books
    final booksToUpload = await _getBooksNeedingUpload(remoteRealFileHashes);

    for (int i = 0; i < booksToUpload.length; i++) {
      final book = booksToUpload[i];
      onProgress?.call(
        'Uploading ${i + 1}/${booksToUpload.length}: ${book.title}',
      );

      final uploadResult = await _uploadBook(book);
      if (uploadResult.isRight()) {
        uploaded++;
      }
    }

    return FileSyncResult(downloaded: downloaded, uploaded: uploaded);
  }

  /// Get books that need to be downloaded
  Future<List<ShelfBook>> _getBooksNeedingDownload() async {
    final isar = await IsarService.getInstance();
    final allBooks = await isar.shelfBooks
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    final appDir = await getApplicationDocumentsDirectory();

    return allBooks.where((book) {
      // Need download if filePath is null or file doesn't exist
      if (book.filePath == null) return true;
      final fullPath = '${appDir.path}/${book.filePath!}';
      return !File(fullPath).existsSync();
    }).toList();
  }

  /// Get books that need to be uploaded
  Future<List<ShelfBook>> _getBooksNeedingUpload(
    Set<String> remoteRealFileHashes,
  ) async {
    final isar = await IsarService.getInstance();
    final allBooks = await isar.shelfBooks
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    final appDir = await getApplicationDocumentsDirectory();

    return allBooks.where((book) {
      // Need upload if filePath exists locally but not in cloud
      if (book.filePath == null) return false;
      final fullPath = '${appDir.path}/${book.filePath!}';
      if (!File(fullPath).existsSync()) return false;
      return !remoteRealFileHashes.contains(book.fileHash);
    }).toList();
  }

  /// Download and process a single book
  Future<Either<String, bool>> _downloadAndProcessBook(ShelfBook book) async {
    try {
      // Download EPUB file
      final remoteFileName = '$booksFolder/${book.fileHash}.epub';
      final downloadResult = await _webDavService.downloadFile(remoteFileName);

      if (downloadResult.isLeft()) {
        return left(
          'Download failed: ${downloadResult.getLeft().toNullable()}',
        );
      }

      final epubBytes = downloadResult.getRight().toNullable()!;

      // Save to local storage
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!booksDir.existsSync()) {
        booksDir.createSync(recursive: true);
      }

      final absFilePath = '${booksDir.path}/${book.fileHash}.epub';
      final localFilePath = 'books/${book.fileHash}.epub';
      final epubFile = File(absFilePath);
      await epubFile.writeAsBytes(epubBytes);

      // Parse EPUB in isolate (generate manifest + cover)
      final processResult = await _processEpubIsolate(
        absFilePath,
        book.id,
        book.fileHash,
      );

      if (processResult.error != null) {
        return left('EPUB processing failed: ${processResult.error}');
      }

      // Update book record
      final isar = await IsarService.getInstance();
      await isar.writeTxn(() async {
        final bookToUpdate = await isar.shelfBooks
            .filter()
            .fileHashEqualTo(book.fileHash)
            .findFirst();
        if (bookToUpdate != null) {
          bookToUpdate.filePath = localFilePath;
          bookToUpdate.coverPath = processResult.coverPath;
          await isar.shelfBooks.put(bookToUpdate);
        }
      });

      return right(true);
    } catch (e) {
      return left('Download and process failed: $e');
    }
  }

  Future<_EpubProcessResult> _processEpubIsolate(
    String epubFilePath,
    int bookId,
    String fileHash,
  ) async {
    final result = await _epubImportService.updateBookManifestAndCover(
      epubFilePath,
      bookId,
      fileHash,
    );

    if (result.isLeft()) {
      return _EpubProcessResult(
        coverPath: null,
        error: result.getLeft().toNullable(),
      );
    }

    final coverPath = result.getRight().toNullable()!.$2;

    return _EpubProcessResult(coverPath: coverPath, error: null);
  }

  /// Upload a single book (with pre-upload validation)
  Future<Either<String, bool>> _uploadBook(ShelfBook book) async {
    try {
      // Pre-upload check: Re-verify book status in database
      final isar = await IsarService.getInstance();
      final currentBook = await isar.shelfBooks
          .filter()
          .fileHashEqualTo(book.fileHash)
          .findFirst();

      // Skip if book was deleted during sync
      if (currentBook == null || currentBook.isDeleted) {
        debugPrint(
          'Upload skipped: Book ${book.fileHash} was deleted during sync',
        );
        return left('Book was deleted - upload skipped');
      }

      if (currentBook.filePath == null) {
        return left('Book has no local file');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fullPath = '${appDir.path}/${currentBook.filePath!}';

      final epubFile = File(fullPath);
      if (!epubFile.existsSync()) {
        debugPrint(
          'Upload skipped: File not found for book ${book.fileHash} at $fullPath',
        );
        return left('Local file not found - upload skipped');
      }

      final remoteFileName = '$booksFolder/${currentBook.fileHash}.epub';
      return await _webDavService.uploadFile(
        localFile: epubFile,
        remoteFileName: remoteFileName,
      );
    } catch (e) {
      return left('Upload failed: $e');
    }
  }

  /// STEP 5: Push local snapshot to WebDAV (with Late Fetch)
  /// CRITICAL: Re-fetch database to capture any changes made during File Sync
  Future<Either<String, SyncSnapshot>> _pushSnapshot() async {
    try {
      // Late Fetch: Generate snapshot from CURRENT database state
      // This ensures we capture any reading progress updates, deletions,
      // or other changes that occurred during the File Sync phase
      final snapshot = await _generateLocalSnapshot();

      // Serialize in isolate
      final jsonString = await compute(_serializeSnapshotIsolate, snapshot);

      // Upload to WebDAV
      final uploadResult = await _webDavService.uploadText(
        content: jsonString,
        remoteFileName: snapshotFileName,
      );

      if (uploadResult.isLeft()) {
        return left('Upload failed: ${uploadResult.getLeft().toNullable()}');
      }

      if (!uploadResult.getRight().toNullable()!) {
        return left('Unknown error during snapshot upload');
      }

      return right(snapshot);
    } catch (e) {
      return left('Push snapshot failed: $e');
    }
  }

  /// Generate snapshot from local database
  Future<SyncSnapshot> _generateLocalSnapshot() async {
    final isar = await IsarService.getInstance();

    // Fetch all data (including deleted for tombstone records)
    final localGroups = await isar.shelfGroups.where().anyId().findAll();
    final localBooks = await isar.shelfBooks.where().anyId().findAll();

    final deviceId = 'flutter-${Platform.operatingSystem}-${Platform.version}';

    final PackageInfo info = await PackageInfo.fromPlatform();
    final appVersion = '${info.version}+${info.buildNumber}}';

    return SyncSnapshot(
      meta: SnapshotMeta(
        version: 1,
        generatedAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: deviceId,
        appVersion: appVersion,
      ),
      groups: localGroups.map(_groupToSnapshot).toList(),
      books: localBooks.map(_bookToSnapshot).toList(),
    );
  }

  /// Convert ShelfGroup to SnapshotGroup
  SnapshotGroup _groupToSnapshot(ShelfGroup group) {
    return SnapshotGroup(
      name: group.name,
      creationDate: group.creationDate,
      updatedAt: group.updatedAt,
      isDeleted: group.isDeleted,
    );
  }

  /// Convert ShelfBook to SnapshotBook
  SnapshotBook _bookToSnapshot(ShelfBook book) {
    return SnapshotBook(
      fileHash: book.fileHash,
      groupName: book.groupName,
      title: book.title,
      author: book.author,
      authors: book.authors,
      description: book.description,
      subjects: book.subjects,
      totalChapters: book.totalChapters,
      epubVersion: book.epubVersion,
      importDate: book.importDate,
      lastOpenedDate: book.lastOpenedDate,
      currentChapterIndex: book.currentChapterIndex,
      readingProgress: book.readingProgress,
      chapterScrollPosition: book.chapterScrollPosition,
      isFinished: book.isFinished,
      updatedAt: book.updatedAt,
      isDeleted: book.isDeleted,
    );
  }

  Future<Either<String, bool>> _cleanupRemoteDeletedBooks(
    SyncSnapshot cloudSnapshot,
  ) async {
    try {
      // List all remote hashes
      final remoteFileHashes = await _getRemoteRealHashes();

      // Identify files that should be deleted (present remotely but marked as deleted in snapshot)
      final reservedBooks = cloudSnapshot.books
          .where((b) => !b.isDeleted)
          .map((b) => b.fileHash)
          .toSet();

      final filesToDelete = remoteFileHashes.difference(reservedBooks);
      for (final fileHash in filesToDelete) {
        final remoteFileName = '$booksFolder/$fileHash.epub';
        await _webDavService.deleteFile(remoteFileName);
      }

      return right(true);
    } catch (e) {
      return left('Failed to cleanup remote deleted books: $e');
    }
  }
}

// ==================== ISOLATE FUNCTIONS ====================

/// Parse snapshot JSON in isolate
SyncSnapshot _parseSnapshotIsolate(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return SyncSnapshot.fromJson(json);
}

/// Serialize snapshot to JSON in isolate
String _serializeSnapshotIsolate(SyncSnapshot snapshot) {
  return jsonEncode(snapshot.toJson());
}

/// Result from EPUB processing isolate
class _EpubProcessResult {
  final String? coverPath;
  final String? error;

  _EpubProcessResult({this.coverPath, this.error});
}

// ==================== RESULT CLASSES ====================

/// Result of merge operation
class MergeResult {
  final List<SnapshotGroup> groupsToInsert = [];
  final List<SnapshotGroup> groupsToUpdate = [];
  final List<SnapshotGroup> groupsToDelete = [];

  final List<SnapshotBook> booksToInsert = [];
  final List<SnapshotBook> booksToUpdate = [];
  final List<SnapshotBook> booksToDelete = [];
}

/// Result of file sync operation
class FileSyncResult {
  final int downloaded;
  final int uploaded;

  FileSyncResult({required this.downloaded, required this.uploaded});
}

/// Result of full sync operation
class SyncResult {
  final bool success;
  final int groupsAdded;
  final int groupsUpdated;
  final int groupsDeleted;
  final int booksAdded;
  final int booksUpdated;
  final int booksDeleted;
  final int filesDownloaded;
  final int filesUploaded;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.groupsAdded,
    required this.groupsUpdated,
    required this.groupsDeleted,
    required this.booksAdded,
    required this.booksUpdated,
    required this.booksDeleted,
    required this.filesDownloaded,
    required this.filesUploaded,
    required this.timestamp,
  });

  String getSummary() {
    final parts = <String>[];

    if (groupsAdded > 0) parts.add('$groupsAdded groups added');
    if (groupsUpdated > 0) parts.add('$groupsUpdated groups updated');
    if (groupsDeleted > 0) parts.add('$groupsDeleted groups deleted');
    if (booksAdded > 0) parts.add('$booksAdded books added');
    if (booksUpdated > 0) parts.add('$booksUpdated books updated');
    if (booksDeleted > 0) parts.add('$booksDeleted books deleted');
    if (filesDownloaded > 0) parts.add('$filesDownloaded files downloaded');
    if (filesUploaded > 0) parts.add('$filesUploaded files uploaded');

    return parts.isEmpty ? 'No changes' : parts.join(', ');
  }
}
