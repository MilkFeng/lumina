import 'package:isar_community/isar.dart';
import 'package:fpdart/fpdart.dart';
import '../domain/shelf_book.dart';
import '../domain/shelf_group.dart';
import 'package:collection/collection.dart';

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
  final Isar _isar;

  ShelfBookRepository({required Isar isar}) : _isar = isar;

  /// Get all books sorted by import date (newest first)
  Future<List<ShelfBook>> getAllBooks() async {
    return await _isar.shelfBooks.where().sortByImportDateDesc().findAll();
  }

  /// Get all file hashes.
  /// Used by [StorageCleanupService] to determine which physical files are valid.
  Future<Set<String>> getAllFileHashes() async {
    final books = await _isar.shelfBooks.where().findAll();
    return books.map((b) => b.fileHash).toSet();
  }

  /// Get all books with advanced sorting and optional group filter
  Future<List<ShelfBook>> getBooksSorted({
    ShelfBookSortBy sortBy = ShelfBookSortBy.recentlyAdded,
    String? groupName,
    bool includeAll = false,
  }) async {
    final isar = _isar;

    // Load the candidate set: every book, or just the requested group.
    final List<ShelfBook> books;
    if (includeAll) {
      books = await isar.shelfBooks.where().findAll();
    } else if (groupName != null) {
      books = await isar.shelfBooks
          .where()
          .groupNameEqualTo(groupName)
          .findAll();
    } else {
      books = await isar.shelfBooks.where().groupNameIsNull().findAll();
    }

    // Sorting is applied in Dart so titles and authors can use natural
    // (human-friendly) comparison.
    switch (sortBy) {
      case ShelfBookSortBy.titleAsc:
        return books..sort((a, b) => compareNatural(a.title, b.title));
      case ShelfBookSortBy.titleDesc:
        return books..sort((a, b) => compareNatural(b.title, a.title));
      case ShelfBookSortBy.authorAsc:
        return books
          ..sort(
            (a, b) => compareNatural(
              a.authors.firstOrNull ?? '',
              b.authors.firstOrNull ?? '',
            ),
          );
      case ShelfBookSortBy.authorDesc:
        return books
          ..sort(
            (a, b) => compareNatural(
              b.authors.firstOrNull ?? '',
              a.authors.firstOrNull ?? '',
            ),
          );
      case ShelfBookSortBy.recentlyRead:
        return books
          ..sort(
            (a, b) => (b.lastOpenedDate ?? 0).compareTo(a.lastOpenedDate ?? 0),
          );
      case ShelfBookSortBy.recentlyAdded:
        return books..sort((a, b) => b.importDate.compareTo(a.importDate));
      case ShelfBookSortBy.progress:
        return books
          ..sort((a, b) => b.readingProgress.compareTo(a.readingProgress));
    }
  }

  /// Get all groups (flat structure, no nesting)
  Future<List<ShelfGroup>> getGroups() async {
    final isar = _isar;
    return await isar.shelfGroups.where().sortByName().findAll();
  }

  /// Get group by ID
  Future<ShelfGroup?> getGroupById(int id) async {
    final isar = _isar;
    return await isar.shelfGroups.get(id);
  }

  Future<ShelfGroup?> getGroupByName(String name) async {
    final isar = _isar;
    return await isar.shelfGroups.where().nameEqualTo(name).findFirst();
  }

  Future<ShelfGroup> saveGroup(ShelfGroup group) async {
    final isar = _isar;
    final id = await isar.writeTxn(() async {
      return await isar.shelfGroups.put(group);
    });
    return group..id = id;
  }

  /// Create a new group
  Future<Either<String, int>> createGroup({required String name}) async {
    try {
      final isar = _isar;
      final now = DateTime.now().millisecondsSinceEpoch;
      // check if group already exists
      final existingGroup = await isar.shelfGroups
          .where()
          .nameEqualTo(name)
          .findFirst();
      if (existingGroup != null) {
        return left('Group already exists');
      }

      final group = ShelfGroup()
        ..name = name
        ..creationDate = now
        ..updatedAt = now;
      final id = await isar.writeTxn(() async {
        return await isar.shelfGroups.put(group);
      });
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
      final isar = _isar;
      return await isar.writeTxn(() async {
        final group = await isar.shelfGroups.get(groupId);
        if (group == null) {
          return left('Group not found');
        }
        final oldGroupName = group.name;
        group.name = name;
        group.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await isar.shelfGroups.put(group);

        final books = await isar.shelfBooks
            .filter()
            .groupNameEqualTo(oldGroupName)
            .findAll();

        for (final book in books) {
          book.groupName = name;
          book.updatedAt = DateTime.now().millisecondsSinceEpoch;
        }

        if (books.isNotEmpty) {
          await isar.shelfBooks.putAll(books);
        }

        return right(true);
      });
    } catch (e) {
      return left('Update group failed: $e');
    }
  }

  /// Delete a group and unassign its books
  Future<Either<String, bool>> deleteGroup({required int groupId}) async {
    try {
      final isar = _isar;
      return await isar.writeTxn(() async {
        final group = await isar.shelfGroups.get(groupId);
        if (group == null) {
          return left('Group not found');
        }

        // Unassign books from this group
        final books = await isar.shelfBooks
            .filter()
            .groupNameEqualTo(group.name)
            .findAll();
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final book in books) {
          book.groupName = null;
          book.updatedAt = now;
        }
        if (books.isNotEmpty) {
          await isar.shelfBooks.putAll(books);
        }

        await isar.shelfGroups.delete(groupId);
        return right(true);
      });
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
      final isar = _isar;
      await isar.writeTxn(() async {
        final book = await isar.shelfBooks.get(bookId);
        if (book != null) {
          book.groupName = groupName;
          book.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await isar.shelfBooks.put(book);
        }
      });
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
      final isar = _isar;
      final now = DateTime.now().millisecondsSinceEpoch;
      await isar.writeTxn(() async {
        // Batch fetch all books in a single round-trip, then batch write.
        final books = await isar.shelfBooks.getAll(bookIds.toList());
        final toUpdate = <ShelfBook>[];
        for (final book in books) {
          if (book != null) {
            book.groupName = targetGroupName;
            book.updatedAt = now;
            toUpdate.add(book);
          }
        }
        if (toUpdate.isNotEmpty) {
          await isar.shelfBooks.putAll(toUpdate);
        }
      });
      return right(true);
    } catch (e) {
      return left('Move books failed: $e');
    }
  }

  /// Get book by ID
  Future<ShelfBook?> getBookById(int id) async {
    final isar = _isar;
    return await isar.shelfBooks.get(id);
  }

  /// Get book by file hash
  Future<ShelfBook?> getBookByHash(String fileHash) async {
    final isar = _isar;
    return await isar.shelfBooks.where().fileHashEqualTo(fileHash).findFirst();
  }

  /// Check if book exists by hash
  Future<bool> bookExists(String fileHash) async {
    final book = await getBookByHash(fileHash);
    return book != null;
  }

  /// Get book ID by hash
  Future<Id> getBookIdByHash(String fileHash) async {
    final book = await getBookByHash(fileHash);
    if (book != null) {
      return book.id;
    } else {
      throw Exception('Book not found for hash: $fileHash');
    }
  }

  /// Save or update a book
  Future<Either<String, int>> saveBook(ShelfBook book) async {
    try {
      final isar = _isar;
      final id = await isar.writeTxn(() async {
        return await isar.shelfBooks.put(book);
      });
      return right(id);
    } catch (e) {
      return left('Save failed: $e');
    }
  }

  /// Delete every book and group record.
  ///
  /// Used by the restore flow, which replaces the whole library with a backup
  /// instead of merging into the existing data. Auto-increment counters are
  /// left untouched so that ids of the removed rows are never reused.
  Future<void> clearAll() async {
    final isar = _isar;
    await isar.writeTxn(() async {
      await isar.shelfBooks.clear();
      await isar.shelfGroups.clear();
    });
  }

  /// Delete a book permanently by ID
  Future<Either<String, bool>> deleteBook(int id) async {
    try {
      final isar = _isar;
      final success = await isar.writeTxn(() async {
        return await isar.shelfBooks.delete(id);
      });
      return right(success);
    } catch (e) {
      return left('Delete failed: $e');
    }
  }

  /// Update reading progress
  Future<Either<String, bool>> updateProgress({
    required int bookId,
    required int currentChapterIndex,
    required double progress,
    required double? scrollPosition,
  }) async {
    try {
      final isar = _isar;
      final now = DateTime.now().millisecondsSinceEpoch;
      await isar.writeTxn(() async {
        final book = await isar.shelfBooks.get(bookId);
        if (book != null) {
          book.currentChapterIndex = currentChapterIndex;
          book.readingProgress = progress;
          book.chapterScrollPosition = scrollPosition;
          book.lastOpenedDate = now;
          await isar.shelfBooks.put(book);
        }
      });
      return right(true);
    } catch (e) {
      return left('Update progress failed: $e');
    }
  }

  /// Get recently opened books
  Future<List<ShelfBook>> getRecentBooks({int limit = 10}) async {
    final isar = _isar;
    return await isar.shelfBooks
        .filter()
        .lastOpenedDateIsNotNull()
        .sortByLastOpenedDateDesc()
        .limit(limit)
        .findAll();
  }

  /// Search books by title or author
  Future<List<ShelfBook>> searchBooks(String query) async {
    final isar = _isar;
    final lowercaseQuery = query.toLowerCase();

    return await isar.shelfBooks
        .filter()
        .group(
          (q) => q
              .titleContains(lowercaseQuery, caseSensitive: false)
              .or()
              .authorsElementContains(lowercaseQuery, caseSensitive: false),
        )
        .findAll();
  }
}
