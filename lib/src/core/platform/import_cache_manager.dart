import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:path/path.dart' as path;
import 'package:saf_stream/saf_stream.dart';

import 'platform_path.dart';

/// Copies platform files into the app's import-cache directory.
///
/// Covers only the mechanics of getting bytes out of a [PlatformPath] and into
/// a real file on internal storage:
/// - Android: streams from the `content://` URI through `saf_stream`, so large
///   files never block the platform thread.
/// - iOS: delegates to a copy-on-demand callback that the native picker runs
///   while the security-scoped resource is still open, then moves the result
///   into place (an O(1) rename on the same volume).
///
/// Hashing, deduplication and the decision of what a cached file *means* are
/// deliberately left to the feature layers.
class ImportCacheManager {
  static const String _importCacheDir = 'import_cache';

  final _safStream = SafStream();

  /// Optional callback used on iOS for copy-on-demand.
  ///
  /// When set, the iOS branch of [writeToCache] delegates to this instead of
  /// reading the security-scoped file directly. This allows Swift to copy the
  /// file inside the still-open security scope and return a plain temp path
  /// that Dart can then rename into the cache directory in O(1) time.
  final Future<String> Function(String)? _iosFetchCallback;

  Directory? _cacheDirectory;

  ImportCacheManager({Future<String> Function(String)? iosFetchCallback})
    : _iosFetchCallback = iosFetchCallback;

  /// Gets the import cache directory, creating it if necessary
  Future<Directory> _getCacheDirectory() async {
    if (_cacheDirectory != null) {
      return _cacheDirectory!;
    }

    final cacheDir = Directory(
      path.join(AppStorage.tempPath, _importCacheDir),
    );

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    _cacheDirectory = cacheDir;
    return cacheDir;
  }

  /// Copies [platformPath] into the import cache and returns the cached file.
  ///
  /// The original file extension is preserved so that callers can hand the
  /// result to the right consumer (`.epub` to the parser, `.ttf` to the fonts
  /// directory). Callers own the returned file and must delete it via [clean]
  /// when they are done with it.
  ///
  /// Throws on I/O errors. A partially written cache file is removed before
  /// the exception propagates.
  Future<File> writeToCache(PlatformPath platformPath) async {
    final cacheDir = await _getCacheDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = platformPath.name;
    final ext = _extensionOf(originalName);
    final target = File(path.join(cacheDir.path, 'temp_$timestamp$ext'));

    switch (platformPath) {
      case AndroidUriPath(:final uri):
        await _streamFromSaf(uri, target);
      case IOSFilePath(path: final originalPath):
        final fetchCallback = _iosFetchCallback;
        if (fetchCallback != null) {
          // Copy-on-demand: Swift copies the security-scoped file to a temp
          // location, then we rename it into the cache directory (O(1)).
          final tempPath = await fetchCallback(originalPath);
          await _moveFromFileSystem(tempPath, target);
        } else {
          // Fallback when no callback was provided (e.g. in unit tests).
          await _copyFromFileSystem(originalPath, target);
        }
    }

    return target;
  }

  /// Extension of [fileName] including the leading dot, or `''` when it has
  /// none.
  static String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(dotIndex) : '';
  }

  /// Streams content from an Android SAF URI to [targetFile].
  ///
  /// Uses the `saf_stream` package to read from `content://` URIs without
  /// blocking the main thread or causing ANRs.
  Future<void> _streamFromSaf(String uri, File targetFile) async {
    try {
      final stream = await _safStream.readFileStream(uri, start: 0);

      // Stream to target file - IMPORTANT: await addStream before closing.
      final sink = targetFile.openWrite();
      await sink.addStream(stream);
      await sink.close();
    } catch (e) {
      await _deleteQuietly(targetFile);
      rethrow;
    }
  }

  /// Copies a plain file-system path (iOS) to [targetFile].
  Future<void> _copyFromFileSystem(String sourcePath, File targetFile) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('Source file does not exist', sourcePath);
      }

      await sourceFile.copy(targetFile.path);
    } catch (e) {
      await _deleteQuietly(targetFile);
      rethrow;
    }
  }

  /// Moves [srcPath] to [targetFile] using a rename when possible (O(1) on the
  /// same APFS volume), otherwise falls back to copy + delete.
  ///
  /// Used for the iOS copy-on-demand path where Swift has already placed a
  /// fresh copy in `NSTemporaryDirectory()`.
  Future<void> _moveFromFileSystem(String srcPath, File targetFile) async {
    final srcFile = File(srcPath);
    try {
      // Prefer atomic rename (O(1)).
      await srcFile.rename(targetFile.path);
    } on FileSystemException {
      // Cross-device move: copy then delete.
      try {
        await srcFile.copy(targetFile.path);
      } catch (e) {
        await _deleteQuietly(targetFile);
        rethrow;
      }
      try {
        if (await srcFile.exists()) await srcFile.delete();
      } catch (_) {
        // Non-fatal: the OS will eventually reclaim the temp file.
      }
    }
  }

  /// Deletes [file] if it exists, swallowing failures.
  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Nothing useful to do: we are already unwinding from a failure.
    }
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
      // Log error but don't throw to avoid interrupting cleanup operations.
      debugPrint('Warning: Failed to delete cache file ${cacheFile.path}: $e');
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
      debugPrint('Warning: Failed to clear import cache: $e');
    }
  }
}
