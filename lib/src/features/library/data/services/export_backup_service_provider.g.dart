// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_backup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exportBackupServiceHash() =>
    r'6bb6e48bcb00de4b228c41df63c409db21573954';

/// Provider for [ExportBackupService].
///
/// Builds the service by injecting the two required repositories.
/// Because both repositories are synchronous providers, this provider
/// is also synchronous — no [FutureProvider] overhead needed.
///
/// Copied from [exportBackupService].
@ProviderFor(exportBackupService)
final exportBackupServiceProvider =
    AutoDisposeProvider<ExportBackupService>.internal(
  exportBackupService,
  name: r'exportBackupServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exportBackupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ExportBackupServiceRef = AutoDisposeProviderRef<ExportBackupService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
