import 'dart:convert';
import 'dart:io';

import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/core/storage/app_storage_constants.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Scans on-disk storage and removes files that no longer have a matching
/// record.
///
/// This is app-level maintenance, so it lives in `core/`. It receives the
/// pieces it cannot know about through its constructor — the set of hashes
/// that are still valid, and the cache-clearing callbacks — instead of
/// importing the features that own them. That keeps `core` free of
/// `features/` imports.
class StorageCleanupService {
  /// SharedPreferences key under which the fonts feature persists its list of
  /// imported font file names.
  static const String kImportedFontsPrefsKey = 'imported_fonts';

  final SharedPreferences _prefs;
  final Future<Set<String>> Function() _validHashes;
  final Future<void> Function() _clearImportCache;
  final Future<void> Function() _clearExportCache;

  StorageCleanupService({
    required SharedPreferences sharedPreferences,
    required Future<Set<String>> Function() validHashes,
    required Future<void> Function() clearImportCache,
    required Future<void> Function() clearExportCache,
  }) : _prefs = sharedPreferences,
       _validHashes = validHashes,
       _clearImportCache = clearImportCache,
       _clearExportCache = clearExportCache;

  /// Empties the import cache and the backup export cache.
  Future<void> cleanCacheFiles() async {
    await _clearExportCache();
    await _clearImportCache();
  }

  /// Deletes every `books/` and `covers/` file whose hash is no longer in the
  /// database.
  ///
  /// Returns the total number of files deleted.
  Future<int> cleanOrphanFiles() async {
    final validHashes = await _validHashes();

    int deletedCount = 0;
    deletedCount += await _cleanDirectory(
      p.join(AppStorage.documentsPath, AppStorageConstants.booksDir),
      validHashes,
    );
    deletedCount += await _cleanDirectory(
      p.join(AppStorage.documentsPath, AppStorageConstants.coversDir),
      validHashes,
    );
    return deletedCount;
  }

  /// Deletes every `fonts/` file whose name is absent from the persisted font
  /// list ([kImportedFontsPrefsKey]).
  ///
  /// Returns the total number of files deleted.
  Future<int> cleanOrphanFontFiles() async {
    return _cleanDirectory(
      p.join(AppStorage.documentsPath, AppStorageConstants.fontsDir),
      _importedFontFileNames(),
      withExtension: true,
    );
  }

  /// Reads the persisted font file names; malformed JSON means "no font is
  /// valid", which turns every font file into an orphan.
  Set<String> _importedFontFileNames() {
    final jsonStr = _prefs.getString(kImportedFontsPrefsKey);
    if (jsonStr == null) return const <String>{};
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.whereType<String>().toSet();
    } catch (_) {
      return const <String>{};
    }
  }

  /// Iterates [dirPath], deletes any [File] whose name (without extension)
  /// is absent from [validFileNames], and returns the number of files removed.
  Future<int> _cleanDirectory(
    String dirPath,
    Set<String> validFileNames, {
    bool withExtension = false,
  }) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;

    int deleted = 0;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final nameWithoutExt = p.basenameWithoutExtension(entity.path);
      final nameWithExt = p.basename(entity.path);
      final isValid = withExtension
          ? validFileNames.contains(nameWithExt)
          : validFileNames.contains(nameWithoutExt);
      if (!isValid) {
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
