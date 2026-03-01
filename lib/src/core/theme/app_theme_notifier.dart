import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'app_theme_settings.dart';

part 'app_theme_notifier.g.dart';

/// Keeps the user's chosen app-wide theme settings alive for the entire
/// app session and persists them with [SharedPreferences].
@Riverpod(keepAlive: true)
class AppThemeNotifier extends _$AppThemeNotifier {
  // ── Persistence keys ──────────────────────────────────────────────────────
  static const _kThemeMode = 'app_theme_mode';
  static const _kLightVariant = 'app_light_variant';
  static const _kDarkVariant = 'app_dark_variant';

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  AppThemeSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeModeIndex = prefs.getInt(_kThemeMode);
    final lightVariantIndex = prefs.getInt(_kLightVariant);
    final darkVariantIndex = prefs.getInt(_kDarkVariant);

    return AppThemeSettings().copyWith(
      themeMode: themeModeIndex != null
          ? AppThemeMode.values.elementAt(themeModeIndex)
          : null,
      lightVariant: lightVariantIndex != null
          ? AppLightThemeVariant.values.elementAt(lightVariantIndex)
          : null,
      darkVariant: darkVariantIndex != null
          ? AppDarkThemeVariant.values.elementAt(darkVariantIndex)
          : null,
    );
  }

  // ── Internal helper ───────────────────────────────────────────────────────
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  // ── Mutation methods ──────────────────────────────────────────────────────

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs.setInt(_kThemeMode, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLightVariant(AppLightThemeVariant variant) async {
    await _prefs.setInt(_kLightVariant, variant.index);
    state = state.copyWith(lightVariant: variant);
  }

  Future<void> setDarkVariant(AppDarkThemeVariant variant) async {
    await _prefs.setInt(_kDarkVariant, variant.index);
    state = state.copyWith(darkVariant: variant);
  }
}
