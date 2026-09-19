// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing library operations with dependency injection
///
/// Must stay alive: `importPipelineStream` and `importLibraryFromFolder` are
/// long-running generators that keep using `ref` and `state` across many async
/// gaps. With the default `autoDispose`, the provider is disposed as soon as no
/// widget is listening (e.g. the library screen is unmounted while the import
/// progress dialog is showing), which makes every later `ref.read`/`state`
/// assignment throw "Cannot use the Ref ... after it has been disposed".

@ProviderFor(LibraryNotifier)
const libraryProvider = LibraryNotifierProvider._();

/// Notifier for managing library operations with dependency injection
///
/// Must stay alive: `importPipelineStream` and `importLibraryFromFolder` are
/// long-running generators that keep using `ref` and `state` across many async
/// gaps. With the default `autoDispose`, the provider is disposed as soon as no
/// widget is listening (e.g. the library screen is unmounted while the import
/// progress dialog is showing), which makes every later `ref.read`/`state`
/// assignment throw "Cannot use the Ref ... after it has been disposed".
final class LibraryNotifierProvider
    extends $AsyncNotifierProvider<LibraryNotifier, LibraryState> {
  /// Notifier for managing library operations with dependency injection
  ///
  /// Must stay alive: `importPipelineStream` and `importLibraryFromFolder` are
  /// long-running generators that keep using `ref` and `state` across many async
  /// gaps. With the default `autoDispose`, the provider is disposed as soon as no
  /// widget is listening (e.g. the library screen is unmounted while the import
  /// progress dialog is showing), which makes every later `ref.read`/`state`
  /// assignment throw "Cannot use the Ref ... after it has been disposed".
  const LibraryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryNotifierHash();

  @$internal
  @override
  LibraryNotifier create() => LibraryNotifier();
}

String _$libraryNotifierHash() => r'928701632823be8581b133e1dc6690cfc3494aba';

/// Notifier for managing library operations with dependency injection
///
/// Must stay alive: `importPipelineStream` and `importLibraryFromFolder` are
/// long-running generators that keep using `ref` and `state` across many async
/// gaps. With the default `autoDispose`, the provider is disposed as soon as no
/// widget is listening (e.g. the library screen is unmounted while the import
/// progress dialog is showing), which makes every later `ref.read`/`state`
/// assignment throw "Cannot use the Ref ... after it has been disposed".

abstract class _$LibraryNotifier extends $AsyncNotifier<LibraryState> {
  FutureOr<LibraryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<LibraryState>, LibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LibraryState>, LibraryState>,
              AsyncValue<LibraryState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
