import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/reader_settings.dart';

part 'reader_settings_notifier.g.dart';

@riverpod
class ReaderSettingsNotifier extends _$ReaderSettingsNotifier {
  // ── Persistence keys ────────────────────────────────────────────────────────
  static const _kZoom = 'reader_zoom';
  static const _kFollowSystem = 'reader_follow_system';
  static const _kThemeMode = 'reader_theme_mode';
  static const _kMarginTop = 'reader_margin_top';
  static const _kMarginBottom = 'reader_margin_bottom';
  static const _kMarginLeft = 'reader_margin_left';
  static const _kMarginRight = 'reader_margin_right';

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  ReaderSettings build() {
    return ref
        .watch(sharedPreferencesProvider)
        .when(
          data: (prefs) => ReaderSettings(
            zoom: prefs.getDouble(_kZoom) ?? 1.0,
            followSystemTheme: prefs.getBool(_kFollowSystem) ?? true,
            themeMode:
                ReaderSettingThemeMode.values[prefs.getInt(_kThemeMode) ??
                    ReaderSettingThemeMode.light.index],
            marginTop: prefs.getDouble(_kMarginTop) ?? 16.0,
            marginBottom: prefs.getDouble(_kMarginBottom) ?? 16.0,
            marginLeft: prefs.getDouble(_kMarginLeft) ?? 16.0,
            marginRight: prefs.getDouble(_kMarginRight) ?? 16.0,
          ),
          loading: () => const ReaderSettings(),
          error: (_, __) => const ReaderSettings(),
        );
  }

  // ── Convenience accessor ─────────────────────────────────────────────────────
  /// Returns the [SharedPreferences] instance synchronously.
  /// Safe to call inside mutation methods because [sharedPreferencesProvider]
  /// is [keepAlive] and will already be resolved by the time the UI can
  /// trigger any of these methods.
  SharedPreferences get _prefs =>
      ref.read(sharedPreferencesProvider).requireValue;

  // ── Mutation methods ─────────────────────────────────────────────────────────

  Future<void> setZoom(double zoom) async {
    await _prefs.setDouble(_kZoom, zoom);
    state = state.copyWith(zoom: zoom);
  }

  Future<void> setFollowSystemTheme(bool follow) async {
    await _prefs.setBool(_kFollowSystem, follow);
    state = state.copyWith(followSystemTheme: follow);
  }

  Future<void> setThemeMode(ReaderSettingThemeMode mode) async {
    await _prefs.setInt(_kThemeMode, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setMarginTop(double value) async {
    await _prefs.setDouble(_kMarginTop, value);
    state = state.copyWith(marginTop: value);
  }

  Future<void> setMarginBottom(double value) async {
    await _prefs.setDouble(_kMarginBottom, value);
    state = state.copyWith(marginBottom: value);
  }

  Future<void> setMarginLeft(double value) async {
    await _prefs.setDouble(_kMarginLeft, value);
    state = state.copyWith(marginLeft: value);
  }

  Future<void> setMarginRight(double value) async {
    await _prefs.setDouble(_kMarginRight, value);
    state = state.copyWith(marginRight: value);
  }
}
