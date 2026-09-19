import 'package:lumina/src/core/platform/provider.dart';
import 'package:lumina/src/features/library/data/repositories/book_manifest_repository_provider.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'package:lumina/src/features/library/data/services/import_file_pipeline_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'import_backup_service.dart';

part 'import_backup_service_provider.g.dart';

/// Provider for [ImportBackupService].
///
/// Injects the platform picker (for iOS security-scope release) and the import
/// pipeline (for reading and caching backup payloads).
@riverpod
ImportBackupService importBackupService(Ref ref) {
  final shelfBookRepo = ref.watch(shelfBookRepositoryProvider);
  final manifestRepo = ref.watch(bookManifestRepositoryProvider);

  return ImportBackupService(
    shelfBookRepository: shelfBookRepo,
    bookManifestRepository: manifestRepo,
    picker: ref.watch(filePickerProvider),
    pipeline: ref.watch(importFilePipelineProvider),
  );
}
