import 'package:isar/isar.dart';
import 'package:fpdart/fpdart.dart';
import '../domain/book_manifest.dart';

/// Repository for BookManifest CRUD operations
/// Heavy queries only when opening the reader
class BookManifestRepository {
  final Isar _isar;

  BookManifestRepository({required Isar isar}) : _isar = isar;

  /// Get manifest by file hash
  /// This is the primary query when opening a book
  Future<BookManifest?> getManifestByHash(String fileHash) async {
    final isar = _isar;
    return await isar.bookManifests
        .where()
        .fileHashEqualTo(fileHash)
        .findFirst();
  }

  /// Get manifest by ID
  Future<BookManifest?> getManifestById(int id) async {
    final isar = _isar;
    return await isar.bookManifests.get(id);
  }

  /// Check if manifest exists by hash
  Future<bool> manifestExists(String fileHash) async {
    final manifest = await getManifestByHash(fileHash);
    return manifest != null;
  }

  /// Save or update a manifest
  Future<Either<String, int>> saveManifest(BookManifest manifest) async {
    try {
      final isar = _isar;
      final id = await isar.writeTxn(() async {
        return await isar.bookManifests.put(manifest);
      });
      return right(id);
    } catch (e) {
      return left('Save manifest failed: $e');
    }
  }

  /// Delete a manifest by file hash
  Future<Either<String, bool>> deleteManifestByHash(String fileHash) async {
    try {
      final isar = _isar;
      final success = await isar.writeTxn(() async {
        final manifest = await isar.bookManifests
            .where()
            .fileHashEqualTo(fileHash)
            .findFirst();
        if (manifest != null) {
          return await isar.bookManifests.delete(manifest.id);
        }
        return false;
      });
      return right(success);
    } catch (e) {
      return left('Delete manifest failed: $e');
    }
  }

  /// Delete a manifest by ID
  Future<Either<String, bool>> deleteManifest(int id) async {
    try {
      final isar = _isar;
      final success = await isar.writeTxn(() async {
        return await isar.bookManifests.delete(id);
      });
      return right(success);
    } catch (e) {
      return left('Delete manifest failed: $e');
    }
  }

  /// Get all manifests (rarely used, mainly for debugging/migration)
  Future<List<BookManifest>> getAllManifests() async {
    final isar = _isar;
    return await isar.bookManifests.where().findAll();
  }

  /// Get spine file path by index
  /// Convenience method to avoid loading full manifest for simple navigation
  Future<String?> getSpinePathByIndex(String fileHash, int index) async {
    final manifest = await getManifestByHash(fileHash);
    if (manifest != null && index >= 0 && index < manifest.spine.length) {
      return manifest.spine[index];
    }
    return null;
  }

  /// Get total spine count
  Future<int?> getSpineCount(String fileHash) async {
    final manifest = await getManifestByHash(fileHash);
    return manifest?.spine.length;
  }

  /// Flatten TOC to a simple list (for UI display)
  Future<List<TocItem>> getFlattenedToc(String fileHash) async {
    final manifest = await getManifestByHash(fileHash);
    if (manifest == null) return [];
    
    return _flattenTocItems(manifest.toc);
  }

  /// Helper to recursively flatten TOC
  List<TocItem> _flattenTocItems(List<TocItem> items) {
    final result = <TocItem>[];
    for (final item in items) {
      result.add(item);
      if (item.children.isNotEmpty) {
        result.addAll(_flattenTocItems(item.children));
      }
    }
    return result;
  }
}
