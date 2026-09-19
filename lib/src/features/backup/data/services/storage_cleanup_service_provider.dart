import 'package:lumina/src/core/platform/import_cache_manager.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:lumina/src/core/services/storage_cleanup_service.dart';
import 'package:lumina/src/features/backup/data/services/export_backup_service_provider.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_cleanup_service_provider.g.dart';

/// Provider for [StorageCleanupService].
///
/// Wires the app-wide maintenance service to what it cannot know by itself:
/// the set of hashes the library still references, and the two caches that
/// belong to the import pipeline and the backup exporter.
///
/// It lives in the backup feature because it is the only feature that needs to
/// clear the backup export cache; the library shelf repository it also reads is
/// reached through the normal `library → backup` dependency direction.
@riverpod
StorageCleanupService storageCleanupService(Ref ref) {
  final shelfBookRepo = ref.watch(shelfBookRepositoryProvider);
  final exportBackupService = ref.watch(exportBackupServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return StorageCleanupService(
    sharedPreferences: prefs,
    validHashes: shelfBookRepo.getAllFileHashes,
    clearImportCache: ImportCacheManager().clearAll,
    clearExportCache: exportBackupService.clearCache,
  );
}
