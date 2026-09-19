// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assembly-layer providers: the handful of things that inherently have to name
/// more than one feature.
///
/// They live at the `src/` root next to `app.dart` and `router.dart` for the
/// same reason those do — a database schema list and a keychain-backed
/// credential store span features, and putting them inside any single feature
/// would make that feature import the others.
/// Provider for the [IsarDatabase] interface.
///
/// **This is where collections get registered.** A new `@collection` class that
/// is not listed in [appDatabaseSchemas] will silently not persist.

@ProviderFor(isarDatabase)
const isarDatabaseProvider = IsarDatabaseProvider._();

/// Assembly-layer providers: the handful of things that inherently have to name
/// more than one feature.
///
/// They live at the `src/` root next to `app.dart` and `router.dart` for the
/// same reason those do — a database schema list and a keychain-backed
/// credential store span features, and putting them inside any single feature
/// would make that feature import the others.
/// Provider for the [IsarDatabase] interface.
///
/// **This is where collections get registered.** A new `@collection` class that
/// is not listed in [appDatabaseSchemas] will silently not persist.

final class IsarDatabaseProvider
    extends $FunctionalProvider<IsarDatabase, IsarDatabase, IsarDatabase>
    with $Provider<IsarDatabase> {
  /// Assembly-layer providers: the handful of things that inherently have to name
  /// more than one feature.
  ///
  /// They live at the `src/` root next to `app.dart` and `router.dart` for the
  /// same reason those do — a database schema list and a keychain-backed
  /// credential store span features, and putting them inside any single feature
  /// would make that feature import the others.
  /// Provider for the [IsarDatabase] interface.
  ///
  /// **This is where collections get registered.** A new `@collection` class that
  /// is not listed in [appDatabaseSchemas] will silently not persist.
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

String _$isarDatabaseHash() => r'33c6a16a68333c4778d7bd970129ccfb7390535a';

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

/// Provider for the secure store holding external source passwords.
///
/// Declared here so that tests can swap the keychain out; the feature itself
/// only depends on the store's own class.

@ProviderFor(externalSourceCredentialsStore)
const externalSourceCredentialsStoreProvider =
    ExternalSourceCredentialsStoreProvider._();

/// Provider for the secure store holding external source passwords.
///
/// Declared here so that tests can swap the keychain out; the feature itself
/// only depends on the store's own class.

final class ExternalSourceCredentialsStoreProvider
    extends
        $FunctionalProvider<
          ExternalSourceCredentialsStore,
          ExternalSourceCredentialsStore,
          ExternalSourceCredentialsStore
        >
    with $Provider<ExternalSourceCredentialsStore> {
  /// Provider for the secure store holding external source passwords.
  ///
  /// Declared here so that tests can swap the keychain out; the feature itself
  /// only depends on the store's own class.
  const ExternalSourceCredentialsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalSourceCredentialsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalSourceCredentialsStoreHash();

  @$internal
  @override
  $ProviderElement<ExternalSourceCredentialsStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExternalSourceCredentialsStore create(Ref ref) {
    return externalSourceCredentialsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExternalSourceCredentialsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExternalSourceCredentialsStore>(
        value,
      ),
    );
  }
}

String _$externalSourceCredentialsStoreHash() =>
    r'42fa70abdf9d18c837e22966f85b32348dca0a37';
