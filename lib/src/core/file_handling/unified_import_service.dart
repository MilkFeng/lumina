import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lumina/src/core/services/toast_service.dart';
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
    try {
      if (Platform.isAndroid) {
        return await _pickFilesAndroid();
      } else if (Platform.isIOS) {
        return await _pickFilesIOS();
      } else {
        throw UnsupportedError('Platform not supported');
      }
    } catch (e) {
      // Log error but don't throw to maintain graceful degradation
      ToastService.showError('Error picking files: $e');
      return [];
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
    try {
      if (Platform.isAndroid) {
        return await _pickFolderAndroid();
      } else if (Platform.isIOS) {
        return await _pickFolderIOS();
      } else {
        throw UnsupportedError('Platform not supported');
      }
    } catch (e) {
      // Log error but don't throw to maintain graceful degradation
      ToastService.showError('Error picking folder: $e');
      return [];
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
    try {
      if (Platform.isAndroid) {
        return await _pickBackupFolderAndroid();
      } else if (Platform.isIOS) {
        return await _pickBackupFolderIOS();
      } else {
        throw UnsupportedError('Platform not supported');
      }
    } on PlatformException catch (e) {
      ToastService.showError('Backup folder picker error: ${e.message}');
      return null;
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
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pickBackupFolder',
      );

      if (result == null || result.isEmpty) {
        return null;
      }

      PlatformPath? shelfFile;
      final Map<String, Map<String, PlatformPath>> tempBookComponents = {};

      for (final item in result) {
        if (item is! String) continue;

        final uriString = item;
        final platformPath = AndroidUriPath(uriString);

        final decodedUri = Uri.decodeFull(uriString);

        final fileName = p.basename(decodedUri);
        final parentDirName = p.basename(p.dirname(decodedUri));

        if (fileName.isEmpty) continue;

        if (fileName == 'shelf.json') {
          shelfFile = platformPath;
          continue;
        }

        if (parentDirName == 'books' && fileName.endsWith('.epub')) {
          final hash = fileName.replaceAll('.epub', '');
          tempBookComponents.putIfAbsent(hash, () => {})['epub'] = platformPath;
        } else if (parentDirName == 'manifests' && fileName.endsWith('.json')) {
          final hash = fileName.replaceAll('.json', '');
          tempBookComponents.putIfAbsent(hash, () => {})['manifest'] =
              platformPath;
        } else if (parentDirName == 'covers') {
          final extIndex = fileName.lastIndexOf('.');
          if (extIndex != -1) {
            final hash = fileName.substring(0, extIndex);
            tempBookComponents.putIfAbsent(hash, () => {})['cover'] =
                platformPath;
          }
        }
      }

      if (shelfFile == null) {
        ToastService.showError('Invalid backup: shelf.json not found');
        return null;
      }

      final Map<String, BackupPathsForBook> bookPaths = {};

      for (final entry in tempBookComponents.entries) {
        final hash = entry.key;
        final components = entry.value;

        if (components.containsKey('epub') &&
            components.containsKey('manifest')) {
          bookPaths[hash] = BackupPathsForBook(
            epubPath: components['epub']!,
            manifestPath: components['manifest']!,
            coverPath: components['cover'],
          );
        } else {
          debugPrint(
            'Warning: Missing EPUB or manifest file for hash $hash, skipping.',
          );
        }
      }

      final shelfUri = Uri.decodeFull((shelfFile as AndroidUriPath).uri);
      final rootUri = p.dirname(shelfUri);
      final rootPath = AndroidUriPath(rootUri);

      return BackupPaths(
        rootPath: rootPath,
        shelfFile: shelfFile,
        bookPaths: bookPaths,
      );
    } on PlatformException catch (e) {
      ToastService.showError('Failed to pick backup folder: ${e.message}');
      return null;
    } catch (e, st) {
      ToastService.showError('Unexpected error picking backup folder: $e');
      debugPrint('Unexpected error picking backup folder: $e\n$st');
      return null;
    }
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
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pickBackupFolder',
      );
      if (result == null || result.isEmpty) return null;

      PlatformPath? shelfFile;
      final Map<String, Map<String, PlatformPath>> tempBookComponents = {};

      for (final item in result) {
        if (item is! String) continue;

        final pathStr = item;
        final platformPath = IOSFilePath(pathStr);
        final fileName = p.basename(pathStr);
        final parentDirName = p.basename(p.dirname(pathStr));

        if (fileName.isEmpty) continue;

        if (fileName == 'shelf.json') {
          shelfFile = platformPath;
          continue;
        }

        if (parentDirName == 'books' && fileName.endsWith('.epub')) {
          final hash = fileName.replaceAll('.epub', '');
          tempBookComponents.putIfAbsent(hash, () => {})['epub'] = platformPath;
        } else if (parentDirName == 'manifests' && fileName.endsWith('.json')) {
          final hash = fileName.replaceAll('.json', '');
          tempBookComponents.putIfAbsent(hash, () => {})['manifest'] =
              platformPath;
        } else if (parentDirName == 'covers') {
          final extIndex = fileName.lastIndexOf('.');
          if (extIndex != -1) {
            final hash = fileName.substring(0, extIndex);
            tempBookComponents.putIfAbsent(hash, () => {})['cover'] =
                platformPath;
          }
        }
      }

      if (shelfFile == null) {
        ToastService.showError('Invalid backup: shelf.json not found');
        return null;
      }

      final Map<String, BackupPathsForBook> bookPaths = {};
      for (final entry in tempBookComponents.entries) {
        final hash = entry.key;
        final components = entry.value;
        if (components.containsKey('epub') &&
            components.containsKey('manifest')) {
          bookPaths[hash] = BackupPathsForBook(
            epubPath: components['epub']!,
            manifestPath: components['manifest']!,
            coverPath: components['cover'],
          );
        } else {
          debugPrint(
            'Warning: Missing EPUB or manifest for hash $hash, skipping.',
          );
        }
      }

      final rootPath = IOSFilePath(p.dirname((shelfFile as IOSFilePath).path));

      return BackupPaths(
        rootPath: rootPath,
        shelfFile: shelfFile,
        bookPaths: bookPaths,
      );
    } on PlatformException catch (e) {
      ToastService.showError('Failed to pick backup folder: ${e.message}');
      return null;
    } catch (e, st) {
      ToastService.showError('Unexpected error picking backup folder: $e');
      debugPrint('Unexpected error picking backup folder: $e\n$st');
      return null;
    }
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
