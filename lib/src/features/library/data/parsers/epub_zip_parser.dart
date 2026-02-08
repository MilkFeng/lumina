import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:xml/xml.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/book_manifest.dart';

/// Parser that reads EPUB structure directly from ZIP archive
/// No full extraction required - reads specific files in-memory
class EpubZipParser {
  /// Parse EPUB from file path
  Future<Either<String, EpubZipParseResult>> parseFromFile(
    String filePath, {
    String? fileName,
  }) async {
    try {
      final inputStream = InputFileStream(filePath);
      final archive = ZipDecoder().decodeStream(inputStream);
      return parseFromArchive(archive, fileName: fileName);
    } catch (e) {
      return left('Failed to read file: $e');
    }
  }

  Either<String, EpubZipParseResult> parseFromBytes(
    List<int> bytes, {
    String? fileName,
  }) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      return parseFromArchive(archive, fileName: fileName);
    } catch (e) {
      return left('Failed to read bytes: $e');
    }
  }

  /// Parse EPUB from bytes
  Either<String, EpubZipParseResult> parseFromArchive(
    Archive archive, {
    String? fileName,
  }) {
    try {
      // Step 1: Find OPF file path
      final opfPathResult = _findOpfPath(archive);
      if (opfPathResult.isLeft()) {
        return left(opfPathResult.getLeft().toNullable()!);
      }
      final opfPath = opfPathResult.getRight().toNullable()!;

      // Step 2: Read OPF file content
      final opfFile = archive.findFile(opfPath);
      if (opfFile == null) {
        return left('OPF file not found in archive');
      }
      final opfContent = _decodeString(opfFile.content as List<int>);

      // Step 3: Parse OPF XML
      final parseResult = _parseOpf(opfContent, opfPath, archive, fileName);
      return parseResult;
    } catch (e) {
      return left('Parse error: $e');
    }
  }

  static String _decodeString(List<int> bytes) {
    String decodedString;
    try {
      decodedString = utf8.decode(bytes);
    } catch (e) {
      try {
        decodedString = gbk.decode(bytes);
      } catch (e) {
        throw FormatException('cannot decode string');
      }
    }
    return decodedString;
  }

  /// Find OPF file path in the archive
  Either<String, String> _findOpfPath(Archive archive) {
    try {
      // Strategy 1: Parse container.xml (standard EPUB structure)
      final containerFile = archive.findFile('META-INF/container.xml');
      if (containerFile != null) {
        final containerContent = _decodeString(
          containerFile.content as List<int>,
        );
        final containerDoc = XmlDocument.parse(containerContent);

        final rootFileElement = containerDoc
            .findAllElements('rootfile')
            .firstOrNull;

        if (rootFileElement != null) {
          final fullPath = rootFileElement.getAttribute('full-path');
          if (fullPath != null) {
            return right(fullPath);
          }
        }
      }

      // Strategy 2: Check common locations
      final commonPaths = [
        'content.opf',
        'OEBPS/content.opf',
        'OPS/content.opf',
        'EPUB/content.opf',
      ];

      for (final path in commonPaths) {
        if (archive.findFile(path) != null) {
          return right(path);
        }
      }

      // Strategy 3: Scan for .opf files
      for (final file in archive.files) {
        if (file.name.endsWith('.opf')) {
          return right(file.name);
        }
      }

      return left('OPF file not found');
    } catch (e) {
      return left('Error finding OPF: $e');
    }
  }

  /// Parse OPF file content
  /// Parse OPF file content
  static Either<String, EpubZipParseResult> _parseOpf(
    String content,
    String opfPath,
    Archive archive,
    String? fileName,
  ) {
    try {
      final doc = XmlDocument.parse(content);
      final packageElement = doc.rootElement;

      // Extract version
      final version = packageElement.getAttribute('version') ?? '2.0';

      // Parse metadata
      final metadataElement = packageElement
          .findElements('metadata')
          .firstOrNull;
      if (metadataElement == null) {
        return left('Metadata element not found');
      }

      // Parse spine for chapter order
      final spineElement = packageElement.findElements('spine').firstOrNull;
      final manifestElement = packageElement
          .findElements('manifest')
          .firstOrNull;

      if (spineElement == null || manifestElement == null) {
        return left('Spine or manifest element not found');
      }

      // Build manifest map (id -> (href, properties))
      final manifestMap = <String, (Href, String?)>{};
      for (final item in manifestElement.findElements('item')) {
        final id = item.getAttribute('id');
        final href = item.getAttribute('href');
        final properties = item.getAttribute('properties');
        if (id != null && href != null) {
          manifestMap[id] = (_resolveHref(href)!, properties);
        }
      }

      final metadata = _parseMetadata(
        metadataElement,
        manifestMap,
        version,
        opfPath,
        fileName,
      );

      final opfDir = opfPath.contains('/')
          ? opfPath.substring(0, opfPath.lastIndexOf('/'))
          : '';

      // Step 1: Build spine list with full metadata
      final spineItems = <SpineItem>[];
      final spineIndexMap = <String, int>{}; // path -> index for TOC mapping
      int index = 0;

      for (final itemref in spineElement.findElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        final linearAttr = itemref.getAttribute('linear');
        final isLinear = linearAttr == null || linearAttr.toLowerCase() != 'no';

        if (idref != null && manifestMap.containsKey(idref)) {
          final href = manifestMap[idref]!.$1;
          final resolvedPath = _normalizePath(
            opfDir.isEmpty ? href.path : '$opfDir/${href.path}',
          );

          spineItems.add(
            SpineItem(
              index: index,
              href: resolvedPath,
              idref: idref,
              linear: isLinear,
            ),
          );

          spineIndexMap[resolvedPath] = index;
          index++;
        }
      }

      // Step 2: Parse TOC structure (NCX or NAV)
      final tocId = spineElement.getAttribute('toc');
      List<TocItem> toc = [];

      if (tocId != null && manifestMap.containsKey(tocId)) {
        final tocHref = manifestMap[tocId]!.$1;
        final tocPath = opfDir.isEmpty
            ? tocHref.path
            : '$opfDir/${tocHref.path}';
        final tocFile = archive.findFile(tocPath);

        if (tocFile != null) {
          final tocContent = _decodeString(tocFile.content as List<int>);
          toc = _parseNcx(tocContent, manifestMap, opfDir, spineIndexMap);
        }
      }

      // Fallback: Create flat TOC from spine if no NCX/NAV found
      if (toc.isEmpty) {
        toc = _parseSpineAsChapters(spineItems, opfDir);
      }

      // Generate id for each TocItem
      int tocIdCounter = 0;
      void assignTocIds(TocItem item, [int parentId = -1]) {
        item.id = tocIdCounter++;
        item.parentId = parentId;
        for (final child in item.children) {
          assignTocIds(child, item.id);
        }
      }

      for (final item in toc) {
        assignTocIds(item);
      }

      final result = EpubZipParseResult(
        title: metadata.title,
        author: metadata.author,
        authors: metadata.authors,
        description: metadata.description,
        subjects: metadata.subjects,
        coverHref: metadata.coverHref,
        opfRootPath: opfPath,
        epubVersion: version,
        totalChapters: toc.expand((item) => item.flatten()).length,
        spine: spineItems,
        toc: toc,
        manifestItems: manifestMap.entries
            .map(
              (e) => ManifestItem()
                ..id = e.key
                ..href = e.value.$1
                ..properties = e.value.$2
                ..mediaType = 'application/xhtml+xml',
            )
            .toList(),
      );

      return right(result);
    } catch (e) {
      return left('OPF parse error: $e');
    }
  }

  /// Parse metadata element
  static _MetadataResult _parseMetadata(
    XmlElement metadataElement,
    Map<String, (Href, String?)> manifestMap,
    String version,
    String opfPath,
    String? fileName,
  ) {
    // Helper function to find elements by local name (ignoring namespace prefix)
    // This handles both <title> and <dc:title> formats
    Iterable<XmlElement> findByLocalName(String name) {
      return metadataElement.descendantElements.where(
        (e) => e.localName == name,
      );
    }

    // Extract titles
    var titles = findByLocalName(
      'title',
    ).map((e) => e.innerText.trim()).where((t) => t.isNotEmpty).toList();
    if (titles.isEmpty) {
      // Fallback to file name without extension
      final fallbackTitle = fileName != null
          ? fileName.split('/').last.split('.').first
          : 'Unknown Title';
      titles = [fallbackTitle];
    }

    // Extract authors (dc:creator)
    final authors = findByLocalName(
      'creator',
    ).map((e) => e.innerText.trim()).where((a) => a.isNotEmpty).toList();

    // Extract description
    final description = findByLocalName(
      'description',
    ).firstOrNull?.innerText.trim();

    // Extract subjects
    final subjects = findByLocalName(
      'subject',
    ).map((e) => e.innerText.trim()).where((s) => s.isNotEmpty).toList();

    // Extract cover (from meta tag with name="cover")
    String? coverHref;
    final coverMeta = metadataElement
        .findAllElements('meta')
        .where((e) => e.getAttribute('name') == 'cover')
        .firstOrNull;

    if (coverMeta != null) {
      final coverId = coverMeta.getAttribute('content');
      if (coverId != null) {
        // Find cover href in manifest (will be resolved later)
        coverHref = manifestMap[coverId]!.$1.path;
      }
    }

    if (coverHref == null) {
      for (final key in manifestMap.keys) {
        final lowerCaseKey = key.toLowerCase();
        if (lowerCaseKey == 'cover.jpg' || lowerCaseKey == 'cover.png') {
          coverHref = manifestMap[key]!.$1.path;
          break;
        }
      }
    }

    return _MetadataResult(
      title: titles.firstOrNull ?? '',
      author: authors.firstOrNull ?? '',
      authors: authors,
      description: description,
      subjects: subjects,
      coverHref: coverHref,
    );
  }

  /// Parse NCX file for TOC navigation tree
  /// Returns the pure hierarchical structure as defined in the NCX
  /// No gap-filling or spine merging is performed
  static List<TocItem> _parseNcx(
    String content,
    Map<String, (Href, String?)> manifestMap,
    String opfDir,
    Map<String, int> spineIndexMap,
  ) {
    try {
      final doc = XmlDocument.parse(content);
      final navMapElement = doc.findAllElements('navMap').firstOrNull;

      if (navMapElement == null) {
        return [];
      }

      return _parseNavPoints(
        navMapElement.findElements('navPoint'),
        manifestMap,
        0,
        opfDir,
        spineIndexMap,
      );
    } catch (e) {
      return [];
    }
  }

  /// Parse navPoint elements recursively
  /// Builds the pure hierarchical TOC tree as defined in the NCX
  static List<TocItem> _parseNavPoints(
    Iterable<XmlElement> navPoints,
    Map<String, (Href, String?)> manifestMap,
    int depth,
    String opfDir,
    Map<String, int> spineIndexMap,
  ) {
    final chapters = <TocItem>[];

    for (final navPoint in navPoints) {
      final labelElement = navPoint.findElements('navLabel').firstOrNull;
      final contentElement = navPoint.findElements('content').firstOrNull;

      if (labelElement == null || contentElement == null) {
        continue;
      }

      final label =
          labelElement.findElements('text').firstOrNull?.innerText.trim() ??
          'Chapter';
      final src = contentElement.getAttribute('src') ?? '';

      // Resolve href relative to OPF directory
      final hrefStr = opfDir.isEmpty ? src : '$opfDir/$src';
      var href = _resolveHref(hrefStr);

      // Map to spine index for progress tracking
      int spineIdx = -1;
      if (href != null) {
        final normalizedPath = _normalizePath(href.path);
        spineIdx = spineIndexMap[normalizedPath] ?? -1;
      }

      // Parse nested children recursively
      final children = _parseNavPoints(
        navPoint.findElements('navPoint'),
        manifestMap,
        depth + 1,
        opfDir,
        spineIndexMap,
      );

      // Skip parent label if first child has the same href
      if (children.isNotEmpty && children.first.href == href) {
        href = null;
      }

      chapters.add(
        TocItem()
          ..label = label
          ..href =
              href ??
              (Href()
                ..path = ''
                ..anchor = 'top')
          ..depth = depth
          ..spineIndex = spineIdx
          ..children = children,
      );
    }

    return chapters;
  }

  /// Parse spine as flat TOC list (fallback when no NCX/NAV exists)
  /// Creates simple sequential chapter entries from spine order
  static List<TocItem> _parseSpineAsChapters(
    List<SpineItem> spineItems,
    String opfDir,
  ) {
    final chapters = <TocItem>[];
    int chapterNum = 1;

    for (final spineItem in spineItems) {
      // Only include linear items in fallback TOC
      if (!spineItem.linear) continue;

      final href = Href()
        ..path = spineItem.href
        ..anchor = 'top';

      chapters.add(
        TocItem()
          ..label = 'Chapter $chapterNum'
          ..href = href
          ..depth = 0
          ..spineIndex = spineItem.index
          ..children = [],
      );
      chapterNum++;
    }

    return chapters;
  }

  static Href? _resolveHref(String? href) {
    if (href == null) return null;
    final parts = href.split('#');
    return Href()
      ..path = parts[0]
      ..anchor = parts.length > 1 ? parts[1] : 'top';
  }

  /// Normalize path for consistent comparison
  /// Removes redundant slashes and resolves relative paths
  static String _normalizePath(String path) {
    // Remove leading/trailing slashes
    path = path.trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    // Replace multiple slashes with single slash
    path = path.replaceAll(RegExp(r'/+'), '/');
    return path;
  }
}

/// Result of EPUB ZIP parsing
class EpubZipParseResult {
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

  EpubZipParseResult({
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

/// Internal metadata result
class _MetadataResult {
  final String title;
  final String author;
  final List<String> authors;
  final String? description;
  final List<String> subjects;
  final String? coverHref;

  _MetadataResult({
    required this.title,
    required this.author,
    required this.authors,
    this.description,
    required this.subjects,
    this.coverHref,
  });
}
