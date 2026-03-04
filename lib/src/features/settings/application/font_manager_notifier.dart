import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
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

  /// Opens the system file picker and copies all selected fonts into the app's
  /// fonts directory. Returns the list of successfully imported [ImportedFont]s,
  /// or an empty list if the picker was cancelled.
  Future<List<ImportedFont>> importFonts() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
      withData: false,
      withReadStream: false,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return [];

    // Ensure fonts directory exists.
    final fontsDir = Directory('${AppStorage.documentsPath}fonts');
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final imported = <ImportedFont>[];
    var current = state;

    for (final picked in result.files) {
      final sourcePath = picked.path;
      if (sourcePath == null) continue;

      final fileName = picked.name;
      final destPath = '${fontsDir.path}/$fileName';
      await File(sourcePath).copy(destPath);

      // Avoid duplicate entries in state.
      if (current.any((f) => f.fileName == fileName)) {
        imported.add(ImportedFont.fromFileName(fileName));
        continue;
      }

      final font = ImportedFont.fromFileName(fileName);
      current = [...current, font];
      imported.add(font);
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
