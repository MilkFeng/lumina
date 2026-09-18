import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/shelf_book_repository_provider.dart';
import '../repositories/book_manifest_repository_provider.dart';
import 'epub_import_service.dart';

part 'epub_import_service_provider.g.dart';

/// Provider for EpubImportService
/// This service handles EPUB file import, parsing, and storage
@riverpod
EpubImportService epubImportService(EpubImportServiceRef ref) {
  final shelfBookRepo = ref.watch(shelfBookRepositoryProvider);
  final manifestRepo = ref.watch(bookManifestRepositoryProvider);

  return EpubImportService(
    shelfBookRepo: shelfBookRepo,
    manifestRepo: manifestRepo,
  );
}
