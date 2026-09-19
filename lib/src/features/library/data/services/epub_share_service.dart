import 'dart:io';

import 'package:lumina/src/core/storage/app_storage.dart';

/// Creates and removes the temporary `.epub` copies handed to the platform
/// share sheet.
///
/// Split out of the former storage-cleanup service because sharing a book is a
/// library concern, while orphan-file cleanup is app-wide maintenance.
class EpubShareService {
  static const String _kShareDir = 'share';

  /// Directory holding the temporary share copies.
  Directory get _shareDir => Directory('${AppStorage.tempPath}$_kShareDir');

  /// Copies [sourceFile] into the share directory under a sanitised version of
  /// [title] and returns the temporary copy.
  ///
  /// The caller owns the returned file and should delete it after sharing;
  /// [cleanShareFiles] removes anything left behind.
  Future<File> saveTempFileForSharing(File sourceFile, String title) async {
    final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final tempDir = _shareDir;
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final tempFile = File('${tempDir.path}/$sanitizedTitle.epub');
    await sourceFile.copy(tempFile.path);
    return tempFile;
  }

  /// Deletes the whole share directory, if it exists.
  Future<void> cleanShareFiles() async {
    final dir = _shareDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
