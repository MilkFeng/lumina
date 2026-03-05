import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/library/data/services/unified_import_service_provider.dart';
import 'package:lumina/src/features/settings/domain/imported_font.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_manager_notifier.g.dart';

// ── Font Manager Notifier ────────────────────────────────────────────────────
// Manages the list of user-imported fonts persisted in SharedPreferences.
// Font files are stored at <documentsPath>/fonts/<fileName>.
// They are served to the WebView via epub://localhost/fonts/<fileName>.
@riverpod
class FontManagerNotifier extends _$FontManagerNotifier {
  static const _kImportedFonts = 'imported_fonts';

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
    final unifiedImportService = ref.read(unifiedImportServiceProvider);

    final paths = await unifiedImportService.pickFontFiles();
    if (paths.isEmpty) return [];

    // Ensure fonts directory exists.
    final fontsDir = Directory('${AppStorage.documentsPath}fonts');
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final imported = <ImportedFont>[];
    var current = state;

    try {
      for (final platformPath in paths) {
        File? cacheFile;
        try {
          final fileName = platformPath.name;

          // 1. Cache file from platform path to temp location.
          cacheFile = await unifiedImportService.processFontFile(platformPath);

          // 2. Copy cached file to fonts directory.
          final destPath = '${fontsDir.path}/$fileName';
          await cacheFile.copy(destPath);

          // 3. Update state (avoid duplicate entries).
          if (!current.any((f) => f.fileName == fileName)) {
            final font = ImportedFont.fromFileName(fileName);
            current = [...current, font];
            imported.add(font);
          } else {
            imported.add(ImportedFont.fromFileName(fileName));
          }
        } catch (e) {
          debugPrint('Failed to import font ${platformPath.name}: $e');
        } finally {
          // 4. Always clean the cache file immediately after use.
          if (cacheFile != null) {
            await unifiedImportService.cleanCache(cacheFile);
          }
        }
      }
    } finally {
      // Release iOS security-scoped resources after all files are processed.
      await unifiedImportService.releaseIosAccess();
    }

    if (current != state) {
      await _persist(current);
      state = current;
    }

    return imported;
  }

  /// Removes the given font from the list and deletes its file.
  Future<void> deleteFont(ImportedFont font) async {
    final filePath = '${AppStorage.documentsPath}fonts/${font.fileName}';
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    final updated = state.where((f) => f.fileName != font.fileName).toList();
    await _persist(updated);
    state = updated;
  }

  Future<void> _persist(List<ImportedFont> fonts) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(fonts.map((f) => f.fileName).toList());
    await prefs.setString(_kImportedFonts, jsonStr);
  }
}
