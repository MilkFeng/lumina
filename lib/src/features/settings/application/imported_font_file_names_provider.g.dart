// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_font_file_names_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$importedFontFileNamesHash() =>
    r'02f6d241253bda44d34661475a371d6b23707fa0';

/// Exposes the set of imported font file names derived from [FontManagerNotifier].
/// Use this to check font existence without creating a direct
/// notifier-to-notifier dependency.
///
/// Copied from [importedFontFileNames].
@ProviderFor(importedFontFileNames)
final importedFontFileNamesProvider = AutoDisposeProvider<Set<String>>.internal(
  importedFontFileNames,
  name: r'importedFontFileNamesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$importedFontFileNamesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ImportedFontFileNamesRef = AutoDisposeProviderRef<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
