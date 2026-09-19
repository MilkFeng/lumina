import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/platform/platform_path.dart';
import 'package:lumina/src/core/platform/provider.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/core/storage/app_storage_constants.dart';
import 'package:lumina/src/features/fonts/domain/imported_font.dart';
import 'package:lumina/src/features/library/data/services/import_file_pipeline_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_manager_notifier.g.dart';

// ── Font Manager Notifier ────────────────────────────────────────────────────
// Manages the list of user-imported fonts persisted in SharedPreferences.
// Font files are stored at <documentsPath>/fonts/<fileName>.
// They are served to the WebView via epub://localhost/fonts/<fileName>.
@Riverpod(keepAlive: true)
class FontManagerNotifier extends _$FontManagerNotifier {
  static const _kImportedFonts = 'imported_fonts';

  /// Extensions the reader serves as fonts; see `EpubWebViewHandler`.
  static const List<String> _fontExtensions = [
    '.ttf',
    '.otf',
    '.ttc',
    '.otc',
    '.woff',
    '.woff2',
  ];

  /// Characters replaced with `_` inside a font file name.
  ///
  /// Path separators would escape the fonts directory, `#` and `?` would
  /// truncate the `epub://localhost/fonts/{name}` URL the reader requests, `%`
  /// would make that URL undecodable, and a quote would break the `@font-face`
  /// rule the web layer builds from the name. The rest is the usual
  /// cross-platform set.
  static final RegExp _unsafeFileNameChars = RegExp(
    r'''[\x00-\x1f\x7f/\\:*?"<>|#%']''',
  );

  @override
  List<ImportedFont> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_kImportedFonts);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.whereType<String>().map(ImportedFont.fromFileName).toList();
    } catch (_) {
      return [];
    }
  }

  /// Picks font files via the platform-native picker and copies them into the
  /// app's fonts directory one-by-one (cache → copy → clean), following the
  /// same pipeline pattern used by [LibraryNotifier.importPipelineStream].
  ///
  /// Returns the list of successfully imported [ImportedFont]s,
  /// or an empty list if the picker was cancelled.
  Future<List<ImportedFont>> importFonts() async {
    final picker = ref.read(filePickerProvider);
    final pipeline = ref.read(importFilePipelineProvider);

    final paths = await picker.pickFontFiles();
    if (paths.isEmpty) return [];

    // A [PlatformPath] is an opaque platform handle, so the real file name has
    // to come from the platform (see [FilePickerService.resolveDisplayNames]).
    // Deriving it from the handle is what previously degraded every import to
    // the `unknown.epub` placeholder.
    final displayNames = await picker.resolveDisplayNames(paths);

    // Ensure fonts directory exists.
    final fontsDir = Directory(
      '${AppStorage.documentsPath}${AppStorageConstants.fontsDir}',
    );
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final imported = <ImportedFont>[];
    var current = state;

    try {
      for (var index = 0; index < paths.length; index++) {
        final platformPath = paths[index];
        File? cacheFile;
        try {
          // 1. Cache file from platform path to temp location.
          cacheFile = await pipeline.cacheFile(platformPath);

          // 2. Derive the on-disk file name, then copy the cached file.
          final fileName = _fileNameFor(
            displayName: displayNames[index],
            platformPath: platformPath,
            cacheFile: cacheFile,
          );
          await cacheFile.copy('${fontsDir.path}/$fileName');

          // 3. Update state (avoid duplicate entries).
          final existingIndex = current.indexWhere(
            (f) => f.fileName == fileName,
          );
          if (existingIndex == -1) {
            final font = ImportedFont.fromFileName(fileName);
            current = [...current, font];
            imported.add(font);
          } else {
            // Importing the same font again only refreshes its file.
            imported.add(current[existingIndex]);
          }
        } catch (e) {
          debugPrint('Failed to import font ${platformPath.name}: $e');
        } finally {
          // 4. Always clean the cache file immediately after use.
          if (cacheFile != null) {
            await pipeline.cleanCache(cacheFile);
          }
        }
      }
    } finally {
      // Release iOS security-scoped resources after all files are processed.
      await pipeline.releaseIosAccess();
    }

    if (current != state) {
      await _persist(current);
      state = current;
    }

    return imported;
  }

  /// Removes the given font from the list and deletes its file.
  Future<void> deleteFont(ImportedFont font) async {
    final filePath =
        '${AppStorage.documentsPath}${AppStorageConstants.fontsDir}/${font.fileName}';
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    final updated = state.where((f) => f.fileName != font.fileName).toList();
    await _persist(updated);
    state = updated;
  }

  /// Builds the on-disk file name for one picked font.
  ///
  /// The platform display name wins: it is the only source that carries the
  /// name the system shows for the file. [platformPath] is the next best guess,
  /// and [cacheFile] supplies the extension when the resolved name has none
  /// (the import cache preserves the original extension).
  ///
  /// A font whose name cannot be resolved at all gets a generated, unique name.
  /// One shared placeholder is not an option: the file name is the identity of
  /// a font in the list, so every later font would be treated as a duplicate of
  /// the first and would overwrite the same file.
  static String _fileNameFor({
    required String? displayName,
    required PlatformPath platformPath,
    required File cacheFile,
  }) {
    final fallbackExtension = _fontExtensionOf(cacheFile.path);

    for (final candidate in [displayName, platformPath.name]) {
      final sanitized = _sanitizeFileName(candidate);
      if (sanitized != null) {
        return _withFontExtension(sanitized, fallbackExtension);
      }
    }

    return 'font_${DateTime.now().microsecondsSinceEpoch}$fallbackExtension';
  }

  /// Reduces [rawName] to a bare, storage- and URL-safe file name.
  ///
  /// Returns `null` when nothing usable is left.
  static String? _sanitizeFileName(String? rawName) {
    if (rawName == null) return null;

    // Providers may hand back a slash-separated path instead of a plain name.
    final baseName = rawName
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(_unsafeFileNameChars, '_')
        .trim();

    if (baseName.isEmpty || baseName == '.' || baseName == '..') return null;
    return baseName;
  }

  /// Extension of [fileName], dot included, when the reader can serve it as a
  /// font; `.ttf` otherwise.
  static String _fontExtensionOf(String fileName) {
    final lower = fileName.toLowerCase();
    for (final extension in _fontExtensions) {
      if (lower.endsWith(extension)) return extension;
    }
    return '.ttf';
  }

  /// Returns [fileName] unchanged when it already carries a font extension, and
  /// appends [fallbackExtension] when it does not.
  static String _withFontExtension(String fileName, String fallbackExtension) {
    final lower = fileName.toLowerCase();
    if (_fontExtensions.any(lower.endsWith)) return fileName;
    return '$fileName$fallbackExtension';
  }

  Future<void> _persist(List<ImportedFont> fonts) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(fonts.map((f) => f.fileName).toList());
    await prefs.setString(_kImportedFonts, jsonStr);
  }
}
