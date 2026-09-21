import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

import '../../../core/platform/file_picker_service.dart';
import '../../../core/platform/import_cache_manager.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/storage/app_storage_constants.dart';
import '../../library/data/services/epub_import_workers.dart';

/// Stages cover drafts in cache and rolls back file changes if persistence fails.
class BookCoverEditService {
  final FilePickerService _picker;
  final ImportCacheManager _cache;

  BookCoverEditService({FilePickerService? picker, ImportCacheManager? cache})
    : _picker = picker ?? FilePickerService(),
      _cache = cache ?? ImportCacheManager();

  Future<Either<String, File?>> pickCover() async {
    try {
      final paths = await _picker.pickImageFile();
      if (paths.isEmpty) return right(null);
      try {
        return await stageCover(await _picker.readBytes(paths.first));
      } finally {
        await _picker.releaseIosAccess();
      }
    } catch (error) {
      return left(error.toString());
    }
  }

  /// Converts every draft with the same JPEG settings used for imported covers.
  Future<Either<String, File?>> stageCover(Uint8List bytes) async {
    File? draft;
    try {
      final jpeg = await ImportWorkers.compressImage(bytes);
      if (jpeg == null) return left('Could not convert the selected image.');
      draft = await _cache.createCacheFile('.jpg');
      await draft.writeAsBytes(jpeg, flush: true);
      return right(draft);
    } catch (error) {
      await discard(draft);
      return left(error.toString());
    }
  }

  /// Keeps the draft for retry and the previous file until the database commits.
  Future<Either<String, int>> saveCover({
    required File draft,
    required String fileHash,
    required Future<Either<String, int>> Function(String relativePath) persist,
  }) async {
    final relativePath = '${AppStorageConstants.coversDir}/$fileHash.jpg';
    final target = File(p.join(AppStorage.documentsPath, relativePath));
    File? backup;
    var replacementStarted = false;
    try {
      await target.parent.create(recursive: true);
      if (await target.exists()) {
        backup = await _cache.createCacheFile('.bak');
        await target.copy(backup.path);
      }
      replacementStarted = true;
      await draft.copy(target.path);
      final result = await persist(relativePath);
      if (result.isLeft()) {
        await _restore(target, backup);
      }
      await discard(backup);
      return result;
    } catch (error) {
      if (replacementStarted) {
        try {
          await _restore(target, backup);
        } catch (restoreError) {
          // Keep the backup available if the filesystem cannot restore it.
          return left('$error; cover rollback failed: $restoreError');
        }
      }
      await discard(backup);
      return left(error.toString());
    }
  }

  Future<void> _restore(File target, File? backup) async {
    if (backup != null) {
      await backup.copy(target.path);
    } else if (await target.exists()) {
      await target.delete();
    }
  }

  /// Cleanup failure must never turn a committed edit into a failed save.
  Future<void> discard(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error) {
      debugPrint('Could not remove cover edit file: $error');
    }
  }
}
