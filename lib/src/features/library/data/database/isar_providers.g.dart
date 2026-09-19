// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the [IsarDatabase] interface.
///
/// **This is where collections get registered.** The schema list lives here
/// rather than in `core/` because the entities belong to features; a new
/// `@collection` class must be added to [_schemas] or it will silently not
/// persist.

@ProviderFor(isarDatabase)
const isarDatabaseProvider = IsarDatabaseProvider._();

/// Provider for the [IsarDatabase] interface.
///
/// **This is where collections get registered.** The schema list lives here
/// rather than in `core/` because the entities belong to features; a new
/// `@collection` class must be added to [_schemas] or it will silently not
/// persist.

final class IsarDatabaseProvider
    extends $FunctionalProvider<IsarDatabase, IsarDatabase, IsarDatabase>
    with $Provider<IsarDatabase> {
  /// Provider for the [IsarDatabase] interface.
  ///
  /// **This is where collections get registered.** The schema list lives here
  /// rather than in `core/` because the entities belong to features; a new
  /// `@collection` class must be added to [_schemas] or it will silently not
  /// persist.
  const IsarDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isarDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isarDatabaseHash();

  @$internal
  @override
  $ProviderElement<IsarDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IsarDatabase create(Ref ref) {
    return isarDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IsarDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IsarDatabase>(value),
    );
  }
}

String _$isarDatabaseHash() => r'd0c23c8adcacca6fcc7cb4262f5ec03ce3a8cfa0';

/// Provider for the live [Isar] instance.

@ProviderFor(isar)
const isarProvider = IsarProvider._();

/// Provider for the live [Isar] instance.

final class IsarProvider
    extends $FunctionalProvider<AsyncValue<Isar>, Isar, FutureOr<Isar>>
    with $FutureModifier<Isar>, $FutureProvider<Isar> {
  /// Provider for the live [Isar] instance.
  const IsarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isarHash();

  @$internal
  @override
  $FutureProviderElement<Isar> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Isar> create(Ref ref) {
    return isar(ref);
  }
}

String _$isarHash() => r'56671c8bc16b357cb7a36e1dee3e26b811ece4be';
