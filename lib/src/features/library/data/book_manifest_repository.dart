import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lumina/src/core/database/lumina_db.dart';
import 'package:lumina/src/core/database/mappers.dart';

import '../domain/book_manifest.dart';

/// Repository for BookManifest CRUD operations
/// Heavy queries only when opening the reader
class BookManifestRepository {
  final LuminaDb _db;

  BookManifestRepository({required LuminaDb db}) : _db = db;

  SimpleSelectStatement<BookManifests, BookManifestRow> get _manifests =>
      _db.select(_db.bookManifests);

  /// Get manifest by file hash
  /// This is the primary query when opening a book
  Future<BookManifest?> getManifestByHash(String fileHash) async {
    final row = await (_manifests..where((t) => t.fileHash.equals(fileHash)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  /// Get manifest by ID
  Future<BookManifest?> getManifestById(int id) async {
    final row = await (_manifests..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  /// Save or update a manifest.
  ///
  /// Returns the row id. The return value of drift's `insertOnConflictUpdate`
  /// is deliberately not used here: drift documents that it reports the rowid
  /// of the last *insert*, which is the wrong row when the call turned into an
  /// update.
  Future<Either<String, int>> saveManifest(BookManifest manifest) async {
    try {
      final isNew = manifest.id == 0;
      if (isNew) {
        manifest.id = await _db
            .into(_db.bookManifests)
            .insert(manifest.toCompanion());
      } else {
        await _db
            .into(_db.bookManifests)
            .insertOnConflictUpdate(manifest.toCompanion());
      }
      return right(manifest.id);
    } catch (e) {
      return left('Save manifest failed: $e');
    }
  }

  /// Delete a manifest by file hash
  Future<Either<String, bool>> deleteManifestByHash(String fileHash) async {
    try {
      final deleted = await (_db.delete(_db.bookManifests)
            ..where((t) => t.fileHash.equals(fileHash)))
          .go();
      return right(deleted > 0);
    } catch (e) {
      return left('Delete manifest failed: $e');
    }
  }

  /// Delete a manifest by ID
  Future<Either<String, bool>> deleteManifest(int id) async {
    try {
      final deleted = await (_db.delete(_db.bookManifests)
            ..where((t) => t.id.equals(id)))
          .go();
      return right(deleted > 0);
    } catch (e) {
      return left('Delete manifest failed: $e');
    }
  }
}
