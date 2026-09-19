import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/widgets/progress_dialog.dart';
import 'package:lumina/src/features/backup/data/services/backup_folder_resolver.dart';
import 'package:lumina/src/features/backup/data/services/import_backup_service_provider.dart';
import 'package:lumina/src/features/library/application/bookshelf_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_notifier.g.dart';

/// Drives backup restore.
///
/// Restore lives here rather than on `LibraryNotifier` so that the library
/// feature does not have to depend on the backup feature; the dependency runs
/// the other way round, exactly once, through `bookshelfProvider`.
///
/// Must stay alive: [restoreFromBackup] is a generator that keeps using `ref`
/// across many async gaps, and an `autoDispose` provider would be torn down as
/// soon as no widget is listening — see `LibraryNotifier` for the same
/// reasoning.
@Riverpod(keepAlive: true)
class BackupNotifier extends _$BackupNotifier {
  @override
  void build() {}

  /// Replaces the whole library with the one stored in [backupPaths].
  ///
  /// The current library is erased by `ImportBackupService.restoreLibrary`
  /// before the backup is applied, so the caller is responsible for asking the
  /// user to confirm first. The stream ends with either an `ImportSuccess` or
  /// an `ImportFailure` progress event; the shelf is reloaded afterwards in
  /// both cases so the UI never keeps showing deleted books.
  Stream<ProgressLog> restoreFromBackup(BackupPaths backupPaths) async* {
    yield ProgressLog(
      'Starting restore from folder: ${backupPaths.rootPath}',
      ProgressLogType.info,
    );

    final importService = ref.read(importBackupServiceProvider);

    try {
      yield* importService.restoreLibrary(backupPaths);
    } catch (e) {
      debugPrint('Restore from folder error: $e');
      yield ProgressLog(
        'Failed to restore from folder: $e',
        ProgressLogType.error,
      );
    }

    yield ProgressLog(
      'Restore from folder finished. Refreshing library...',
      ProgressLogType.info,
    );
    await ref.read(bookshelfProvider.notifier).refresh();
  }
}
