import 'package:flutter/material.dart';

/// Notion-like Minimalist Theme for Lumina Reader
/// Philosophy: Content-first, monochrome, no shadows, serif typography
class AppTheme {
  AppTheme._();

  // Color Palette - Strictly Monochrome (Notion-like)
  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _greySecondary = Color(0xFF9E9E9E);
  static const Color _divider = Color(0xFFE0E0E0);
  static const Color _red = Color(0xFFDC2626);
  static const Color _darkRed = Color(0xFFEF4444);

  static const Color _darkBg = Color(0xFF191919);
  static const Color _darkSurface = Color(0xFF202020);
  static const Color _darkTextPrimary = Color(0xFFECECEC);
  static const Color _darkTextSecondary = Color(0xFFAAAAAA);
  static const Color _darkDivider = Color(0xFF333333);

  // Border Radius - Sharp, minimal
  static const double _radiusSmall = 4.0;

  // Font Family - Elegant Serif for a literary feel
  static const String _fontFamily = 'AppSerif';

  // Content Font Family - Slightly softer serif for body text
  static const String fontFamilyContent = 'AppSerifContent';
  static const TextStyle contentTextStyle = TextStyle(
    fontFamily: fontFamilyContent,
    fontWeight: FontWeight.w400,
  );

  static const List<String> _defaultFallback = [
    "AppSerifContent",
    "Songti SC",
    "STSong",
    "Noto Serif CJK SC",
    "Source Han Serif SC",
    'SimSun',
    'serif',
  ];

  static const int defaultAnimationDurationMs = 250;
  static const int defaultLongAnimationDurationMs = 320;
  static const int defaultPresentationDurationMs = 3 * 1000; // 3 seconds

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: const ColorScheme.light(
        primary: _black,
        onPrimary: _white,
        secondary: _greySecondary,
        onSecondary: _black,
        surface: _white,
        onSurface: _black,
        error: _red,
        onError: _white,
        outline: _divider,
      ),
      scaffoldBackgroundColor: _white,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _white,
        foregroundColor: _black,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _black),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: _divider),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _divider),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _black, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _black,
          foregroundColor: _white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _black,
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _black,
          side: const BorderSide(color: _black, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          side: BorderSide(color: _divider, width: 1),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      iconTheme: const IconThemeData(color: _black),
      extensions: const [NotionStatusColors.light()],
    );
  }

  /// Dark Theme - Optional monochrome variant
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: const ColorScheme.dark(
        primary: _white,
        onPrimary: _black,
        secondary: _greySecondary,
        onSecondary: _white,
        surface: _darkBg,
        onSurface: _darkTextPrimary,
        surfaceContainer: _darkSurface,
        error: _darkRed,
        onError: _black,
        outline: _darkDivider,
      ),
      scaffoldBackgroundColor: _darkBg,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: _darkTextPrimary,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _white),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _darkDivider),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _white, width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _white,
          foregroundColor: _darkBg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkTextPrimary,
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkTextPrimary,
          side: const BorderSide(color: _greySecondary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkDivider,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          side: BorderSide(color: AppTheme._darkDivider, width: 1),
        ),
      ),

      splashFactory: NoSplash.splashFactory,
      iconTheme: const IconThemeData(color: _darkTextPrimary),
      extensions: const [NotionStatusColors.dark()],
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    final baseWithFont = baseTextTheme.apply(
      fontFamily: _fontFamily,
      fontFamilyFallback: _defaultFallback,
    );

    final mainColor = brightness == Brightness.light
        ? _black
        : _darkTextPrimary;
    final mutedColor = brightness == Brightness.light
        ? _greySecondary
        : _darkTextSecondary;

    return baseWithFont.copyWith(
      displayLarge: baseWithFont.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: mainColor,
      ),
      displayMedium: baseWithFont.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: mainColor,
      ),
      displaySmall: baseWithFont.displaySmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: mainColor,
      ),
      headlineLarge: baseWithFont.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: mainColor,
      ),
      headlineMedium: baseWithFont.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600, // SemiBold
        color: mainColor,
      ),
      headlineSmall: baseWithFont.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      titleLarge: baseWithFont.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      titleMedium: baseWithFont.titleMedium?.copyWith(
        fontWeight: FontWeight.w500, // Medium
        color: mainColor,
      ),
      titleSmall: baseWithFont.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: mainColor,
      ),
      bodyLarge: baseWithFont.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: mainColor,
      ),
      bodyMedium: baseWithFont.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: mainColor,
      ),
      bodySmall: baseWithFont.bodySmall?.copyWith(
        fontWeight: FontWeight.w300,
        color: mutedColor,
      ),
      labelLarge: baseWithFont.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: mainColor,
      ),
    );
  }

  static PageTransitionsTheme get pageTransitionsTheme {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );
  }
}

@immutable
class NotionStatusColors extends ThemeExtension<NotionStatusColors> {
  final Color emphasis;
  final Color muted;

  const NotionStatusColors({required this.emphasis, required this.muted});

  const NotionStatusColors.light()
    : emphasis = AppTheme._black,
      muted = AppTheme._greySecondary;

  const NotionStatusColors.dark()
    : emphasis = AppTheme._darkTextPrimary,
      muted = AppTheme._darkTextSecondary;

  @override
  NotionStatusColors copyWith({Color? emphasis, Color? muted}) {
    return NotionStatusColors(
      emphasis: emphasis ?? this.emphasis,
      muted: muted ?? this.muted,
    );
  }

  @override
  NotionStatusColors lerp(ThemeExtension<NotionStatusColors>? other, double t) {
    if (other is! NotionStatusColors) return this;
    return NotionStatusColors(
      emphasis: Color.lerp(emphasis, other.emphasis, t) ?? emphasis,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
    );
  }
}
