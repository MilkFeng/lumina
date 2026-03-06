import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/book_manifest.dart';
import '../parsers/pdf_zip_parser.dart';

/// Parameters for PDF parsing in isolate (not used directly)
class PdfParseParams {
  final String filePath;
  final String fileHash;
  final String? originalFileName;
  final String? password; // Optional password for protected PDFs

  PdfParseParams({
    required this.filePath,
    required this.fileHash,
    this.originalFileName,
    this.password,
  });
}

/// Static utility class for PDF import operations
/// These methods are designed to be run in isolates via compute()
class PdfImportWorkers {
  /// Calculate SHA-256 hash of a file and convert to Base62
  /// Shared with epub_import_workers
  static Future<Either<String, String>> calculateFileHash(String path) async {
    try {
      final file = File(path);
      final stream = file.openRead();
      final digest = await sha256.bind(stream).first;

      BigInt number = BigInt.parse(digest.toString(), radix: 16);
      final hash = _toBase62(number);

      return right(hash);
    } catch (e) {
      return left('Hash calculation failed: $e');
    }
  }

  /// Parse PDF file and extract metadata
  /// Returns Either with error message or ParseResult
  static Future<Either<String, PdfParseResult>> parsePdf(
    PdfParseParams params,
  ) async {
    try {
      final parser = PdfZipParser();

      // If password is provided, parse with it
      if (params.password != null && params.password!.isNotEmpty) {
        final parseResult = parser.parseWithPassword(
          params.filePath,
          params.password!,
          fileName: params.originalFileName,
        );

        if (parseResult.isRight()) {
          final data = parseResult.getRight().toNullable()!;
          return right(_convertParseResult(data));
        } else {
          return left(parseResult.getLeft().toNullable()!);
        }
      }

      // Try parsing without password
      final parseResult = await parser.parseFromFile(
        params.filePath,
        fileName: params.originalFileName,
      );

      if (parseResult.isLeft()) {
        return left(parseResult.getLeft().toNullable()!);
      }

      final data = parseResult.getRight().toNullable()!;
      return right(_convertParseResult(data));
    } catch (e) {
      return left('PDF parse error: $e');
    }
  }

  /// Convert PdfZipParseResult to PdfParseResult
  static PdfParseResult _convertParseResult(data) {
    return PdfParseResult(
      title: data.title,
      author: data.author,
      authors: data.authors,
      description: data.description,
      subjects: data.subjects,
      pdfVersion: data.pdfVersion,
      totalChapters: data.pageCount,
      toc: data.toc.isNotEmpty ? data.toc : _generatePageToc(data.pageCount),
      isPasswordProtected: data.isPasswordProtected,
    );
  }

  /// Generate simple page-based TOC when PDF has no outline
  static List<TocItem> _generatePageToc(int pageCount) {
    final result = <TocItem>[];
    for (int i = 0; i < pageCount && i < 1000; i++) {
      // Limit to 1000 pages to prevent excessive memory usage
      final pageNum = i + 1;
      final href = Href();
      href.path = '$i';
      result.add(TocItem()
        ..id = i
        ..label = 'Page $pageNum'
        ..href = href
        ..depth = 0
        ..parentId = -1
        ..spineIndex = i
        ..children = []);
    }
    return result;
  }

  /// Extract cover image from PDF
  /// Returns null if extraction fails or PDF is password-protected
  static Future<Uint8List?> extractCover(
    String filePath, {
    String? password,
  }) async {
    try {
      final parser = PdfZipParser();
      final imageBytes = await parser.extractCoverImage(
        filePath,
        password: password,
        maxWidth: 400,
        maxHeight: 600,
      );

      if (imageBytes == null || imageBytes.isEmpty) {
        return null;
      }

      // Compress the image
      final compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 300,
        minHeight: 400,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      return compressed.isEmpty ? imageBytes : compressed;
    } catch (e) {
      debugPrint('PDF cover extraction failed: $e');
      return null;
    }
  }

  /// Check if PDF is password protected
  static Future<bool> checkPasswordProtection(String filePath) async {
    try {
      return await PdfZipParser.checkPasswordProtection(filePath);
    } catch (e) {
      debugPrint('Password check failed: $e');
      return false;
    }
  }

  /// Validate PDF password by attempting to parse with it
  static Future<bool> validatePassword(
    String filePath,
    String password,
  ) async {
    try {
      final parser = PdfZipParser();
      final result = parser.parseWithPassword(filePath, password);

      if (result.isRight()) {
        // Success - password is valid, clean up
        final pdfDoc = result.getRight().toNullable();
        if (pdfDoc != null) {
          // Parser already disposes document
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Convert BigInt to Base62 string
  static String _toBase62(BigInt num) {
    if (num == BigInt.zero) return '0';

    const chars =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final base = BigInt.from(chars.length);
    final codeUnits = <int>[];

    while (num > BigInt.zero) {
      var remainder = (num % base).toInt();
      codeUnits.add(chars.codeUnitAt(remainder));
      num = num ~/ base;
    }

    return String.fromCharCodes(codeUnits.reversed);
  }
}