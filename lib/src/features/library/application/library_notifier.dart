import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../domain/shelf_book.dart';
import '../data/shelf_book_repository.dart';
import '../../../core/services/epub_import_service.dart';

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

/// Notifier for managing library operations
/// Updated to use ShelfBook and EpubImportService (stream-from-zip)
@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  late final ShelfBookRepository _repository;
  late final EpubImportService _importService;

  @override
  Future<LibraryState> build() async {
    _repository = ShelfBookRepository();
    _importService = EpubImportService();
    return await _loadBooks();
  }

  /// Load all books from database
  Future<LibraryState> _loadBooks() async {
    try {
      final books = await _repository.getAllBooks();
      return LibraryLoaded(books);
    } catch (e) {
      return LibraryError('Failed to load books: $e');
    }
  }

  /// Import a new book from file
  Future<Either<String, ShelfBook>> importBook(File file) async {
    state = const AsyncValue.loading();

    try {
      // Single call to import service handles everything
      final importResult = await _importService.importBook(file);

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

    for (final file in files) {
      final result = await _importService.importBook(file);

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
      // Get book
      final result = await _repository.softDeleteBook(bookId);
      if (result.isRight()) {
        await refresh();

        if (result.getRight().toNullable() == false) {
          return left('Delete failed');
        }
      } else {
        return left(result.getLeft().toNullable()!);
      }

      final book = await _repository.getBookById(bookId);
      if (book == null) {
        return left('Book not found');
      }

      // Delete using import service (handles files + database)
      final deleteResult = await _importService.deleteBook(book);
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
      final result = await _repository.updateBookGroup(
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

/// Provider for ShelfBook repository
@riverpod
ShelfBookRepository shelfBookRepository(ShelfBookRepositoryRef ref) {
  return ShelfBookRepository();
}

/// Provider for EPUB import service
@riverpod
EpubImportService epubImportService(EpubImportServiceRef ref) {
  return EpubImportService();
}
