// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_cleanup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [StorageCleanupService].
///
/// Wires the app-wide maintenance service to the pieces it cannot know about
/// by itself: the set of hashes the library still references, and the two
/// caches that belong to the import pipeline and the backup exporter.

@ProviderFor(storageCleanupService)
const storageCleanupServiceProvider = StorageCleanupServiceProvider._();

/// Provider for [StorageCleanupService].
///
/// Wires the app-wide maintenance service to the pieces it cannot know about
/// by itself: the set of hashes the library still references, and the two
/// caches that belong to the import pipeline and the backup exporter.

final class StorageCleanupServiceProvider
    extends
        $FunctionalProvider<
          StorageCleanupService,
          StorageCleanupService,
          StorageCleanupService
        >
    with $Provider<StorageCleanupService> {
  /// Provider for [StorageCleanupService].
  ///
  /// Wires the app-wide maintenance service to the pieces it cannot know about
  /// by itself: the set of hashes the library still references, and the two
  /// caches that belong to the import pipeline and the backup exporter.
  const StorageCleanupServiceProvider._()
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
    r'e6230d8cb1c10a58968d02b61a6269cb630da54f';
