import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/file_handling/file_handling.dart';

part 'unified_import_service_provider.g.dart';

/// Provider for UnifiedImportService
///
/// This service provides a unified interface for importing EPUB files
/// across different platforms (Android SAF and iOS file system).
///
/// Features:
/// - Pick multiple EPUB files
/// - Pick folder and scan for EPUB files recursively
/// - Process files into cached, hashed ImportableEpub objects
/// - Platform-agnostic API with native performance
@riverpod
UnifiedImportService unifiedImportService(Ref ref) {
  return UnifiedImportService();
}
