import 'package:fpdart/fpdart.dart';
import '../domain/sync_config.dart';
import 'sync_config_storage.dart';

/// Repository for SyncConfig CRUD operations
/// Uses SharedPreferences + FlutterSecureStorage instead of Isar
class SyncConfigRepository {
  SyncConfigStorage? _storage;

  Future<SyncConfigStorage> _getStorage() async {
    _storage ??= await SyncConfigStorage.create();
    return _storage!;
  }

  /// Get sync configuration
  Future<SyncConfig?> getConfig() async {
    final storage = await _getStorage();
    return await storage.loadConfig();
  }

  /// Save or update sync configuration
  Future<Either<String, bool>> saveConfig(SyncConfig config) async {
    try {
      final storage = await _getStorage();
      await storage.saveConfig(config);
      return right(true);
    } catch (e) {
      return left('Save config failed: $e');
    }
  }

  /// Save a single field (for auto-save)
  Future<Either<String, bool>> saveField(String field, String value) async {
    try {
      final storage = await _getStorage();
      await storage.saveField(field, value);
      return right(true);
    } catch (e) {
      return left('Save field failed: $e');
    }
  }

  /// Update last sync date
  Future<Either<String, bool>> updateLastSync({
    DateTime? syncDate,
    String? error,
  }) async {
    try {
      final storage = await _getStorage();
      await storage.updateLastSync(syncDate: syncDate, error: error);
      return right(true);
    } catch (e) {
      return left('Update last sync failed: $e');
    }
  }

  /// Delete sync configuration
  Future<Either<String, bool>> deleteConfig() async {
    try {
      final storage = await _getStorage();
      await storage.deleteConfig();
      return right(true);
    } catch (e) {
      return left('Delete config failed: $e');
    }
  }

  /// Check if sync is configured
  Future<bool> isConfigured() async {
    final storage = await _getStorage();
    return await storage.hasConfig();
  }
}
