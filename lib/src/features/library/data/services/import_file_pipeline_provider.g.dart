// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_file_pipeline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ImportFilePipeline] — the picker plus the import cache,
/// wired together for iOS copy-on-demand.

@ProviderFor(importFilePipeline)
const importFilePipelineProvider = ImportFilePipelineProvider._();

/// Provider for [ImportFilePipeline] — the picker plus the import cache,
/// wired together for iOS copy-on-demand.

final class ImportFilePipelineProvider
    extends
        $FunctionalProvider<
          ImportFilePipeline,
          ImportFilePipeline,
          ImportFilePipeline
        >
    with $Provider<ImportFilePipeline> {
  /// Provider for [ImportFilePipeline] — the picker plus the import cache,
  /// wired together for iOS copy-on-demand.
  const ImportFilePipelineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importFilePipelineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importFilePipelineHash();

  @$internal
  @override
  $ProviderElement<ImportFilePipeline> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImportFilePipeline create(Ref ref) {
    return importFilePipeline(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportFilePipeline value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportFilePipeline>(value),
    );
  }
}

String _$importFilePipelineHash() =>
    r'2d796af27d65f6f5ada9ea9a383e18480592539d';
