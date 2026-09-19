import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:saf_stream/saf_stream.dart';

import 'platform_path.dart';

/// Platform file/folder picker backed by the native
/// `com.lumina.ereader/native_picker` channel.
///
/// This service is deliberately **domain-free**: it only knows how to obtain
/// opaque [PlatformPath] handles from the OS and how to read bytes through
/// them. It knows nothing about EPUBs, backups, fonts or the on-disk library
/// layout — that all lives in the feature layers.
///
/// Platform notes:
/// - Android: SAF (`ACTION_OPEN_DOCUMENT` / `ACTION_OPEN_DOCUMENT_TREE`),
///   returns `content://` URIs wrapped as [AndroidUriPath].
/// - iOS: `UIDocumentPickerViewController`, returns file-system paths wrapped
///   as [IOSFilePath] while the security-scoped resource stays open on the
///   native side. Callers **must** call [releaseIosAccess] in a `finally` block
///   once they are done reading, otherwise the scope leaks.
class FilePickerService {
  static const String _channelName = 'com.lumina.ereader/native_picker';
  static const MethodChannel _channel = MethodChannel(_channelName);

  final _safStream = SafStream();

  // ===========================================================================
  // Picking
  // ===========================================================================

  /// Picks multiple EPUB files.
  ///
  /// Returns an empty list when the user cancels, on picker failure, or when
  /// the platform is unsupported.
  Future<List<PlatformPath>> pickEpubFiles() => _pickPathList('pickEpubFiles');

  /// Picks a folder and returns every EPUB found inside it (recursive scan).
  Future<List<PlatformPath>> pickEpubFolder() =>
      _pickPathList('pickEpubFolder');

  /// Picks a folder and returns **every** file inside it, unfiltered.
  ///
  /// The native side applies no knowledge of the backup layout; classifying
  /// the returned flat list is the caller's job.
  Future<List<PlatformPath>> pickFolderFiles() =>
      _pickPathList('pickBackupFolder');

  /// Picks multiple font files (`.ttf` / `.otf`).
  Future<List<PlatformPath>> pickFontFiles() => _pickPathList('pickFontFiles');

  /// Resolves the display name (the name the system shows for the file) of
  /// every entry in [paths].
  ///
  /// A [PlatformPath] only carries an opaque platform handle. On Android that
  /// handle is a `content://` URI whose last path segment is **not** guaranteed
  /// to be a file name — the Downloads provider hands out `msf:1000000123`
  /// identifiers, and document ids may be partially escaped — so callers that
  /// need a real name (the fonts directory layout, for instance) ask the
  /// platform through this method instead of parsing the URI themselves.
  ///
  /// The returned list always has the same length as [paths]; an entry is
  /// `null` when the name could not be resolved.
  Future<List<String?>> resolveDisplayNames(List<PlatformPath> paths) async {
    if (paths.isEmpty) return const [];
    if (!Platform.isAndroid && !Platform.isIOS) {
      return List<String?>.filled(paths.length, null);
    }

    final handles = paths.map((path) {
      switch (path) {
        case AndroidUriPath(:final uri):
          return uri;
        case IOSFilePath(path: final filePath):
          return filePath;
      }
    }).toList();

    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'getDisplayNames',
        handles,
      );
      if (result == null) return List<String?>.filled(paths.length, null);

      return List<String?>.generate(paths.length, (index) {
        final name = index < result.length ? result[index] : null;
        return name is String && name.trim().isNotEmpty ? name : null;
      });
    } on PlatformException catch (e) {
      debugPrint('File picker error (getDisplayNames): ${e.message}');
      return List<String?>.filled(paths.length, null);
    }
  }

  /// Invokes a list-returning picker method and wraps the result.
  ///
  /// Every platform-specific quirk (URI vs path wrapping, error swallowing,
  /// the single-pending-operation limit on Android) is normalised here so the
  /// public methods stay one-liners.
  Future<List<PlatformPath>> _pickPathList(String method) async {
    if (!Platform.isAndroid && !Platform.isIOS) return const [];

    try {
      final result = await _channel.invokeMethod<List<Object?>>(method);
      if (result == null) return const [];

      return result.whereType<String>().map(_wrap).toList();
    } on PlatformException catch (e) {
      debugPrint('File picker error ($method): ${e.message}');
      return const [];
    }
  }

  /// Wraps a raw native result in the platform-appropriate [PlatformPath].
  static PlatformPath _wrap(String value) =>
      Platform.isAndroid ? AndroidUriPath(value) : IOSFilePath(value);

  // ===========================================================================
  // Reading
  // ===========================================================================

  /// Reads [path] fully into memory.
  ///
  /// On iOS the file is copied into `NSTemporaryDirectory()` first, inside the
  /// still-open security scope, and the temporary copy is deleted right after
  /// it has been read.
  Future<Uint8List> readBytes(PlatformPath path) async {
    switch (path) {
      case AndroidUriPath(:final uri):
        return await _safStreamReadBytes(uri);
      case IOSFilePath(path: final pathStr):
        final bytes = await readBytesViaTempFile(pathStr);
        return bytes;
    }
  }

  /// Reads [path] as UTF-8 text.
  Future<String> readPlainFile(PlatformPath path) async {
    final bytes = await readBytes(path);
    return utf8.decode(bytes);
  }

  /// Asks the native iOS side to copy [originalPath] — which must still be
  /// inside an active security scope — to a fresh file in
  /// `NSTemporaryDirectory()`, and returns that temporary path.
  ///
  /// iOS only; on other platforms the original path is returned unchanged.
  Future<String> fetchIosFileToTemp(String originalPath) async {
    if (!Platform.isIOS) return originalPath;
    final tempPath = await _channel.invokeMethod<String>(
      'fetchIosFile',
      originalPath,
    );
    return tempPath ?? originalPath;
  }

  /// Copies the iOS file at [pathStr] to a temp file, reads it, and removes
  /// the temp copy. Used by [readBytes].
  @visibleForTesting
  Future<Uint8List> readBytesViaTempFile(String pathStr) async {
    final tempPath = await fetchIosFileToTemp(pathStr);
    final tempFile = File(tempPath);
    try {
      return await tempFile.readAsBytes();
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  /// Releases every security-scoped resource currently held by the native
  /// picker (iOS only; a no-op elsewhere).
  ///
  /// **Must** be called in the `finally` block of any iOS pick→read sequence.
  Future<void> releaseIosAccess() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod<void>('releaseIosAccess');
    }
  }

  /// Reads a `content://` URI through the SAF streaming package so that large
  /// files never block the platform thread.
  Future<Uint8List> _safStreamReadBytes(String uri) {
    return _safStream.readFileBytes(uri);
  }
}
