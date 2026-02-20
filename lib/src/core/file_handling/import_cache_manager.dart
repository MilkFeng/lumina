import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'platform_path.dart';
import 'importable_epub.dart';

/// Manages the import cache directory and file operations
///
/// Handles platform-specific file I/O:
/// - Android: Uses SAF streams to read content URIs without blocking main thread
/// - iOS: Uses standard file system operations
///
/// All imported files are cached in the app's document directory under
/// 'import_cache' and hashed using SHA-256 for deduplication.
class ImportCacheManager {
  static const String _importCacheDir = 'import_cache';
  final _safStream = SafStream();

  Directory? _cacheDirectory;

  /// Gets the import cache directory, creating it if necessary
  Future<Directory> _getCacheDirectory() async {
    if (_cacheDirectory != null) {
      return _cacheDirectory!;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(docDir.path, _importCacheDir));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    _cacheDirectory = cacheDir;
    return cacheDir;
  }

  /// Creates a cached copy of the file and calculates its SHA-256 hash
  ///
  /// For [AndroidUriPath]: Streams content from SAF URI to cache file
  /// For [IOSFilePath]: Directly copies file to cache
  ///
  /// Returns an [ImportableEpub] containing the cached file and its hash.
  /// The cache file is created with a temporary name and can be renamed later
  /// based on the hash.
  Future<ImportableEpub> createCacheAndHash(PlatformPath platformPath) async {
    final cacheDir = await _getCacheDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempCachePath = path.join(cacheDir.path, 'temp_$timestamp.epub');
    final tempCacheFile = File(tempCachePath);

    switch (platformPath) {
      case AndroidUriPath(:final uri):
        await _streamAndHashFromSAF(uri, tempCacheFile);
      case IOSFilePath(:final path):
        await _copyAndHashFromFileSystem(path, tempCacheFile);
    }

    // Calculate hash of the cached file
    final hash = await _calculateFileHash(tempCacheFile);

    return ImportableEpub(cacheFile: tempCacheFile, hash: hash);
  }

  /// Streams content from Android SAF URI to cache file
  ///
  /// Uses saf_stream package to read from content:// URIs without
  /// blocking the main thread or causing ANRs.
  Future<void> _streamAndHashFromSAF(String uri, File targetFile) async {
    try {
      // Open stream from SAF URI
      final stream = await _safStream.readFileStream(uri, start: 0);

      // Stream to target file - IMPORTANT: await addStream before closing
      final sink = targetFile.openWrite();
      await sink.addStream(stream);
      await sink.close();
    } catch (e) {
      // Clean up on error
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      rethrow;
    }
  }

  /// Copies file from iOS file system to cache
  ///
  /// Uses standard Dart file copy for iOS file paths.
  Future<void> _copyAndHashFromFileSystem(
    String sourcePath,
    File targetFile,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('Source file does not exist', sourcePath);
      }

      await sourceFile.copy(targetFile.path);
    } catch (e) {
      // Clean up on error
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      rethrow;
    }
  }

  /// Calculates SHA-256 hash of a file
  ///
  /// Reads the file in chunks to avoid memory issues with large files.
  Future<String> _calculateFileHash(File file) async {
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  /// Safely deletes a cache file
  ///
  /// Checks if the file exists before attempting deletion.
  /// Does not throw if the file doesn't exist.
  Future<void> clean(File cacheFile) async {
    try {
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
    } catch (e) {
      // Log error but don't throw to avoid interrupting cleanup operations
      // In production, you might want to log this to a logging service
      // ignore: avoid_print
      print('Warning: Failed to delete cache file ${cacheFile.path}: $e');
    }
  }

  /// Clears all files in the import cache directory
  ///
  /// Useful for cleanup operations or debugging.
  /// Use with caution as this will remove all cached import files.
  Future<void> clearAll() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to clear import cache: $e');
    }
  }

  /// Gets the size of the import cache directory in bytes
  ///
  /// Useful for displaying cache usage to users.
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
