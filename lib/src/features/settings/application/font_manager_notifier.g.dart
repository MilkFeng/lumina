// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_manager_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FontManagerNotifier)
final fontManagerProvider = FontManagerNotifierProvider._();

final class FontManagerNotifierProvider
    extends $NotifierProvider<FontManagerNotifier, List<ImportedFont>> {
  FontManagerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontManagerNotifierHash();

  @$internal
  @override
  FontManagerNotifier create() => FontManagerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ImportedFont> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ImportedFont>>(value),
    );
  }
}

String _$fontManagerNotifierHash() =>
    r'9f7ada19a6b56bfa2a4c3f736f27323789b980eb';

abstract class _$FontManagerNotifier extends $Notifier<List<ImportedFont>> {
  List<ImportedFont> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<ImportedFont>, List<ImportedFont>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ImportedFont>, List<ImportedFont>>,
              List<ImportedFont>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
