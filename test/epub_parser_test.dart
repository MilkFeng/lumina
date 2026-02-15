import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/src/features/library/data/parsers/epub_zip_parser.dart';

void main() {
  group('EpubZipParser', () {
    late EpubZipParser parser;

    setUp(() {
      parser = EpubZipParser();
    });

    group('Happy Path (Success Cases)', () {
      test(
        'Parse valid EPUB 2.0 byte stream - should return correct book metadata',
        () {
          // Arrange: Generate EPUB ZIP byte data with complete structure
          final epubBytes = _createMinimalEpub2(
            title: 'The Three-Body Problem',
            author: 'Liu Cixin',
            description: 'A science fiction novel',
            chapters: ['Chapter 1', 'Chapter 2', 'Chapter 3'],
          );

          // Act: Parse EPUB
          final result = parser.parseFromBytes(epubBytes);

          // Assert: Verify parsing succeeded
          expect(result.isRight(), true);

          final parseResult = result.getRight().toNullable()!;
          expect(parseResult.title, 'The Three-Body Problem');
          expect(parseResult.author, 'Liu Cixin');
          expect(parseResult.authors, contains('Liu Cixin'));
          expect(parseResult.description, 'A science fiction novel');
        },
      );

      test(
        'Parse valid EPUB - should correctly parse chapter list (TOC non-empty)',
        () {
          // Arrange
          final epubBytes = _createMinimalEpub2(
            title: 'Test Book',
            author: 'Test Author',
            chapters: ['Chapter 1', 'Chapter 2'],
          );

          // Act
          final result = parser.parseFromBytes(epubBytes);

          // Assert
          expect(result.isRight(), true);

          final parseResult = result.getRight().toNullable()!;
          expect(parseResult.toc, isNotEmpty);
          expect(parseResult.totalChapters, greaterThan(0));
          expect(parseResult.spine, isNotEmpty);
        },
      );

      test(
        'Parse EPUB with cover - should correctly extract cover information',
        () {
          // Arrange
          final epubBytes = _createMinimalEpub2WithCover(
            title: 'Book with Cover',
            author: 'Author',
            coverImageData: Uint8List.fromList([
              0xFF,
              0xD8,
              0xFF,
            ]), // Simulate JPEG header
          );

          // Act
          final result = parser.parseFromBytes(epubBytes);

          // Assert
          expect(result.isRight(), true);

          final parseResult = result.getRight().toNullable()!;
          expect(parseResult.coverHref, isNotNull);
          expect(parseResult.coverHref, isNotEmpty);
        },
      );

      test('Parse EPUB 3.0 format - should recognize version number', () {
        // Arrange
        final epubBytes = _createMinimalEpub3(
          title: 'EPUB 3 Book',
          author: 'Modern Author',
        );

        // Act
        final result = parser.parseFromBytes(epubBytes);

        // Assert
        expect(result.isRight(), true);

        final parseResult = result.getRight().toNullable()!;
        expect(parseResult.epubVersion, '3.0');
        expect(parseResult.title, 'EPUB 3 Book');
      });
    });

    group('Edge Case (Boundary Conditions)', () {
      test('Input non-ZIP format byte stream - should return error', () {
        // Arrange: Create invalid byte stream
        final invalidBytes = Uint8List.fromList([
          0x00,
          0x01,
          0x02,
          0x03,
          0x04,
          0x05,
        ]);

        // Act
        final result = parser.parseFromBytes(invalidBytes);

        // Assert: Should return Left (error)
        expect(result.isLeft(), true);

        final errorMsg = result.getLeft().toNullable()!;
        // Archive package may successfully parse invalid bytes but not find OPF, so error message may vary
        expect(errorMsg, isNotEmpty);
      });

      test('Input empty byte stream - should return error', () {
        // Arrange
        final emptyBytes = Uint8List(0);

        // Act
        final result = parser.parseFromBytes(emptyBytes);

        // Assert
        expect(result.isLeft(), true);
      });

      test(
        'Corrupted EPUB missing container.xml - should try fallback strategy',
        () {
          // Arrange: Create ZIP with only content.opf but missing META-INF/container.xml
          final archive = Archive();

          // Add content.opf (in root directory)
          final opfContent = '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Fallback Test</dc:title>
    <dc:creator>Test Author</dc:creator>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';

          archive.addFile(
            ArchiveFile('content.opf', opfContent.length, opfContent.codeUnits),
          );

          final zipEncoder = ZipEncoder();
          final zipBytes = zipEncoder.encode(archive);

          // Act
          final result = parser.parseFromBytes(zipBytes);

          // Assert: Should successfully parse through fallback strategy
          expect(result.isRight(), true);

          final parseResult = result.getRight().toNullable()!;
          expect(parseResult.title, 'Fallback Test');
        },
      );

      test('Corrupted OPF missing metadata element - should return error', () {
        // Arrange: Create OPF missing metadata
        final archive = Archive();

        final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

        final opfContent = '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';

        archive.addFile(
          ArchiveFile(
            'META-INF/container.xml',
            containerXml.length,
            containerXml.codeUnits,
          ),
        );
        archive.addFile(
          ArchiveFile('content.opf', opfContent.length, opfContent.codeUnits),
        );

        final zipEncoder = ZipEncoder();
        final zipBytes = zipEncoder.encode(archive);

        // Act
        final result = parser.parseFromBytes(zipBytes);

        // Assert
        expect(result.isLeft(), true);

        final errorMsg = result.getLeft().toNullable()!;
        expect(errorMsg, contains('Metadata element not found'));
      });

      test('Corrupted OPF missing spine element - should return error', () {
        // Arrange
        final archive = Archive();

        final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

        final opfContent = '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test</dc:title>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
</package>''';

        archive.addFile(
          ArchiveFile(
            'META-INF/container.xml',
            containerXml.length,
            containerXml.codeUnits,
          ),
        );
        archive.addFile(
          ArchiveFile('content.opf', opfContent.length, opfContent.codeUnits),
        );

        final zipEncoder = ZipEncoder();
        final zipBytes = zipEncoder.encode(archive);

        // Act
        final result = parser.parseFromBytes(zipBytes);

        // Assert
        expect(result.isLeft(), true);

        final errorMsg = result.getLeft().toNullable()!;
        expect(errorMsg, contains('Spine or manifest element not found'));
      });

      test('OPF file does not exist at all - should return error', () {
        // Arrange: Create ZIP with only container.xml but pointing to non-existent OPF
        final archive = Archive();

        final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

        archive.addFile(
          ArchiveFile(
            'META-INF/container.xml',
            containerXml.length,
            containerXml.codeUnits,
          ),
        );

        final zipEncoder = ZipEncoder();
        final zipBytes = zipEncoder.encode(archive);

        // Act
        final result = parser.parseFromBytes(zipBytes);

        // Assert
        expect(result.isLeft(), true);

        final errorMsg = result.getLeft().toNullable()!;
        expect(errorMsg, contains('OPF file not found in archive'));
      });
    });

    group('Complex Scenarios', () {
      test(
        'EPUB with NCX table of contents - should correctly parse nested chapters',
        () {
          // Arrange
          final epubBytes = _createEpubWithNcx(
            title: 'Book with NCX',
            chapters: [
              (
                'Part 1',
                [('Chapter 1', 'ch1.xhtml'), ('Chapter 2', 'ch2.xhtml')],
              ),
              ('Part 2', [('Chapter 3', 'ch3.xhtml')]),
            ],
          );

          // Act
          final result = parser.parseFromBytes(epubBytes);

          // Assert
          expect(result.isRight(), true);

          final parseResult = result.getRight().toNullable()!;
          expect(parseResult.toc, isNotEmpty);

          // Verify nested structure
          final topLevelItems = parseResult.toc.where(
            (item) => item.depth == 0,
          );
          expect(topLevelItems, isNotEmpty);
        },
      );

      test('Multi-author EPUB - should correctly parse all authors', () {
        // Arrange
        final epubBytes = _createEpubWithMultipleAuthors(
          title: 'Multi-Author Book',
          authors: ['Author A', 'Author B', 'Author C'],
        );

        // Act
        final result = parser.parseFromBytes(epubBytes);

        // Assert
        expect(result.isRight(), true);

        final parseResult = result.getRight().toNullable()!;
        expect(parseResult.authors.length, 3);
        expect(
          parseResult.authors,
          containsAll(['Author A', 'Author B', 'Author C']),
        );
      });

      test('EPUB with Subject tags - should correctly extract topics', () {
        // Arrange
        final epubBytes = _createEpubWithSubjects(
          title: 'Book with Subjects',
          subjects: ['Science Fiction', 'Space', 'Future'],
        );

        // Act
        final result = parser.parseFromBytes(epubBytes);

        // Assert
        expect(result.isRight(), true);

        final parseResult = result.getRight().toNullable()!;
        expect(parseResult.subjects.length, 3);
        expect(
          parseResult.subjects,
          containsAll(['Science Fiction', 'Space', 'Future']),
        );
      });

      test('EPUB 3 with NAV document - should parse hierarchical TOC', () {
        // Arrange
        final epubBytes = _createEpubWithNav(
          title: 'Book with NAV',
          navEntries: [
            (
              'Part I',
              null,
              [
                (
                  'Chapter 1',
                  'chapter1.xhtml',
                  <(String, String, List<(String, String, List)>)>[],
                ),
              ],
            ),
            (
              'Chapter 2',
              'chapter2.xhtml',
              <(String, String, List<(String, String, List)>)>[],
            ),
          ],
        );

        // Act
        final result = parser.parseFromBytes(epubBytes);

        // Assert
        expect(result.isRight(), true);
        final parseResult = result.getRight().toNullable()!;

        expect(parseResult.toc, isNotEmpty);
        expect(parseResult.toc.first.label, 'Part I');
        expect(parseResult.toc.first.depth, 0);
        expect(parseResult.toc.first.children, isNotEmpty);
        expect(parseResult.toc.first.children.first.label, 'Chapter 1');
        expect(parseResult.toc.first.children.first.depth, 1);
        expect(parseResult.toc[1].label, 'Chapter 2');
      });

      test('EPUB with both NAV and NCX - should prioritize NAV', () {
        // Arrange
        final epubBytes = _createEpubWithNavAndNcx();

        // Act
        final result = parser.parseFromBytes(epubBytes);

        // Assert
        expect(result.isRight(), true);
        final parseResult = result.getRight().toNullable()!;

        expect(parseResult.toc, isNotEmpty);
        expect(parseResult.toc.first.label, 'NAV TOC Entry');
        expect(
          parseResult.toc.any((item) => item.label.contains('NCX')),
          false,
        );
      });
    });
  });
}

// ==================== Helper Functions ====================

/// Create a minimal EPUB 2.0 ZIP byte data
Uint8List _createMinimalEpub2({
  required String title,
  required String author,
  String? description,
  List<String> chapters = const ['Chapter 1'],
}) {
  final archive = Archive();

  // 1. mimetype (must be first, uncompressed)
  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  // 2. META-INF/container.xml
  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  // 3. OEBPS/content.opf
  final manifestItems = StringBuffer();
  final spineItems = StringBuffer();

  for (var i = 0; i < chapters.length; i++) {
    manifestItems.writeln(
      '    <item id="chapter$i" href="chapter$i.xhtml" media-type="application/xhtml+xml"/>',
    );
    spineItems.writeln('    <itemref idref="chapter$i"/>');
  }

  final descriptionTag = description != null
      ? '<dc:description>$description</dc:description>'
      : '';

  final opfContent =
      '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    $descriptionTag
  </metadata>
  <manifest>
$manifestItems  </manifest>
  <spine>
$spineItems  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('OEBPS/content.opf', opfContent.length, opfContent.codeUnits),
  );

  // 4. Chapter files
  for (var i = 0; i < chapters.length; i++) {
    final chapterContent =
        '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${chapters[i]}</title></head>
<body><h1>${chapters[i]}</h1><p>Content here...</p></body>
</html>''';

    archive.addFile(
      ArchiveFile(
        'OEBPS/chapter$i.xhtml',
        chapterContent.length,
        chapterContent.codeUnits,
      ),
    );
  }

  // Encode to ZIP
  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}

/// Create EPUB 2.0 with cover image
Uint8List _createMinimalEpub2WithCover({
  required String title,
  required String author,
  required Uint8List coverImageData,
}) {
  final archive = Archive();

  // mimetype
  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  // container.xml
  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  // content.opf with cover metadata
  final opfContent =
      '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    <meta name="cover" content="cover-image"/>
  </metadata>
  <manifest>
    <item id="cover-image" href="cover.jpg" media-type="image/jpeg"/>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('OEBPS/content.opf', opfContent.length, opfContent.codeUnits),
  );

  // Cover image
  archive.addFile(
    ArchiveFile('OEBPS/cover.jpg', coverImageData.length, coverImageData),
  );

  // Chapter
  final chapterContent = '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1></body>
</html>''';

  archive.addFile(
    ArchiveFile(
      'OEBPS/chapter1.xhtml',
      chapterContent.length,
      chapterContent.codeUnits,
    ),
  );

  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}

/// Create EPUB 3.0 ZIP byte data
Uint8List _createMinimalEpub3({required String title, required String author}) {
  final archive = Archive();

  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  // EPUB 3.0 OPF
  final opfContent =
      '''<?xml version="1.0"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('OEBPS/content.opf', opfContent.length, opfContent.codeUnits),
  );

  final chapterContent = '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1></body>
</html>''';

  archive.addFile(
    ArchiveFile(
      'OEBPS/chapter1.xhtml',
      chapterContent.length,
      chapterContent.codeUnits,
    ),
  );

  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}

/// Create EPUB with NCX table of contents
Uint8List _createEpubWithNcx({
  required String title,
  required List<(String, List<(String, String)>)> chapters,
}) {
  final archive = Archive();

  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  // Build manifest and spine
  final manifestItems = StringBuffer();
  final spineItems = StringBuffer();
  manifestItems.writeln(
    '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
  );

  var chapterId = 0;
  for (final part in chapters) {
    for (final chapter in part.$2) {
      manifestItems.writeln(
        '    <item id="ch$chapterId" href="${chapter.$2}" media-type="application/xhtml+xml"/>',
      );
      spineItems.writeln('    <itemref idref="ch$chapterId"/>');
      chapterId++;
    }
  }

  final opfContent =
      '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>Author</dc:creator>
  </metadata>
  <manifest>
$manifestItems  </manifest>
  <spine toc="ncx">
$spineItems  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('OEBPS/content.opf', opfContent.length, opfContent.codeUnits),
  );

  // Build NCX
  final navPoints = StringBuffer();
  var navId = 1;
  for (final part in chapters) {
    navPoints.writeln('    <navPoint id="navPoint-$navId">');
    navPoints.writeln('      <navLabel><text>${part.$1}</text></navLabel>');
    navPoints.writeln('      <content src="${part.$2.first.$2}"/>');

    for (final chapter in part.$2) {
      navId++;
      navPoints.writeln('      <navPoint id="navPoint-$navId">');
      navPoints.writeln(
        '        <navLabel><text>${chapter.$1}</text></navLabel>',
      );
      navPoints.writeln('        <content src="${chapter.$2}"/>');
      navPoints.writeln('      </navPoint>');
    }

    navPoints.writeln('    </navPoint>');
    navId++;
  }

  final ncxContent =
      '''<?xml version="1.0"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-id"/>
  </head>
  <docTitle><text>$title</text></docTitle>
  <navMap>
$navPoints  </navMap>
</ncx>''';

  archive.addFile(
    ArchiveFile('OEBPS/toc.ncx', ncxContent.length, ncxContent.codeUnits),
  );

  // Add chapter files
  chapterId = 0;
  for (final part in chapters) {
    for (final chapter in part.$2) {
      final chapterContent =
          '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${chapter.$1}</title></head>
<body><h1>${chapter.$1}</h1></body>
</html>''';

      archive.addFile(
        ArchiveFile(
          'OEBPS/${chapter.$2}',
          chapterContent.length,
          chapterContent.codeUnits,
        ),
      );
      chapterId++;
    }
  }

  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}

/// Create EPUB with multiple authors
Uint8List _createEpubWithMultipleAuthors({
  required String title,
  required List<String> authors,
}) {
  final archive = Archive();

  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  final authorTags = authors
      .map((a) => '<dc:creator>$a</dc:creator>')
      .join('\n    ');

  final opfContent =
      '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    $authorTags
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('content.opf', opfContent.length, opfContent.codeUnits),
  );

  final chapterContent = '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1></body>
</html>''';

  archive.addFile(
    ArchiveFile(
      'chapter1.xhtml',
      chapterContent.length,
      chapterContent.codeUnits,
    ),
  );

  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}

/// Create EPUB with Subject tags
Uint8List _createEpubWithSubjects({
  required String title,
  required List<String> subjects,
}) {
  final archive = Archive();

  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  final subjectTags = subjects
      .map((s) => '<dc:subject>$s</dc:subject>')
      .join('\n    ');

  final opfContent =
      '''<?xml version="1.0"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>Author</dc:creator>
    $subjectTags
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('content.opf', opfContent.length, opfContent.codeUnits),
  );

  final chapterContent = '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1></body>
</html>''';

  archive.addFile(
    ArchiveFile(
      'chapter1.xhtml',
      chapterContent.length,
      chapterContent.codeUnits,
    ),
  );

  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}

/// Create EPUB 3 with NAV TOC document
Uint8List _createEpubWithNav({
  required String title,
  required List<(String, String?, List<(String, String, List)>)> navEntries,
}) {
  final archive = Archive();

  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  final opfContent =
      '''<?xml version="1.0"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>Author</dc:creator>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('OEBPS/content.opf', opfContent.length, opfContent.codeUnits),
  );

  final navList = StringBuffer();
  for (final entry in navEntries) {
    navList.write('<li>');
    if (entry.$2 != null) {
      navList.write('<a href="${entry.$2}">${entry.$1}</a>');
    } else {
      navList.write('<span>${entry.$1}</span>');
    }

    if (entry.$3.isNotEmpty) {
      navList.write('<ol>');
      for (final child in entry.$3) {
        navList.write('<li><a href="${child.$2}">${child.$1}</a></li>');
      }
      navList.write('</ol>');
    }
    navList.write('</li>');
  }

  final navContent =
      '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>TOC</title></head>
  <body>
    <nav epub:type="toc" type="toc">
      <ol>
        $navList
      </ol>
    </nav>
  </body>
</html>''';

  archive.addFile(
    ArchiveFile('OEBPS/nav.xhtml', navContent.length, navContent.codeUnits),
  );

  final chapter1Content = '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1></body>
</html>''';

  final chapter2Content = '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 2</title></head>
<body><h1>Chapter 2</h1></body>
</html>''';

  archive.addFile(
    ArchiveFile(
      'OEBPS/chapter1.xhtml',
      chapter1Content.length,
      chapter1Content.codeUnits,
    ),
  );
  archive.addFile(
    ArchiveFile(
      'OEBPS/chapter2.xhtml',
      chapter2Content.length,
      chapter2Content.codeUnits,
    ),
  );

  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}

/// Create EPUB containing both NAV and NCX TOCs, used to verify NAV priority.
Uint8List _createEpubWithNavAndNcx() {
  final archive = Archive();

  final mimetype = 'application/epub+zip';
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype.codeUnits));

  final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  archive.addFile(
    ArchiveFile(
      'META-INF/container.xml',
      containerXml.length,
      containerXml.codeUnits,
    ),
  );

  final opfContent = '''<?xml version="1.0"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>NAV Priority Book</dc:title>
    <dc:creator>Author</dc:creator>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="ch1"/>
  </spine>
</package>''';

  archive.addFile(
    ArchiveFile('OEBPS/content.opf', opfContent.length, opfContent.codeUnits),
  );

  final navContent = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>TOC</title></head>
  <body>
    <nav epub:type="toc" type="toc">
      <ol>
        <li><a href="chapter1.xhtml">NAV TOC Entry</a></li>
      </ol>
    </nav>
  </body>
</html>''';

  final ncxContent = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="n1">
      <navLabel><text>NCX TOC Entry</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

  final chapterContent = '''<?xml version="1.0"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1></body>
</html>''';

  archive.addFile(
    ArchiveFile('OEBPS/nav.xhtml', navContent.length, navContent.codeUnits),
  );
  archive.addFile(
    ArchiveFile('OEBPS/toc.ncx', ncxContent.length, ncxContent.codeUnits),
  );
  archive.addFile(
    ArchiveFile(
      'OEBPS/chapter1.xhtml',
      chapterContent.length,
      chapterContent.codeUnits,
    ),
  );

  final zipEncoder = ZipEncoder();
  return Uint8List.fromList(zipEncoder.encode(archive));
}
