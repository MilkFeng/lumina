import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lumina/src/features/library/data/repositories/book_manifest_repository_provider.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'export_backup_service.dart';

part 'export_backup_service_provider.g.dart';

/// Provider for [ExportBackupService].
///
/// Builds the service by injecting the two required repositories.
/// Because both repositories are synchronous providers, this provider
/// is also synchronous — no [FutureProvider] overhead needed.
@riverpod
ExportBackupService exportBackupService(Ref ref) {
  final shelfBookRepo = ref.watch(shelfBookRepositoryProvider);
  final manifestRepo = ref.watch(bookManifestRepositoryProvider);

  return ExportBackupService(
    shelfBookRepo: shelfBookRepo,
    manifestRepo: manifestRepo,
  );
}
