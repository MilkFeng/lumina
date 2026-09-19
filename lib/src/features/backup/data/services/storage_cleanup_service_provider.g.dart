// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_cleanup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [StorageCleanupService].
///
/// Wires the app-wide maintenance service to what it cannot know by itself:
/// the set of hashes the library still references, and the two caches that
/// belong to the import pipeline and the backup exporter.
///
/// It lives in the backup feature because it is the only feature that needs to
/// clear the backup export cache; the library shelf repository it also reads is
/// reached through the normal `library → backup` dependency direction.

@ProviderFor(storageCleanupService)
const storageCleanupServiceProvider = StorageCleanupServiceProvider._();

/// Provider for [StorageCleanupService].
///
/// Wires the app-wide maintenance service to what it cannot know by itself:
/// the set of hashes the library still references, and the two caches that
/// belong to the import pipeline and the backup exporter.
///
/// It lives in the backup feature because it is the only feature that needs to
/// clear the backup export cache; the library shelf repository it also reads is
/// reached through the normal `library → backup` dependency direction.

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
  /// Wires the app-wide maintenance service to what it cannot know by itself:
  /// the set of hashes the library still references, and the two caches that
  /// belong to the import pipeline and the backup exporter.
  ///
  /// It lives in the backup feature because it is the only feature that needs to
  /// clear the backup export cache; the library shelf repository it also reads is
  /// reached through the normal `library → backup` dependency direction.
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
    r'9671dd0fc7d97df63a19347b2badbf1d8d8078ea';
