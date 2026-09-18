import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'font_manager_notifier.dart';

part 'imported_font_file_names_provider.g.dart';

// ── Derived provider ─────────────────────────────────────────────────────────
/// Exposes the set of imported font file names derived from [FontManagerNotifier].
/// Use this to check font existence without creating a direct
/// notifier-to-notifier dependency.
@riverpod
Set<String> importedFontFileNames(ImportedFontFileNamesRef ref) =>
    ref.watch(fontManagerNotifierProvider).map((f) => f.fileName).toSet();
