// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_source_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ExternalSourceRepository].
///
/// Reads through the app-level [isarProvider], which is what lets external
/// sources live in their own feature without the library feature having to know
/// about them.

@ProviderFor(externalSourceRepository)
const externalSourceRepositoryProvider = ExternalSourceRepositoryProvider._();

/// Provider for [ExternalSourceRepository].
///
/// Reads through the app-level [isarProvider], which is what lets external
/// sources live in their own feature without the library feature having to know
/// about them.

final class ExternalSourceRepositoryProvider
    extends
        $FunctionalProvider<
          ExternalSourceRepository,
          ExternalSourceRepository,
          ExternalSourceRepository
        >
    with $Provider<ExternalSourceRepository> {
  /// Provider for [ExternalSourceRepository].
  ///
  /// Reads through the app-level [isarProvider], which is what lets external
  /// sources live in their own feature without the library feature having to know
  /// about them.
  const ExternalSourceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalSourceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalSourceRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExternalSourceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExternalSourceRepository create(Ref ref) {
    return externalSourceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExternalSourceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExternalSourceRepository>(value),
    );
  }
}

String _$externalSourceRepositoryHash() =>
    r'184365756ef07d4711f8974452e5f2a8c8ac0be6';
