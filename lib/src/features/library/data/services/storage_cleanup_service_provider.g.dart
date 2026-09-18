// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_cleanup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [StorageCleanupService].

@ProviderFor(storageCleanupService)
final storageCleanupServiceProvider = StorageCleanupServiceProvider._();

/// Provider for [StorageCleanupService].

final class StorageCleanupServiceProvider
    extends
        $FunctionalProvider<
          StorageCleanupService,
          StorageCleanupService,
          StorageCleanupService
        >
    with $Provider<StorageCleanupService> {
  /// Provider for [StorageCleanupService].
  StorageCleanupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageCleanupServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageCleanupServiceHash();

  @$internal
  @override
  $ProviderElement<StorageCleanupService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StorageCleanupService create(Ref ref) {
    return storageCleanupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageCleanupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageCleanupService>(value),
    );
  }
}

String _$storageCleanupServiceHash() =>
    r'f4d44e13bb0942fd36f3e14596e3c12b2e6de85b';
