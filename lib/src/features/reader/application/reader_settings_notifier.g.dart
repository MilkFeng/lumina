// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReaderSettingsNotifier)
final readerSettingsProvider = ReaderSettingsNotifierProvider._();

final class ReaderSettingsNotifierProvider
    extends $NotifierProvider<ReaderSettingsNotifier, ReaderSettings> {
  ReaderSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerSettingsNotifierHash();

  @$internal
  @override
  ReaderSettingsNotifier create() => ReaderSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReaderSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReaderSettings>(value),
    );
  }
}

String _$readerSettingsNotifierHash() =>
    r'2fc99f565d63105b2f243e0afb0b6501e30d47c8';

abstract class _$ReaderSettingsNotifier extends $Notifier<ReaderSettings> {
  ReaderSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReaderSettings, ReaderSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReaderSettings, ReaderSettings>,
              ReaderSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
