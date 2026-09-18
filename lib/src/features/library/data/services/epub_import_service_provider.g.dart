// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_import_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for EpubImportService
/// This service handles EPUB file import, parsing, and storage

@ProviderFor(epubImportService)
final epubImportServiceProvider = EpubImportServiceProvider._();

/// Provider for EpubImportService
/// This service handles EPUB file import, parsing, and storage

final class EpubImportServiceProvider
    extends
        $FunctionalProvider<
          EpubImportService,
          EpubImportService,
          EpubImportService
        >
    with $Provider<EpubImportService> {
  /// Provider for EpubImportService
  /// This service handles EPUB file import, parsing, and storage
  EpubImportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'epubImportServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$epubImportServiceHash();

  @$internal
  @override
  $ProviderElement<EpubImportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EpubImportService create(Ref ref) {
    return epubImportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpubImportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpubImportService>(value),
    );
  }
}

String _$epubImportServiceHash() => r'4ea83dd80df102c5ec2f3a19c976b793882264d1';
