// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_sources_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The source types this build can create, in editor order.

@ProviderFor(externalSourceRegistry)
const externalSourceRegistryProvider = ExternalSourceRegistryProvider._();

/// The source types this build can create, in editor order.

final class ExternalSourceRegistryProvider
    extends
        $FunctionalProvider<
          ExternalSourceRegistry,
          ExternalSourceRegistry,
          ExternalSourceRegistry
        >
    with $Provider<ExternalSourceRegistry> {
  /// The source types this build can create, in editor order.
  const ExternalSourceRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalSourceRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalSourceRegistryHash();

  @$internal
  @override
  $ProviderElement<ExternalSourceRegistry> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExternalSourceRegistry create(Ref ref) {
    return externalSourceRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExternalSourceRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExternalSourceRegistry>(value),
    );
  }
}

String _$externalSourceRegistryHash() =>
    r'9b1400b9c21c832f504851ac30c77cc5694b0dcf';

/// Every configured external source, ordered by name.
///
/// Kept alive because both the settings screen and the home screen's import
/// menu read it, and because building an adapter reads the keychain — an
/// `autoDispose` provider could be torn down in the middle of that.
///
/// It is a stream, so consumers that render the list synchronously read
/// `.value ?? const []`, the same way the bookshelf is read. Before the first
/// emission that is an empty list, which is what both call sites want while the
/// database is still opening.

@ProviderFor(ExternalSourcesNotifier)
const externalSourcesProvider = ExternalSourcesNotifierProvider._();

/// Every configured external source, ordered by name.
///
/// Kept alive because both the settings screen and the home screen's import
/// menu read it, and because building an adapter reads the keychain — an
/// `autoDispose` provider could be torn down in the middle of that.
///
/// It is a stream, so consumers that render the list synchronously read
/// `.value ?? const []`, the same way the bookshelf is read. Before the first
/// emission that is an empty list, which is what both call sites want while the
/// database is still opening.
final class ExternalSourcesNotifierProvider
    extends
        $StreamNotifierProvider<ExternalSourcesNotifier, List<ExternalSource>> {
  /// Every configured external source, ordered by name.
  ///
  /// Kept alive because both the settings screen and the home screen's import
  /// menu read it, and because building an adapter reads the keychain — an
  /// `autoDispose` provider could be torn down in the middle of that.
  ///
  /// It is a stream, so consumers that render the list synchronously read
  /// `.value ?? const []`, the same way the bookshelf is read. Before the first
  /// emission that is an empty list, which is what both call sites want while the
  /// database is still opening.
  const ExternalSourcesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalSourcesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalSourcesNotifierHash();

  @$internal
  @override
  ExternalSourcesNotifier create() => ExternalSourcesNotifier();
}

String _$externalSourcesNotifierHash() =>
    r'3d1f682a3ccc4d071666e8fca11fcfab010c3139';

/// Every configured external source, ordered by name.
///
/// Kept alive because both the settings screen and the home screen's import
/// menu read it, and because building an adapter reads the keychain — an
/// `autoDispose` provider could be torn down in the middle of that.
///
/// It is a stream, so consumers that render the list synchronously read
/// `.value ?? const []`, the same way the bookshelf is read. Before the first
/// emission that is an empty list, which is what both call sites want while the
/// database is still opening.

abstract class _$ExternalSourcesNotifier
    extends $StreamNotifier<List<ExternalSource>> {
  Stream<List<ExternalSource>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ExternalSource>>, List<ExternalSource>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ExternalSource>>,
                List<ExternalSource>
              >,
              AsyncValue<List<ExternalSource>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
