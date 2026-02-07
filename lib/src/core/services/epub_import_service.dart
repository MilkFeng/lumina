import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fpdart/fpdart.dart';
import '../../features/library/domain/shelf_book.dart';
import '../../features/library/domain/book_manifest.dart';
import '../../features/library/data/shelf_book_repository.dart';
import '../../features/library/data/book_manifest_repository.dart';
import 'epub_zip_parser.dart';

/// Service for importing EPUB files using "stream-from-zip" strategy
/// - Copies EPUB to AppDocDir/books/{fileHash}.epub (keeps compressed)
/// - Extracts cover to AppDocDir/covers/{fileHash}.jpg
/// - Parses metadata in-memory (no full unzip)
/// - Saves to Isar: ShelfBook + BookManifest
class EpubImportService {
  final ShelfBookRepository _shelfBookRepo;
  final BookManifestRepository _manifestRepo;

  EpubImportService({
    ShelfBookRepository? shelfBookRepo,
    BookManifestRepository? manifestRepo,
    EpubZipParser? zipParser,
  }) : _shelfBookRepo = shelfBookRepo ?? ShelfBookRepository(),
       _manifestRepo = manifestRepo ?? BookManifestRepository();

  /// Import an EPUB file
  /// Returns Either:
  ///   - Right: The imported ShelfBook
  ///   - Left: error message
  Future<Either<String, ShelfBook>> importBook(File file) async {
    try {
      // Step 1: Calculate SHA-256 hash
      final hashResult = await _calculateFileHash(file);
      if (hashResult.isLeft()) {
        return left(hashResult.getLeft().toNullable()!);
      }
      final fileHash = hashResult.getRight().toNullable()!;

      // Step 2: Check if book already exists
      final existsAndNotDeleted = await _shelfBookRepo.bookExistsAndNotDeleted(
        fileHash,
      );
      if (existsAndNotDeleted) {
        return left('Book already exists');
      }

      final exists = await _shelfBookRepo.bookExists(fileHash);

      // Step 3: Copy EPUB to books directory
      final copyResult = await _copyEpubFile(file, fileHash);
      if (copyResult.isLeft()) {
        return left(copyResult.getLeft().toNullable()!);
      }
      final epubPath = copyResult.getRight().toNullable()!;

      // Step 4: Parse EPUB in-memory (heavy operation, use isolate)
      final parseResult = await compute(
        _parseEpubInIsolate,
        _ParseParams(
          filePath: epubPath,
          fileHash: fileHash,
          originalFileName: file.path.split('/').last,
        ),
      );

      if (parseResult.isLeft()) {
        // Clean up copied file on parse failure
        await _deleteFile(epubPath);
        return left(parseResult.getLeft().toNullable()!);
      }

      final parseData = parseResult.getRight().toNullable()!;

      // Step 5: Extract and save cover image
      final coverPath = await _extractCover(
        epubPath,
        fileHash,
        parseData.coverHref,
        parseData.opfRootPath,
      );

      final appDir = await getApplicationDocumentsDirectory();
      final relativePath = epubPath.replaceAll(appDir.path, '');

      // Step 6: Create ShelfBook entity
      final now = DateTime.now().millisecondsSinceEpoch;
      final shelfBook = ShelfBook()
        ..fileHash = fileHash
        ..filePath = relativePath
        ..coverPath = coverPath
        ..title = parseData.title
        ..author = parseData.author
        ..authors = parseData.authors
        ..description = parseData.description
        ..subjects = parseData.subjects
        ..totalChapters = parseData.totalChapters
        ..epubVersion = parseData.epubVersion
        ..importDate = now
        ..updatedAt = now;

      if (exists) {
        shelfBook.id = await _shelfBookRepo.getBookIdByHash(fileHash);
      }

      // Step 7: Create BookManifest entity
      final manifest = BookManifest()
        ..fileHash = fileHash
        ..opfRootPath = parseData.opfRootPath
        ..spine = parseData.spine
        ..toc = parseData.toc
        ..manifest = parseData.manifestItems
        ..epubVersion = parseData.epubVersion
        ..lastUpdated = DateTime.now();

      // Step 8: Save to database (transactional)
      final saveBookResult = await _shelfBookRepo.saveBook(shelfBook);
      if (saveBookResult.isLeft()) {
        // Clean up files on save failure
        await _deleteFile(epubPath);
        if (coverPath != null) await _deleteFile(coverPath);
        return left(saveBookResult.getLeft().toNullable()!);
      }

      final saveManifestResult = await _manifestRepo.saveManifest(manifest);
      if (saveManifestResult.isLeft()) {
        // Rollback: delete ShelfBook and files
        final bookId = saveBookResult.getRight().toNullable()!;
        await _shelfBookRepo.deleteBook(bookId);
        await _deleteFile(epubPath);
        if (coverPath != null) await _deleteFile(coverPath);
        return left(saveManifestResult.getLeft().toNullable()!);
      }

      // Update book ID from database
      shelfBook.id = saveBookResult.getRight().toNullable()!;

      return right(shelfBook);
    } catch (e) {
      return left('Import failed: $e');
    }
  }

  Future<Either<String, (BookManifest, String?)>> updateBookManifestAndCover(
    String epubAbsPath,
    int bookId,
    String? fileHash,
  ) async {
    File epubFile = File(epubAbsPath);
    if (!await epubFile.exists()) {
      return left('EPUB file does not exist at $epubAbsPath');
    }

    if (fileHash == null) {
      final hashResult = await _calculateFileHash(epubFile);
      if (hashResult.isLeft()) {
        return left(hashResult.getLeft().toNullable()!);
      }
      fileHash = hashResult.getRight().toNullable()!;
    }

    final parseResult = await compute(
      _parseEpubInIsolate,
      _ParseParams(filePath: epubAbsPath, fileHash: fileHash),
    );

    if (parseResult.isLeft()) {
      // Clean up copied file on parse failure
      await _deleteFile(epubAbsPath);
      return left(parseResult.getLeft().toNullable()!);
    }

    final parseData = parseResult.getRight().toNullable()!;

    // Extract and save cover image
    final coverPath = await _extractCover(
      epubAbsPath,
      fileHash,
      parseData.coverHref,
      parseData.opfRootPath,
    );

    final manifest = BookManifest()
      ..fileHash = fileHash
      ..opfRootPath = parseData.opfRootPath
      ..spine = parseData.spine
      ..toc = parseData.toc
      ..manifest = parseData.manifestItems
      ..epubVersion = parseData.epubVersion
      ..lastUpdated = DateTime.now();

    final saveManifestResult = await _manifestRepo.saveManifest(manifest);
    if (saveManifestResult.isLeft()) {
      // Rollback: delete ShelfBook and files
      await _shelfBookRepo.deleteBook(bookId);
      await _deleteFile(epubAbsPath);
      if (coverPath != null) await _deleteFile(coverPath);
      return left(saveManifestResult.getLeft().toNullable()!);
    }

    return right((manifest, coverPath));
  }

  /// Calculate SHA-256 hash of a file
  Future<Either<String, String>> _calculateFileHash(File file) async {
    try {
      final stream = file.openRead();
      final digest = await sha256.bind(stream).first;

      BigInt number = BigInt.parse(digest.toString(), radix: 16);
      final hash = _toBase62(number);

      return right(hash);
    } catch (e) {
      return left('Hash calculation failed: $e');
    }
  }

  String _toBase62(BigInt num) {
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

  /// Copy EPUB file to books directory
  /// Returns absolute path to the copied file
  Future<Either<String, String>> _copyEpubFile(
    File sourceFile,
    String fileHash,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final targetPath = '${booksDir.path}/$fileHash.epub';
      final targetFile = File(targetPath);

      // Check if file already exists (edge case)
      if (await targetFile.exists()) {
        return right(targetPath);
      }

      await sourceFile.copy(targetPath);
      return right(targetPath);
    } catch (e) {
      return left('File copy failed: $e');
    }
  }

  /// Extract cover image from EPUB and save to covers directory
  /// Returns absolute path to the cover image, or null if no cover found
  Future<String?> _extractCover(
    String epubPath,
    String fileHash,
    String? coverHref,
    String opfRootPath,
  ) async {
    if (coverHref == null || coverHref.isEmpty) {
      return null;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${appDir.path}/covers');
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      // Read EPUB as archive
      final inputStream = InputFileStream(epubPath);
      final archive = ZipDecoder().decodeStream(inputStream);

      // Resolve cover path (relative to OPF root)
      final opfDir = opfRootPath.contains('/')
          ? opfRootPath.substring(0, opfRootPath.lastIndexOf('/'))
          : '';
      final coverPath = opfDir.isEmpty ? coverHref : '$opfDir/$coverHref';

      // Find cover file in archive
      final coverFile = archive.findFile(coverPath);
      if (coverFile == null) {
        return null;
      }

      // Determine file extension from MIME type or filename
      final extension = _getImageExtension(coverPath);
      final outputPath = '${coversDir.path}/$fileHash$extension';

      // Write cover to disk
      final coverData = coverFile.content as List<int>;
      await File(outputPath).writeAsBytes(coverData);

      return 'covers/$fileHash$extension';
    } catch (e) {
      // Cover extraction is non-critical, log and continue
      debugPrint('Cover extraction failed: $e');
      return null;
    }
  }

  /// Get image extension from filename
  String _getImageExtension(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return '.jpg';
    } else if (lower.endsWith('.png')) {
      return '.png';
    } else if (lower.endsWith('.gif')) {
      return '.gif';
    } else if (lower.endsWith('.webp')) {
      return '.webp';
    }
    return '.jpg'; // Default
  }

  /// Delete a file (helper for cleanup)
  Future<void> _deleteFile(String path) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final absolutePath = '${appDir.path}/$path';
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete file $path: $e');
    }
  }

  /// Delete imported book (ShelfBook + BookManifest + files)
  Future<Either<String, bool>> deleteBook(ShelfBook book) async {
    try {
      // Delete from database
      await _shelfBookRepo.softDeleteBook(book.id);
      await _manifestRepo.deleteManifestByHash(book.fileHash);

      // Delete files
      if (book.filePath != null) {
        await _deleteFile(book.filePath!);
      }
      if (book.coverPath != null) {
        await _deleteFile(book.coverPath!);
      }

      return right(true);
    } catch (e) {
      return left('Delete book failed: $e');
    }
  }
}

/// Parameters for isolate parsing
class _ParseParams {
  final String filePath;
  final String fileHash;
  final String? originalFileName;

  _ParseParams({
    required this.filePath,
    required this.fileHash,
    this.originalFileName,
  });
}

/// Result of in-memory EPUB parsing
class _ParseResult {
  final String title;
  final String author;
  final List<String> authors;
  final String? description;
  final List<String> subjects;
  final String? coverHref;
  final String opfRootPath;
  final String epubVersion;
  final int totalChapters;
  final List<String> spine;
  final List<TocItem> toc;
  final List<ManifestItem> manifestItems;

  _ParseResult({
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
  });
}

/// Isolate function to parse EPUB in-memory
Future<Either<String, _ParseResult>> _parseEpubInIsolate(
  _ParseParams params,
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

    final result = _ParseResult(
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
    );

    return right(result);
  } catch (e) {
    return left('Parse error: $e');
  }
}
