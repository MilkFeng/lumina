import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/shelf_book_repository_provider.dart';
import '../repositories/book_manifest_repository_provider.dart';
import '../../application/pdf_password_manager_provider.dart';
import 'pdf_import_service.dart';

part 'pdf_import_service_provider.g.dart';

/// Provider for PdfImportService
/// This service handles PDF file import, parsing, and storage
/// Supports password-protected PDFs by importing them even without metadata
@riverpod
PdfImportService pdfImportService(PdfImportServiceRef ref) {
  final shelfBookRepo = ref.watch(shelfBookRepositoryProvider);
  final manifestRepo = ref.watch(bookManifestRepositoryProvider);
  final passwordManager = ref.watch(pdfPasswordManagerProvider);

  return PdfImportService(
    shelfBookRepo: shelfBookRepo,
    manifestRepo: manifestRepo,
    passwordManager: passwordManager,
  );
}