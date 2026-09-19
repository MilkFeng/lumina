import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/platform/platform.dart';
import 'package:lumina/src/core/storage/app_storage_constants.dart';
import 'package:path/path.dart' as p;

/// File handles for the three components a single backed-up book can have.
///
/// [coverPath] is nullable because a cover is optional in a backup.
class BackupPathsForBook {
  final PlatformPath epubPath;
  final PlatformPath manifestPath;
  final PlatformPath? coverPath;

  const BackupPathsForBook({
    required this.epubPath,
    required this.manifestPath,
    required this.coverPath,
  });
}

/// The resolved structure of a picked backup folder.
class BackupPaths {
  /// Root folder of the backup.
  final PlatformPath rootPath;

  /// The `shelf.json` file holding groups and book metadata.
  final PlatformPath shelfFile;

  /// Per-book component handles, keyed by book hash.
  final Map<String, BackupPathsForBook> bookPaths;

  const BackupPaths({
    required this.rootPath,
    required this.shelfFile,
    required this.bookPaths,
  });
}

/// Turns the flat file list returned by the platform picker into the structured
/// [BackupPaths] that a restore needs.
///
/// This is the only place in the app that knows the backup layout:
/// ```
/// lumina-backup-{timestamp}/
///   ├── books/         ← {hash}.epub
///   ├── covers/        ← {hash}.{ext}
///   ├── manifests/     ← {hash}.json
///   └── shelf.json
/// ```
/// The native layer intentionally returns an unclassified list, and
/// [FilePickerService] passes it through untouched, so this layout stays a
/// Flutter-side concern.
class BackupFolderResolver {
  final FilePickerService _picker;

  const BackupFolderResolver({required FilePickerService picker})
    : _picker = picker;

  /// Picks a backup folder and resolves its structure.
  ///
  /// Returns `null` when the user cancels the picker or the native call fails.
  /// Throws when the folder was picked but does not look like a Lumina backup
  /// (no `shelf.json`), so that callers can surface a real error instead of
  /// silently doing nothing.
  ///
  /// On iOS the returned handles are only valid until [FilePickerService
  /// .releaseIosAccess] is called.
  Future<BackupPaths?> pickAndResolve() async {
    final files = await _picker.pickFolderFiles();
    if (files.isEmpty) return null;
    return resolve(files);
  }

  /// Classifies a flat list of backup-file handles into [BackupPaths].
  ///
  /// Throws a [FormatException] when `shelf.json` is absent — proof that the
  /// picked folder is not a Lumina backup. Books lacking either an EPUB or a
  /// manifest are dropped with a warning, since neither can be restored on its
  /// own.
  BackupPaths resolve(List<PlatformPath> files) {
    PlatformPath? shelfFile;
    final components = <String, Map<String, PlatformPath>>{};

    for (final file in files) {
      // `path` is a plain string on iOS; on Android `name` already unwraps the
      // SAF document id, and dirname() still works on the decoded URI.
      final fileName = file.name;
      if (fileName.isEmpty) continue;

      if (fileName == AppStorageConstants.shelfFile) {
        shelfFile = file;
        continue;
      }

      final parentDirName = _parentDirName(file);
      if (parentDirName == AppStorageConstants.booksDir) {
        if (_isEpub(fileName)) {
          components.putIfAbsent(_stem(fileName), () => {})['epub'] = file;
        }
      } else if (parentDirName == AppStorageConstants.manifestsDir) {
        if (fileName.endsWith('.json')) {
          components.putIfAbsent(_stem(fileName), () => {})['manifest'] = file;
        }
      } else if (parentDirName == AppStorageConstants.coversDir) {
        final extIndex = fileName.lastIndexOf('.');
        if (extIndex > 0) {
          components.putIfAbsent(
            fileName.substring(0, extIndex),
            () => {},
          )['cover'] = file;
        }
      }
    }

    if (shelfFile == null) {
      throw FormatException(
        'Invalid backup: ${AppStorageConstants.shelfFile} not found',
      );
    }

    return BackupPaths(
      rootPath: _parentPath(shelfFile),
      shelfFile: shelfFile,
      bookPaths: _buildBookPaths(components),
    );
  }

  /// Keeps only the hashes that have both an EPUB and a manifest.
  Map<String, BackupPathsForBook> _buildBookPaths(
    Map<String, Map<String, PlatformPath>> components,
  ) {
    final result = <String, BackupPathsForBook>{};
    for (final entry in components.entries) {
      final c = entry.value;
      final epub = c['epub'];
      final manifest = c['manifest'];
      if (epub != null && manifest != null) {
        result[entry.key] = BackupPathsForBook(
          epubPath: epub,
          manifestPath: manifest,
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

  // ---------------------------------------------------------------------------
  // Path helpers
  // ---------------------------------------------------------------------------

  static bool _isEpub(String fileName) =>
      fileName.toLowerCase().endsWith('.epub');

  static String _stem(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /// Directory name that directly contains [file].
  static String _parentDirName(PlatformPath file) =>
      p.basename(p.dirname(file.displayPath));

  /// The parent folder of [file], as a [PlatformPath].
  static PlatformPath _parentPath(PlatformPath file) {
    final parent = p.dirname(file.displayPath);
    return switch (file) {
      AndroidUriPath() => AndroidUriPath(parent),
      IOSFilePath() => IOSFilePath(parent),
    };
  }
}
