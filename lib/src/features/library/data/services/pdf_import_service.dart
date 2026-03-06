import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/features/library/data/services/pdf_import_workers.dart';
import 'package:lumina/src/features/library/domain/book_type.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/features/library/application/pdf_password_manager.dart';
import 'package:fpdart/fpdart.dart';
import 'package:saf_stream/saf_stream.dart';
import '../shelf_book_repository.dart';
import '../book_manifest_repository.dart';
import '../../../library/data/parsers/pdf_zip_parser.dart';
/// Service for importing PDF files
/// Handles password-protected PDFs by still importing them even if metadata extraction fails
class PdfImportService {
  static const String kBooksDir = 'books';
  static const String kCoversDir = 'covers';
  static const String kCacheDir = 'import_cache';

  final ShelfBookRepository _shelfBookRepo;
  final BookManifestRepository _manifestRepo;
  final PdfPasswordManager _passwordManager;

  PdfImportService({
    required ShelfBookRepository shelfBookRepo,
    required BookManifestRepository manifestRepo,
    PdfPasswordManager? passwordManager,
  })  : _shelfBookRepo = shelfBookRepo,
        _manifestRepo = manifestRepo,
        _passwordManager = passwordManager ?? PdfPasswordManager();

  /// Import a PDF from PlatformPath (used during batch import from file picker)
  /// Converts PlatformPath to temporary File, imports, then cleans up
  Future<Either<String, ShelfBook>> importPdfFromPath(
    PlatformPath path, {
    String? password,
  }) async {
    File? tempFile;
    try {
      // Create temp cache file from PlatformPath
      tempFile = await _createTempFileFromPath(path);
      
      // Import using the standard import method
      final result = await importBook(tempFile, password: password);
      
      return result;
    } catch (e) {
      return left('PDF import from path failed: $e');
    } finally {
      // Clean up temp file
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('Failed to delete temp PDF file: $e');
        }
      }
    }
  }

  /// Create a temporary file from PlatformPath
  Future<File> _createTempFileFromPath(PlatformPath path) async {
    final cacheDir = Directory('${AppStorage.documentsPath}$kCacheDir');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final tempPath = '${cacheDir.path}/${DateTime.now().millisecondsSinceEpoch}_${path.name}';
    final tempFile = File(tempPath);

    switch (path) {
      case AndroidUriPath(:final uri):
        // For Android, read from SAF URI
        final safStream = SafStream();
        final bytes = await safStream.readFileBytes(uri);
        await tempFile.writeAsBytes(bytes);
        break;
      case IOSFilePath(:final path):
        // For iOS, copy from file system
        final sourceFile = File(path);
        await sourceFile.copy(tempPath);
        break;
    }

    return tempFile;
  }

  /// Import a PDF file following the import pipeline
  /// Returns Either:
  ///   - Right: The imported ShelfBook
  ///   - Left: error message
  Future<Either<String, ShelfBook>> importBook(
    File file, {
    String? password,
  }) async {
    try {
      // Pipeline: Hash → Check → Copy → Parse → Extract → Create → Save

      // Step 1: Calculate hash
      final fileHash = await _calculateHash(file).then(
        (result) => result.getOrElse((error) => throw Exception(error)),
      );

      // Step 2: Check if book already exists
      final bookExists = await _checkBookExistence(fileHash);
      if (bookExists.isLeft()) {
        // Book exists and is not deleted
        return left(bookExists.getLeft().toNullable()!);
      }

      // Step 3: Check if password is needed
      final needsPassword = await PdfImportWorkers.checkPasswordProtection(file.path);

      // Step 4: Copy file to app storage
      final pdfPath = await _copyToAppStorage(file, fileHash).then(
        (result) => result.getOrElse((error) => throw Exception(error)),
      );

      // Step 5: Parse PDF (with password if provided)
      PdfParseResult? parseData;
      final fileName = file.path.split('/').last;

      if (password != null && password.isNotEmpty) {
        // Try to parse with provided password
        final parseResult = PdfZipParser().parseWithPassword(
          file.path,
          password,
          fileName: fileName,
        );
        if (parseResult.isRight()) {
          parseData = parseResult.getRight().toNullable()!;
          // Save password for future access
          await _passwordManager.savePassword(fileHash, password);
        } else {
          // Password is incorrect - but still import with minimal info
          parseData = _createMinimalParseData(fileName);
        }
      } else if (needsPassword) {
        // Password required but not provided - import with minimal info
        parseData = _createMinimalParseData(fileName);
      } else {
        // No password needed - parse normally
        final parseResult = await PdfZipParser().parseFromFile(file.path, fileName: fileName);
        if (parseResult.isRight()) {
          parseData = parseResult.getRight().toNullable()!;
        } else {
          // Parse failed - default to minimal
          parseData = _createMinimalParseData(fileName);
        }
      }

      // Step 6: Extract cover (only if not password-protected or password provided)
      String? coverPath;
      if (!needsPassword || password != null) {
        coverPath = await _extractCover(
          file.path,
          fileHash,
          needsPassword ? password : null,
        );
      }

      // Step 7: Create entities
      final bookExisted = bookExists.getRight().toNullable()!;
      final entities = await _createEntities(
        fileHash,
        pdfPath,
        coverPath,
        parseData,
        needsPassword,
        bookExisted,
      );

      // Step 8: Save to database
      final savedBook = await _saveTransaction(
        entities.$1,
        entities.$2,
        pdfPath,
        coverPath,
      ).then(
        (result) => result.fold(
          (error) {
            _cleanupFiles(pdfPath, coverPath);
            throw Exception(error);
          },
          (book) => book,
        ),
      );

      return right(savedBook);
    } catch (e) {
      return left('Import failed: $e');
    }
  }

  /// Create minimal parse data when PDF cannot be parsed (e.g., password-protected)
  PdfParseResult _createMinimalParseData(String fileName) {
    final title = fileName.split('.').first;
    return PdfParseResult(
      title: title,
      author: '',
      authors: [],
      description: null,
      subjects: [],
      pdfVersion: null,
      totalChapters: 0, // Unknown until password provided
      toc: [],
      isPasswordProtected: true,
    );
  }

  /// Update a password-protected PDF after user provides password
  /// This will re-parse the PDF, extract missing metadata and cover
  Future<Either<String, ShelfBook>> updatePassword(
    String fileHash,
    String password,
  ) async {
    try {
      // Validate the password first
      final bookFilePath = await _getBookFilePath(fileHash);
      final isValid = await PdfImportWorkers.validatePassword(
        bookFilePath,
        password,
      );

      if (!isValid) {
        return left('Incorrect password');
      }

      // Save password to secure storage
      await _passwordManager.savePassword(fileHash, password);

      // Get existing book
      final book = await _shelfBookRepo.getBookByHash(fileHash);
      if (book == null) {
        return left('Book not found');
      }

      // Re-parse PDF with password
      final filePath = await _getFullBookPath(book.filePath);
      final fileName = book.title;

      final parseResult = PdfZipParser().parseWithPassword(filePath, password, fileName: fileName);

      if (parseResult.isLeft()) {
        return left(parseResult.getLeft().toNullable()!);
      }

      final parseData = parseResult.getRight().toNullable()!;

      // Extract cover if needed
      String? coverPath = book.coverPath;
      if (coverPath == null || coverPath.isEmpty) {
        coverPath = await _extractCover(filePath, fileHash, password);
      }

      // Update book with new metadata
      final updatedBook = book
        ..title = parseData.title
        ..author = parseData.author
        ..authors = parseData.authors
        ..description = parseData.description
        ..subjects = parseData.subjects
        ..totalChapters = parseData.totalChapters
        ..coverPath = coverPath
        ..pdfPassword = 'stored' // Mark as having stored password
        ..updatedAt = DateTime.now().millisecondsSinceEpoch;

      // Update manifest
      final manifest = BookManifest()
        ..fileHash = fileHash
        ..opfRootPath = book.filePath ?? ''
        ..spine = _createSpineFromPages(parseData.totalChapters)
        ..toc = parseData.toc
        ..manifest = []
        ..epubVersion = parseData.pdfVersion ?? ''
        ..lastUpdated = DateTime.now();

      // Save updates
      await _shelfBookRepo.saveBook(updatedBook);
      await _manifestRepo.deleteManifestByHash(fileHash);
      await _manifestRepo.saveManifest(manifest);

      return right(updatedBook);
    } catch (e) {
      return left('Failed to update password: $e');
    }
  }

  /// Delete an imported PDF book
  Future<Either<String, bool>> deleteBook(ShelfBook book) async {
    try {
      debugPrint('PdfImportService.deleteBook called for book: ${book.title}, hash: ${book.fileHash}');
      
      await _shelfBookRepo.softDeleteBook(book.id);
      await _manifestRepo.deleteManifestByHash(book.fileHash);

      // Delete password from secure storage if exists
      if (book.isPasswordProtected) {
        debugPrint('Book is password-protected, deleting password for hash: ${book.fileHash}');
        await _passwordManager.deletePassword(book.fileHash);
        debugPrint('Password deletion completed');
      } else {
        debugPrint('Book is not password-protected, skipping password deletion');
      }

      // Delete files
      if (book.filePath != null) {
        await _deleteFile(book.filePath!);
      }
      if (book.coverPath != null) {
        await _deleteFile(book.coverPath!);
      }

      debugPrint('PdfImportService.deleteBook completed successfully');
      return right(true);
    } catch (e) {
      debugPrint('PdfImportService.deleteBook error: $e');
      return left('Delete book failed: $e');
    }
  }

  // ========== Private Helper Methods ==========

  /// Calculate file hash (reuse from workers)
  Future<Either<String, String>> _calculateHash(File file) {
    return PdfImportWorkers.calculateFileHash(file.path);
  }

  /// Check if book already exists
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

  /// Copy PDF file to books directory
  Future<Either<String, String>> _copyToAppStorage(
    File sourceFile,
    String fileHash,
  ) async {
    try {
      final booksDir = Directory('${AppStorage.documentsPath}$kBooksDir');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final targetPath = '${booksDir.path}/$fileHash.pdf';
      final targetFile = File(targetPath);

      if (await targetFile.exists()) {
        return right(targetPath);
      }

      await sourceFile.copy(targetPath);
      return right(targetPath);
    } catch (e) {
      return left('File copy failed: $e');
    }
  }

  /// Extract cover from PDF
  Future<String?> _extractCover(
    String filePath,
    String fileHash,
    String? password,
  ) async {
    try {
      final coversDir = Directory('${AppStorage.documentsPath}$kCoversDir');
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final coverBytes = await PdfImportWorkers.extractCover(
        filePath,
        password: password,
      );

      if (coverBytes == null || coverBytes.isEmpty) {
        return null;
      }

      final outputPath = '${coversDir.path}/$fileHash.jpg';
      await File(outputPath).writeAsBytes(coverBytes);

      return '$kCoversDir/$fileHash.jpg';
    } catch (e) {
      debugPrint('Cover extraction failed: $e');
      return null;
    }
  }

  /// Create ShelfBook and BookManifest entities
  Future<(ShelfBook, BookManifest)> _createEntities(
    String fileHash,
    String pdfPath,
    String? coverPath,
    PdfParseResult parseData,
    bool isPasswordProtected,
    bool bookExisted,
  ) async {
    final relativePath = pdfPath.replaceAll(AppStorage.documentsPath, '');
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
      ..epubVersion = parseData.pdfVersion ?? ''
      ..importDate = now
      ..updatedAt = now
      ..direction = 0 // PDFs are typically LTR
      ..bookType = BookType.pdf
      ..isPasswordProtected = isPasswordProtected
      ..pdfPassword = isPasswordProtected ? null : ''; // null if protected, empty if saved

    if (bookExisted) {
      shelfBook.id = await _shelfBookRepo.getBookIdByHash(fileHash);
    }

    final manifest = BookManifest()
      ..fileHash = fileHash
      ..opfRootPath = relativePath
      ..spine = _createSpineFromPages(parseData.totalChapters)
      ..toc = parseData.toc
      ..manifest = [] // PDFs don't have manifest like EPUB
      ..epubVersion = parseData.pdfVersion ?? ''
      ..lastUpdated = DateTime.now();

    return (shelfBook, manifest);
  }

  /// Create spine items from page count
  List<SpineItem> _createSpineFromPages(int pageCount) {
    final spineItems = <SpineItem>[];
    for (int i = 0; i < pageCount && i < 10000; i++) {
      spineItems.add(SpineItem(
        index: i,
        href: i.toString(), // Page number as href
        idref: 'page_$i',
        linear: true,
      ));
    }
    return spineItems;
  }

  /// Save ShelfBook and BookManifest transactionally
  Future<Either<String, ShelfBook>> _saveTransaction(
    ShelfBook shelfBook,
    BookManifest manifest,
    String pdfPath,
    String? coverPath,
  ) async {
    final saveBookResult = await _shelfBookRepo.saveBook(shelfBook);
    if (saveBookResult.isLeft()) {
      return left(saveBookResult.getLeft().toNullable()!);
    }

    final bookId = saveBookResult.getRight().toNullable()!;

    final saveManifestResult = await _manifestRepo.saveManifest(manifest);
    if (saveManifestResult.isLeft()) {
      await _shelfBookRepo.deleteBook(bookId);
      return left(saveManifestResult.getLeft().toNullable()!);
    }

    shelfBook.id = bookId;
    return right(shelfBook);
  }

  /// Delete a file
  Future<void> _deleteFile(String path) async {
    try {
      final absolutePath = '${AppStorage.documentsPath}$path';
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete file $path: $e');
    }
  }

  /// Clean up files on error
  void _cleanupFiles(String pdfPath, String? coverPath) {
    _deleteFile(pdfPath);
    if (coverPath != null) {
      _deleteFile(coverPath);
    }
  }

  /// Get full book file path from relative path
  Future<String> _getFullBookPath(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      throw Exception('Book file path is null');
    }
    return '${AppStorage.documentsPath}$relativePath';
  }

  /// Get book file path from file hash
  Future<String> _getBookFilePath(String fileHash) async {
    final book = await _shelfBookRepo.getBookByHash(fileHash);
    if (book == null || book.filePath == null) {
      throw Exception('Book not found or file path is null');
    }
    return await _getFullBookPath(book.filePath!);
  }
}
