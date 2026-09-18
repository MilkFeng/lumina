// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_font_file_names_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes the set of imported font file names derived from [FontManagerNotifier].
/// Use this to check font existence without creating a direct
/// notifier-to-notifier dependency.

@ProviderFor(importedFontFileNames)
final importedFontFileNamesProvider = ImportedFontFileNamesProvider._();

/// Exposes the set of imported font file names derived from [FontManagerNotifier].
/// Use this to check font existence without creating a direct
/// notifier-to-notifier dependency.

final class ImportedFontFileNamesProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Exposes the set of imported font file names derived from [FontManagerNotifier].
  /// Use this to check font existence without creating a direct
  /// notifier-to-notifier dependency.
  ImportedFontFileNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importedFontFileNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importedFontFileNamesHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return importedFontFileNames(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$importedFontFileNamesHash() =>
    r'bd3f3e0e28b949e1ade43eabcce3151e39e0593e';
