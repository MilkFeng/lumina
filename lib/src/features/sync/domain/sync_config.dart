/// Plain Dart class for storing WebDAV sync configuration
class SyncConfig {
  /// WebDAV server URL (e.g., "https://cloud.example.com/remote.php/dav/files/username/")
  final String serverUrl;

  /// WebDAV username
  final String username;

  /// WebDAV password (stored securely via flutter_secure_storage)
  final String password;

  /// Remote folder path for books (relative to serverUrl)
  /// e.g., "EpubReader/" will store books at serverUrl + "EpubReader/"
  final String remoteFolderPath;

  /// Last successful sync timestamp
  final DateTime? lastSyncDate;

  /// Last sync error message (null if no error)
  final String? lastSyncError;

  SyncConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.remoteFolderPath = 'Lumina/',
    this.lastSyncDate,
    this.lastSyncError,
  });

  SyncConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? remoteFolderPath,
    DateTime? lastSyncDate,
    String? lastSyncError,
  }) {
    return SyncConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remoteFolderPath: remoteFolderPath ?? this.remoteFolderPath,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      lastSyncError: lastSyncError ?? this.lastSyncError,
    );
  }
}
