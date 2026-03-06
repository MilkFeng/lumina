import 'dart:io';
import '../../features/library/domain/book_type.dart';

/// Detects book file type (EPUB or PDF) based on file extension
class FileTypeDetector {
  // Supported file extensions
  static const _epubExtensions = ['.epub'];
  static const _pdfExtensions = ['.pdf'];

  // Magic bytes for file type identification (check header)
  // EPUB is ZIP-based, starts with PK (0x504B)
  static const _zipMagicBytes = [0x50, 0x4B];
  // PDF starts with %PDF (0x25 0x50 0x44 0x46)
  static const _pdfMagicBytes = [0x25, 0x50, 0x44, 0x46];

  /// Detect book file type from file path and optionally magic bytes
  /// Returns BookType.epub or BookType.pdf
  /// Defaults to epub if unable to determine
  static BookType detectFileType(File file) {
    // First, check file extension
    final extension = getFileExtension(file.path).toLowerCase();

    if (_pdfExtensions.contains(extension)) {
      return BookType.pdf;
    }
    if (_epubExtensions.contains(extension)) {
      return BookType.epub;
    }

    // If extension is not recognized, try magic bytes
    final magicBytes = _readMagicBytes(file);
    if (magicBytes != null) {
      if (_isPdfMagicBytes(magicBytes)) {
        return BookType.pdf;
      }
      if (_isZipMagicBytes(magicBytes)) {
        return BookType.epub;
      }
    }

    // Default fallback
    return BookType.epub;
  }

  /// Detect book type from file path only (without reading file)
  // Use this when file is not yet accessible (e.g., pending download)
  static BookType detectTypeFromPath(String filePath) {
    final extension = getFileExtension(filePath).toLowerCase();

    if (_pdfExtensions.contains(extension)) {
      return BookType.pdf;
    }
    if (_epubExtensions.contains(extension)) {
      return BookType.epub;
    }

    return BookType.epub; // Default
  }

  /// Get file extension from path (including the dot)
  static String getFileExtension(String path) {
    final lastDotIndex = path.lastIndexOf('.');
    if (lastDotIndex == -1) {
      return '';
    }
    // Handle potential query strings or fragments in URLs
    final queryIndex = path.indexOf('?', lastDotIndex);
    if (queryIndex != -1) {
      return path.substring(lastDotIndex, queryIndex);
    }
    final fragmentIndex = path.indexOf('#', lastDotIndex);
    if (fragmentIndex != -1) {
      return path.substring(lastDotIndex, fragmentIndex);
    }
    return path.substring(lastDotIndex);
  }

  /// Check if file is a supported book file (EPUB or PDF)
  static bool isSupportedBookFile(File file) {
    final extension = getFileExtension(file.path).toLowerCase();
    return _epubExtensions.contains(extension) ||
        _pdfExtensions.contains(extension);
  }

  /// Check if file is a PDF based on extension
  static bool isPdfFile(File file) {
    return detectFileType(file) == BookType.pdf;
  }

  /// Check if file is a PDF based on path
  static bool isPdfPath(String path) {
    return detectTypeFromPath(path) == BookType.pdf;
  }

  /// Check if file is an EPUB based on extension
  static bool isEpubFile(File file) {
    return detectFileType(file) == BookType.epub;
  }

  /// Check if file is an EPUB based on path
  static bool isEpubPath(String path) {
    return detectTypeFromPath(path) == BookType.epub;
  }

  /// Read first 4 bytes of file to check magic bytes
  static List<int>? _readMagicBytes(File file) {
    try {
      final bytes = file.readAsBytesSync();
      if (bytes.length < 4) {
        return bytes.sublist(0, bytes.length);
      }
      return bytes.sublist(0, 4);
    } catch (e) {
      // File may not exist or be readable
      return null;
    }
  }

  /// Check if bytes match PDF magic bytes
  static bool _isPdfMagicBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == _pdfMagicBytes[0] &&
        bytes[1] == _pdfMagicBytes[1] &&
        bytes[2] == _pdfMagicBytes[2] &&
        bytes[3] == _pdfMagicBytes[3];
  }

  /// Check if bytes match ZIP magic bytes (EPUB is ZIP-based)
  static bool _isZipMagicBytes(List<int> bytes) {
    if (bytes.length < 2) return false;
    return bytes[0] == _zipMagicBytes[0] &&
        bytes[1] == _zipMagicBytes[1];
  }
}