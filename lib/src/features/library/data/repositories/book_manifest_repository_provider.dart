import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/providers.dart';
import '../book_manifest_repository.dart';

part 'book_manifest_repository_provider.g.dart';

/// Provider for BookManifestRepository
/// Repository for managing book manifest CRUD operations
@riverpod
BookManifestRepository bookManifestRepository(
  BookManifestRepositoryRef ref,
) {
  final isar = ref.watch(isarProvider).requireValue;
  return BookManifestRepository(isar: isar);
}
