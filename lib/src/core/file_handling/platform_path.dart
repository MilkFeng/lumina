import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Sealed class representing a platform-specific file path
///
/// This abstraction allows us to handle file access differently on Android
/// (using SAF URIs) and iOS (using traditional file paths).
sealed class PlatformPath {
  const PlatformPath();

  String get name;

  /// Creates a PlatformPath from a platform-specific string
  ///
  /// On Android, this should be a content:// URI
  /// On iOS, this should be a file system path
  factory PlatformPath.fromString(String value) {
    if (Platform.isAndroid && value.startsWith('content://')) {
      return AndroidUriPath(value);
    } else {
      return IOSFilePath(value);
    }
  }
}

/// Android-specific path using Storage Access Framework (SAF) URI
///
/// Example: content://com.android.providers.downloads.documents/document/123
final class AndroidUriPath extends PlatformPath {
  /// The SAF content URI as a string
  final String uri;

  const AndroidUriPath(this.uri);

  @override
  String toString() => 'AndroidUriPath(uri: $uri)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AndroidUriPath &&
          runtimeType == other.runtimeType &&
          uri == other.uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String get name {
    try {
      final decodedUri = Uri.decodeFull(uri);
      return p.basename(decodedUri);
    } catch (e) {
      debugPrint('Failed to decode URI: $uri, error: $e');
      return uri; // Fallback to raw URI if decoding fails
    }
  }
}

/// iOS-specific path using traditional file system path
///
/// Example: /var/mobile/Containers/Data/Application/xxx/Documents/book.epub
final class IOSFilePath extends PlatformPath {
  /// The file system path as a string
  final String path;

  const IOSFilePath(this.path);

  @override
  String toString() => 'IOSFilePath(path: $path)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IOSFilePath &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String get name => p.basename(path);
}
