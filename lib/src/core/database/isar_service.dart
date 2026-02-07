import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/library/domain/shelf_book.dart';
import '../../features/library/domain/book_manifest.dart';
import '../../features/library/domain/shelf_group.dart';

/// Isar database service - V2 Architecture (Stream-from-Zip)
/// Singleton pattern for global access
class IsarService {
  static Isar? _instance;

  /// Get Isar instance (lazy initialization)
  static Future<Isar> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }

    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        ShelfBookSchema, // Lightweight UI entity
        ShelfGroupSchema, // Folder/group entity
        BookManifestSchema, // Heavy reader entity
      ],
      directory: dir.path,
      inspector: true, // Enable Isar Inspector for debugging
    );

    return _instance!;
  }

  /// Close database (call on app dispose)
  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
