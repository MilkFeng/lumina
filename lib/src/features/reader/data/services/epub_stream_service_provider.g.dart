// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_stream_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for EpubStreamService
/// This service handles streaming EPUB files without extraction

@ProviderFor(epubStreamService)
const epubStreamServiceProvider = EpubStreamServiceProvider._();

/// Provider for EpubStreamService
/// This service handles streaming EPUB files without extraction

final class EpubStreamServiceProvider
    extends
        $FunctionalProvider<
          EpubStreamService,
          EpubStreamService,
          EpubStreamService
        >
    with $Provider<EpubStreamService> {
  /// Provider for EpubStreamService
  /// This service handles streaming EPUB files without extraction
  const EpubStreamServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'epubStreamServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$epubStreamServiceHash();

  @$internal
  @override
  $ProviderElement<EpubStreamService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EpubStreamService create(Ref ref) {
    return epubStreamService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpubStreamService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpubStreamService>(value),
    );
  }
}

String _$epubStreamServiceHash() => r'2f90b6721b0eb99f2be9b13b012cf1ee4f898865';
