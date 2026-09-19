// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_backup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ImportBackupService].
///
/// Injects the platform picker (for iOS security-scope release) and the import
/// pipeline (for reading and caching backup payloads).

@ProviderFor(importBackupService)
const importBackupServiceProvider = ImportBackupServiceProvider._();

/// Provider for [ImportBackupService].
///
/// Injects the platform picker (for iOS security-scope release) and the import
/// pipeline (for reading and caching backup payloads).

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
  /// Injects the platform picker (for iOS security-scope release) and the import
  /// pipeline (for reading and caching backup payloads).
  const ImportBackupServiceProvider._()
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
    r'fda6bcb43138bba77b5e0ae545341e37ff3fc19a';
