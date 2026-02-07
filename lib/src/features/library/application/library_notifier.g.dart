// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shelfBookRepositoryHash() =>
    r'83c44a13e57072a55513c29cba81a48b0cc0b07a';

/// Provider for ShelfBook repository
///
/// Copied from [shelfBookRepository].
@ProviderFor(shelfBookRepository)
final shelfBookRepositoryProvider =
    AutoDisposeProvider<ShelfBookRepository>.internal(
  shelfBookRepository,
  name: r'shelfBookRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shelfBookRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ShelfBookRepositoryRef = AutoDisposeProviderRef<ShelfBookRepository>;
String _$epubImportServiceHash() => r'4da8695b0d79094d0e3d1741450f913403507cb2';

/// Provider for EPUB import service
///
/// Copied from [epubImportService].
@ProviderFor(epubImportService)
final epubImportServiceProvider =
    AutoDisposeProvider<EpubImportService>.internal(
  epubImportService,
  name: r'epubImportServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$epubImportServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EpubImportServiceRef = AutoDisposeProviderRef<EpubImportService>;
String _$libraryNotifierHash() => r'7167f1402c4fce7bdf29b8b628742a104f191a25';

/// Notifier for managing library operations
/// Updated to use ShelfBook and EpubImportService (stream-from-zip)
///
/// Copied from [LibraryNotifier].
@ProviderFor(LibraryNotifier)
final libraryNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LibraryNotifier, LibraryState>.internal(
  LibraryNotifier.new,
  name: r'libraryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$libraryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LibraryNotifier = AutoDisposeAsyncNotifier<LibraryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
