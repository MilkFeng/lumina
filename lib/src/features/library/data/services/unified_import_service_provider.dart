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
UnifiedImportService unifiedImportService(UnifiedImportServiceRef ref) {
  return UnifiedImportService();
}

/// Provider for ImportCacheManager
///
/// Manages the import cache directory and file operations.
/// Can be used directly if you need lower-level cache management.
@riverpod
ImportCacheManager importCacheManager(ImportCacheManagerRef ref) {
  return ImportCacheManager();
}
