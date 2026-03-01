import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/reader_settings.dart';

part 'reader_settings_notifier.g.dart';

@riverpod
class ReaderSettingsNotifier extends _$ReaderSettingsNotifier {
  // ── Persistence keys ────────────────────────────────────────────────────────
  static const _kZoom = 'reader_zoom';
  static const _kFollowApp = 'reader_follow_app';
  static const _kThemeMode = 'reader_theme_mode';
  static const _kMarginTop = 'reader_margin_top';
  static const _kMarginBottom = 'reader_margin_bottom';
  static const _kMarginLeft = 'reader_margin_left';
  static const _kMarginRight = 'reader_margin_right';
  static const _kLinkHandling = 'reader_link_handling';
  static const _kHandleIntraLink = 'reader_handle_intra_link';

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  ReaderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final linkHandlingIndex = prefs.getInt(_kLinkHandling);

    return ReaderSettings().copyWith(
      zoom: prefs.getDouble(_kZoom),
      followAppTheme: prefs.getBool(_kFollowApp),
      themeIndex: prefs.getInt(_kThemeMode),
      marginTop: prefs.getDouble(_kMarginTop),
      marginBottom: prefs.getDouble(_kMarginBottom),
      marginLeft: prefs.getDouble(_kMarginLeft),
      marginRight: prefs.getDouble(_kMarginRight),
      linkHandling: linkHandlingIndex != null
          ? ReaderLinkHandling.values.elementAt(linkHandlingIndex)
          : null,
      handleIntraLink: prefs.getBool(_kHandleIntraLink),
    );
  }

  // ── Convenience accessor ─────────────────────────────────────────────────────
  /// Returns the [SharedPreferences] instance synchronously.
  /// Safe to call inside mutation methods because [sharedPreferencesProvider]
  /// is [keepAlive] and will already be resolved by the time the UI can
  /// trigger any of these methods.
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  // ── Mutation methods ─────────────────────────────────────────────────────────

  Future<void> setZoom(double zoom) async {
    await _prefs.setDouble(_kZoom, zoom);
    state = state.copyWith(zoom: zoom);
  }

  Future<void> setFollowAppTheme(bool follow) async {
    await _prefs.setBool(_kFollowApp, follow);
    state = state.copyWith(followAppTheme: follow);
  }

  Future<void> setThemeIndex(int index) async {
    await _prefs.setInt(_kThemeMode, index);
    state = state.copyWith(themeIndex: index);
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

  Future<void> setLinkHandling(ReaderLinkHandling value) async {
    await _prefs.setInt(_kLinkHandling, value.index);
    state = state.copyWith(linkHandling: value);
  }

  Future<void> setHandleIntraLink(bool value) async {
    await _prefs.setBool(_kHandleIntraLink, value);
    state = state.copyWith(handleIntraLink: value);
  }
}
