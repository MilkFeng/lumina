import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/providers.dart';
import '../../../features/library/data/services/epub_import_service_provider.dart';
import '../domain/sync_config.dart';
import '../domain/failures/sync_failures.dart' as failures;
import '../data/sync_config_repository.dart';
import '../data/webdav_sync_service.dart' as sync_service;
import '../data/webdav_service_provider.dart';

part 'sync_notifier.g.dart';

/// Enhanced state for sync operations with typed failures
sealed class SyncState {}

class SyncInitial extends SyncState {}

class SyncLoading extends SyncState {
  final String? message;
  SyncLoading([this.message]);
}

class SyncConfigured extends SyncState {
  final SyncConfig config;
  SyncConfigured(this.config);
}

class SyncNotConfigured extends SyncState {}

class SyncInProgress extends SyncState {
  final String message;
  final double? progress; // 0.0 to 1.0
  SyncInProgress(this.message, [this.progress]);
}

class SyncSuccess extends SyncState {
  final String message;
  final DateTime timestamp;
  final Map<String, int>? stats; // Optional sync statistics

  SyncSuccess(this.message, this.timestamp, [this.stats]);
}

class SyncFailure extends SyncState {
  final failures.SyncFailure failure;

  SyncFailure(this.failure);

  /// Get user-friendly error message
  String get userMessage => _getUserFriendlyMessage(failure);

  /// Convert technical failure to user-friendly message
  String _getUserFriendlyMessage(failures.SyncFailure failure) {
    return switch (failure) {
      failures.NetworkConnectionFailure() =>
        'Connection failed. Please check your internet connection.',
      failures.AuthenticationFailure() =>
        'Authentication failed. Please check your credentials.',
      failures.FileTransferFailure(fileName: final name) =>
        'Failed to transfer file${name != null ? ': $name' : ''}',
      failures.ConfigurationFailure() =>
        'Sync not configured. Please set up WebDAV connection.',
      failures.ServerFailure(statusCode: final code) =>
        'Server error${code != null ? ' ($code)' : ''}. Please try again later.',
      failures.StorageFailure() =>
        'Storage error. Please check available space.',
      failures.DataParseFailure() =>
        'Data parsing failed. Sync data may be corrupted.',
      _ => failure.message,
    };
  }
}

/// Notifier for managing sync operations with dependency injection
@riverpod
class SyncNotifier extends _$SyncNotifier {
  late final SyncConfigRepository _configRepository;
  late final sync_service.WebDavSyncService _syncService;

  @override
  Future<SyncState> build() async {
    // Initialize with dependency injection
    _configRepository = SyncConfigRepository();

    final webDavService = ref.read(webDavServiceProvider);
    final isar = await ref.read(isarProvider.future);
    final epubImportService = ref.read(epubImportServiceProvider);

    _syncService = sync_service.WebDavSyncService(
      webDavService: webDavService,
      configRepository: _configRepository,
      epubImportService: epubImportService,
      isar: isar,
    );

    return await _loadConfig();
  }

  /// Load sync configuration with error handling
  Future<SyncState> _loadConfig() async {
    try {
      final config = await _configRepository.getConfig();
      if (config == null) {
        return SyncNotConfigured();
      }
      return SyncConfigured(config);
    } catch (e, stackTrace) {
      return SyncFailure(failures.UnknownFailure.fromException(e, stackTrace));
    }
  }

  /// Test WebDAV connection with comprehensive error handling
  Future<failures.SyncResult<bool>> testConnection({
    required String serverUrl,
    required String username,
    required String password,
    required String remoteFolderPath,
  }) async {
    state = AsyncValue.data(SyncLoading('Testing connection...'));

    try {
      // Get WebDAV service from provider
      final webDav = ref.read(webDavServiceProvider);

      // Initialize with credentials
      final initResult = await webDav.initialize(
        serverUrl: serverUrl,
        username: username,
        password: password,
        remoteFolderPath: remoteFolderPath,
      );

      // Handle initialization failure
      if (initResult.isLeft()) {
        final failure = initResult.failureOrNull!;
        state = AsyncValue.data(SyncFailure(failure));
        return left(failure);
      }

      // Test connection with timeout
      final testResult = await webDav.testConnection(
        timeout: const Duration(seconds: 15),
      );

      // Handle connection test failure
      if (testResult.isLeft()) {
        final failure = testResult.failureOrNull!;
        state = AsyncValue.data(SyncFailure(failure));
        return left(failure);
      }

      // Ensure remote directory exists
      final dirResult = await webDav.ensureRemoteDirectory();
      if (dirResult.isLeft()) {
        final failure = dirResult.failureOrNull!;
        state = AsyncValue.data(SyncFailure(failure));
        return left(failure);
      }

      // Auto-save configuration on successful test
      final config = SyncConfig(
        serverUrl: serverUrl,
        username: username,
        password: password,
        remoteFolderPath: remoteFolderPath,
      );

      final saveResult = await _configRepository.saveConfig(config);
      if (saveResult.isLeft()) {
        final errorMsg = saveResult.getLeft().toNullable()!;
        final failure = failures.ConfigurationFailure(
          message: 'Failed to save config: $errorMsg',
        );
        state = AsyncValue.data(SyncFailure(failure));
        return left(failure);
      }

      // Reload configuration
      state = await AsyncValue.guard(() => _loadConfig());
      return right(true);
    } catch (e, stackTrace) {
      final failure = failures.UnknownFailure.fromException(e, stackTrace);
      state = AsyncValue.data(SyncFailure(failure));
      return left(failure);
    }
  }

  /// Save sync configuration
  Future<failures.SyncResult<bool>> saveConfig(SyncConfig config) async {
    state = AsyncValue.data(SyncLoading('Saving configuration...'));

    try {
      final result = await _configRepository.saveConfig(config);

      if (result.isLeft()) {
        final errorMsg = result.getLeft().toNullable()!;
        final failure = failures.ConfigurationFailure(
          message: 'Failed to save: $errorMsg',
        );
        state = AsyncValue.data(SyncFailure(failure));
        return left(failure);
      }

      state = await AsyncValue.guard(() => _loadConfig());
      return right(true);
    } catch (e, stackTrace) {
      final failure = failures.UnknownFailure.fromException(e, stackTrace);
      state = AsyncValue.data(SyncFailure(failure));
      return left(failure);
    }
  }

  /// Perform full sync with progress tracking
  Future<failures.SyncResult<bool>> performSync() async {
    state = AsyncValue.data(SyncInProgress('Initializing sync...', 0.0));

    try {
      final result = await _syncService.performFullSync(
        onProgress: (message) {
          // Update state with progress messages
          state = AsyncValue.data(SyncInProgress(message));
        },
      );

      // Handle sync failure
      if (result.isLeft()) {
        final errorMsg = result.getLeft().toNullable()!;
        final failure = failures.UnknownFailure(message: errorMsg);
        state = AsyncValue.data(SyncFailure(failure));
        return left(failure);
      }

      final syncResult = result.getRight().toNullable()!;

      // Create statistics map
      final stats = {
        'groupsAdded': syncResult.groupsAdded,
        'groupsUpdated': syncResult.groupsUpdated,
        'groupsDeleted': syncResult.groupsDeleted,
        'booksAdded': syncResult.booksAdded,
        'booksUpdated': syncResult.booksUpdated,
        'booksDeleted': syncResult.booksDeleted,
        'filesDownloaded': syncResult.filesDownloaded,
        'filesUploaded': syncResult.filesUploaded,
      };

      state = AsyncValue.data(
        SyncSuccess(syncResult.getSummary(), syncResult.timestamp, stats),
      );

      // Reload config after delay to get updated last sync date
      Future.delayed(const Duration(seconds: 2), () async {
        state = await AsyncValue.guard(() => _loadConfig());
      });

      return right(true);
    } catch (e, stackTrace) {
      final failure = failures.UnknownFailure.fromException(e, stackTrace);
      state = AsyncValue.data(SyncFailure(failure));
      return left(failure);
    }
  }

  /// Delete sync configuration
  Future<failures.SyncResult<bool>> deleteConfig() async {
    state = AsyncValue.data(SyncLoading('Deleting configuration...'));

    try {
      final result = await _configRepository.deleteConfig();

      if (result.isLeft()) {
        final errorMsg = result.getLeft().toNullable()!;
        final failure = failures.ConfigurationFailure(
          message: 'Failed to delete: $errorMsg',
        );
        state = AsyncValue.data(SyncFailure(failure));
        return left(failure);
      }

      state = await AsyncValue.guard(() => _loadConfig());
      return right(true);
    } catch (e, stackTrace) {
      final failure = failures.UnknownFailure.fromException(e, stackTrace);
      state = AsyncValue.data(SyncFailure(failure));
      return left(failure);
    }
  }

  /// Refresh configuration
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _loadConfig());
  }

  /// Check if currently syncing
  bool get isSyncing => state.valueOrNull is SyncInProgress;

  /// Check if has error
  bool get hasError => state.valueOrNull is SyncFailure;

  /// Get current failure if any
  failures.SyncFailure? get currentFailure {
    final currentState = state.valueOrNull;
    if (currentState is SyncFailure) {
      return currentState.failure;
    }
    return null;
  }
}
