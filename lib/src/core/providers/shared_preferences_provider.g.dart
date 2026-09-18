// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A synchronous, keep-alive provider for [SharedPreferences].
///
/// ⚠️ This will throw an [UnimplementedError] by default.
/// It MUST be overridden in `main.dart` using `overrideWithValue`
/// after `SharedPreferences.getInstance()` is awaited.

@ProviderFor(sharedPreferences)
const sharedPreferencesProvider = SharedPreferencesProvider._();

/// A synchronous, keep-alive provider for [SharedPreferences].
///
/// ⚠️ This will throw an [UnimplementedError] by default.
/// It MUST be overridden in `main.dart` using `overrideWithValue`
/// after `SharedPreferences.getInstance()` is awaited.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// A synchronous, keep-alive provider for [SharedPreferences].
  ///
  /// ⚠️ This will throw an [UnimplementedError] by default.
  /// It MUST be overridden in `main.dart` using `overrideWithValue`
  /// after `SharedPreferences.getInstance()` is awaited.
  const SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'a93f25206ddd003bb76187306dedc371f5d90201';
