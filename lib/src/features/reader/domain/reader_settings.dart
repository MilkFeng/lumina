import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme_settings.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

/// Controls how the reader handles external link taps.
enum ReaderLinkHandling { ask, always, never }

/// Controls the page-turning animation style.
enum ReaderPageAnimation { none, slide }

/// Controls page turn direction for PDF
enum PdfSwipeDirection { horizontal, vertical }

class ReaderSettings {
  final double zoom;
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

  /// File name (with extension) of the user-imported font to use, or null to
  /// use the epub's own fonts.
  final String? fontFileName;

  /// When true the custom font overrides the epub's own font-family rules.
  final bool overrideFontFamily;

  /// When true, volume up/down keys turn pages in the reader.
  final bool volumeKeyTurnsPage;
  
  // PDF-specific settings
  final bool pdfPageSpacing;
  final bool pdfAutoSpacing;
  final bool pdfPageFling;
  final bool pdfPageSnap;
  final PdfSwipeDirection pdfSwipeDirection;

  const ReaderSettings({
    this.zoom = 1.0,
    this.followAppTheme = true,
    this.themeIndex = 0,
    this.marginTop = 16.0,
    this.marginBottom = 16.0,
    this.marginLeft = 16.0,
    this.marginRight = 16.0,
    this.linkHandling = ReaderLinkHandling.ask,
    this.handleIntraLink = true,
    this.pageAnimation = ReaderPageAnimation.slide,
      this.fontFileName,
    this.overrideFontFamily = false,
    this.volumeKeyTurnsPage = false,
    
    // PDF defaults
    this.pdfPageSpacing = true,
    this.pdfAutoSpacing = true,
    this.pdfPageFling = true,
    this.pdfPageSnap = true,
    this.pdfSwipeDirection = PdfSwipeDirection.vertical,
  });

  // Sentinel: lets copyWith(fontFileName: null) mean "set to null" rather than
  // "leave unchanged". Used only for the nullable fontFileName field.
  static const Object _kUnset = Object();

  ReaderSettings copyWith({
    double? zoom,
    bool? followAppTheme,
    int? themeIndex,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    ReaderLinkHandling? linkHandling,
    bool? handleIntraLink,
    ReaderPageAnimation? pageAnimation,
    Object? fontFileName = _kUnset,
    bool? overrideFontFamily,
    bool? volumeKeyTurnsPage,
    bool? pdfPageSpacing,
    bool? pdfAutoSpacing,
    bool? pdfPageFling,
    bool? pdfPageSnap,
    PdfSwipeDirection? pdfSwipeDirection,
  }) {
    return ReaderSettings(
      zoom: zoom ?? this.zoom,
      followAppTheme: followAppTheme ?? this.followAppTheme,
      themeIndex: themeIndex ?? this.themeIndex,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      linkHandling: linkHandling ?? this.linkHandling,
      handleIntraLink: handleIntraLink ?? this.handleIntraLink,
      pageAnimation: pageAnimation ?? this.pageAnimation,
      fontFileName: identical(fontFileName, _kUnset)
          ? this.fontFileName
          : fontFileName as String?,
      overrideFontFamily: overrideFontFamily ?? this.overrideFontFamily,
      volumeKeyTurnsPage: volumeKeyTurnsPage ?? this.volumeKeyTurnsPage,
      pdfPageSpacing: pdfPageSpacing ?? this.pdfPageSpacing,
      pdfAutoSpacing: pdfAutoSpacing ?? this.pdfAutoSpacing,
      pdfPageFling: pdfPageFling ?? this.pdfPageFling,
      pdfPageSnap: pdfPageSnap ?? this.pdfPageSnap,
      pdfSwipeDirection: pdfSwipeDirection ?? this.pdfSwipeDirection,
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

  /// The [LuminaThemePreset] currently selected by [themeIndex].
  LuminaThemePreset get currentPreset =>
      LuminaThemePreset.fromIndex(themeIndex);

  /// The [ColorScheme] currently selected from [LuminaThemePreset].
  ColorScheme get currentColorScheme => currentPreset.colorScheme;
}
