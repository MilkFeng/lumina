// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_manifest_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for BookManifestRepository
/// Repository for managing book manifest CRUD operations

@ProviderFor(bookManifestRepository)
final bookManifestRepositoryProvider = BookManifestRepositoryProvider._();

/// Provider for BookManifestRepository
/// Repository for managing book manifest CRUD operations

final class BookManifestRepositoryProvider
    extends
        $FunctionalProvider<
          BookManifestRepository,
          BookManifestRepository,
          BookManifestRepository
        >
    with $Provider<BookManifestRepository> {
  /// Provider for BookManifestRepository
  /// Repository for managing book manifest CRUD operations
  BookManifestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookManifestRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookManifestRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookManifestRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookManifestRepository create(Ref ref) {
    return bookManifestRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookManifestRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookManifestRepository>(value),
    );
  }
}

String _$bookManifestRepositoryHash() =>
    r'd679538b9a291ecf7f9595b8872d46b3604f4454';
