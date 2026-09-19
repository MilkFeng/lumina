// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives backup restore.
///
/// Restore lives here rather than on `LibraryNotifier` so that the library
/// feature does not have to depend on the backup feature; the dependency runs
/// the other way round, exactly once, through `bookshelfProvider`.
///
/// Must stay alive: [restoreFromBackup] is a generator that keeps using `ref`
/// across many async gaps, and an `autoDispose` provider would be torn down as
/// soon as no widget is listening — see `LibraryNotifier` for the same
/// reasoning.

@ProviderFor(BackupNotifier)
const backupProvider = BackupNotifierProvider._();

/// Drives backup restore.
///
/// Restore lives here rather than on `LibraryNotifier` so that the library
/// feature does not have to depend on the backup feature; the dependency runs
/// the other way round, exactly once, through `bookshelfProvider`.
///
/// Must stay alive: [restoreFromBackup] is a generator that keeps using `ref`
/// across many async gaps, and an `autoDispose` provider would be torn down as
/// soon as no widget is listening — see `LibraryNotifier` for the same
/// reasoning.
final class BackupNotifierProvider
    extends $NotifierProvider<BackupNotifier, void> {
  /// Drives backup restore.
  ///
  /// Restore lives here rather than on `LibraryNotifier` so that the library
  /// feature does not have to depend on the backup feature; the dependency runs
  /// the other way round, exactly once, through `bookshelfProvider`.
  ///
  /// Must stay alive: [restoreFromBackup] is a generator that keeps using `ref`
  /// across many async gaps, and an `autoDispose` provider would be torn down as
  /// soon as no widget is listening — see `LibraryNotifier` for the same
  /// reasoning.
  const BackupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupNotifierHash();

  @$internal
  @override
  BackupNotifier create() => BackupNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backupNotifierHash() => r'37fe13ba88fcbbc37a7e72623d5e3eabd2c77bf4';

/// Drives backup restore.
///
/// Restore lives here rather than on `LibraryNotifier` so that the library
/// feature does not have to depend on the backup feature; the dependency runs
/// the other way round, exactly once, through `bookshelfProvider`.
///
/// Must stay alive: [restoreFromBackup] is a generator that keeps using `ref`
/// across many async gaps, and an `autoDispose` provider would be torn down as
/// soon as no widget is listening — see `LibraryNotifier` for the same
/// reasoning.

abstract class _$BackupNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
