import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pdf_password_manager.dart';

/// Provider for PdfPasswordManager
/// This singleton manages secure storage of PDF passwords
final pdfPasswordManagerProvider = Provider<PdfPasswordManager>((ref) {
  return PdfPasswordManager();
});