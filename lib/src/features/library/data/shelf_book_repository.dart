import 'package:isar/isar.dart';
import 'package:fpdart/fpdart.dart';
import '../domain/shelf_book.dart';
import '../domain/shelf_group.dart';
import '../../../core/database/isar_service.dart';

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
  /// Get all books (excluding deleted) sorted by import date (newest first)
  Future<List<ShelfBook>> getAllBooks() async {
    final isar = await IsarService.getInstance();
    return await isar.shelfBooks
        .filter()
        .isDeletedEqualTo(false)
        .sortByImportDateDesc()
        .findAll();
  }

  /// Get all books with advanced sorting and optional group filter
  Future<List<ShelfBook>> getBooksSorted({
    ShelfBookSortBy sortBy = ShelfBookSortBy.recentlyAdded,
    String? groupName,
    bool includeAll = false,
  }) async {
    final isar = await IsarService.getInstance();

    // Build filter conditions
    var query = isar.shelfBooks.filter().isDeletedEqualTo(false);

    if (!includeAll) {
      if (groupName != null) {
        query = query.groupNameEqualTo(groupName);
      } else {
        query = query.groupNameIsNull();
      }
    }

    // Cast to sortable query builder
    final sortableQuery = query as QueryBuilder<ShelfBook, ShelfBook, QSortBy>;

    // Apply sorting
    switch (sortBy) {
      case ShelfBookSortBy.titleAsc:
        return await sortableQuery.sortByTitle().findAll();
      case ShelfBookSortBy.titleDesc:
        return await sortableQuery.sortByTitleDesc().findAll();
      case ShelfBookSortBy.authorAsc:
        return await sortableQuery.sortByAuthor().findAll();
      case ShelfBookSortBy.authorDesc:
        return await sortableQuery.sortByAuthorDesc().findAll();
      case ShelfBookSortBy.recentlyRead:
        return await sortableQuery.sortByLastOpenedDateDesc().findAll();
      case ShelfBookSortBy.recentlyAdded:
        return await sortableQuery.sortByImportDateDesc().findAll();
      case ShelfBookSortBy.progress:
        return await sortableQuery.sortByReadingProgressDesc().findAll();
    }
  }

  /// Get all groups (flat structure, no nesting)
  Future<List<ShelfGroup>> getGroups() async {
    final isar = await IsarService.getInstance();
    return await isar.shelfGroups
        .filter()
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  /// Get all groups (for move dialog)
  Future<List<ShelfGroup>> getAllGroups() async {
    final isar = await IsarService.getInstance();
    return await isar.shelfGroups
        .filter()
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  /// Get group by ID
  Future<ShelfGroup?> getGroupById(int id) async {
    final isar = await IsarService.getInstance();
    return await isar.shelfGroups.get(id);
  }

  /// Create a new group
  Future<Either<String, int>> createGroup({required String name}) async {
    try {
      final isar = await IsarService.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final group = ShelfGroup()
        ..name = name
        ..creationDate = now
        ..updatedAt = now
        ..isDeleted = false;
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
      final isar = await IsarService.getInstance();
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
      final isar = await IsarService.getInstance();
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

        // Soft delete the group
        group.isDeleted = true;
        group.updatedAt = now;
        await isar.shelfGroups.put(group);
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
      final isar = await IsarService.getInstance();
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
      final isar = await IsarService.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await isar.writeTxn(() async {
        for (final bookId in bookIds) {
          final book = await isar.shelfBooks.get(bookId);
          if (book != null) {
            book.groupName = targetGroupName;
            book.updatedAt = now;
            await isar.shelfBooks.put(book);
          }
        }
      });
      return right(true);
    } catch (e) {
      return left('Move books failed: $e');
    }
  }

  /// Soft delete a book (marks as deleted instead of removing)
  Future<Either<String, bool>> softDeleteBook(int bookId) async {
    try {
      final isar = await IsarService.getInstance();
      await isar.writeTxn(() async {
        final book = await isar.shelfBooks.get(bookId);
        if (book != null) {
          book.isDeleted = true;
          book.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await isar.shelfBooks.put(book);
        }
      });
      return right(true);
    } catch (e) {
      return left('Soft delete failed: $e');
    }
  }

  /// Get book by ID
  Future<ShelfBook?> getBookById(int id) async {
    final isar = await IsarService.getInstance();
    return await isar.shelfBooks.get(id);
  }

  /// Get book by file hash
  Future<ShelfBook?> getBookByHash(String fileHash) async {
    final isar = await IsarService.getInstance();
    return await isar.shelfBooks.where().fileHashEqualTo(fileHash).findFirst();
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
      final isar = await IsarService.getInstance();
      final id = await isar.writeTxn(() async {
        return await isar.shelfBooks.put(book);
      });
      return right(id);
    } catch (e) {
      return left('Save failed: $e');
    }
  }

  /// Delete a book permanently by ID
  Future<Either<String, bool>> deleteBook(int id) async {
    try {
      final isar = await IsarService.getInstance();
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
      final isar = await IsarService.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await isar.writeTxn(() async {
        final book = await isar.shelfBooks.get(bookId);
        if (book != null) {
          book.currentChapterIndex = currentChapterIndex;
          book.readingProgress = progress;
          book.chapterScrollPosition = scrollPosition;
          book.lastOpenedDate = now;
          book.updatedAt = now;
          await isar.shelfBooks.put(book);
        }
      });
      return right(true);
    } catch (e) {
      return left('Update progress failed: $e');
    }
  }

  /// Mark book as finished
  Future<Either<String, bool>> markAsFinished(int bookId) async {
    try {
      final isar = await IsarService.getInstance();
      await isar.writeTxn(() async {
        final book = await isar.shelfBooks.get(bookId);
        if (book != null) {
          book.isFinished = true;
          book.readingProgress = 1.0;
          book.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await isar.shelfBooks.put(book);
        }
      });
      return right(true);
    } catch (e) {
      return left('Mark finished failed: $e');
    }
  }

  /// Get recently opened books
  Future<List<ShelfBook>> getRecentBooks({int limit = 10}) async {
    final isar = await IsarService.getInstance();
    return await isar.shelfBooks
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .lastOpenedDateIsNotNull()
        .sortByLastOpenedDateDesc()
        .limit(limit)
        .findAll();
  }

  /// Search books by title or author
  Future<List<ShelfBook>> searchBooks(String query) async {
    final isar = await IsarService.getInstance();
    final lowercaseQuery = query.toLowerCase();

    return await isar.shelfBooks
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .group(
          (q) => q
              .titleContains(lowercaseQuery, caseSensitive: false)
              .or()
              .authorContains(lowercaseQuery, caseSensitive: false),
        )
        .findAll();
  }
}
