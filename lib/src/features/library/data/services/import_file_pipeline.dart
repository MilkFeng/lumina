import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:lumina/src/core/platform/platform.dart';

/// Domain-free pipeline that turns a picked [PlatformPath] into a local file.
///
/// Two primitives, composed:
/// - [FilePickerService] obtains handles and reads through them (SAF URIs on
///   Android, security-scoped paths on iOS).
/// - [ImportCacheManager] writes those handles into the import-cache directory.
///
/// Everything above this layer — what a file *means*, whether it needs a
/// SHA-256 dedup key, where it should finally live — belongs to the feature
/// that requested it.
class ImportFilePipeline {
  final FilePickerService _picker;
  final ImportCacheManager _cache;

  ImportFilePipeline({
    required FilePickerService picker,
    required ImportCacheManager cache,
  }) : _picker = picker,
       _cache = cache;

  /// Builds a pipeline whose cache manager knows how to ask the picker for
  /// iOS copy-on-demand. Prefer this over wiring the two by hand.
  factory ImportFilePipeline.from(FilePickerService picker) {
    return ImportFilePipeline(
      picker: picker,
      cache: ImportCacheManager(iosFetchCallback: picker.fetchIosFileToTemp),
    );
  }

  // ===========================================================================
  // Reading
  // ===========================================================================

  /// Reads [path] fully into memory.
  Future<Uint8List> readBytes(PlatformPath path) => _picker.readBytes(path);

  /// Reads [path] as UTF-8 text (e.g. a `shelf.json` or manifest payload).
  Future<String> readText(PlatformPath path) => _picker.readPlainFile(path);

  // ===========================================================================
  // Caching
  // ===========================================================================

  /// Copies [path] into the import cache and returns the cached file.
  ///
  /// The extension of the original file is preserved. The caller owns the
  /// returned file and must release it with [cleanCache].
  Future<File> cacheFile(PlatformPath path) => _cache.writeToCache(path);

  /// Copies [path] into the import cache and returns it together with its
  /// SHA-256 digest, which callers use as the deduplication key.
  Future<ImportableEpub> cacheFileWithHash(PlatformPath path) async {
    final cacheFile = await _cache.writeToCache(path);
    try {
      final hash = await hashFile(cacheFile);
      return ImportableEpub(
        cacheFile: cacheFile,
        hash: hash,
        originalName: path.name,
      );
    } catch (_) {
      // Never leave a half-registered cache file behind on hashing failure.
      await _cache.clean(cacheFile);
      rethrow;
    }
  }

  /// Deletes a file previously produced by [cacheFile] or [cacheFileWithHash].
  Future<void> cleanCache(File cacheFile) => _cache.clean(cacheFile);

  /// Empties the whole import cache. Safe to call at the end of a batch.
  Future<void> clearCache() => _cache.clearAll();

  // ===========================================================================
  // iOS security scope
  // ===========================================================================

  /// Releases the security-scoped resources the native picker holds.
  ///
  /// iOS only; a no-op elsewhere. Must run in a `finally` block once a whole
  /// pick → read batch is finished, otherwise the scope leaks.
  Future<void> releaseIosAccess() => _picker.releaseIosAccess();

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// SHA-256 digest of [file], read as a stream so that large EPUBs never sit
  /// in memory all at once.
  static Future<String> hashFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
