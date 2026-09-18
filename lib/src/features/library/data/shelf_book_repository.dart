import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lumina/src/core/database/lumina_db.dart';
import 'package:lumina/src/core/database/mappers.dart';

import '../domain/shelf_book.dart';
import '../domain/shelf_group.dart';

/// Sorting options for shelf book list
enum ShelfBookSortBy {
  titleAsc,
  titleDesc,
  authorAsc,
  authorDesc,
  recentlyRead,
  recentlyAdded,
  progress,
}

/// Repository for ShelfBook CRUD operations
/// Lightweight queries for UI display and sync
class ShelfBookRepository {
  final LuminaDb _db;

  ShelfBookRepository({required LuminaDb db}) : _db = db;

  SimpleSelectStatement<ShelfBooks, ShelfBookRow> get _books =>
      _db.select(_db.shelfBooks);

  SimpleSelectStatement<ShelfGroups, ShelfGroupRow> get _groups =>
      _db.select(_db.shelfGroups);

  /// Get all books (excluding deleted) sorted by import date (newest first)
  Future<List<ShelfBook>> getAllBooks() async {
    final query = _books
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.importDate)]);
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Get all file hashes across every record that is not soft-deleted.
  /// Used by [StorageCleanupService] to determine which physical files are valid.
  Future<Set<String>> getAllNotDeletedFileHashes() async {
    final query = _db.selectOnly(_db.shelfBooks)
      ..addColumns([_db.shelfBooks.fileHash])
      ..where(_db.shelfBooks.isDeleted.equals(false));
    final rows = await query.get();
    return rows.map((row) => row.read(_db.shelfBooks.fileHash)!).toSet();
  }

  /// Get all books with advanced sorting and optional group filter.
  ///
  /// [includeAll] returns every non-deleted book; otherwise only the books of
  /// [groupName] (or the root level when it is null) are returned.
  Future<List<ShelfBook>> getBooksSorted({
    ShelfBookSortBy sortBy = ShelfBookSortBy.recentlyAdded,
    String? groupName,
    bool includeAll = false,
  }) async {
    // A single `where` call: drift replaces the predicate when `where` is
    // invoked twice, so the deleted filter and the group filter must be
    // combined into one expression.
    final query = _books
      ..where(
        (t) =>
            t.isDeleted.equals(false) &
            (includeAll
                ? const Constant(true)
                : (groupName == null
                      ? t.groupName.isNull()
                      : t.groupName.equals(groupName))),
      );

    switch (sortBy) {
      case ShelfBookSortBy.recentlyRead:
        query.orderBy([(t) => OrderingTerm.desc(t.lastOpenedDate)]);
      case ShelfBookSortBy.recentlyAdded:
        query.orderBy([(t) => OrderingTerm.desc(t.importDate)]);
      case ShelfBookSortBy.progress:
        query.orderBy([(t) => OrderingTerm.desc(t.readingProgress)]);
      case ShelfBookSortBy.titleAsc:
      case ShelfBookSortBy.titleDesc:
      case ShelfBookSortBy.authorAsc:
      case ShelfBookSortBy.authorDesc:
        break;
    }

    final rows = await query.get();
    final books = rows.map((row) => row.toDomain()).toList();

    // SQLite has no natural sort, so title/author ordering stays in Dart to
    // keep "Book 2" before "Book 10".
    switch (sortBy) {
      case ShelfBookSortBy.titleAsc:
        return books..sort((a, b) => compareNatural(a.title, b.title));
      case ShelfBookSortBy.titleDesc:
        return books..sort((a, b) => compareNatural(b.title, a.title));
      case ShelfBookSortBy.authorAsc:
        return books..sort((a, b) => compareNatural(a.author, b.author));
      case ShelfBookSortBy.authorDesc:
        return books..sort((a, b) => compareNatural(b.author, a.author));
      default:
        return books;
    }
  }

  /// Get all groups (flat structure, no nesting)
  Future<List<ShelfGroup>> getGroups() async {
    final query = _groups
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Get group by ID
  Future<ShelfGroup?> getGroupById(int id) async {
    final row = await (_groups..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<ShelfGroup?> getGroupByName(String name) async {
    final row = await (_groups
          ..where(
            (t) => t.name.equals(name) & (t.isDeleted.equals(false)),
          ))
        .getSingleOrNull();
    return row?.toDomain();
  }

  Future<ShelfGroup> saveGroup(ShelfGroup group) async {
    final id = await _db
        .into(_db.shelfGroups)
        .insertOnConflictUpdate(group.toCompanion());
    return group..id = id;
  }

  /// Create a new group
  Future<Either<String, int>> createGroup({required String name}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final existingGroup = await getGroupByName(name);
      if (existingGroup != null) {
        return left('Group already exists');
      }

      // A soft-deleted group with this name still occupies the unique index, so
      // revive it instead of inserting a duplicate.
      final deletedGroup = await (_groups
            ..where((t) => t.name.equals(name) & t.isDeleted.equals(true)))
          .getSingleOrNull();
      if (deletedGroup != null) {
        final revived = await (_db.update(_db.shelfGroups)
              ..where((t) => t.id.equals(deletedGroup.id)))
            .write(
              ShelfGroupsCompanion(
                isDeleted: const Value(false),
                updatedAt: Value(now),
              ),
            );
        return revived == 0
            ? left('Create group failed')
            : right(deletedGroup.id);
      }

      final group = ShelfGroup()
        ..name = name
        ..creationDate = now
        ..updatedAt = now
        ..isDeleted = false;
      final id = await _db
          .into(_db.shelfGroups)
          .insert(group.toCompanion());
      return right(id);
    } catch (e) {
      return left('Create group failed: $e');
    }
  }

  /// Update a group's name
  Future<Either<String, bool>> updateGroupName({
    required int groupId,
    required String name,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final updated = await _db.transaction(() async {
        final existing = await (_groups..where((t) => t.id.equals(groupId)))
            .getSingleOrNull();
        if (existing == null) {
          return false;
        }

        final oldGroupName = existing.name;
        await (_db.update(_db.shelfGroups)..where((t) => t.id.equals(groupId)))
            .write(
              ShelfGroupsCompanion(
                name: Value(name),
                updatedAt: Value(now),
              ),
            );
        await (_db.update(_db.shelfBooks)
              ..where((t) => t.groupName.equals(oldGroupName)))
            .write(
              ShelfBooksCompanion(
                groupName: Value(name),
                updatedAt: Value(now),
              ),
            );
        return true;
      });

      return updated ? right(true) : left('Group not found');
    } catch (e) {
      return left('Update group failed: $e');
    }
  }

  /// Delete a group and unassign its books
  Future<Either<String, bool>> deleteGroup({required int groupId}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final deleted = await _db.transaction(() async {
        final group = await (_groups..where((t) => t.id.equals(groupId)))
            .getSingleOrNull();
        if (group == null) {
          return false;
        }

        // Unassign books from this group
        await (_db.update(_db.shelfBooks)
              ..where((t) => t.groupName.equals(group.name)))
            .write(
              ShelfBooksCompanion(
                groupName: const Value(null),
                updatedAt: Value(now),
              ),
            );

        // Soft delete the group
        await (_db.update(_db.shelfGroups)..where((t) => t.id.equals(groupId)))
            .write(
              ShelfGroupsCompanion(
                isDeleted: const Value(true),
                updatedAt: Value(now),
              ),
            );
        return true;
      });

      return deleted ? right(true) : left('Group not found');
    } catch (e) {
      return left('Delete group failed: $e');
    }
  }

  /// Update book group assignment
  Future<Either<String, bool>> updateBookGroup({
    required int bookId,
    String? groupName,
  }) async {
    try {
      await (_db.update(_db.shelfBooks)..where((t) => t.id.equals(bookId)))
          .write(
            ShelfBooksCompanion(
              groupName: Value(groupName),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      return right(true);
    } catch (e) {
      return left('Update group failed: $e');
    }
  }

  /// Move multiple books to a group
  Future<Either<String, bool>> moveBooksToGroup({
    required Set<int> bookIds,
    String? targetGroupName,
  }) async {
    try {
      if (bookIds.isEmpty) {
        return right(true);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.transaction(() async {
        await (_db.update(_db.shelfBooks)
              ..where((t) => t.id.isIn(bookIds)))
            .write(
              ShelfBooksCompanion(
                groupName: Value(targetGroupName),
                updatedAt: Value(now),
              ),
            );
      });
      return right(true);
    } catch (e) {
      return left('Move books failed: $e');
    }
  }

  /// Soft delete a book (marks as deleted instead of removing)
  Future<Either<String, bool>> softDeleteBook(int bookId) async {
    try {
      await (_db.update(_db.shelfBooks)..where((t) => t.id.equals(bookId)))
          .write(
            ShelfBooksCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      return right(true);
    } catch (e) {
      return left('Soft delete failed: $e');
    }
  }

  /// Undo a soft delete, clearing the sync marker.
  ///
  /// Used when re-importing a book that still exists as a soft-deleted row, or
  /// when a backup contains a book the user previously deleted.
  Future<Either<String, bool>> restoreBook(int bookId) async {
    try {
      await (_db.update(_db.shelfBooks)..where((t) => t.id.equals(bookId)))
          .write(
            ShelfBooksCompanion(
              isDeleted: const Value(false),
              lastSyncedDate: const Value(null),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      return right(true);
    } catch (e) {
      return left('Restore failed: $e');
    }
  }

  /// Get book by ID
  Future<ShelfBook?> getBookById(int id) async {
    final row = await (_books..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  /// Get book by file hash
  Future<ShelfBook?> getBookByHash(String fileHash) async {
    final row = await (_books..where((t) => t.fileHash.equals(fileHash)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  /// Check if book exists by hash
  Future<bool> bookExists(String fileHash) async {
    final book = await getBookByHash(fileHash);
    return book != null;
  }

  /// Check if book is marked as deleted by hash
  Future<bool> bookExistsAndNotDeleted(String fileHash) async {
    final book = await getBookByHash(fileHash);
    return book != null && !book.isDeleted;
  }

  /// Get book ID by hash
  Future<int> getBookIdByHash(String fileHash) async {
    final book = await getBookByHash(fileHash);
    if (book != null) {
      return book.id;
    } else {
      throw Exception('Book not found for hash: $fileHash');
    }
  }

  /// Save or update a book.
  ///
  /// Returns the id the row has in the database. Note that the return value of
  /// `insertOnConflictUpdate` cannot be used for this: drift documents that it
  /// reports the rowid of the last *insert*, which is the wrong row when the
  /// call turned into an update.
  Future<Either<String, int>> saveBook(ShelfBook book) async {
    try {
      final isNew = book.id == 0;
      if (isNew) {
        book.id = await _db.into(_db.shelfBooks).insert(book.toCompanion());
      } else {
        await _db
            .into(_db.shelfBooks)
            .insertOnConflictUpdate(book.toCompanion());
      }
      return right(book.id);
    } catch (e) {
      return left('Save failed: $e');
    }
  }

  /// Delete a book permanently by ID
  Future<Either<String, bool>> deleteBook(int id) async {
    try {
      final deleted = await (_db.delete(_db.shelfBooks)
            ..where((t) => t.id.equals(id)))
          .go();
      return right(deleted > 0);
    } catch (e) {
      return left('Delete failed: $e');
    }
  }

  /// Update reading progress
  ///
  /// This runs on every page turn, so it writes a single `UPDATE` instead of
  /// reading the row and putting it back.
  Future<Either<String, bool>> updateProgress({
    required int bookId,
    required int currentChapterIndex,
    required double progress,
    required double? scrollPosition,
  }) async {
    try {
      await (_db.update(_db.shelfBooks)..where((t) => t.id.equals(bookId)))
          .write(
            ShelfBooksCompanion(
              currentChapterIndex: Value(currentChapterIndex),
              readingProgress: Value(progress),
              chapterScrollPosition: Value(scrollPosition),
              lastOpenedDate: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      return right(true);
    } catch (e) {
      return left('Update progress failed: $e');
    }
  }

  /// Mark book as finished
  Future<Either<String, bool>> markAsFinished(int bookId) async {
    try {
      await (_db.update(_db.shelfBooks)..where((t) => t.id.equals(bookId)))
          .write(
            ShelfBooksCompanion(
              isFinished: const Value(true),
              readingProgress: const Value(1.0),
              lastOpenedDate: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      return right(true);
    } catch (e) {
      return left('Mark finished failed: $e');
    }
  }

  /// Get recently opened books
  Future<List<ShelfBook>> getRecentBooks({int limit = 10}) async {
    final query = _books
      ..where((t) => t.isDeleted.equals(false) & t.lastOpenedDate.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastOpenedDate)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Search books by title or author (case-insensitive).
  ///
  /// Soft-deleted rows are excluded, like every other shelf query.
  /// `LIKE` is only case-insensitive for ASCII, which is enough for the current
  /// library UI. Swap this for an FTS5 table if real full-text search (or CJK
  /// tokenization) is needed later.
  Future<List<ShelfBook>> searchBooks(String query) async {
    final pattern = '%${query.toLowerCase()}%';
    final search = _books
      ..where(
        (t) =>
            t.isDeleted.equals(false) &
            (t.title.lower().like(pattern) | t.author.lower().like(pattern)),
      );
    final rows = await search.get();
    return rows.map((row) => row.toDomain()).toList();
  }
}
