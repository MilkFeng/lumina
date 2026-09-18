import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/providers.dart';
import '../shelf_book_repository.dart';

part 'shelf_book_repository_provider.g.dart';

/// Provider for ShelfBookRepository
/// Repository for managing shelf book CRUD operations
@riverpod
ShelfBookRepository shelfBookRepository(ShelfBookRepositoryRef ref) {
  return ref
      .watch(isarProvider)
      .when(
        data: (isar) => ShelfBookRepository(isar: isar),
        loading: () => throw StateError(
          'Database is still initializing. '
          'Ensure the app awaits database initialization before accessing repositories.',
        ),
        error: (e, stack) => Error.throwWithStackTrace(
          StateError('Database initialization failed: $e'),
          stack,
        ),
      );
}
