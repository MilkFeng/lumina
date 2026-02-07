// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cover_file_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$coverFileHash() => r'6fbbd3f8a82ceff43deb31a373e5a8a485bfc09c';

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

/// Provider that caches cover file lookups by relative path.
/// Returns null if path is null/empty or file doesn't exist.
///
/// Copied from [coverFile].
@ProviderFor(coverFile)
const coverFileProvider = CoverFileFamily();

/// Provider that caches cover file lookups by relative path.
/// Returns null if path is null/empty or file doesn't exist.
///
/// Copied from [coverFile].
class CoverFileFamily extends Family<AsyncValue<File?>> {
  /// Provider that caches cover file lookups by relative path.
  /// Returns null if path is null/empty or file doesn't exist.
  ///
  /// Copied from [coverFile].
  const CoverFileFamily();

  /// Provider that caches cover file lookups by relative path.
  /// Returns null if path is null/empty or file doesn't exist.
  ///
  /// Copied from [coverFile].
  CoverFileProvider call(
    String? relativePath,
  ) {
    return CoverFileProvider(
      relativePath,
    );
  }

  @override
  CoverFileProvider getProviderOverride(
    covariant CoverFileProvider provider,
  ) {
    return call(
      provider.relativePath,
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
  String? get name => r'coverFileProvider';
}

/// Provider that caches cover file lookups by relative path.
/// Returns null if path is null/empty or file doesn't exist.
///
/// Copied from [coverFile].
class CoverFileProvider extends AutoDisposeFutureProvider<File?> {
  /// Provider that caches cover file lookups by relative path.
  /// Returns null if path is null/empty or file doesn't exist.
  ///
  /// Copied from [coverFile].
  CoverFileProvider(
    String? relativePath,
  ) : this._internal(
          (ref) => coverFile(
            ref as CoverFileRef,
            relativePath,
          ),
          from: coverFileProvider,
          name: r'coverFileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$coverFileHash,
          dependencies: CoverFileFamily._dependencies,
          allTransitiveDependencies: CoverFileFamily._allTransitiveDependencies,
          relativePath: relativePath,
        );

  CoverFileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.relativePath,
  }) : super.internal();

  final String? relativePath;

  @override
  Override overrideWith(
    FutureOr<File?> Function(CoverFileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CoverFileProvider._internal(
        (ref) => create(ref as CoverFileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        relativePath: relativePath,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<File?> createElement() {
    return _CoverFileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CoverFileProvider && other.relativePath == relativePath;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, relativePath.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CoverFileRef on AutoDisposeFutureProviderRef<File?> {
  /// The parameter `relativePath` of this provider.
  String? get relativePath;
}

class _CoverFileProviderElement extends AutoDisposeFutureProviderElement<File?>
    with CoverFileRef {
  _CoverFileProviderElement(super.provider);

  @override
  String? get relativePath => (origin as CoverFileProvider).relativePath;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
