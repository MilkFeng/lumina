// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the book import batch and exposes it to the library UI.
///
/// This notifier deliberately holds **no UI state**: the shelf renders from
/// `bookshelfProvider`, and the import dialog renders from the stream returned
/// by [importPipelineStream]. It exists to give that stream a `Ref` that
/// survives its many async gaps, which is also why it must stay alive — with
/// the default `autoDispose` the provider would be torn down as soon as no
/// widget is listening (for example while the import progress dialog is the
/// only thing on screen), and every later `ref.read` inside the generator would
/// throw "Cannot use the Ref ... after it has been disposed".
///
/// Restoring a backup lives in
/// `features/backup/application/backup_notifier.dart` instead, so that the
/// library feature never depends on the backup feature.

@ProviderFor(LibraryNotifier)
const libraryProvider = LibraryNotifierProvider._();

/// Drives the book import batch and exposes it to the library UI.
///
/// This notifier deliberately holds **no UI state**: the shelf renders from
/// `bookshelfProvider`, and the import dialog renders from the stream returned
/// by [importPipelineStream]. It exists to give that stream a `Ref` that
/// survives its many async gaps, which is also why it must stay alive — with
/// the default `autoDispose` the provider would be torn down as soon as no
/// widget is listening (for example while the import progress dialog is the
/// only thing on screen), and every later `ref.read` inside the generator would
/// throw "Cannot use the Ref ... after it has been disposed".
///
/// Restoring a backup lives in
/// `features/backup/application/backup_notifier.dart` instead, so that the
/// library feature never depends on the backup feature.
final class LibraryNotifierProvider
    extends $NotifierProvider<LibraryNotifier, void> {
  /// Drives the book import batch and exposes it to the library UI.
  ///
  /// This notifier deliberately holds **no UI state**: the shelf renders from
  /// `bookshelfProvider`, and the import dialog renders from the stream returned
  /// by [importPipelineStream]. It exists to give that stream a `Ref` that
  /// survives its many async gaps, which is also why it must stay alive — with
  /// the default `autoDispose` the provider would be torn down as soon as no
  /// widget is listening (for example while the import progress dialog is the
  /// only thing on screen), and every later `ref.read` inside the generator would
  /// throw "Cannot use the Ref ... after it has been disposed".
  ///
  /// Restoring a backup lives in
  /// `features/backup/application/backup_notifier.dart` instead, so that the
  /// library feature never depends on the backup feature.
  const LibraryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryNotifierHash();

  @$internal
  @override
  LibraryNotifier create() => LibraryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$libraryNotifierHash() => r'30989a5b956c67cebc8d90d5d0ba37654ea02a5f';

/// Drives the book import batch and exposes it to the library UI.
///
/// This notifier deliberately holds **no UI state**: the shelf renders from
/// `bookshelfProvider`, and the import dialog renders from the stream returned
/// by [importPipelineStream]. It exists to give that stream a `Ref` that
/// survives its many async gaps, which is also why it must stay alive — with
/// the default `autoDispose` the provider would be torn down as soon as no
/// widget is listening (for example while the import progress dialog is the
/// only thing on screen), and every later `ref.read` inside the generator would
/// throw "Cannot use the Ref ... after it has been disposed".
///
/// Restoring a backup lives in
/// `features/backup/application/backup_notifier.dart` instead, so that the
/// library feature never depends on the backup feature.

abstract class _$LibraryNotifier extends $Notifier<void> {
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
