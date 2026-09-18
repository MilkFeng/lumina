// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_detail_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to fetch a single book by file hash.

@ProviderFor(bookDetail)
const bookDetailProvider = BookDetailFamily._();

/// Provider to fetch a single book by file hash.

final class BookDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShelfBook?>,
          ShelfBook?,
          FutureOr<ShelfBook?>
        >
    with $FutureModifier<ShelfBook?>, $FutureProvider<ShelfBook?> {
  /// Provider to fetch a single book by file hash.
  const BookDetailProvider._({
    required BookDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookDetailHash();

  @override
  String toString() {
    return r'bookDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ShelfBook?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ShelfBook?> create(Ref ref) {
    final argument = this.argument as String;
    return bookDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookDetailHash() => r'8a3acbd7a6527cbe1f047f6fde65c893f8ce6593';

/// Provider to fetch a single book by file hash.

final class BookDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ShelfBook?>, String> {
  const BookDetailFamily._()
    : super(
        retry: null,
        name: r'bookDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to fetch a single book by file hash.

  BookDetailProvider call(String fileHash) =>
      BookDetailProvider._(argument: fileHash, from: this);

  @override
  String toString() => r'bookDetailProvider';
}
