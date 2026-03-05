import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lumina/src/rust/api/epub.dart' as rust_epub;
import 'package:path/path.dart' as p;

/// Service for streaming EPUB content backed by a Rust native library.
///
/// Concurrency model (vs. previous Dart-Isolate approach):
///   * [openBook] calls the Rust `load_epub` function, which reads the ZIP
///     central directory once and caches a filename→entry-index map.
///     No file content is decompressed at this stage.
///   * [readFileFromEpub] calls the Rust `read_epub_file` function.
///     Rust holds a *read* lock only for the microsecond needed to look up the
///     entry index, then releases it before decompressing.  Multiple concurrent
///     calls from different WebView requests execute in parallel on the Rust
///     thread pool �?no serialisation bottleneck.
///   * The single-Isolate message queue that caused jank under heavy load is
///     completely eliminated.
class EpubStreamService {
  String? _currentBookPath;

  /// No-op: the Rust runtime is initialised globally in [main].
  Future<void> warmUp() async {}

  /// Load the EPUB file index (ZIP central directory only �?no decompression).
  /// Idempotent: calling twice with the same path is a no-op.
  Future<void> openBook(String epubPath) async {
    if (_currentBookPath == epubPath) return;

    try {
      await rust_epub.loadEpub(epubPath: epubPath);
      _currentBookPath = epubPath;
    } catch (e) {
      _currentBookPath = null;
      rethrow;
    }
  }

  /// Read a specific file from the currently opened EPUB.
  ///
  /// Returns [right] with the raw bytes on success, or [left] with an error
  /// message on failure.  Multiple concurrent calls are served in parallel by
  /// the Rust thread pool.
  Future<Either<String, Uint8List>> readFileFromEpub({
    required String targetFilePath,
    String? epubPath,
  }) async {
    if (epubPath != null && epubPath != _currentBookPath) {
      await openBook(epubPath);
    }

    try {
      final data = await rust_epub.readEpubFile(
        epubPath: _currentBookPath!,
        filePath: targetFilePath,
      );
      if (data == null) {
        return left('File not found: $targetFilePath');
      }
      return right(data);
    } catch (e) {
      return left('Read error: $e');
    }
  }

  /// Release the in-memory index for the current book path.
  void dispose() {
    if (_currentBookPath != null) {
      rust_epub.closeEpub(epubPath: _currentBookPath!).ignore();
      _currentBookPath = null;
    }
  }

  /// Returns the MIME type for the given file path based on its extension.
  String getMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
    return _mimeTypeMap[ext] ?? 'application/octet-stream';
  }

  static const _mimeTypeMap = {
    'html': 'text/html',
    'htm': 'text/html',
    'xhtml': 'application/xhtml+xml',
    'xml': 'application/xml',
    'css': 'text/css',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'svg': 'image/svg+xml',
    'webp': 'image/webp',
    'ttf': 'font/ttf',
    'otf': 'font/otf',
    'woff': 'font/woff',
    'woff2': 'font/woff2',
    'js': 'application/javascript',
  };
}
