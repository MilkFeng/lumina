import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/providers.dart';
import '../shelf_book_repository.dart';

part 'shelf_book_repository_provider.g.dart';

/// Provider for ShelfBookRepository
/// Repository for managing shelf book CRUD operations
@riverpod
ShelfBookRepository shelfBookRepository(ShelfBookRepositoryRef ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return ShelfBookRepository(isar: isar);
}
