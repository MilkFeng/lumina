import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:lumina/src/core/database/isar_database.dart';
import 'package:lumina/src/core/storage/app_storage.dart';

/// Concrete implementation of [IsarDatabase].
///
/// The collection schemas are injected rather than imported, so this `core`
/// class never has to know which features define entities. The list is
/// supplied by `isarDatabaseProvider` in
/// `features/library/data/database/isar_providers.dart`.
class IsarDatabaseImpl implements IsarDatabase {
  final List<CollectionSchema<dynamic>> _schemas;
  final String _directory;

  IsarDatabaseImpl({required List<CollectionSchema<dynamic>> schemas})
    : _schemas = schemas,
      _directory = AppStorage.supportPath;

  Isar? _instance;

  @override
  Future<Isar> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }

    _instance = await Isar.open(
      _schemas,
      directory: _directory,
      inspector: kDebugMode, // Isar Inspector for debug builds only
    );

    return _instance!;
  }

  @override
  Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
