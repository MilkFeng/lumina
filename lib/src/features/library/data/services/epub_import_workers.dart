import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import '../../domain/book_manifest.dart';
import '../parsers/epub_zip_parser.dart';

/// Configuration constants for import workers
class ImportWorkerConfig {
  static const int imageThumbnailMaxHeight = 1200;
  static const int imageCompressionQuality = 90;
}

/// Parameters for isolate parsing
class ParseParams {
  final String filePath;
  final String fileHash;
  final String? originalFileName;

  ParseParams({
    required this.filePath,
    required this.fileHash,
    this.originalFileName,
  });
}

/// Result of in-memory EPUB parsing
class ParseResult {
  final String title;
  final String author;
  final List<String> authors;
  final String? description;
  final List<String> subjects;
  final String? coverHref;
  final String opfRootPath;
  final String epubVersion;
  final int totalChapters;
  final List<SpineItem> spine;
  final List<TocItem> toc;
  final List<ManifestItem> manifestItems;
  final int readDirection;

  ParseResult({
    required this.title,
    required this.author,
    required this.authors,
    this.description,
    required this.subjects,
    this.coverHref,
    required this.opfRootPath,
    required this.epubVersion,
    required this.totalChapters,
    required this.spine,
    required this.toc,
    required this.manifestItems,
    required this.readDirection,
  });
}

/// Static utility class for EPUB import operations
/// These methods are designed to be run in isolates via compute()
class ImportWorkers {
  /// Calculate SHA-256 hash of a file and convert to Base62
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

  /// Parse EPUB file in-memory and extract metadata
  static Future<Either<String, ParseResult>> parseEpub(
    ParseParams params,
  ) async {
    try {
      final parser = EpubZipParser();
      final parseResult = await parser.parseFromFile(
        params.filePath,
        fileName: params.originalFileName,
      );

      if (parseResult.isLeft()) {
        return left(parseResult.getLeft().toNullable()!);
      }

      final data = parseResult.getRight().toNullable()!;

      final result = ParseResult(
        title: data.title,
        author: data.author,
        authors: data.authors,
        description: data.description,
        subjects: data.subjects,
        coverHref: data.coverHref,
        opfRootPath: data.opfRootPath,
        epubVersion: data.epubVersion,
        totalChapters: data.totalChapters,
        spine: data.spine,
        toc: data.toc,
        manifestItems: data.manifestItems,
        readDirection: data.readDirection,
      );

      return right(result);
    } catch (e) {
      return left('Parse error: $e');
    }
  }

  /// Compress and resize image to JPEG format
  /// Returns null if image cannot be decoded
  static Uint8List? compressImage(
    Uint8List rawBytes, {
    int maxHeight = ImportWorkerConfig.imageThumbnailMaxHeight,
    int quality = ImportWorkerConfig.imageCompressionQuality,
  }) {
    try {
      final image = img.decodeImage(rawBytes);
      if (image == null) return null;

      img.Image resizedImage = image;
      if (image.height > maxHeight) {
        resizedImage = img.copyResize(
          image,
          height: maxHeight,
          interpolation: img.Interpolation.average,
        );
      }

      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
    } catch (e) {
      debugPrint('Image compression worker error: $e');
      return null;
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
