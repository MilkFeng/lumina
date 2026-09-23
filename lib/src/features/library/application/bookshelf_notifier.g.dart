// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing bookshelf operations with dependency injection
///
/// App-scoped state: it holds an LRU cache of books per tab/group and is
/// refreshed from the import pipeline (`refresh()`) while the library screen
/// may not be mounted. `autoDispose` would drop that cache and invalidate `ref`
/// mid-import.

@ProviderFor(BookshelfNotifier)
const bookshelfProvider = BookshelfNotifierProvider._();

/// Notifier for managing bookshelf operations with dependency injection
///
/// App-scoped state: it holds an LRU cache of books per tab/group and is
/// refreshed from the import pipeline (`refresh()`) while the library screen
/// may not be mounted. `autoDispose` would drop that cache and invalidate `ref`
/// mid-import.
final class BookshelfNotifierProvider
    extends $AsyncNotifierProvider<BookshelfNotifier, BookshelfState> {
  /// Notifier for managing bookshelf operations with dependency injection
  ///
  /// App-scoped state: it holds an LRU cache of books per tab/group and is
  /// refreshed from the import pipeline (`refresh()`) while the library screen
  /// may not be mounted. `autoDispose` would drop that cache and invalidate `ref`
  /// mid-import.
  const BookshelfNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookshelfProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookshelfNotifierHash();

  @$internal
  @override
  BookshelfNotifier create() => BookshelfNotifier();
}

String _$bookshelfNotifierHash() => r'37d2796db479ec895601767385dd0577c4da7285';

/// Notifier for managing bookshelf operations with dependency injection
///
/// App-scoped state: it holds an LRU cache of books per tab/group and is
/// refreshed from the import pipeline (`refresh()`) while the library screen
/// may not be mounted. `autoDispose` would drop that cache and invalidate `ref`
/// mid-import.

abstract class _$BookshelfNotifier extends $AsyncNotifier<BookshelfState> {
  FutureOr<BookshelfState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<BookshelfState>, BookshelfState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BookshelfState>, BookshelfState>,
              AsyncValue<BookshelfState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
