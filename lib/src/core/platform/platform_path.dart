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

  /// A slash-separated, human-readable location for this path, suitable for
  /// basename/dirname inspection with `package:path`.
  ///
  /// Unlike [name] — which is always just the file name — this keeps the
  /// parent segments, so callers can tell *where* a file came from (for
  /// example to distinguish `books/x.epub` from `covers/x.jpg`).
  String get displayPath;

  /// Creates a PlatformPath from a platform-specific string
  ///
  /// On Android, this should be a content:// URI
  /// On iOS, this should be a file system path
  factory PlatformPath.fromString(String value) {
    if (Platform.isAndroid && value.startsWith('content://')) {
      return AndroidUriPath(value);
    } else {
      String filePath = value;
      if (Platform.isIOS && value.startsWith('file://')) {
        final decodedUri = Uri.decodeFull(value);
        filePath = decodedUri.replaceFirst('file://', '');
      }
      return IOSFilePath(filePath);
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
    final location = _documentIdPath;
    if (location == null) return 'unknown.epub';
    return location.split('/').last;
  }

  @override
  String get displayPath => _documentIdPath ?? uri;

  /// Decodes the SAF document id of this URI into a slash-separated path.
  ///
  /// A document URI looks like
  /// `content://authority/document/primary%3ABooks%2Fshelf.json`, so the last
  /// path segment holds a percent-encoded `volume:relative/path`. Returns
  /// `null` when the URI cannot be parsed.
  String? get _documentIdPath {
    try {
      final segments = Uri.parse(uri).pathSegments;
      if (segments.isEmpty) return null;
      return Uri.decodeFull(segments.last);
    } catch (e) {
      debugPrint('Error decoding document id from URI: $e');
      return null;
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

  @override
  String get displayPath => path;
}
