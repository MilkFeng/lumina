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
  static const _kThemeVariant = 'app_theme_variant';

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  AppThemeSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeModeIndex = prefs.getInt(_kThemeMode);
    final themeVariantIndex = prefs.getInt(_kThemeVariant);

    return AppThemeSettings().copyWith(
      themeMode: themeModeIndex != null
          ? AppThemeMode.values.elementAt(themeModeIndex)
          : null,
      themeVariant: themeVariantIndex != null
          ? AppThemeVariant.values.elementAt(themeVariantIndex)
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

  Future<void> setThemeVariant(AppThemeVariant variant) async {
    await _prefs.setInt(_kThemeVariant, variant.index);
    state = state.copyWith(themeVariant: variant);
  }
}
