import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/providers.dart';
import '../book_manifest_repository.dart';

part 'book_manifest_repository_provider.g.dart';

/// Provider for BookManifestRepository
/// Repository for managing book manifest CRUD operations
@riverpod
BookManifestRepository bookManifestRepository(BookManifestRepositoryRef ref) {
  return ref
      .watch(isarProvider)
      .when(
        data: (isar) => BookManifestRepository(isar: isar),
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
