// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for IsarDatabase interface
/// Use this to access the database throughout the app

@ProviderFor(isarDatabase)
const isarDatabaseProvider = IsarDatabaseProvider._();

/// Provider for IsarDatabase interface
/// Use this to access the database throughout the app

final class IsarDatabaseProvider
    extends $FunctionalProvider<IsarDatabase, IsarDatabase, IsarDatabase>
    with $Provider<IsarDatabase> {
  /// Provider for IsarDatabase interface
  /// Use this to access the database throughout the app
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

String _$isarDatabaseHash() => r'bb1af5de2a34d59642cf30de84c81c52edc60362';

/// Provider for Isar instance
/// Convenience provider that returns the actual Isar instance

@ProviderFor(isar)
const isarProvider = IsarProvider._();

/// Provider for Isar instance
/// Convenience provider that returns the actual Isar instance

final class IsarProvider
    extends $FunctionalProvider<AsyncValue<Isar>, Isar, FutureOr<Isar>>
    with $FutureModifier<Isar>, $FutureProvider<Isar> {
  /// Provider for Isar instance
  /// Convenience provider that returns the actual Isar instance
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
