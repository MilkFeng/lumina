import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fpdart/fpdart.dart';

/// Service for importing and managing EPUB files
/// Uses "exploded archive" strategy: unzips EPUBs to local filesystem
class FileService {
  /// Import an EPUB file and unzip it to local storage
  /// Returns Either:
  ///   - Right: relative path to the unzipped folder (e.g., "books/{hash}")
  ///   - Left: error message
  Future<Either<String, String>> importBook(File file) async {
    try {
      // 1. Calculate SHA-256 hash
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      // 2. Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      // 3. Check if book already exists
      final bookDir = Directory('${booksDir.path}/$hash');
      if (await bookDir.exists()) {
        // Book already imported
        return right('books/$hash');
      }

      // 4. Unzip in isolate (heavy operation)
      final unzipResult = await compute(
        _unzipEpub,
        _UnzipParams(bytes: bytes, targetPath: bookDir.path),
      );

      if (unzipResult.isLeft()) {
        return left(unzipResult.getLeft().toNullable() ?? 'Unzip failed');
      }

      return right('books/$hash');
    } catch (e) {
      return left('Import failed: $e');
    }
  }

  /// Get the absolute path to a book folder
  /// Input: relative path (e.g., "books/{hash}")
  /// Output: absolute path (e.g., "/data/user/0/.../books/{hash}")
  Future<String> getBookAbsolutePath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$relativePath';
  }

  /// Check if a book exists by hash
  Future<bool> bookExists(String fileHash) async {
    final appDir = await getApplicationDocumentsDirectory();
    final bookDir = Directory('${appDir.path}/books/$fileHash');
    return await bookDir.exists();
  }

  /// Delete a book folder
  Future<Either<String, bool>> deleteBook(String relativePath) async {
    try {
      final absolutePath = await getBookAbsolutePath(relativePath);
      final bookDir = Directory(absolutePath);
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
      }
      return right(true);
    } catch (e) {
      return left('Delete failed: $e');
    }
  }

  /// Calculate SHA-256 hash of a file
  Future<String> calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}

/// Parameters for isolate unzip operation
class _UnzipParams {
  final List<int> bytes;
  final String targetPath;

  _UnzipParams({required this.bytes, required this.targetPath});
}

/// Isolate function to unzip EPUB
/// This runs in a separate thread to avoid blocking the UI
Future<Either<String, bool>> _unzipEpub(_UnzipParams params) async {
  try {
    // Decode the archive
    final archive = ZipDecoder().decodeBytes(params.bytes);

    // Create target directory
    final targetDir = Directory(params.targetPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // Extract all files
    for (final file in archive) {
      final filename = file.name;

      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File('${params.targetPath}/$filename');

        // Create parent directories if needed
        await outFile.parent.create(recursive: true);

        // Write file
        await outFile.writeAsBytes(data);
      } else {
        // Create directory
        final outDir = Directory('${params.targetPath}/$filename');
        await outDir.create(recursive: true);
      }
    }

    return right(true);
  } catch (e) {
    return left('Unzip error: $e');
  }
}
