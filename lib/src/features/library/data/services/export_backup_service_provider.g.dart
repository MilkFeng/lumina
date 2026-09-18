// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_backup_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ExportBackupService].
///
/// Builds the service by injecting the two required repositories.
/// Because both repositories are synchronous providers, this provider
/// is also synchronous — no [FutureProvider] overhead needed.

@ProviderFor(exportBackupService)
final exportBackupServiceProvider = ExportBackupServiceProvider._();

/// Provider for [ExportBackupService].
///
/// Builds the service by injecting the two required repositories.
/// Because both repositories are synchronous providers, this provider
/// is also synchronous — no [FutureProvider] overhead needed.

final class ExportBackupServiceProvider
    extends
        $FunctionalProvider<
          ExportBackupService,
          ExportBackupService,
          ExportBackupService
        >
    with $Provider<ExportBackupService> {
  /// Provider for [ExportBackupService].
  ///
  /// Builds the service by injecting the two required repositories.
  /// Because both repositories are synchronous providers, this provider
  /// is also synchronous — no [FutureProvider] overhead needed.
  ExportBackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportBackupServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportBackupServiceHash();

  @$internal
  @override
  $ProviderElement<ExportBackupService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExportBackupService create(Ref ref) {
    return exportBackupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportBackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportBackupService>(value),
    );
  }
}

String _$exportBackupServiceHash() =>
    r'c3732989404e673610a941d8d1a155af2f5699ef';
