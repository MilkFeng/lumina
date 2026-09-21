import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme_settings.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

/// Controls how the reader handles external link taps.
enum ReaderLinkHandling { ask, always, never }

/// Controls the page-turning animation style.
enum ReaderPageAnimation { none, slide }

/// Controls how a chapter is laid out and advanced.
///
/// [paginated] is the classic discrete mode: the chapter is split into columns
/// and a page turn moves by exactly one column.  [scrolling] lays the chapter
/// out as a single continuous column that is scrolled vertically, with
/// chapter switching handled by the control panel arrows.
enum ReaderScrollMode { paginated, scrolling }

class ReaderSettings {
  final double zoom;
  final double lineHeight;
  final bool changeLineHeight;
  final bool followAppTheme;

  /// Index into [AppThemeSettings.allColorSchemes] representing the reader theme.
  final int themeIndex;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final ReaderLinkHandling linkHandling;
  final bool handleIntraLink;
  final ReaderPageAnimation pageAnimation;

  /// Chapter layout mode.  Only honoured for left-to-right books; see
  /// [supportsScrollMode].
  final ReaderScrollMode scrollMode;

  /// File name (with extension) of the user-imported font to use, or null to
  /// use the epub's own fonts.
  final String? fontFileName;

  /// When true the custom font overrides the epub's own font-family rules.
  final bool overrideFontFamily;

  /// When true, volume up/down keys turn pages in the reader.
  final bool volumeKeyTurnsPage;

  const ReaderSettings({
    this.zoom = 1.0,
    this.lineHeight = 1.6,
    this.changeLineHeight = false,
    this.followAppTheme = true,
    this.themeIndex = 0,
    this.marginTop = 16.0,
    this.marginBottom = 16.0,
    this.marginLeft = 16.0,
    this.marginRight = 16.0,
    this.linkHandling = ReaderLinkHandling.ask,
    this.handleIntraLink = true,
    this.pageAnimation = ReaderPageAnimation.slide,
    this.scrollMode = ReaderScrollMode.paginated,
    this.fontFileName,
    this.overrideFontFamily = false,
    this.volumeKeyTurnsPage = false,
  });

  // Sentinel: lets copyWith(fontFileName: null) mean "set to null" rather than
  // "leave unchanged". Used only for the nullable fontFileName field.
  static const Object _kUnset = Object();

  ReaderSettings copyWith({
    double? zoom,
    double? lineHeight,
    bool? changeLineHeight,
    bool? followAppTheme,
    int? themeIndex,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    ReaderLinkHandling? linkHandling,
    bool? handleIntraLink,
    ReaderPageAnimation? pageAnimation,
    ReaderScrollMode? scrollMode,
    Object? fontFileName = _kUnset,
    bool? overrideFontFamily,
    bool? volumeKeyTurnsPage,
  }) {
    return ReaderSettings(
      zoom: zoom ?? this.zoom,
      lineHeight: lineHeight ?? this.lineHeight,
      changeLineHeight: changeLineHeight ?? this.changeLineHeight,
      followAppTheme: followAppTheme ?? this.followAppTheme,
      themeIndex: themeIndex ?? this.themeIndex,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      linkHandling: linkHandling ?? this.linkHandling,
      handleIntraLink: handleIntraLink ?? this.handleIntraLink,
      pageAnimation: pageAnimation ?? this.pageAnimation,
      scrollMode: scrollMode ?? this.scrollMode,
      fontFileName: identical(fontFileName, _kUnset)
          ? this.fontFileName
          : fontFileName as String?,
      overrideFontFamily: overrideFontFamily ?? this.overrideFontFamily,
      volumeKeyTurnsPage: volumeKeyTurnsPage ?? this.volumeKeyTurnsPage,
    );
  }

  EpubTheme toEpubTheme(BuildContext context) {
    final appColorScheme = Theme.of(context).colorScheme;
    final appPreset =
        Theme.of(context).extension<LuminaThemeExtension>()?.preset ??
        LuminaThemePreset.standardLight;

    final LuminaThemePreset preset;
    final ColorScheme colorScheme;

    if (followAppTheme) {
      preset = appPreset;
      colorScheme = appColorScheme;
    } else {
      preset = currentPreset;
      colorScheme = currentPreset.colorScheme;
    }

    return EpubTheme(
      zoom: zoom,
      lineHeight: lineHeight,
      changeLineHeight: changeLineHeight,
      shouldOverrideTextColor: preset.shouldOverrideTextColor,
      colorScheme: colorScheme,
      overridePrimaryColor: preset.overridePrimaryColor,
      padding: EdgeInsets.only(
        top: marginTop,
        bottom: marginBottom,
        left: marginLeft,
        right: marginRight,
      ),
      fontFileName: fontFileName,
      overrideFontFamily: overrideFontFamily,
    );
  }

  /// Whether continuous scrolling is available for a book whose page
  /// progression is [direction].
  ///
  /// Scrolling relies on a single vertically flowing column, which is
  /// incompatible with the vertical-writing / right-to-left layout used when
  /// `direction == 1`, so those books are always paginated.
  static bool supportsScrollMode(int direction) => direction == 0;

  /// The effective layout mode for a book whose page progression is
  /// [direction] — the stored [scrollMode], forced back to
  /// [ReaderScrollMode.paginated] when the book cannot scroll.
  ReaderScrollMode effectiveScrollMode(int direction) =>
      supportsScrollMode(direction) ? scrollMode : ReaderScrollMode.paginated;

  /// The [LuminaThemePreset] currently selected by [themeIndex].
  LuminaThemePreset get currentPreset =>
      LuminaThemePreset.fromIndex(themeIndex);

  /// The [ColorScheme] currently selected from [LuminaThemePreset].
  ColorScheme get currentColorScheme => currentPreset.colorScheme;
}
