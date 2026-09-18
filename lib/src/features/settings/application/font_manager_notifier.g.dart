// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_manager_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FontManagerNotifier)
const fontManagerProvider = FontManagerNotifierProvider._();

final class FontManagerNotifierProvider
    extends $NotifierProvider<FontManagerNotifier, List<ImportedFont>> {
  const FontManagerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontManagerProvider',
        isAutoDispose: false,
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
    r'f7e24c743a92b480c72b2a9bc411de73eff7d305';

abstract class _$FontManagerNotifier extends $Notifier<List<ImportedFont>> {
  List<ImportedFont> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<ImportedFont>, List<ImportedFont>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ImportedFont>, List<ImportedFont>>,
              List<ImportedFont>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
