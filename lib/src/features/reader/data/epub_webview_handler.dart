import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';
import 'services/epub_stream_service.dart';

/// WebView request handler for streaming EPUB content
/// Intercepts requests to virtual domain and serves files from compressed EPUB
class EpubWebViewHandler {
  final EpubStreamService _streamService;

  /// Virtual domain for EPUB content
  /// Format: epub://localhost/book/{fileHash}/{filePath}
  static const String virtualDomain = 'localhost';
  static const String virtualScheme = 'epub';
  static const _headers = {'Cache-Control': 'public, max-age=31536000'};

  EpubWebViewHandler({required EpubStreamService streamService})
    : _streamService = streamService;

  /// Create WebView resource request handler
  /// This should be set as the shouldInterceptRequest callback
  Future<WebResourceResponse?> handleRequest({
    required String epubPath,
    required String fileHash,
    required WebUri requestUrl,
  }) async {
    try {
      // Serve user-imported fonts.
      if (isFontRequest(requestUrl)) {
        final result = await _readFontFile(requestUrl);
        if (result.isLeft()) {
          return WebResourceResponse(
            statusCode: 404,
            reasonPhrase: 'Not Found',
            data: Uint8List.fromList('Font not found'.codeUnits),
          );
        }
        final data = result.getRight().toNullable()!.$1;
        final mimeType = result.getRight().toNullable()!.$2;
        return WebResourceResponse(
          contentType: mimeType,
          statusCode: 200,
          reasonPhrase: 'OK',
          data: data,
          headers: _headers,
        );
      }

      // Read file from EPUB
      final result = await _readFileFromEpub(epubPath, fileHash, requestUrl);

      if (result.isLeft()) {
        // File not found or error
        return WebResourceResponse(
          statusCode: 404,
          reasonPhrase: 'Not Found',
          data: Uint8List.fromList('File not found'.codeUnits),
        );
      }

      final data = result.getRight().toNullable()!.$1;
      final mimeType = result.getRight().toNullable()!.$2;

      // Return the file content
      return WebResourceResponse(
        contentType: mimeType,
        statusCode: 200,
        reasonPhrase: 'OK',
        data: data,
        headers: _headers,
      );
    } catch (e) {
      // Internal error
      return WebResourceResponse(
        statusCode: 500,
        reasonPhrase: 'Internal Server Error',
        data: Uint8List.fromList('Error: $e'.codeUnits),
      );
    }
  }

  Future<CustomSchemeResponse?> handleRequestWithCustomScheme({
    required String epubPath,
    required String fileHash,
    required WebUri requestUrl,
  }) async {
    try {
      // Serve user-imported fonts.
      if (isFontRequest(requestUrl)) {
        final result = await _readFontFile(requestUrl);
        if (result.isLeft()) {
          final msg = result.getLeft().toNullable()!;
          return CustomSchemeResponse(
            contentType: 'text/plain',
            data: Uint8List.fromList(msg.codeUnits),
          );
        }
        final data = result.getRight().toNullable()!.$1;
        final mimeType = result.getRight().toNullable()!.$2;
        return CustomSchemeResponse(contentType: mimeType, data: data);
      }

      final result = await _readFileFromEpub(epubPath, fileHash, requestUrl);

      if (result.isLeft()) {
        final errorMessage = result.getLeft().toNullable()!;
        return CustomSchemeResponse(
          contentType: 'text/plain',
          data: Uint8List.fromList(errorMessage.codeUnits),
        );
      }

      final data = result.getRight().toNullable()!.$1;
      final mimeType = result.getRight().toNullable()!.$2;

      return CustomSchemeResponse(contentType: mimeType, data: data);
    } catch (e) {
      final errorMessage = 'Error reading file: $e';
      return CustomSchemeResponse(
        contentType: 'text/plain',
        data: Uint8List.fromList(errorMessage.codeUnits),
      );
    }
  }

  /// Read a file from an EPUB
  /// Returns Either:
  ///   - Left: error message
  ///   - Right: (data, mimeType)
  Future<Either<String, (Uint8List, String)>> _readFileFromEpub(
    String epubPath,
    String fileHash,
    WebUri requestUrl,
  ) async {
    final prefix = "/book/$fileHash/";
    if (!requestUrl.path.startsWith(prefix)) {
      return left('Invalid file hash');
    }

    final decodedPath = Uri.decodeFull(requestUrl.path);
    final relativePath = decodedPath.substring(prefix.length);

    final fileRelativePath = relativePath.split('#')[0];

    epubPath = '${AppStorage.documentsPath}$epubPath';

    final result = await _streamService.readFileFromEpub(
      epubPath: epubPath,
      targetFilePath: fileRelativePath,
    );

    if (result.isLeft()) {
      return left(result.getLeft().toNullable() ?? 'Error reading file');
    }

    final data = result.getRight().toNullable()!;
    final mimeType = _streamService.getMimeType(fileRelativePath);

    return right((data, mimeType));
  }

  /// Reads a font file from the app's fonts directory.
  /// URL format: epub://localhost/fonts/<fileName>
  Future<Either<String, (Uint8List, String)>> _readFontFile(
    WebUri requestUrl,
  ) async {
    const prefix = '/fonts/';
    if (!requestUrl.path.startsWith(prefix)) {
      return left('Invalid font path');
    }
    final fileName = Uri.decodeComponent(
      requestUrl.path.substring(prefix.length),
    );
    if (fileName.isEmpty || fileName.contains('/')) {
      return left('Invalid font file name');
    }
    final filePath = '${AppStorage.documentsPath}fonts/$fileName';
    final file = File(filePath);
    if (!await file.exists()) {
      return left('Font file not found: $fileName');
    }
    final bytes = await file.readAsBytes();
    final ext = fileName.toLowerCase().split('.').last;
    final mimeType = _fontMimeTypes[ext] ?? 'application/octet-stream';
    return right((bytes, mimeType));
  }

  static const _fontMimeTypes = {
    'ttf': 'font/ttf',
    'otf': 'font/otf',
    'woff': 'font/woff',
    'woff2': 'font/woff2',
  };

  /// Generate base URL for a chapter
  /// This URL should be used as the baseUrl parameter when loading HTML
  static String getBaseUrl() {
    return '$virtualScheme://$virtualDomain/book/index.html';
  }

  /// Generate full URL for a specific file
  static String getFileUrl(String fileHash, Href href) {
    final url =
        '$virtualScheme://$virtualDomain/book/$fileHash/${href.path}${'#${href.anchor}'}';
    return Uri.encodeFull(url);
  }

  /// Generate URL for a user-imported font file.
  /// Format: epub://localhost/fonts/<fileName>
  static String getFontUrl(String fileName) {
    return '$virtualScheme://$virtualDomain/fonts/$fileName';
  }

  /// Check if a request is for an EPUB file
  static bool isEpubRequest(WebUri requestUrl) {
    return requestUrl.scheme == virtualScheme &&
        requestUrl.host == virtualDomain &&
        requestUrl.path.startsWith('/book/');
  }

  /// Check if a request is for a user-imported font.
  static bool isFontRequest(WebUri requestUrl) {
    return requestUrl.scheme == virtualScheme &&
        requestUrl.host == virtualDomain &&
        requestUrl.path.startsWith('/fonts/');
  }
}
