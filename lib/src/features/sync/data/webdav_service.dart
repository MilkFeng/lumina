import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../domain/failures/sync_failures.dart';

/// Service for WebDAV operations with robust error handling
/// All methods return SyncResult<T> for functional error handling
class WebDavService {
  webdav.Client? _client;
  String? _remoteFolderPath;
  bool _isInitialized = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize WebDAV client with credentials
  /// Returns SyncResult<bool> instead of Either<String, bool>
  Future<SyncResult<bool>> initialize({
    required String serverUrl,
    required String username,
    required String password,
    required String remoteFolderPath,
  }) async {
    try {
      // Validate inputs
      if (serverUrl.isEmpty) {
        return left(
          const ConfigurationFailure(message: 'Server URL cannot be empty'),
        );
      }

      // Ensure server URL ends with /
      final normalizedUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';

      _remoteFolderPath = remoteFolderPath.endsWith('/')
          ? remoteFolderPath
          : '$remoteFolderPath/';

      _client = webdav.newClient(
        normalizedUrl,
        user: username,
        password: password,
        debug: false,
      );

      _client!.setHeaders({
        'accept-charset': 'utf-8',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      });

      _isInitialized = true;
      return right(true);
    } on SocketException catch (e, stackTrace) {
      return left(
        NetworkConnectionFailure(
          message: 'Network error: ${e.message}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    } catch (e, stackTrace) {
      return left(UnknownFailure.fromException(e, stackTrace));
    }
  }

  /// Test connection to WebDAV server with timeout
  Future<SyncResult<bool>> testConnection({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isInitialized || _client == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    try {
      // Wrap ping with timeout
      await _client!.ping().timeout(
        timeout,
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );
      return right(true);
    } on TimeoutException catch (e, stackTrace) {
      return left(
        NetworkConnectionFailure(
          message: 'Connection timeout after ${timeout.inSeconds}s',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    } on SocketException {
      return left(
        NetworkConnectionFailure.unreachable(_remoteFolderPath ?? 'unknown'),
      );
    } catch (e, stackTrace) {
      // Handle authentication errors from webdav_client
      if (e.toString().contains('401') || e.toString().contains('403')) {
        return left(AuthenticationFailure.unauthorized());
      }
      return left(UnknownFailure.fromException(e, stackTrace));
    }
  }

  /// Create remote directory if it doesn't exist
  Future<SyncResult<bool>> ensureRemoteDirectory() async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    try {
      // Check if directory exists
      await _client!.readDir(_remoteFolderPath!);
      return right(true);
    } catch (e, stackTrace) {
      // Directory might not exist (404), try to create it
      if (e.toString().contains('404')) {
        try {
          await _client!.mkdir(_remoteFolderPath!);
          return right(true);
        } catch (createError) {
          if (createError.toString().contains('507')) {
            return left(ServerFailure.insufficientStorage());
          }
          return left(
            ServerFailure.custom(
              500,
              'Failed to create directory: $createError',
            ),
          );
        }
      }
      if (e.toString().contains('401') || e.toString().contains('403')) {
        return left(AuthenticationFailure.unauthorized());
      }
      return left(UnknownFailure.fromException(e, stackTrace));
    }
  }

  /// Upload a file to WebDAV server with retry logic
  Future<SyncResult<bool>> uploadFile({
    required File localFile,
    required String remoteFileName,
    int maxRetries = 3,
    void Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    // Validate file exists
    if (!await localFile.exists()) {
      return left(StorageFailure.fileNotFound(localFile.path));
    }

    final remotePath = '$_remoteFolderPath$remoteFileName';
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final fileBytes = await localFile.readAsBytes();
        await _client!.write(remotePath, fileBytes);
        return right(true);
      } on SocketException catch (e, stackTrace) {
        // Retry on network errors
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return left(
          NetworkConnectionFailure(
            message: 'Network error during upload: ${e.message}',
            error: e,
            stackTrace: stackTrace,
          ),
        );
      } on FileSystemException catch (e, stackTrace) {
        return left(
          StorageFailure(
            message: 'Cannot read file: ${e.message}',
            error: e,
            stackTrace: stackTrace,
          ),
        );
      } catch (e, stackTrace) {
        final errorStr = e.toString();

        if (errorStr.contains('401') || errorStr.contains('403')) {
          return left(AuthenticationFailure.unauthorized());
        }
        if (errorStr.contains('507')) {
          return left(ServerFailure.insufficientStorage());
        }

        // Retry on server errors (5xx)
        if (errorStr.contains('5') && attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        return left(
          FileTransferFailure(
            message: 'Upload failed for $remoteFileName: $e',
            fileName: remoteFileName,
            error: e,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return left(FileTransferFailure.uploadFailed(remoteFileName));
  }

  /// Upload text content to WebDAV server
  Future<SyncResult<bool>> uploadText({
    required String content,
    required String remoteFileName,
    int maxRetries = 3,
  }) async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    final remotePath = '$_remoteFolderPath$remoteFileName';
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final bytes = utf8.encode(content);
        await _client!.write(remotePath, bytes);
        return right(true);
      } on SocketException catch (e, stackTrace) {
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return left(
          NetworkConnectionFailure(
            message: 'Network error: ${e.message}',
            error: e,
            stackTrace: stackTrace,
          ),
        );
      } catch (e) {
        final errorStr = e.toString();

        if (errorStr.contains('401') || errorStr.contains('403')) {
          return left(AuthenticationFailure.unauthorized());
        }

        // Retry on server errors
        if (errorStr.contains('5') && attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        return left(FileTransferFailure.uploadFailed(remoteFileName));
      }
    }

    return left(FileTransferFailure.uploadFailed(remoteFileName));
  }

  /// Download a file from WebDAV server with retry logic
  Future<SyncResult<List<int>>> downloadFile(
    String remoteFileName, {
    int maxRetries = 3,
    void Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    final remotePath = '$_remoteFolderPath$remoteFileName';
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final bytes = await _client!.read(remotePath);
        return right(bytes);
      } on SocketException catch (e, stackTrace) {
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return left(
          NetworkConnectionFailure(
            message: 'Network error: ${e.message}',
            error: e,
            stackTrace: stackTrace,
          ),
        );
      } catch (e) {
        final errorStr = e.toString();

        if (errorStr.contains('404')) {
          return left(FileTransferFailure.notFound(remoteFileName));
        }
        if (errorStr.contains('401') || errorStr.contains('403')) {
          return left(AuthenticationFailure.unauthorized());
        }

        // Retry on server errors
        if (errorStr.contains('5') && attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        return left(FileTransferFailure.downloadFailed(remoteFileName));
      }
    }

    return left(FileTransferFailure.downloadFailed(remoteFileName));
  }

  /// Download text content from WebDAV server
  Future<SyncResult<String>> downloadText(
    String remoteFileName, {
    int maxRetries = 3,
  }) async {
    final result = await downloadFile(remoteFileName, maxRetries: maxRetries);

    return result.flatMap((bytes) {
      try {
        final content = utf8.decode(bytes);
        return right(content);
      } catch (e, stackTrace) {
        return left(
          DataParseFailure(
            message: 'Failed to decode text file: $remoteFileName',
            error: e,
            stackTrace: stackTrace as StackTrace?,
          ),
        );
      }
    });
  }

  /// List files in remote directory
  Future<SyncResult<List<webdav.File>>> listFiles() async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    try {
      final files = await _client!.readDir(_remoteFolderPath!);
      return right(files);
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('404')) {
        return right([]); // Directory doesn't exist yet, return empty list
      }
      if (errorStr.contains('401') || errorStr.contains('403')) {
        return left(AuthenticationFailure.unauthorized());
      }
      return left(ServerFailure.custom(500, 'Failed to list files: $e'));
    }
  }

  /// List files in a specific path
  Future<SyncResult<List<webdav.File>>> listFilesByPath(String path) async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    final fullPath = '$_remoteFolderPath$path';

    try {
      final files = await _client!.readDir(fullPath);
      return right(files);
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('404')) {
        return right([]); // Path doesn't exist, return empty list
      }
      if (errorStr.contains('401') || errorStr.contains('403')) {
        return left(AuthenticationFailure.unauthorized());
      }
      return left(
        ServerFailure.custom(500, 'Failed to list files at $path: $e'),
      );
    }
  }

  /// Check if a file exists on the server
  Future<bool> fileExists(String remoteFileName) async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return false;
    }

    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      await _client!.readDir(remotePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a file from the server
  Future<SyncResult<bool>> deleteFile(String remoteFileName) async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      await _client!.remove(remotePath);
      return right(true);
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('404')) {
        return right(true); // File doesn't exist, consider it deleted
      }
      if (errorStr.contains('401') || errorStr.contains('403')) {
        return left(AuthenticationFailure.unauthorized());
      }
      return left(
        ServerFailure.custom(500, 'Failed to delete $remoteFileName: $e'),
      );
    }
  }

  /// Get file modification date
  Future<SyncResult<DateTime?>> getFileModifiedDate(
    String remoteFileName,
  ) async {
    if (!_isInitialized || _client == null || _remoteFolderPath == null) {
      return left(ConfigurationFailure.notConfigured());
    }

    try {
      final files = await _client!.readDir(_remoteFolderPath!);
      final file = files.where((f) => f.name == remoteFileName).firstOrNull;

      if (file == null) {
        return left(FileTransferFailure.notFound(remoteFileName));
      }

      return right(file.mTime);
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('401') || errorStr.contains('403')) {
        return left(AuthenticationFailure.unauthorized());
      }
      return left(ServerFailure.custom(500, 'Failed to get file date: $e'));
    }
  }

  /// Dispose client and reset state
  void dispose() {
    _client = null;
    _remoteFolderPath = null;
    _isInitialized = false;
  }
}
