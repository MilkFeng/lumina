import 'dart:io';
import 'package:flutter/services.dart';
import 'platform_path.dart';
import 'importable_epub.dart';
import 'import_cache_manager.dart';

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
  static const String _channelName = 'com.lumina.reader/native_picker';
  static const MethodChannel _channel = MethodChannel(_channelName);

  final ImportCacheManager _cacheManager;

  UnifiedImportService({ImportCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? ImportCacheManager();

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
      // ignore: avoid_print
      print('Error picking files: $e');
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
      // ignore: avoid_print
      print('Error picking folder: $e');
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
      // ignore: avoid_print
      print('Android file picker error: ${e.message}');
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
      // ignore: avoid_print
      print('Android folder picker error: ${e.message}');
      return [];
    }
  }

  // ==================== iOS Implementation ====================

  /// iOS: Pick files - currently unsupported without file_picker package
  ///
  /// To support iOS, either:
  /// 1. Implement native iOS file picker via MethodChannel
  /// 2. Add file_picker package back
  /// 3. Use UIDocumentPickerViewController via platform channel
  Future<List<PlatformPath>> _pickFilesIOS() async {
    // ignore: avoid_print
    print(
      'iOS file picker not implemented. Add file_picker package or implement native picker.',
    );
    return [];
  }

  /// iOS: Pick folder - currently unsupported without file_picker package
  Future<List<PlatformPath>> _pickFolderIOS() async {
    // ignore: avoid_print
    print(
      'iOS folder picker not implemented. Add file_picker package or implement native picker.',
    );
    return [];
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
