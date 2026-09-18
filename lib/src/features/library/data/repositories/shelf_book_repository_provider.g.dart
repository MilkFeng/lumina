// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelf_book_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for ShelfBookRepository
/// Repository for managing shelf book CRUD operations

@ProviderFor(shelfBookRepository)
final shelfBookRepositoryProvider = ShelfBookRepositoryProvider._();

/// Provider for ShelfBookRepository
/// Repository for managing shelf book CRUD operations

final class ShelfBookRepositoryProvider
    extends
        $FunctionalProvider<
          ShelfBookRepository,
          ShelfBookRepository,
          ShelfBookRepository
        >
    with $Provider<ShelfBookRepository> {
  /// Provider for ShelfBookRepository
  /// Repository for managing shelf book CRUD operations
  ShelfBookRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shelfBookRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shelfBookRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShelfBookRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShelfBookRepository create(Ref ref) {
    return shelfBookRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShelfBookRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShelfBookRepository>(value),
    );
  }
}

String _$shelfBookRepositoryHash() =>
    r'2da707ce7e52043725129b0303b51c13dce98aa1';
