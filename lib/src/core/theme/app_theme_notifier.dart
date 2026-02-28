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
    return ref
        .watch(sharedPreferencesProvider)
        .when(
          data: (prefs) => AppThemeSettings(
            themeMode: AppThemeMode
                .values[prefs.getInt(_kThemeMode) ?? AppThemeMode.system.index],
            lightVariant:
                AppLightThemeVariant.values[prefs.getInt(_kLightVariant) ??
                    AppLightThemeVariant.standard.index],
            darkVariant:
                AppDarkThemeVariant.values[prefs.getInt(_kDarkVariant) ??
                    AppDarkThemeVariant.standard.index],
          ),
          loading: () => const AppThemeSettings(),
          error: (_, __) => const AppThemeSettings(),
        );
  }

  // ── Internal helper ───────────────────────────────────────────────────────
  SharedPreferences get _prefs =>
      ref.read(sharedPreferencesProvider).requireValue;

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
