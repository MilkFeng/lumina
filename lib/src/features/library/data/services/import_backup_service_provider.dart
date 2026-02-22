import 'package:lumina/src/features/library/data/services/unified_import_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/providers.dart';
import 'import_backup_service.dart';

part 'import_backup_service_provider.g.dart';

/// Provider for [ImportBackupService].
///
/// Injects the raw [Isar] instance directly so the service can call
/// index-based upsert methods (`putByFileHash`, `putByName`) that are not
/// exposed through the higher-level repository layer.
@riverpod
ImportBackupService importBackupService(ImportBackupServiceRef ref) {
  final isar = ref.watch(isarProvider).requireValue;
  final importService = ref.watch(unifiedImportServiceProvider);
  return ImportBackupService(isar: isar, importService: importService);
}
