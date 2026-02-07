import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/sync_config.dart';
import '../data/sync_config_repository.dart';
import '../data/webdav_sync_service.dart';
import '../data/webdav_service.dart';

part 'sync_notifier.g.dart';

/// State for sync operations
sealed class SyncState {}

class SyncInitial extends SyncState {}

class SyncLoading extends SyncState {}

class SyncConfigured extends SyncState {
  final SyncConfig config;
  SyncConfigured(this.config);
}

class SyncNotConfigured extends SyncState {}

class SyncInProgress extends SyncState {
  final String message;
  SyncInProgress(this.message);
}

class SyncSuccess extends SyncState {
  final String message;
  final DateTime timestamp;
  SyncSuccess(this.message, this.timestamp);
}

class SyncError extends SyncState {
  final String message;
  SyncError(this.message);
}

/// Notifier for managing sync operations
@riverpod
class SyncNotifier extends _$SyncNotifier {
  late final SyncConfigRepository _configRepository;
  late final WebDavSyncService _syncService;

  @override
  Future<SyncState> build() async {
    _configRepository = SyncConfigRepository();
    _syncService = WebDavSyncService();
    return await _loadConfig();
  }

  /// Load sync configuration
  Future<SyncState> _loadConfig() async {
    try {
      final config = await _configRepository.getConfig();
      if (config == null) {
        return SyncNotConfigured();
      }
      return SyncConfigured(config);
    } catch (e) {
      return SyncError('Failed to load config: $e');
    }
  }

  /// Test WebDAV connection and auto-save config if successful
  Future<bool> testConnection({
    required String serverUrl,
    required String username,
    required String password,
    required String remoteFolderPath,
  }) async {
    state = AsyncValue.data(SyncLoading());

    try {
      final webDav = WebDavService();
      final initResult = await webDav.initialize(
        serverUrl: serverUrl,
        username: username,
        password: password,
        remoteFolderPath: remoteFolderPath,
      );

      if (initResult.isLeft()) {
        state = AsyncValue.data(SyncError(initResult.getLeft().toNullable()!));
        return false;
      }

      final testResult = await webDav.testConnection();
      if (testResult.isLeft()) {
        state = AsyncValue.data(SyncError(testResult.getLeft().toNullable()!));
        return false;
      }

      // Create remote directory
      await webDav.ensureRemoteDirectory();

      // Auto-save the configuration on successful test
      final config = SyncConfig(
        serverUrl: serverUrl,
        username: username,
        password: password,
        remoteFolderPath: remoteFolderPath,
      );
      await _configRepository.saveConfig(config);

      state = await AsyncValue.guard(() => _loadConfig());
      return true;
    } catch (e) {
      state = AsyncValue.data(SyncError('Connection test failed: $e'));
      return false;
    }
  }

  /// Save sync configuration
  Future<bool> saveConfig(SyncConfig config) async {
    state = AsyncValue.data(SyncLoading());

    try {
      final result = await _configRepository.saveConfig(config);
      if (result.isLeft()) {
        state = AsyncValue.data(SyncError(result.getLeft().toNullable()!));
        return false;
      }

      state = await AsyncValue.guard(() => _loadConfig());
      return true;
    } catch (e) {
      state = AsyncValue.data(SyncError('Save config failed: $e'));
      return false;
    }
  }

  /// Perform full sync
  Future<bool> performSync() async {
    state = AsyncValue.data(SyncInProgress('Starting sync...'));

    try {
      final result = await _syncService.performFullSync(
        onProgress: (message) {
          state = AsyncValue.data(SyncInProgress(message));
        },
      );

      if (result.isLeft()) {
        state = AsyncValue.data(SyncError(result.getLeft().toNullable()!));
        return false;
      }

      final syncResult = result.getRight().toNullable()!;
      state = AsyncValue.data(
        SyncSuccess(syncResult.getSummary(), syncResult.timestamp),
      );

      // Reload config to get updated last sync date
      Future.delayed(const Duration(seconds: 2), () async {
        state = await AsyncValue.guard(() => _loadConfig());
      });

      return true;
    } catch (e) {
      state = AsyncValue.data(SyncError('Sync failed: $e'));
      return false;
    }
  }

  /// Delete sync configuration
  Future<bool> deleteConfig() async {
    state = AsyncValue.data(SyncLoading());

    try {
      final result = await _configRepository.deleteConfig();
      if (result.isLeft()) {
        state = AsyncValue.data(SyncError(result.getLeft().toNullable()!));
        return false;
      }

      state = await AsyncValue.guard(() => _loadConfig());
      return true;
    } catch (e) {
      state = AsyncValue.data(SyncError('Delete config failed: $e'));
      return false;
    }
  }

  /// Refresh config
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _loadConfig());
  }
}
