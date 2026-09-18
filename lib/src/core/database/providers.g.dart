// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the database lifecycle abstraction
/// Use this to access the database throughout the app

@ProviderFor(luminaDatabase)
final luminaDatabaseProvider = LuminaDatabaseProvider._();

/// Provider for the database lifecycle abstraction
/// Use this to access the database throughout the app

final class LuminaDatabaseProvider
    extends $FunctionalProvider<LuminaDatabase, LuminaDatabase, LuminaDatabase>
    with $Provider<LuminaDatabase> {
  /// Provider for the database lifecycle abstraction
  /// Use this to access the database throughout the app
  LuminaDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'luminaDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$luminaDatabaseHash();

  @$internal
  @override
  $ProviderElement<LuminaDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LuminaDatabase create(Ref ref) {
    return luminaDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LuminaDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LuminaDatabase>(value),
    );
  }
}

String _$luminaDatabaseHash() => r'9a353feecd9359e18a128e955e05c14f3caf1981';

/// Provider for the opened drift database
/// Convenience provider that returns the actual database instance

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// Provider for the opened drift database
/// Convenience provider that returns the actual database instance

final class DatabaseProvider
    extends
        $FunctionalProvider<AsyncValue<LuminaDb>, LuminaDb, FutureOr<LuminaDb>>
    with $FutureModifier<LuminaDb>, $FutureProvider<LuminaDb> {
  /// Provider for the opened drift database
  /// Convenience provider that returns the actual database instance
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $FutureProviderElement<LuminaDb> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LuminaDb> create(Ref ref) {
    return database(ref);
  }
}

String _$databaseHash() => r'5e960aa5d372a4209fe5f0716cd32c6977a046a3';
