import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;

import '../storage/app_storage.dart';
import 'lumina_database.dart';
import 'lumina_db.dart';

/// Concrete implementation of [LuminaDatabase].
///
/// Owns the single long-lived [LuminaDb] instance for the app.
class LuminaDatabaseImpl implements LuminaDatabase {
  static const _databaseFileName = 'lumina.sqlite';

  LuminaDb? _instance;

  @override
  Future<LuminaDb> getInstance() async {
    return _instance ??= LuminaDb(_openConnection());
  }

  @override
  Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  /// Opens `lumina.sqlite` next to the sandbox support directory rather than in
  /// the user-visible documents directory, matching where the previous database
  /// lived.
  DatabaseConnection _openConnection() {
    return driftDatabase(
      name: 'lumina',
      native: DriftNativeOptions(
        databasePath: () async =>
            p.join(AppStorage.supportPath, _databaseFileName),
      ),
    );
  }
}
