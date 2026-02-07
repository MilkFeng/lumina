import 'dart:convert';
import 'dart:io';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:fpdart/fpdart.dart';

/// Service for WebDAV operations
/// Handles connection, file upload/download, and directory management
class WebDavService {
  late webdav.Client _client;
  String? _remoteFolderPath;

  /// Initialize WebDAV client with credentials
  Future<Either<String, bool>> initialize({
    required String serverUrl,
    required String username,
    required String password,
    required String remoteFolderPath,
  }) async {
    try {
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

      _client.setHeaders({
        'accept-charset': 'utf-8',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      });

      return right(true);
    } catch (e) {
      return left('WebDAV initialization failed: $e');
    }
  }

  /// Test connection to WebDAV server
  Future<Either<String, bool>> testConnection() async {
    try {
      // Try to ping the server
      await _client.ping();
      return right(true);
    } catch (e) {
      return left('Connection test failed: $e');
    }
  }

  /// Create remote directory if it doesn't exist
  Future<Either<String, bool>> ensureRemoteDirectory() async {
    try {
      // Check if directory exists
      await _client.readDir(_remoteFolderPath!);
      return right(true);
    } catch (e) {
      // Directory might not exist, try to create it
      try {
        await _client.mkdir(_remoteFolderPath!);
        return right(true);
      } catch (createError) {
        return left('Failed to create remote directory: $createError');
      }
    }
  }

  /// Upload a file to WebDAV server
  Future<Either<String, bool>> uploadFile({
    required File localFile,
    required String remoteFileName,
  }) async {
    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      final fileBytes = await localFile.readAsBytes();

      await _client.write(remotePath, fileBytes);
      return right(true);
    } catch (e) {
      return left('Upload failed for $remoteFileName: $e');
    }
  }

  /// Upload text content to WebDAV server
  Future<Either<String, bool>> uploadText({
    required String content,
    required String remoteFileName,
  }) async {
    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      final bytes = utf8.encode(content);
      await _client.write(remotePath, bytes);
      return right(true);
    } catch (e) {
      return left('Upload text failed for $remoteFileName: $e');
    }
  }

  /// Download a file from WebDAV server
  Future<Either<String, List<int>>> downloadFile(String remoteFileName) async {
    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      final bytes = await _client.read(remotePath);
      return right(bytes);
    } catch (e) {
      return left('Download failed for $remoteFileName: $e');
    }
  }

  /// Download text content from WebDAV server
  Future<Either<String, String>> downloadText(String remoteFileName) async {
    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      final content = await _client.read(remotePath);
      return right(utf8.decode(content));
    } catch (e) {
      return left('Download text failed for $remoteFileName: $e');
    }
  }

  /// List files in remote directory
  Future<Either<String, List<webdav.File>>> listFiles() async {
    try {
      final files = await _client.readDir(_remoteFolderPath!);
      return right(files);
    } catch (e) {
      return left('List files failed: $e');
    }
  }

  /// List files in remote directory
  Future<Either<String, List<webdav.File>>> listFilesByPath(String path) async {
    final fullPath = '$_remoteFolderPath$path';

    try {
      final files = await _client.readDir(fullPath);
      return right(files);
    } catch (e) {
      return left('List files failed: $e');
    }
  }

  /// Check if a file exists on the server
  Future<bool> fileExists(String remoteFileName) async {
    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      await _client.readDir(remotePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a file from the server
  Future<Either<String, bool>> deleteFile(String remoteFileName) async {
    try {
      final remotePath = '$_remoteFolderPath$remoteFileName';
      await _client.remove(remotePath);
      return right(true);
    } catch (e) {
      return left('Delete failed for $remoteFileName: $e');
    }
  }

  /// Get file modification date
  Future<Either<String, DateTime?>> getFileModifiedDate(
    String remoteFileName,
  ) async {
    try {
      final files = await _client.readDir(_remoteFolderPath!);
      final file = files.firstWhere(
        (f) => f.name == remoteFileName,
        orElse: () => throw Exception('File not found'),
      );
      return right(file.mTime);
    } catch (e) {
      return left('Get file date failed: $e');
    }
  }

  /// Dispose client
  void dispose() {
    // No explicit dispose method in webdav_client
  }
}
