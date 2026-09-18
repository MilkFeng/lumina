// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cover_file_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that caches cover file lookups by relative path.
/// Returns null if path is null/empty or file doesn't exist.

@ProviderFor(coverFile)
final coverFileProvider = CoverFileFamily._();

/// Provider that caches cover file lookups by relative path.
/// Returns null if path is null/empty or file doesn't exist.

final class CoverFileProvider
    extends $FunctionalProvider<AsyncValue<File?>, File?, FutureOr<File?>>
    with $FutureModifier<File?>, $FutureProvider<File?> {
  /// Provider that caches cover file lookups by relative path.
  /// Returns null if path is null/empty or file doesn't exist.
  CoverFileProvider._({
    required CoverFileFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'coverFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coverFileHash();

  @override
  String toString() {
    return r'coverFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<File?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<File?> create(Ref ref) {
    final argument = this.argument as String?;
    return coverFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CoverFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coverFileHash() => r'53d9da69bd65c57889a418654f6dba16b016a937';

/// Provider that caches cover file lookups by relative path.
/// Returns null if path is null/empty or file doesn't exist.

final class CoverFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<File?>, String?> {
  CoverFileFamily._()
    : super(
        retry: null,
        name: r'coverFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider that caches cover file lookups by relative path.
  /// Returns null if path is null/empty or file doesn't exist.

  CoverFileProvider call(String? relativePath) =>
      CoverFileProvider._(argument: relativePath, from: this);

  @override
  String toString() => r'coverFileProvider';
}
