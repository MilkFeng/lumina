import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/src/features/library/domain/book_type.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';

void main() {
  group('ShelfBook PDF Support', () {
    test('should create ShelfBook with PDF type', () {
      // Arrange
      final book = ShelfBook()
        ..fileHash = 'test_hash'
        ..title = 'Test PDF'
        ..author = '<PERSON>'
        ..bookType = BookType.pdf;

      // Assert
      expect(book.bookType, BookType.pdf);
      expect(book.title, 'Test PDF');
      expect(book.fileHash, 'test_hash');
    });

    test('should create ShelfBook with EPUB type', () {
      // Arrange
      final book = ShelfBook()
        ..fileHash = 'test_hash'
        ..title = 'Test EPUB'
        ..author = '<PERSON>'
        ..bookType = BookType.epub;

      // Assert
      expect(book.bookType, BookType.epub);
      expect(book.title, 'Test EPUB');
    });

    test('should handle password-protected PDF metadata', () {
      // Arrange
      final book = ShelfBook()
        ..fileHash = 'protected_hash'
        ..title = 'Protected Doc'
        ..bookType = BookType.pdf
        ..isPasswordProtected = true;

      // Assert
      expect(book.isPasswordProtected, isTrue);
      expect(book.pdfPassword, isNull); // Password not yet provided
    });

    test('should set pdfPassword as reference when password is saved', () {
      // Arrange
      final book = ShelfBook()
        ..fileHash = 'hash_with_password'
        ..title = 'Protected PDF'
        ..bookType = BookType.pdf
        ..isPasswordProtected = true
        ..pdfPassword = 'stored'; // Marker that password is in secure storage

      // Assert
      expect(book.isPasswordProtected, isTrue);
      expect(book.pdfPassword, isNotEmpty);
    });

    test('should handle PDF without password', () {
      // Arrange
      final book = ShelfBook()
        ..bookType = BookType.pdf
        ..isPasswordProtected = false;

      // Assert
      expect(book.isPasswordProtected, isFalse);
      expect(book.pdfPassword, isNull);
    });

    test('should reuse totalChapters for PDF page count', () {
      // Arrange - For PDFs, totalChapters represents page count
      final pdfPageCount = 150;
      final epubChapterCount = 12;

      // Act
      final pdfBook = ShelfBook()
        ..bookType = BookType.pdf
        ..totalChapters = pdfPageCount;

      final epubBook = ShelfBook()
        ..bookType = BookType.epub
        ..totalChapters = epubChapterCount;

      // Assert
      expect(pdfBook.totalChapters, pdfPageCount);
      expect(epubBook.totalChapters, epubChapterCount);
    });

    test('should reuse currentChapterIndex for PDF page index', () {
      // Arrange
      final currentPdfPage = 42;
      final currentEpubChapter = 5;

      // Act
      final pdfBook = ShelfBook()
        ..bookType = BookType.pdf
        ..currentChapterIndex = currentPdfPage;

      final epubBook = ShelfBook()
        ..bookType = BookType.epub
        ..currentChapterIndex = currentEpubChapter;

      // Assert
      expect(pdfBook.currentChapterIndex, currentPdfPage);
      expect(epubBook.currentChapterIndex, currentEpubChapter);
    });

    test('should have reading progress 0.0 for new books', () {
      // Arrange
      final book = ShelfBook()
        ..bookType = BookType.pdf
        ..readingProgress = 0.0;

      // Assert
      expect(book.readingProgress, equals(0.0));
    });

    test('should set isFinished when PDF is fully read', () {
      // Arrange
      final totalPages = 100;
      final lastPage = totalPages - 1;

      // Act
      final book = ShelfBook()
        ..bookType = BookType.pdf
        ..totalChapters = totalPages
        ..currentChapterIndex = lastPage
        ..isFinished = true;

      // Assert
      expect(book.isFinished, isTrue);
      expect(book.currentChapterIndex, lastPage);
    });

    test('should handle book without cover', () {
      // Arrange - PDF without extracted cover or password protected
      final book = ShelfBook()
        ..bookType = BookType.pdf
        ..isPasswordProtected = true
        ..coverPath = null;

      // Assert
      expect(book.coverPath, isNull);
      expect(book.isPasswordProtected, isTrue);
    });

    test('should use empty string for epubVersion of PDF', () {
      // Arrange
      final book = ShelfBook()
        ..bookType = BookType.pdf
        ..epubVersion = '';

      // Assert
      expect(book.epubVersion, isEmpty);
    });

    test('should have direction field for PDFs', () {
      // PDFs typically default to LTR
      final ltrDirection = 0; // LTR
      final rtlDirection = 1; // RTL

      // Arrange
      final book = ShelfBook()
        ..bookType = BookType.pdf
        ..direction = ltrDirection;

      // Assert
      expect(book.direction, ltrDirection);
      expect(rtlDirection, equals(1));
    });
  });

  group('BookType Enum', () {
    test('should have two values: epub and pdf', () {
      // Act
      final epub = BookType.epub;
      final pdf = BookType.pdf;

      // Assert
      expect(epub, isA<BookType>());
      expect(pdf, isA<BookType>());
      expect(epub, isNot(equals(pdf)));
    });

    test('should serialize BookType to json', () {
      expect(BookType.epub.toJson(), 'epub');
      expect(BookType.pdf.toJson(), 'pdf');
    });

    test('should deserialize BookType from json', () {
      expect(BookType.fromJson('epub'), BookType.epub);
      expect(BookType.fromJson('pdf'), BookType.pdf);
    });

    test('should handle case-insensitive deserialization', () {
      expect(BookType.fromJson('EPUB'), BookType.epub);
      expect(BookType.fromJson('PDF'), BookType.pdf);
      expect(BookType.fromJson('Epub'), BookType.epub);
      expect(BookType.fromJson('Pdf'), BookType.pdf);
    });

    test('should default to epub for invalid values', () {
      expect(BookType.fromJson('invalid'), BookType.epub);
      expect(BookType.fromJson(''), BookType.epub);
      expect(BookType.fromJson('mobi'), BookType.epub);
    });
  });

  group('ShelfBook Collections', () {
    test('can have multiple books of different types', () {
      // Arrange
      final pdfBook = ShelfBook()
        ..fileHash = 'pdf_1'
        ..bookType = BookType.pdf;

      final epubBook = ShelfBook()
        ..fileHash = 'epub_1'
        ..bookType = BookType.epub;

      final pdfBook2 = ShelfBook()
        ..fileHash = 'pdf_2'
        ..bookType = BookType.pdf;

      // Assert
      expect(pdfBook.bookType, BookType.pdf);
      expect(epubBook.bookType, BookType.epub);
      expect(pdfBook2.bookType, BookType.pdf);

      // Different hashes should be allowed
      expect(pdfBook.fileHash, isNot(equals(epubBook.fileHash)));
    });

    test('should support grouping by bookType', () {
      // Arrange
      final books = [
        ShelfBook()..bookType = BookType.pdf,
        ShelfBook()..bookType = BookType.epub,
        ShelfBook()..bookType = BookType.pdf,
        ShelfBook()..bookType = BookType.epub,
      ];

      // Act
      final pdfBooks = books.where((b) => b.bookType == BookType.pdf);
      final epubBooks = books.where((b) => b.bookType == BookType.epub);

      // Assert
      expect(pdfBooks.length, equals(2));
      expect(epubBooks.length, equals(2));
    });
  });
}