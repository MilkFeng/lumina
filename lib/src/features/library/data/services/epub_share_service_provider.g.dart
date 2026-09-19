// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_share_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [EpubShareService] — temporary `.epub` copies for the platform
/// share sheet.

@ProviderFor(epubShareService)
const epubShareServiceProvider = EpubShareServiceProvider._();

/// Provider for [EpubShareService] — temporary `.epub` copies for the platform
/// share sheet.

final class EpubShareServiceProvider
    extends
        $FunctionalProvider<
          EpubShareService,
          EpubShareService,
          EpubShareService
        >
    with $Provider<EpubShareService> {
  /// Provider for [EpubShareService] — temporary `.epub` copies for the platform
  /// share sheet.
  const EpubShareServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'epubShareServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$epubShareServiceHash();

  @$internal
  @override
  $ProviderElement<EpubShareService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EpubShareService create(Ref ref) {
    return epubShareService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpubShareService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpubShareService>(value),
    );
  }
}

String _$epubShareServiceHash() => r'f02d90dfa8df8e865dd472a1f6af7f01faa3110d';
