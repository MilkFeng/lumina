import 'package:lumina/src/features/library/data/services/export_backup_service.dart';
import 'package:lumina/src/features/library/data/services/export_backup_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repositories/shelf_book_repository_provider.dart';
import 'storage_cleanup_service.dart';

part 'storage_cleanup_service_provider.g.dart';

/// Provider for [StorageCleanupService].
@riverpod
StorageCleanupService storageCleanupService(StorageCleanupServiceRef ref) {
  final shelfBookRepo = ref.watch(shelfBookRepositoryProvider);
  final ExportBackupService exportBackupService = ref.watch(
    exportBackupServiceProvider,
  );

  return StorageCleanupService(
    shelfBookRepo: shelfBookRepo,
    exportBackupService: exportBackupService,
  );
}
