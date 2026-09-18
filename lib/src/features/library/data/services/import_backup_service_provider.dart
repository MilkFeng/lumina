import 'package:lumina/src/features/library/data/repositories/book_manifest_repository_provider.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'package:lumina/src/features/library/data/services/unified_import_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'import_backup_service.dart';

part 'import_backup_service_provider.g.dart';

/// Provider for [ImportBackupService].
///
/// Wires the repository layer and the unified import service together; all
/// persistence goes through the repositories.
@riverpod
ImportBackupService importBackupService(Ref ref) {
  final shelfBookRepo = ref.watch(shelfBookRepositoryProvider);
  final manifestRepo = ref.watch(bookManifestRepositoryProvider);

  final importService = ref.watch(unifiedImportServiceProvider);
  return ImportBackupService(
    shelfBookRepository: shelfBookRepo,
    bookManifestRepository: manifestRepo,
    importService: importService,
  );
}
