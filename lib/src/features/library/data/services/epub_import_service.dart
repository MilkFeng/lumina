import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/library/data/services/epub_import_workers.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/shelf_book.dart';
import '../../domain/book_manifest.dart';
import '../shelf_book_repository.dart';
import '../book_manifest_repository.dart';

/// Service for importing EPUB files using "stream-from-zip" strategy
/// - Copies EPUB to AppDocDir/books/{fileHash}.epub (keeps compressed)
/// - Extracts cover to AppDocDir/covers/{fileHash}.jpg
/// - Parses metadata in-memory (no full unzip)
/// - Saves to Isar: ShelfBook + BookManifest
class EpubImportService {
  static const String kBooksDir = 'books';
  static const String kCoversDir = 'covers';

  final ShelfBookRepository _shelfBookRepo;
  final BookManifestRepository _manifestRepo;

  EpubImportService({
    required ShelfBookRepository shelfBookRepo,
    required BookManifestRepository manifestRepo,
  }) : _shelfBookRepo = shelfBookRepo,
       _manifestRepo = manifestRepo;

  /// Import an EPUB file following a clean pipeline pattern
  /// Returns Either:
  ///   - Right: The imported ShelfBook
  ///   - Left: error message
  Future<Either<String, ShelfBook>> importBook(File file) async {
    try {
      // Pipeline: Hash → Check → Copy → Parse → Extract → Create → Save
      final fileHash = await _calculateHash(
        file,
      ).then((result) => result.getOrElse((error) => throw Exception(error)));

      final bookExists = await _checkBookExistence(fileHash);
      if (bookExists.isLeft()) {
        return left(bookExists.getLeft().toNullable()!);
      }

      final epubPath = await _copyToAppStorage(
        file,
        fileHash,
      ).then((result) => result.getOrElse((error) => throw Exception(error)));

      final parseData =
          await _parseAndExtract(
            epubPath,
            fileHash,
            file.path.split('/').last,
          ).then(
            (result) => result.fold((error) {
              _deleteFile(epubPath);
              throw Exception(error);
            }, (data) => data),
          );

      final coverPath = await _extractCover(
        epubPath,
        fileHash,
        parseData.coverHref,
        parseData.opfRootPath,
      );

      final entities = await _createEntities(
        fileHash,
        epubPath,
        coverPath,
        parseData,
        bookExists.getRight().toNullable()!,
      );

      final savedBook =
          await _saveTransaction(
            entities.$1,
            entities.$2,
            epubPath,
            coverPath,
          ).then(
            (result) => result.fold((error) {
              _deleteFile(epubPath);
              if (coverPath != null) _deleteFile(coverPath);
              throw Exception(error);
            }, (book) => book),
          );

      return right(savedBook);
    } catch (e) {
      return left('Import failed: $e');
    }
  }

  /// Calculate file hash using isolate
  Future<Either<String, String>> _calculateHash(File file) async {
    return compute(ImportWorkers.calculateFileHash, file.path);
  }

  /// Check if book already exists
  /// Returns Either:
  ///   - Left: error (book already exists)
  ///   - Right: true if book exists but deleted, false if never existed
  Future<Either<String, bool>> _checkBookExistence(String fileHash) async {
    final existsAndNotDeleted = await _shelfBookRepo.bookExistsAndNotDeleted(
      fileHash,
    );
    if (existsAndNotDeleted) {
      return left('Book already exists');
    }

    final exists = await _shelfBookRepo.bookExists(fileHash);
    return right(exists);
  }

  /// Parse EPUB and extract metadata using isolate
  Future<Either<String, ParseResult>> _parseAndExtract(
    String epubPath,
    String fileHash,
    String originalFileName,
  ) async {
    return compute(
      ImportWorkers.parseEpub,
      ParseParams(
        filePath: epubPath,
        fileHash: fileHash,
        originalFileName: originalFileName,
      ),
    );
  }

  /// Create ShelfBook and BookManifest entities
  /// Returns tuple (ShelfBook, BookManifest)
  Future<(ShelfBook, BookManifest)> _createEntities(
    String fileHash,
    String epubPath,
    String? coverPath,
    ParseResult parseData,
    bool bookExisted,
  ) async {
    final relativePath = epubPath.replaceAll(AppStorage.documentsPath, '');
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

    if (bookExisted) {
      shelfBook.id = await _shelfBookRepo.getBookIdByHash(fileHash);
    }

    final manifest = BookManifest()
      ..fileHash = fileHash
      ..opfRootPath = parseData.opfRootPath
      ..spine = parseData.spine
      ..toc = parseData.toc
      ..manifest = parseData.manifestItems
      ..epubVersion = parseData.epubVersion
      ..lastUpdated = DateTime.now();

    return (shelfBook, manifest);
  }

  /// Save ShelfBook and BookManifest in a transactional manner
  /// Rollback on failure
  Future<Either<String, ShelfBook>> _saveTransaction(
    ShelfBook shelfBook,
    BookManifest manifest,
    String epubPath,
    String? coverPath,
  ) async {
    final saveBookResult = await _shelfBookRepo.saveBook(shelfBook);
    if (saveBookResult.isLeft()) {
      return left(saveBookResult.getLeft().toNullable()!);
    }

    final bookId = saveBookResult.getRight().toNullable()!;

    final saveManifestResult = await _manifestRepo.saveManifest(manifest);
    if (saveManifestResult.isLeft()) {
      // Rollback: delete ShelfBook
      await _shelfBookRepo.deleteBook(bookId);
      return left(saveManifestResult.getLeft().toNullable()!);
    }

    // Update book with ID from database
    shelfBook.id = bookId;
    return right(shelfBook);
  }

  /// Copy EPUB file to books directory
  /// Returns absolute path to the copied file
  Future<Either<String, String>> _copyToAppStorage(
    File sourceFile,
    String fileHash,
  ) async {
    try {
      final booksDir = Directory('${AppStorage.documentsPath}/$kBooksDir');
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
  /// Returns relative path to the cover image, or null if no cover found
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
      final coversDir = Directory('${AppStorage.documentsPath}/$kCoversDir');
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
      var extension = _getImageExtension(coverPath);

      // Compress image using worker
      final rawCoverData = coverFile.content;
      var coverData = await compute(ImportWorkers.compressImage, rawCoverData);
      if (coverData != null) {
        extension = '.jpg';
      } else {
        coverData = rawCoverData;
      }

      final outputPath = '${coversDir.path}/$fileHash$extension';
      await File(outputPath).writeAsBytes(coverData as List<int>);

      return '$kCoversDir/$fileHash$extension';
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
      final absolutePath = '${AppStorage.documentsPath}/$path';
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
