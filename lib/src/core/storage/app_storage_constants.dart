/// Shared directory and file-name constants for on-disk storage layout.
///
/// All services that read or write the library storage structure
/// (import, export, backup, cleanup) reference these constants so that
/// a rename in one place propagates everywhere automatically.
class AppStorageConstants {
  AppStorageConstants._();

  /// Sub-directory that holds compressed `.epub` files.
  static const String booksDir = 'books';

  /// Sub-directory that holds extracted cover images.
  static const String coversDir = 'covers';

  /// Sub-directory that holds serialised [BookManifest] JSON files.
  static const String manifestsDir = 'manifests';

  /// Shelf metadata file name used in backup archives.
  static const String shelfFile = 'shelf.json';
}
