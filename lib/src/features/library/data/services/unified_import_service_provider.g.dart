// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_import_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unifiedImportServiceHash() =>
    r'0c1ecd50c896e25b2f150c0ea04b1f194926c670';

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
///
/// Copied from [unifiedImportService].
@ProviderFor(unifiedImportService)
final unifiedImportServiceProvider =
    AutoDisposeProvider<UnifiedImportService>.internal(
  unifiedImportService,
  name: r'unifiedImportServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unifiedImportServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UnifiedImportServiceRef = AutoDisposeProviderRef<UnifiedImportService>;
String _$importCacheManagerHash() =>
    r'f04a068bb0a002bd1962690296a6659e8d5cb92a';

/// Provider for ImportCacheManager
///
/// Manages the import cache directory and file operations.
/// Can be used directly if you need lower-level cache management.
///
/// Copied from [importCacheManager].
@ProviderFor(importCacheManager)
final importCacheManagerProvider =
    AutoDisposeProvider<ImportCacheManager>.internal(
  importCacheManager,
  name: r'importCacheManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$importCacheManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ImportCacheManagerRef = AutoDisposeProviderRef<ImportCacheManager>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
