import 'package:fpdart/fpdart.dart';

/// Base class for all sync-related failures
/// Uses sealed class pattern for exhaustive pattern matching
sealed class SyncFailure {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const SyncFailure({required this.message, this.error, this.stackTrace});

  @override
  String toString() => message;
}

// ==================== Network Failures ====================

/// Failure when connecting to WebDAV server
class NetworkConnectionFailure extends SyncFailure {
  const NetworkConnectionFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  factory NetworkConnectionFailure.timeout() {
    return const NetworkConnectionFailure(
      message: 'Connection timeout. Please check your network.',
    );
  }

  factory NetworkConnectionFailure.unreachable(String serverUrl) {
    return NetworkConnectionFailure(message: 'Cannot reach server: $serverUrl');
  }
}

/// Failure during authentication
class AuthenticationFailure extends SyncFailure {
  const AuthenticationFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  factory AuthenticationFailure.invalidCredentials() {
    return const AuthenticationFailure(message: 'Invalid username or password');
  }

  factory AuthenticationFailure.unauthorized() {
    return const AuthenticationFailure(
      message: 'Unauthorized. Please check your credentials.',
    );
  }
}

/// Failure during file transfer
class FileTransferFailure extends SyncFailure {
  final String? fileName;

  const FileTransferFailure({
    required super.message,
    this.fileName,
    super.error,
    super.stackTrace,
  });

  factory FileTransferFailure.uploadFailed(String fileName) {
    return FileTransferFailure(
      message: 'Failed to upload: $fileName',
      fileName: fileName,
    );
  }

  factory FileTransferFailure.downloadFailed(String fileName) {
    return FileTransferFailure(
      message: 'Failed to download: $fileName',
      fileName: fileName,
    );
  }

  factory FileTransferFailure.notFound(String fileName) {
    return FileTransferFailure(
      message: 'File not found: $fileName',
      fileName: fileName,
    );
  }
}

// ==================== Data Failures ====================

/// Failure when parsing or serializing data
class DataParseFailure extends SyncFailure {
  const DataParseFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  factory DataParseFailure.invalidJson(Object? error) {
    return DataParseFailure(message: 'Invalid JSON format', error: error);
  }

  factory DataParseFailure.snapshotCorrupted() {
    return const DataParseFailure(message: 'Snapshot file is corrupted');
  }
}

/// Failure during merge operations
class MergeConflictFailure extends SyncFailure {
  final int conflictCount;

  const MergeConflictFailure({
    required super.message,
    required this.conflictCount,
    super.error,
    super.stackTrace,
  });

  factory MergeConflictFailure.unresolvable(int count) {
    return MergeConflictFailure(
      message: 'Found $count unresolvable conflicts',
      conflictCount: count,
    );
  }
}

// ==================== Storage Failures ====================

/// Failure when accessing local storage
class StorageFailure extends SyncFailure {
  const StorageFailure({required super.message, super.error, super.stackTrace});

  factory StorageFailure.noSpace() {
    return const StorageFailure(message: 'Insufficient storage space');
  }

  factory StorageFailure.permissionDenied() {
    return const StorageFailure(message: 'Storage permission denied');
  }

  factory StorageFailure.fileNotFound(String path) {
    return StorageFailure(message: 'File not found: $path');
  }
}

/// Failure when accessing configuration
class ConfigurationFailure extends SyncFailure {
  const ConfigurationFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  factory ConfigurationFailure.notConfigured() {
    return const ConfigurationFailure(
      message: 'Sync not configured. Please set up WebDAV connection.',
    );
  }

  factory ConfigurationFailure.invalidConfig() {
    return const ConfigurationFailure(message: 'Invalid sync configuration');
  }
}

// ==================== Server Failures ====================

/// Failure due to server-side issues
class ServerFailure extends SyncFailure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.error,
    super.stackTrace,
  });

  factory ServerFailure.internalError() {
    return const ServerFailure(
      message: 'Server internal error (500)',
      statusCode: 500,
    );
  }

  factory ServerFailure.serviceUnavailable() {
    return const ServerFailure(
      message: 'Service temporarily unavailable (503)',
      statusCode: 503,
    );
  }

  factory ServerFailure.insufficientStorage() {
    return const ServerFailure(
      message: 'Insufficient storage on server (507)',
      statusCode: 507,
    );
  }

  factory ServerFailure.custom(int statusCode, String message) {
    return ServerFailure(
      message: 'Server error ($statusCode): $message',
      statusCode: statusCode,
    );
  }
}

// ==================== Generic Failure ====================

/// Generic failure for unexpected errors
class UnknownFailure extends SyncFailure {
  const UnknownFailure({required super.message, super.error, super.stackTrace});

  factory UnknownFailure.fromException(Object error, StackTrace? stackTrace) {
    return UnknownFailure(
      message: 'Unexpected error: ${error.toString()}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

// ==================== Type Aliases ====================

/// Type alias for sync operation results
typedef SyncResult<T> = Either<SyncFailure, T>;

/// Extension methods for SyncResult
extension SyncResultX<T> on SyncResult<T> {
  /// Get failure or null
  SyncFailure? get failureOrNull => fold((l) => l, (_) => null);

  /// Get value or null
  T? get valueOrNull => fold((_) => null, (r) => r);

  /// Map failure to another failure
  SyncResult<T> mapFailure(SyncFailure Function(SyncFailure) transform) {
    return fold((failure) => left(transform(failure)), (value) => right(value));
  }

  /// Execute action on success
  SyncResult<T> onSuccess(void Function(T) action) {
    return fold((failure) => left(failure), (value) {
      action(value);
      return right(value);
    });
  }

  /// Execute action on failure
  SyncResult<T> onFailure(void Function(SyncFailure) action) {
    return fold((failure) {
      action(failure);
      return left(failure);
    }, (value) => right(value));
  }
}
