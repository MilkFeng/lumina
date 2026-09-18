// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the user's chosen app-wide theme settings alive for the entire
/// app session and persists them with [SharedPreferences].

@ProviderFor(AppThemeNotifier)
const appThemeProvider = AppThemeNotifierProvider._();

/// Keeps the user's chosen app-wide theme settings alive for the entire
/// app session and persists them with [SharedPreferences].
final class AppThemeNotifierProvider
    extends $NotifierProvider<AppThemeNotifier, AppThemeSettings> {
  /// Keeps the user's chosen app-wide theme settings alive for the entire
  /// app session and persists them with [SharedPreferences].
  const AppThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeNotifierHash();

  @$internal
  @override
  AppThemeNotifier create() => AppThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeSettings>(value),
    );
  }
}

String _$appThemeNotifierHash() => r'274878e7d790d46473099be1c9fc84d2eac0b110';

/// Keeps the user's chosen app-wide theme settings alive for the entire
/// app session and persists them with [SharedPreferences].

abstract class _$AppThemeNotifier extends $Notifier<AppThemeSettings> {
  AppThemeSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AppThemeSettings, AppThemeSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppThemeSettings, AppThemeSettings>,
              AppThemeSettings,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
