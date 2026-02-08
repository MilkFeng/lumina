import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/library/domain/shelf_book.dart';
import '../../features/library/domain/book_manifest.dart';
import '../../features/library/domain/shelf_group.dart';
import 'isar_database.dart';

/// Concrete implementation of IsarDatabase
/// Manages Isar database lifecycle and provides access to the instance
class IsarDatabaseImpl implements IsarDatabase {
  Isar? _instance;

  @override
  Future<Isar> getInstance() async {
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

  @override
  Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
