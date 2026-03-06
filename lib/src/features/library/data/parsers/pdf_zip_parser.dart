import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:flutter/foundation.dart';
import '../../domain/book_manifest.dart';
import 'package:fpdart/fpdart.dart';

/// Parser for PDF files that extracts metadata and page information.
/// Uses syncfusion_flutter_pdf for parsing.
class PdfZipParser {
  /// Parse PDF from file path
  Future<Either<String, PdfParseResult>> parseFromFile(
    String filePath, {
    String? fileName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return left('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      return _parseFromBytes(bytes, fileName, filePath);
    } catch (e) {
      return left('Failed to read file: $e');
    }
  }

  /// Parse PDF from bytes
  static Either<String, PdfParseResult> _parseFromBytes(
    List<int> bytes,
    String? fileName,
    String filePath,
  ) {
    try {
      // Try to load the PDF document
      final pdfDocument = sync_pdf.PdfDocument(inputBytes: bytes);

      // Extract metadata
      final info = pdfDocument.documentInformation;
      final title = info.title.trim();
      final author = info.author.trim();
      final authors = author.isNotEmpty ? [author] : <String>[];
      final subject = info.subject.trim();
      final subjects = subject.isNotEmpty ? [subject] : <String>[];
      final description = info.keywords.trim();
      final pageCount = pdfDocument.pages.count;

      // Try to extract bookmarks/outlines from PDF
      final toc = _extractBookmarksAsToc(pdfDocument, pageCount);

      pdfDocument.dispose();

      return right(PdfParseResult(
        title: title,
        author: author,
        authors: authors,
        description: description,
        subjects: subjects,
        pdfVersion: 'PDF',
        totalChapters: pageCount, // Reuse field for page count
        toc: toc,
        isPasswordProtected: false,
      ));
    } catch (e) {
      // If parsing fails, assume it might be password-protected or corrupted
      final fileNameFinal = fileName ?? 'Protected Document';
      // Return minimal info - treat as potentially password-protected
      return right(PdfParseResult(
        title: fileNameFinal.split('/').last.split('.').first,
        author: '',
        authors: [],
        description: null,
        subjects: [],
        pdfVersion: null,
        totalChapters: 0,
        toc: [],
        isPasswordProtected: true, // Assume password-protected if parsing fails
      ));
    }
  }

  /// Parse PDF with provided password
  Either<String, PdfParseResult> parseWithPassword(
    String filePath,
    String password, {
    String? fileName,
  }) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return left('File not found: $filePath');
      }

      final bytes = file.readAsBytesSync();

      try {
        final pdfDocument = sync_pdf.PdfDocument(
          inputBytes: bytes,
          password: password,
        );

        // Extract metadata
        final info = pdfDocument.documentInformation;
        final title = info.title.trim();
        final author = info.author.trim();
        final authors = author.isNotEmpty ? [author] : <String>[];
        final subject = info.subject.trim();
        final subjects = subject.isNotEmpty ? [subject] : <String>[];
        final description = info.keywords.trim();
        final pageCount = pdfDocument.pages.count;

        // Try to extract bookmarks/outlines from PDF
        final toc = _extractBookmarksAsToc(pdfDocument, pageCount);

        pdfDocument.dispose();

        return right(PdfParseResult(
          title: title,
          author: author,
          authors: authors,
          description: description,
          subjects: subjects,
          pdfVersion: 'PDF',
          totalChapters: pageCount,
          toc: toc,
          isPasswordProtected: false,
        ));
      } catch (e) {
        return left('Incorrect password or corrupted PDF');
      }
    } catch (e) {
      return left('PDF parsing error: $e');
    }
  }

  /// Check if PDF requires password
  static Future<bool> checkPasswordProtection(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();

      try {
        final pdfDocument = sync_pdf.PdfDocument(inputBytes: bytes);
        pdfDocument.dispose();

        // If we can read it, it's not password protected
        return false;
      } catch (e) {
        // If we can't read it, assume password protection
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Extract cover image from first page of PDF
  /// 
  /// Note: PDF cover extraction requires additional packages that have build issues.
  /// Returning null for now - PDFs will display without covers.
  /// Future enhancement: Implement cover extraction using a stable rendering solution.
  Future<Uint8List?> extractCoverImage(
    String filePath, {
    String? password,
    int maxWidth = 400,
    int maxHeight = 600,
  }) async {
    // PDF cover extraction not currently implemented
    debugPrint('PDF cover extraction skipped - no cover will be shown');
    return null;
  }

  /// Extract bookmarks from PDF document as TOC
  /// Falls back to page-based TOC if no bookmarks exist
  static List<TocItem> _extractBookmarksAsToc(
    sync_pdf.PdfDocument pdfDocument,
    int pageCount,
  ) {
    try {
      final bookmarks = pdfDocument.bookmarks;
      
      // If no bookmarks, fall back to page-based TOC
      if (bookmarks.count == 0) {
        debugPrint('PDF has no bookmarks, using page-based TOC');
        return _generatePageBasedToc(pageCount);
      }

      // Extract bookmarks into hierarchical TocItem structure
      final result = <TocItem>[];
      int idCounter = 0;

      for (int i = 0; i < bookmarks.count; i++) {
        final bookmark = bookmarks[i];
        final tocItem = _convertBookmarkToTocItem(
          bookmark,
          pdfDocument: pdfDocument,
          depth: 0,
          parentId: -1,
          idCounter: idCounter,
        );
        
        if (tocItem != null) {
          result.add(tocItem);
          idCounter = _countTocItems(result);
        }
      }

      // If extraction failed or resulted in empty list, fall back
      if (result.isEmpty) {
        debugPrint('Bookmark extraction resulted in empty TOC, using page-based fallback');
        return _generatePageBasedToc(pageCount);
      }

      debugPrint('Extracted ${result.length} top-level bookmarks from PDF');
      return result;
    } catch (e) {
      debugPrint('Error extracting PDF bookmarks: $e, using page-based TOC');
      return _generatePageBasedToc(pageCount);
    }
  }

  /// Convert a single PDF bookmark to TocItem with children
  static TocItem? _convertBookmarkToTocItem(
    sync_pdf.PdfBookmark bookmark,
    {
    required sync_pdf.PdfDocument pdfDocument,
    required int depth,
    required int parentId,
    required int idCounter,
  }) {
    try {
      // Extract bookmark title
      final label = bookmark.title;
      if (label.isEmpty) {
        return null;
      }

      // Extract destination page number
      int pageNumber = 0;
      if (bookmark.destination != null) {
        // Get the page from the destination
        final destPage = bookmark.destination!.page;
        if (destPage != null) {
          // Find the index of this page in the document's pages collection
          for (int i = 0; i < pdfDocument.pages.count; i++) {
            if (pdfDocument.pages[i] == destPage) {
              pageNumber = i;
              break;
            }
          }
        }
      } else if (bookmark.namedDestination != null) {
        // Named destinations are harder to resolve, skip for now
        debugPrint('Bookmark uses named destination: ${bookmark.namedDestination}');
        pageNumber = 0;
      }

      // Create TocItem
      final href = Href()
        ..path = '$pageNumber'
        ..anchor = 'top';

      final tocItem = TocItem()
        ..id = idCounter
        ..label = label
        ..href = href
        ..depth = depth
        ..parentId = parentId
        ..spineIndex = pageNumber
        ..children = [];

      // Process child bookmarks recursively
      int childIdCounter = idCounter + 1;
      for (int i = 0; i < bookmark.count; i++) {
        final childBookmark = bookmark[i];
        final childItem = _convertBookmarkToTocItem(
          childBookmark,
          pdfDocument: pdfDocument,
          depth: depth + 1,
          parentId: tocItem.id,
          idCounter: childIdCounter,
        );
        
        if (childItem != null) {
          tocItem.children.add(childItem);
          childIdCounter = childIdCounter + 1 + _countTocItems([childItem]);
        }
      }

      return tocItem;
    } catch (e) {
      debugPrint('Error converting bookmark to TocItem: $e');
      return null;
    }
  }

  /// Count total number of TocItems in a list (including nested children)
  static int _countTocItems(List<TocItem> items) {
    int count = 0;
    for (final item in items) {
      count++; // Count this item
      count += _countTocItems(item.children); // Count children recursively
    }
    return count;
  }

  /// Generate fallback page-based TOC
  static List<TocItem> _generatePageBasedToc(int pageCount) {
    final result = <TocItem>[];
    for (int i = 0; i < pageCount && i < 1000; i++) {
      final pageNum = i + 1;
      final href = Href()
        ..path = '$i'
        ..anchor = 'top';
        
      final tocItem = TocItem()
        ..id = i
        ..label = 'Page $pageNum'
        ..href = href
        ..depth = 0
        ..parentId = -1
        ..spineIndex = i
        ..children = [];

      result.add(tocItem);
    }
    return result;
  }
}

/// Helper wrapper to expose static parser methods as instance methods for service use
class PdfParserHelper {
  /// Parse PDF from bytes (static wrapper)
  static Either<String, PdfParseResult> parseFromBytes(
    List<int> bytes, {
    String? fileName,
    String? filePath,
  }) {
    return PdfZipParser._parseFromBytes(bytes, fileName ?? '', filePath ?? '');
  }

  /// Check password protection (static wrapper)
  static Future<bool> checkPasswordProtection(String filePath) async {
    return await PdfZipParser.checkPasswordProtection(filePath);
  }
}


/// Result of parsing a PDF file
class PdfParseResult {
  final String title;
  final String author;
  final List<String> authors;
  final String? description;
  final List<String> subjects;
  final String? pdfVersion;
  final int totalChapters;
  final List<TocItem> toc;
  final bool isPasswordProtected;

  PdfParseResult({
    required this.title,
    required this.author,
    required this.authors,
    this.description,
    required this.subjects,
    this.pdfVersion,
    required this.totalChapters,
    required this.toc,
    required this.isPasswordProtected,
  });
}
