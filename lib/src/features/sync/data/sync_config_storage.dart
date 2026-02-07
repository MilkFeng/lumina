import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/sync_config.dart';

/// Storage service for sync configuration
/// Uses SharedPreferences for non-sensitive data
/// Uses FlutterSecureStorage for password
class SyncConfigStorage {
  static const String _keyServerUrl = 'sync_server_url';
  static const String _keyUsername = 'sync_username';
  static const String _keyPassword =
      'sync_password'; // Stored in secure storage
  static const String _keyRemoteFolderPath = 'sync_remote_folder_path';
  static const String _keyLastSyncDate = 'sync_last_sync_date';
  static const String _keyLastSyncError = 'sync_last_sync_error';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  SyncConfigStorage._(this._prefs, this._secureStorage);

  /// Factory method to create an instance
  static Future<SyncConfigStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    return SyncConfigStorage._(prefs, secureStorage);
  }

  /// Check if configuration exists
  Future<bool> hasConfig() async {
    return _prefs.containsKey(_keyServerUrl);
  }

  /// Load configuration
  Future<SyncConfig?> loadConfig() async {
    if (!await hasConfig()) {
      return null;
    }

    final serverUrl = _prefs.getString(_keyServerUrl);
    final username = _prefs.getString(_keyUsername);
    final password = await _secureStorage.read(key: _keyPassword);
    final remoteFolderPath = _prefs.getString(_keyRemoteFolderPath);
    final lastSyncDateStr = _prefs.getString(_keyLastSyncDate);
    final lastSyncError = _prefs.getString(_keyLastSyncError);

    if (serverUrl == null ||
        username == null ||
        password == null ||
        remoteFolderPath == null) {
      return null;
    }

    return SyncConfig(
      serverUrl: serverUrl,
      username: username,
      password: password,
      remoteFolderPath: remoteFolderPath,
      lastSyncDate: lastSyncDateStr != null
          ? DateTime.tryParse(lastSyncDateStr)
          : null,
      lastSyncError: lastSyncError,
    );
  }

  /// Save configuration
  Future<void> saveConfig(SyncConfig config) async {
    await Future.wait([
      _prefs.setString(_keyServerUrl, config.serverUrl),
      _prefs.setString(_keyUsername, config.username),
      _secureStorage.write(key: _keyPassword, value: config.password),
      _prefs.setString(_keyRemoteFolderPath, config.remoteFolderPath),
      if (config.lastSyncDate != null)
        _prefs.setString(
          _keyLastSyncDate,
          config.lastSyncDate!.toIso8601String(),
        ),
      if (config.lastSyncError != null)
        _prefs.setString(_keyLastSyncError, config.lastSyncError!),
    ]);
  }

  /// Save a single field (for auto-save)
  Future<void> saveField(String field, String value) async {
    switch (field) {
      case 'serverUrl':
        await _prefs.setString(_keyServerUrl, value);
        break;
      case 'username':
        await _prefs.setString(_keyUsername, value);
        break;
      case 'password':
        await _secureStorage.write(key: _keyPassword, value: value);
        break;
      case 'remoteFolderPath':
        await _prefs.setString(_keyRemoteFolderPath, value);
        break;
    }
  }

  /// Update last sync information
  Future<void> updateLastSync({DateTime? syncDate, String? error}) async {
    if (syncDate != null) {
      await _prefs.setString(_keyLastSyncDate, syncDate.toIso8601String());
    }

    if (error != null) {
      await _prefs.setString(_keyLastSyncError, error);
    } else {
      await _prefs.remove(_keyLastSyncError);
    }
  }

  /// Delete configuration
  Future<void> deleteConfig() async {
    await Future.wait([
      _prefs.remove(_keyServerUrl),
      _prefs.remove(_keyUsername),
      _secureStorage.delete(key: _keyPassword),
      _prefs.remove(_keyRemoteFolderPath),
      _prefs.remove(_keyLastSyncDate),
      _prefs.remove(_keyLastSyncError),
    ]);
  }
}
