// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_source_import_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Downloads books from an external source and feeds them into the library.
///
/// Two concerns chained in one place: downloading is the external-sources
/// feature's job (through its adapter), importing is the library feature's
/// ([EpubImportService]).
///
/// Emitting [ImportProgress] — the library's own event type — is deliberate: it
/// lets the existing import progress dialog render a remote import without
/// knowing where the bytes came from.
///
/// Kept alive because the generator holds a `Ref` across a download and an
/// import per file, and an `autoDispose` provider would be torn down as soon as
/// the progress dialog is the only thing on screen.

@ProviderFor(ExternalSourceImportNotifier)
const externalSourceImportProvider = ExternalSourceImportNotifierProvider._();

/// Downloads books from an external source and feeds them into the library.
///
/// Two concerns chained in one place: downloading is the external-sources
/// feature's job (through its adapter), importing is the library feature's
/// ([EpubImportService]).
///
/// Emitting [ImportProgress] — the library's own event type — is deliberate: it
/// lets the existing import progress dialog render a remote import without
/// knowing where the bytes came from.
///
/// Kept alive because the generator holds a `Ref` across a download and an
/// import per file, and an `autoDispose` provider would be torn down as soon as
/// the progress dialog is the only thing on screen.
final class ExternalSourceImportNotifierProvider
    extends $NotifierProvider<ExternalSourceImportNotifier, void> {
  /// Downloads books from an external source and feeds them into the library.
  ///
  /// Two concerns chained in one place: downloading is the external-sources
  /// feature's job (through its adapter), importing is the library feature's
  /// ([EpubImportService]).
  ///
  /// Emitting [ImportProgress] — the library's own event type — is deliberate: it
  /// lets the existing import progress dialog render a remote import without
  /// knowing where the bytes came from.
  ///
  /// Kept alive because the generator holds a `Ref` across a download and an
  /// import per file, and an `autoDispose` provider would be torn down as soon as
  /// the progress dialog is the only thing on screen.
  const ExternalSourceImportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalSourceImportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalSourceImportNotifierHash();

  @$internal
  @override
  ExternalSourceImportNotifier create() => ExternalSourceImportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$externalSourceImportNotifierHash() =>
    r'9a94abb57cc2680e9dfdfb23b8c362f40e70e3ec';

/// Downloads books from an external source and feeds them into the library.
///
/// Two concerns chained in one place: downloading is the external-sources
/// feature's job (through its adapter), importing is the library feature's
/// ([EpubImportService]).
///
/// Emitting [ImportProgress] — the library's own event type — is deliberate: it
/// lets the existing import progress dialog render a remote import without
/// knowing where the bytes came from.
///
/// Kept alive because the generator holds a `Ref` across a download and an
/// import per file, and an `autoDispose` provider would be torn down as soon as
/// the progress dialog is the only thing on screen.

abstract class _$ExternalSourceImportNotifier extends $Notifier<void> {
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
