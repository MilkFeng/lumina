import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lumina/src/core/storage/app_storage_constants.dart';
import 'package:path/path.dart' as p;
import 'package:saf_stream/saf_stream.dart';
import 'platform_path.dart';
import 'importable_epub.dart';
import 'import_cache_manager.dart';

class BackupPathsForBook {
  PlatformPath epubPath;
  PlatformPath manifestPath;
  PlatformPath? coverPath;

  BackupPathsForBook({
    required this.epubPath,
    required this.manifestPath,
    required this.coverPath,
  });
}

class BackupPaths {
  PlatformPath rootPath;
  PlatformPath shelfFile;
  Map<String, BackupPathsForBook> bookPaths; // Keyed by book hash

  BackupPaths({
    required this.rootPath,
    required this.shelfFile,
    required this.bookPaths,
  });
}

/// Unified entry point for EPUB file import across platforms
///
/// This service provides a clean, platform-agnostic API for:
/// - Picking EPUB files (single or multiple)
/// - Picking folders and scanning for EPUB files
/// - Processing selected files into cached, hashed ImportableEpub objects
///
/// Android: Uses native MethodChannel with SAF (Storage Access Framework)
/// iOS: Currently unsupported (requires native implementation or file_picker package)
class UnifiedImportService {
  static const String _channelName = 'com.lumina.ereader/native_picker';
  static const MethodChannel _channel = MethodChannel(_channelName);

  final _safStream = SafStream();

  // Use `late final` so we can pass `fetchIosFileToTemp` as a callback
  // into ImportCacheManager without a circular-reference problem.
  late final ImportCacheManager _cacheManager;

  UnifiedImportService({ImportCacheManager? cacheManager}) {
    _cacheManager =
        cacheManager ??
        ImportCacheManager(iosFetchCallback: fetchIosFileToTemp);
  }

  /// Pick multiple EPUB files using platform-appropriate picker
  ///
  /// Android: Uses native SAF document picker via MethodChannel
  /// iOS: Currently unsupported - returns empty list
  ///
  /// Returns a list of [PlatformPath] objects representing selected files.
  /// Returns empty list if user cancels or no files are selected.
  Future<List<PlatformPath>> pickFiles() async {
    if (Platform.isAndroid) {
      return await _pickFilesAndroid();
    } else if (Platform.isIOS) {
      return await _pickFilesIOS();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  /// Pick a folder and recursively scan for EPUB files
  ///
  /// Android: Uses native SAF tree picker with background traversal via MethodChannel
  /// iOS: Currently unsupported - returns empty list
  ///
  /// Returns a list of [PlatformPath] objects for all EPUB files found.
  /// Returns empty list if user cancels or no EPUB files are found.
  Future<List<PlatformPath>> pickFolder() async {
    if (Platform.isAndroid) {
      return await _pickFolderAndroid();
    } else if (Platform.isIOS) {
      return await _pickFolderIOS();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  /// Process an EPUB file into a cached, hashed ImportableEpub
  ///
  /// This delegates to [ImportCacheManager.createCacheAndHash] which:
  /// - For Android: Streams content from SAF URI to cache
  /// - For iOS: Copies file from file system to cache
  /// - Calculates SHA-256 hash for deduplication
  ///
  /// Returns [ImportableEpub] with cached file and hash.
  /// Throws exceptions on I/O errors or invalid files.
  Future<ImportableEpub> processEpub(PlatformPath path) async {
    return await _cacheManager.createCacheAndHash(path);
  }

  /// Process a plain text file (e.g. shelf.json) into a String
  ///
  /// For Android: Streams content from SAF URI without loading entire file into memory
  /// For iOS: Reads file from file system
  ///
  /// Returns the file content as a String.
  /// Throws exceptions on I/O errors or invalid files.
  Future<String> processPlainFile(PlatformPath path) async {
    final bytes = await processBinaryFile(path);
    return utf8.decode(bytes);
  }

  /// Process a binary file (e.g. cover image) into bytes
  ///
  /// For Android: Streams content from SAF URI without loading entire file into memory
  /// For iOS: Reads file from file system
  ///
  /// Returns the file content as bytes.
  /// Throws exceptions on I/O errors or invalid files.
  Future<Uint8List> processBinaryFile(PlatformPath path) async {
    switch (path) {
      case AndroidUriPath(:final uri):
        return await _safStream.readFileBytes(uri);
      case IOSFilePath(path: final pathStr):
        // 1. Fetch just-in-time inside the active security scope.
        final tempPath = await fetchIosFileToTemp(pathStr);
        final tempFile = File(tempPath);
        // 2. Read into memory.
        final bytes = await tempFile.readAsBytes();
        // 3. Clean up the temp copy immediately.
        if (await tempFile.exists()) await tempFile.delete();
        return bytes;
    }
  }

  /// Asks Swift to copy [originalPath] (inside the active security scope)
  /// to a fresh unique file in `NSTemporaryDirectory()` and returns the
  /// resulting absolute temp path.
  ///
  /// iOS only.  On other platforms this is a no-op that returns the original
  /// path unchanged.
  Future<String> fetchIosFileToTemp(String originalPath) async {
    if (!Platform.isIOS) return originalPath;
    final tempPath = await _channel.invokeMethod<String>(
      'fetchIosFile',
      originalPath,
    );
    return tempPath ?? originalPath;
  }

  /// Releases all security-scoped resource accesses held on the native side.
  ///
  /// **Must** be called in the `finally` block of any iOS pick+process
  /// operation to prevent resource leaks.
  Future<void> releaseIosAccess() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod<void>('releaseIosAccess');
    }
  }

  /// Pick a backup directory and return its real filesystem path.
  ///
  /// Android: Invokes the native `pickBackupFolder` channel method which
  ///          presents ACTION_OPEN_DOCUMENT_TREE and converts the SAF tree
  ///          URI to an absolute path so [File] API works directly.
  /// iOS:     Not yet implemented — returns null.
  ///
  /// Returns null if the user cancels or the path cannot be resolved.
  Future<BackupPaths?> pickBackupFolder() async {
    if (Platform.isAndroid) {
      return await _pickBackupFolderAndroid();
    } else if (Platform.isIOS) {
      return await _pickBackupFolderIOS();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  /// Clean up a cached file
  ///
  /// Delegates to [ImportCacheManager.clean]
  Future<void> cleanCache(File cacheFile) async {
    await _cacheManager.clean(cacheFile);
  }

  // ==================== Android Implementation ====================

  /// Android: Pick files using native SAF via MethodChannel
  Future<List<PlatformPath>> _pickFilesAndroid() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pickEpubFiles',
      );

      if (result == null) {
        return [];
      }

      return result
          .whereType<String>()
          .map((uri) => AndroidUriPath(uri))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('Android file picker error: ${e.message}');
      return [];
    }
  }

  /// Android: Pick folder using native SAF with background traversal
  Future<List<PlatformPath>> _pickFolderAndroid() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pickEpubFolder',
      );

      if (result == null) {
        return [];
      }

      return result
          .whereType<String>()
          .map((uri) => AndroidUriPath(uri))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('Android folder picker error: ${e.message}');
      return [];
    }
  }

  Future<BackupPaths?> _pickBackupFolderAndroid() async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'pickBackupFolder',
    );
    if (result == null || result.isEmpty) return null;

    final entries = result.whereType<String>().map((uriString) {
      final decoded = Uri.decodeFull(uriString);
      return (
        displayPath: decoded,
        platformPath: AndroidUriPath(uriString) as PlatformPath,
      );
    }).toList();

    final classified = _classifyBackupFiles(entries);

    if (classified.shelfFile == null) {
      throw Exception(
        'Invalid backup: ${AppStorageConstants.shelfFile} not found',
      );
    }

    final bookPaths = _buildBookPaths(classified.tempBookComponents);
    final shelfUri = Uri.decodeFull(
      (classified.shelfFile! as AndroidUriPath).uri,
    );

    return BackupPaths(
      rootPath: AndroidUriPath(p.dirname(shelfUri)),
      shelfFile: classified.shelfFile!,
      bookPaths: bookPaths,
    );
  }

  // ==================== iOS Implementation ====================

  /// iOS: Pick multiple EPUB files (lazy – security scope retained by Swift).
  Future<List<PlatformPath>> _pickFilesIOS() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pickEpubFiles',
      );
      if (result == null) return [];
      return result
          .whereType<String>()
          .map((path) => IOSFilePath(path))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('iOS file picker error: ${e.message}');
      return [];
    }
  }

  /// iOS: Pick EPUB-containing folder (lazy – security scope retained by Swift).
  Future<List<PlatformPath>> _pickFolderIOS() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pickEpubFolder',
      );
      if (result == null) return [];
      return result
          .whereType<String>()
          .map((path) => IOSFilePath(path))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('iOS folder picker error: ${e.message}');
      return [];
    }
  }

  /// iOS: Pick backup folder and parse its structure (lazy – scope retained).
  Future<BackupPaths?> _pickBackupFolderIOS() async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'pickBackupFolder',
    );
    if (result == null || result.isEmpty) return null;

    final entries = result.whereType<String>().map((pathStr) {
      return (
        displayPath: pathStr,
        platformPath: IOSFilePath(pathStr) as PlatformPath,
      );
    }).toList();

    final classified = _classifyBackupFiles(entries);

    if (classified.shelfFile == null) {
      throw Exception(
        'Invalid backup: ${AppStorageConstants.shelfFile} not found',
      );
    }

    final bookPaths = _buildBookPaths(classified.tempBookComponents);
    final rootPath = IOSFilePath(
      p.dirname((classified.shelfFile! as IOSFilePath).path),
    );

    return BackupPaths(
      rootPath: rootPath,
      shelfFile: classified.shelfFile!,
      bookPaths: bookPaths,
    );
  }

  // ==================== Shared Backup Helpers ====================

  /// Classifies a flat list of backup file entries into shelf / books / covers
  /// / manifests buckets.
  ///
  /// [entries] contains one record per file: [displayPath] is a decoded
  /// absolute path used purely for basename/dirname inspection; [platformPath]
  /// is the opaque handle ([AndroidUriPath] or [IOSFilePath]) stored in the
  /// result.
  static ({
    PlatformPath? shelfFile,
    Map<String, Map<String, PlatformPath>> tempBookComponents,
  }) _classifyBackupFiles(
    List<({String displayPath, PlatformPath platformPath})> entries,
  ) {
    PlatformPath? shelfFile;
    final tempBookComponents = <String, Map<String, PlatformPath>>{};

    for (final entry in entries) {
      final fileName = p.basename(entry.displayPath);
      final parentDirName = p.basename(p.dirname(entry.displayPath));
      if (fileName.isEmpty) continue;

      if (fileName == AppStorageConstants.shelfFile) {
        shelfFile = entry.platformPath;
        continue;
      }

      if (parentDirName == AppStorageConstants.booksDir &&
          fileName.endsWith('.epub')) {
        final hash = fileName.replaceAll('.epub', '');
        tempBookComponents.putIfAbsent(hash, () => {})['epub'] =
            entry.platformPath;
      } else if (parentDirName == AppStorageConstants.manifestsDir &&
          fileName.endsWith('.json')) {
        final hash = fileName.replaceAll('.json', '');
        tempBookComponents.putIfAbsent(hash, () => {})['manifest'] =
            entry.platformPath;
      } else if (parentDirName == AppStorageConstants.coversDir) {
        final extIndex = fileName.lastIndexOf('.');
        if (extIndex != -1) {
          final hash = fileName.substring(0, extIndex);
          tempBookComponents.putIfAbsent(hash, () => {})['cover'] =
              entry.platformPath;
        }
      }
    }

    return (
      shelfFile: shelfFile,
      tempBookComponents: tempBookComponents,
    );
  }

  /// Assembles a [BackupPathsForBook] map from parsed component buckets,
  /// skipping entries that are missing an epub or manifest file.
  static Map<String, BackupPathsForBook> _buildBookPaths(
    Map<String, Map<String, PlatformPath>> components,
  ) {
    final result = <String, BackupPathsForBook>{};
    for (final entry in components.entries) {
      final c = entry.value;
      if (c.containsKey('epub') && c.containsKey('manifest')) {
        result[entry.key] = BackupPathsForBook(
          epubPath: c['epub']!,
          manifestPath: c['manifest']!,
          coverPath: c['cover'],
        );
      } else {
        debugPrint(
          'Warning: Missing epub or manifest for hash ${entry.key}, skipping.',
        );
      }
    }
    return result;
  }

  // ==================== Utility Methods ====================

  /// Get the total size of the import cache
  ///
  /// Useful for displaying cache statistics to users.
  Future<int> getCacheSize() async {
    return await _cacheManager.getCacheSize();
  }

  /// Clear all cached import files
  ///
  /// Use with caution as this removes all temporary import cache.
  Future<void> clearAllCache() async {
    await _cacheManager.clearAll();
  }
}
