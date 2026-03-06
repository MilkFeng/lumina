import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/src/core/file_handling/file_type_detector.dart';
import 'package:lumina/src/features/library/domain/book_type.dart';

void main() {
  group('FileTypeDetector', () {
    group('detectFileType', () {
      test('should detect EPUB by .epub extension', () {
        // Arrange
        final file = File('/path/to/book.epub');

        // Act
        final result = FileTypeDetector.detectFileType(file);

        // Assert
        expect(result, BookType.epub);
      });

      test('should detect EPUB by .EPUB extension (case insensitive)', () {
        // Arrange
        final file = File('/path/to/book.EPUB');

        // Act
        final result = FileTypeDetector.detectFileType(file);

        // Assert
        expect(result, BookType.epub);
      });

      test('should detect PDF by .pdf extension', () {
        // Arrange
        final file = File('/path/to/document.pdf');

        // Act
        final result = FileTypeDetector.detectFileType(file);

        // Assert
        expect(result, BookType.pdf);
      });

      test('should detect PDF by .PDF extension (case insensitive)', () {
        // Arrange
        final file = File('/path/to/document.PDF');

        // Act
        final result = FileTypeDetector.detectFileType(file);

        // Assert
        expect(result, BookType.pdf);
      });

      test('should default to EPUB for unknown extensions', () {
        // Arrange
        final file = File('/path/to/document.txt');

        // Act
        final result = FileTypeDetector.detectFileType(file);

        // Assert
        expect(result, BookType.epub);
      });

      test('should detect PDF by magic bytes from file', () {
        // Arrange - Create a file with PDF magic bytes
        final tempFile = File('/tmp/test_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
        final pdfMagicBytes = [0x25, 0x50, 0x44, 0x46]; // %PDF
        tempFile.writeAsBytesSync(pdfMagicBytes);

        // Act
        final result = FileTypeDetector.detectFileType(tempFile);

        // Assert
        expect(result, BookType.pdf);

        // Cleanup
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });

      test('should default to epub for files without valid magic', () {
        // Arrange
        final tempFile = File('/tmp/test_unknown_${DateTime.now().millisecondsSinceEpoch}.txt');
        tempFile.writeAsBytesSync([0x00, 0x01, 0x02]);

        // Act
        final result = FileTypeDetector.detectFileType(tempFile);

        // Assert
        expect(result, BookType.epub);

        // Cleanup
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
    });

    group('isSupportedBookFile', () {
      test('should return true for EPUB files', () {
        // Arrange
        final file = File('/path/to/book.epub');

        // Act
        final result = FileTypeDetector.isSupportedBookFile(file);

        // Assert
        expect(result, true);
      });

      test('should return true for PDF files', () {
        // Arrange
        final file = File('/path/to/document.pdf');

        // Act
        final result = FileTypeDetector.isSupportedBookFile(file);

        // Assert
        expect(result, true);
      });

      test('should return false for unsupported files', () {
        // Arrange
        final file = File('/path/to/image.png');

        // Act
        final result = FileTypeDetector.isSupportedBookFile(file);

        // Assert
        expect(result, false);
      });
    });

    group('isPdfFile', () {
      test('should return true for PDF files', () {
        // Arrange
        final file = File('/path/to/doc.pdf');

        // Act
        final result = FileTypeDetector.isPdfFile(file);

        // Assert
        expect(result, true);
      });

      test('should return false for EPUB files', () {
        // Arrange
        final file = File('/path/to/book.epub');

        // Act
        final result = FileTypeDetector.isPdfFile(file);

        // Assert
        expect(result, false);
      });
    });

    group('isEpubFile', () {
      test('should return true for EPUB files', () {
        // Arrange
        final file = File('/path/to/book.epub');

        // Act
        final result = FileTypeDetector.isEpubFile(file);

        // Assert
        expect(result, true);
      });

      test('should return false for PDF files', () {
        // Arrange
        final file = File('/path/to/doc.pdf');

        // Act
        final result = FileTypeDetector.isEpubFile(file);

        // Assert
        expect(result, false);
      });
    });

    group('getFileExtension', () {
      test('should extract .epub extension', () {
        // Arrange
        final path = '/path/to/mybook.epub';

        // Act
        final result = FileTypeDetector.getFileExtension(path);

        // Assert
        expect(result, '.epub');
      });

      test('should extract .pdf extension', () {
        // Arrange
        final path = '/path/to/document.pdf';

        // Act
        final result = FileTypeDetector.getFileExtension(path);

        // Assert
        expect(result, '.pdf');
      });

      test('should handle paths with query strings', () {
        // Arrange
        final path = '/path/to/document.pdf?param=value';

        // Act
        final result = FileTypeDetector.getFileExtension(path);

        // Assert
        expect(result, '.pdf');
      });

      test('should return empty string for paths without extension', () {
        // Arrange
        final path = '/path/to/document';

        // Act
        final result = FileTypeDetector.getFileExtension(path);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('detectTypeFromPath', () {
      test('should detect PDF from path string', () {
        // Arrange
        final path = '/path/to/document.pdf';

        // Act
        final result = FileTypeDetector.detectTypeFromPath(path);

        // Assert
        expect(result, BookType.pdf);
      });

      test('should detect EPUB from path string', () {
        // Arrange
        final path = '/path/to/book.epub';

        // Act
        final result = FileTypeDetector.detectTypeFromPath(path);

        // Assert
        expect(result, BookType.epub);
      });

      test('should default to EPUB for unknown extensions', () {
        // Arrange
        final path = '/path/to/file.unknown';

        // Act
        final result = FileTypeDetector.detectTypeFromPath(path);

        // Assert
        expect(result, BookType.epub);
      });
    });
  });

  group('BookType', () {
    test('should convert BookType.pdf to json', () {
      // Arrange
      final bookType = BookType.pdf;

      // Act
      final json = bookType.toJson();

      // Assert
      expect(json, 'pdf');
    });

    test('should convert BookType.epub to json', () {
      // Arrange
      final bookType = BookType.epub;

      // Act
      final json = bookType.toJson();

      // Assert
      expect(json, 'epub');
    });

    test('should parse pdf string to BookType', () {
      // Act
      final bookType = BookType.fromJson('pdf');

      // Assert
      expect(bookType, BookType.pdf);
    });

    test('should parse epub string to BookType', () {
      // Act
      final bookType = BookType.fromJson('epub');

      // Assert
      expect(bookType, BookType.epub);
    });

    test('should default to epub for unknown string', () {
      // Act
      final bookType = BookType.fromJson('unknown');

      // Assert
      expect(bookType, BookType.epub);
    });

    test('should parse uppercase PDF string', () {
      // Act
      final bookType = BookType.fromJson('PDF');

      // Assert
      expect(bookType, BookType.pdf);
    });
  });
}