// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_backup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ImportBackupService].
///
/// Wires the repository layer and the unified import service together; all
/// persistence goes through the repositories.

@ProviderFor(importBackupService)
final importBackupServiceProvider = ImportBackupServiceProvider._();

/// Provider for [ImportBackupService].
///
/// Wires the repository layer and the unified import service together; all
/// persistence goes through the repositories.

final class ImportBackupServiceProvider
    extends
        $FunctionalProvider<
          ImportBackupService,
          ImportBackupService,
          ImportBackupService
        >
    with $Provider<ImportBackupService> {
  /// Provider for [ImportBackupService].
  ///
  /// Wires the repository layer and the unified import service together; all
  /// persistence goes through the repositories.
  ImportBackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importBackupServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importBackupServiceHash();

  @$internal
  @override
  $ProviderElement<ImportBackupService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImportBackupService create(Ref ref) {
    return importBackupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportBackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportBackupService>(value),
    );
  }
}

String _$importBackupServiceHash() =>
    r'7c62909bc901d1b6c6fcb774c3a2c225a90f249f';
