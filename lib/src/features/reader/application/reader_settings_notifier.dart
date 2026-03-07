import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:lumina/src/features/settings/application/imported_font_file_names_provider.dart';
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
  static const _kPageAnimation = 'reader_page_animation';
  static const _kFontFileName = 'reader_font_file_name';
  static const _kOverrideFontFamily = 'reader_override_font_family';
  static const _kVolumeKeyTurnsPage = 'reader_volume_key_turns_page';

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  ReaderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final linkHandlingIndex = prefs.getInt(_kLinkHandling);
    final pageAnimationIndex = prefs.getInt(_kPageAnimation);

    // Validate stored font is still in the imported fonts list; clean up if not.
    String? fontFileName = prefs.getString(_kFontFileName);
    bool? overrideFontFamily = prefs.getBool(_kOverrideFontFamily);
    if (fontFileName != null) {
      final importedNames = ref.watch(importedFontFileNamesProvider);
      if (!importedNames.contains(fontFileName)) {
        fontFileName = null;
        overrideFontFamily = false;

        // fire-and-forget cleanup
        prefs.remove(_kFontFileName);
        prefs.remove(_kOverrideFontFamily);
      }
    }

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
      pageAnimation: pageAnimationIndex != null
          ? ReaderPageAnimation.values.elementAt(pageAnimationIndex)
          : null,
      fontFileName: fontFileName,
      overrideFontFamily: overrideFontFamily,
      volumeKeyTurnsPage: prefs.getBool(_kVolumeKeyTurnsPage),
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

  Future<void> setPageAnimation(ReaderPageAnimation value) async {
    await _prefs.setInt(_kPageAnimation, value.index);
    state = state.copyWith(pageAnimation: value);
  }

  Future<void> setFontFileName(String? value) async {
    if (value == null) {
      await _prefs.remove(_kFontFileName);
    } else {
      await _prefs.setString(_kFontFileName, value);
    }
    state = state.copyWith(fontFileName: value);
  }

  Future<void> setOverrideFontFamily(bool value) async {
    await _prefs.setBool(_kOverrideFontFamily, value);
    state = state.copyWith(overrideFontFamily: value);
  }

  Future<void> setVolumeKeyTurnsPage(bool value) async {
    await _prefs.setBool(_kVolumeKeyTurnsPage, value);
    state = state.copyWith(volumeKeyTurnsPage: value);
  }
}
