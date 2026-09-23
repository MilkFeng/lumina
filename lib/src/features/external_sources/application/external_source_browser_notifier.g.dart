// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_source_browser_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Folder navigation for one external source.
///
/// Holds only the folder stack and its listing state — not the selection and not
/// the import progress. Those are per-screen concerns, and putting them here
/// would rebuild the whole list on every import tick.
///
/// Kept alive per source so that leaving the screen and coming back resumes
/// where the user was.

@ProviderFor(ExternalSourceBrowserNotifier)
const externalSourceBrowserProvider = ExternalSourceBrowserNotifierFamily._();

/// Folder navigation for one external source.
///
/// Holds only the folder stack and its listing state — not the selection and not
/// the import progress. Those are per-screen concerns, and putting them here
/// would rebuild the whole list on every import tick.
///
/// Kept alive per source so that leaving the screen and coming back resumes
/// where the user was.
final class ExternalSourceBrowserNotifierProvider
    extends
        $NotifierProvider<
          ExternalSourceBrowserNotifier,
          ExternalSourceBrowserState
        > {
  /// Folder navigation for one external source.
  ///
  /// Holds only the folder stack and its listing state — not the selection and not
  /// the import progress. Those are per-screen concerns, and putting them here
  /// would rebuild the whole list on every import tick.
  ///
  /// Kept alive per source so that leaving the screen and coming back resumes
  /// where the user was.
  const ExternalSourceBrowserNotifierProvider._({
    required ExternalSourceBrowserNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'externalSourceBrowserProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$externalSourceBrowserNotifierHash();

  @override
  String toString() {
    return r'externalSourceBrowserProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExternalSourceBrowserNotifier create() => ExternalSourceBrowserNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExternalSourceBrowserState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExternalSourceBrowserState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExternalSourceBrowserNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$externalSourceBrowserNotifierHash() =>
    r'343d5cb0b5b31a10d49f1edccd0d32fc2aabeff9';

/// Folder navigation for one external source.
///
/// Holds only the folder stack and its listing state — not the selection and not
/// the import progress. Those are per-screen concerns, and putting them here
/// would rebuild the whole list on every import tick.
///
/// Kept alive per source so that leaving the screen and coming back resumes
/// where the user was.

final class ExternalSourceBrowserNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ExternalSourceBrowserNotifier,
          ExternalSourceBrowserState,
          ExternalSourceBrowserState,
          ExternalSourceBrowserState,
          int
        > {
  const ExternalSourceBrowserNotifierFamily._()
    : super(
        retry: null,
        name: r'externalSourceBrowserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Folder navigation for one external source.
  ///
  /// Holds only the folder stack and its listing state — not the selection and not
  /// the import progress. Those are per-screen concerns, and putting them here
  /// would rebuild the whole list on every import tick.
  ///
  /// Kept alive per source so that leaving the screen and coming back resumes
  /// where the user was.

  ExternalSourceBrowserNotifierProvider call(int sourceId) =>
      ExternalSourceBrowserNotifierProvider._(argument: sourceId, from: this);

  @override
  String toString() => r'externalSourceBrowserProvider';
}

/// Folder navigation for one external source.
///
/// Holds only the folder stack and its listing state — not the selection and not
/// the import progress. Those are per-screen concerns, and putting them here
/// would rebuild the whole list on every import tick.
///
/// Kept alive per source so that leaving the screen and coming back resumes
/// where the user was.

abstract class _$ExternalSourceBrowserNotifier
    extends $Notifier<ExternalSourceBrowserState> {
  late final _$args = ref.$arg as int;
  int get sourceId => _$args;

  ExternalSourceBrowserState build(int sourceId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<ExternalSourceBrowserState, ExternalSourceBrowserState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ExternalSourceBrowserState,
                ExternalSourceBrowserState
              >,
              ExternalSourceBrowserState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
