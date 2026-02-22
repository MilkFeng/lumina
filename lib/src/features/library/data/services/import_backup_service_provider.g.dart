// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_backup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$importBackupServiceHash() =>
    r'51bb3092e44dd368d7ca36eff9f5362237a01562';

/// Provider for [ImportBackupService].
///
/// Injects the raw [Isar] instance directly so the service can call
/// index-based upsert methods (`putByFileHash`, `putByName`) that are not
/// exposed through the higher-level repository layer.
///
/// Copied from [importBackupService].
@ProviderFor(importBackupService)
final importBackupServiceProvider =
    AutoDisposeProvider<ImportBackupService>.internal(
  importBackupService,
  name: r'importBackupServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$importBackupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ImportBackupServiceRef = AutoDisposeProviderRef<ImportBackupService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
