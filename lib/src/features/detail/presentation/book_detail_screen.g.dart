// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_detail_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookDetailHash() => r'd11c9ed01a0e9657c4bbd9caedc2cf25aea28eb2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider to fetch a single book by file hash
///
/// Copied from [bookDetail].
@ProviderFor(bookDetail)
const bookDetailProvider = BookDetailFamily();

/// Provider to fetch a single book by file hash
///
/// Copied from [bookDetail].
class BookDetailFamily extends Family<AsyncValue<ShelfBook?>> {
  /// Provider to fetch a single book by file hash
  ///
  /// Copied from [bookDetail].
  const BookDetailFamily();

  /// Provider to fetch a single book by file hash
  ///
  /// Copied from [bookDetail].
  BookDetailProvider call(
    String fileHash,
  ) {
    return BookDetailProvider(
      fileHash,
    );
  }

  @override
  BookDetailProvider getProviderOverride(
    covariant BookDetailProvider provider,
  ) {
    return call(
      provider.fileHash,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookDetailProvider';
}

/// Provider to fetch a single book by file hash
///
/// Copied from [bookDetail].
class BookDetailProvider extends AutoDisposeFutureProvider<ShelfBook?> {
  /// Provider to fetch a single book by file hash
  ///
  /// Copied from [bookDetail].
  BookDetailProvider(
    String fileHash,
  ) : this._internal(
          (ref) => bookDetail(
            ref as BookDetailRef,
            fileHash,
          ),
          from: bookDetailProvider,
          name: r'bookDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookDetailHash,
          dependencies: BookDetailFamily._dependencies,
          allTransitiveDependencies:
              BookDetailFamily._allTransitiveDependencies,
          fileHash: fileHash,
        );

  BookDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.fileHash,
  }) : super.internal();

  final String fileHash;

  @override
  Override overrideWith(
    FutureOr<ShelfBook?> Function(BookDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookDetailProvider._internal(
        (ref) => create(ref as BookDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        fileHash: fileHash,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ShelfBook?> createElement() {
    return _BookDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookDetailProvider && other.fileHash == fileHash;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fileHash.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BookDetailRef on AutoDisposeFutureProviderRef<ShelfBook?> {
  /// The parameter `fileHash` of this provider.
  String get fileHash;
}

class _BookDetailProviderElement
    extends AutoDisposeFutureProviderElement<ShelfBook?> with BookDetailRef {
  _BookDetailProviderElement(super.provider);

  @override
  String get fileHash => (origin as BookDetailProvider).fileHash;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
