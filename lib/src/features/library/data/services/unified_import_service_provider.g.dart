// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_import_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(unifiedImportService)
const unifiedImportServiceProvider = UnifiedImportServiceProvider._();

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

final class UnifiedImportServiceProvider
    extends
        $FunctionalProvider<
          UnifiedImportService,
          UnifiedImportService,
          UnifiedImportService
        >
    with $Provider<UnifiedImportService> {
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
  const UnifiedImportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unifiedImportServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unifiedImportServiceHash();

  @$internal
  @override
  $ProviderElement<UnifiedImportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UnifiedImportService create(Ref ref) {
    return unifiedImportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnifiedImportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnifiedImportService>(value),
    );
  }
}

String _$unifiedImportServiceHash() =>
    r'ab8e62d4d7a2172d38a043c68f2a69fe28fe2506';

/// Provider for ImportCacheManager
///
/// Manages the import cache directory and file operations.
/// Can be used directly if you need lower-level cache management.

@ProviderFor(importCacheManager)
const importCacheManagerProvider = ImportCacheManagerProvider._();

/// Provider for ImportCacheManager
///
/// Manages the import cache directory and file operations.
/// Can be used directly if you need lower-level cache management.

final class ImportCacheManagerProvider
    extends
        $FunctionalProvider<
          ImportCacheManager,
          ImportCacheManager,
          ImportCacheManager
        >
    with $Provider<ImportCacheManager> {
  /// Provider for ImportCacheManager
  ///
  /// Manages the import cache directory and file operations.
  /// Can be used directly if you need lower-level cache management.
  const ImportCacheManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importCacheManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importCacheManagerHash();

  @$internal
  @override
  $ProviderElement<ImportCacheManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImportCacheManager create(Ref ref) {
    return importCacheManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportCacheManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportCacheManager>(value),
    );
  }
}

String _$importCacheManagerHash() =>
    r'4deec75b89537584bc3db1c2b155ba69564f62c8';
