import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../domain/shelf_book.dart';
import '../data/repositories/shelf_book_repository_provider.dart';
import '../data/services/epub_import_service_provider.dart';

part 'library_notifier.g.dart';

/// State for library operations (updated for ShelfBook)
sealed class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<ShelfBook> books;
  LibraryLoaded(this.books);
}

class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);
}

/// Notifier for managing library operations with dependency injection
@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  @override
  Future<LibraryState> build() async {
    return await _loadBooks();
  }

  /// Load all books from database
  Future<LibraryState> _loadBooks() async {
    try {
      final repository = ref.read(shelfBookRepositoryProvider);
      final books = await repository.getAllBooks();
      return LibraryLoaded(books);
    } catch (e) {
      return LibraryError('Failed to load books: $e');
    }
  }

  /// Import a new book from file
  Future<Either<String, ShelfBook>> importBook(File file) async {
    state = const AsyncValue.loading();

    try {
      final importService = ref.read(epubImportServiceProvider);
      // Single call to import service handles everything
      final importResult = await importService.importBook(file);

      if (importResult.isLeft()) {
        final error = importResult.getLeft().toNullable()!;
        state = AsyncValue.data(LibraryError(error));
        return left(error);
      }

      final book = importResult.getRight().toNullable()!;

      // Reload books to update UI
      state = await AsyncValue.guard(() => _loadBooks());

      return right(book);
    } catch (e) {
      final error = 'Import failed: $e';
      state = AsyncValue.data(LibraryError(error));
      return left(error);
    }
  }

  /// Import multiple books at once
  Future<(int success, int failed, List<String> errors)> importMultipleBooks(
    List<File> files,
  ) async {
    int successCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    final importService = ref.read(epubImportServiceProvider);

    for (final file in files) {
      final result = await importService.importBook(file);

      result.fold((error) {
        failedCount++;
        errors.add('${file.path.split('/').last}: $error');
      }, (_) => successCount++);
    }

    // Reload once after all imports
    await refresh();

    return (successCount, failedCount, errors);
  }

  /// Refresh book list
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _loadBooks());
  }

  /// Delete a book (removes .epub file, cover, and database records)
  Future<Either<String, bool>> deleteBook(int bookId) async {
    try {
      final repository = ref.read(shelfBookRepositoryProvider);
      final importService = ref.read(epubImportServiceProvider);

      // Get book
      final result = await repository.softDeleteBook(bookId);
      if (result.isRight()) {
        await refresh();

        if (result.getRight().toNullable() == false) {
          return left('Delete failed');
        }
      } else {
        return left(result.getLeft().toNullable()!);
      }

      final book = await repository.getBookById(bookId);
      if (book == null) {
        return left('Book not found');
      }

      // Delete using import service (handles files + database)
      final deleteResult = await importService.deleteBook(book);
      if (deleteResult.isLeft()) {
        return left(deleteResult.getLeft().toNullable()!);
      }

      // Refresh list
      await refresh();

      return right(true);
    } catch (e) {
      return left('Delete failed: $e');
    }
  }

  /// Update book group
  Future<Either<String, bool>> updateGroup({
    required int bookId,
    String? groupName,
  }) async {
    try {
      final repository = ref.read(shelfBookRepositoryProvider);
      final result = await repository.updateBookGroup(
        bookId: bookId,
        groupName: groupName,
      );

      if (result.isRight()) {
        await refresh();
      }

      return result;
    } catch (e) {
      return left('Update category failed: $e');
    }
  }
}
