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

      // Step 1: Build spine mapping (path -> index)
      final spineList = <String>[];
      final spineIndexMap = <String, int>{};
      int index = 0;
      for (final itemref in spineElement.findElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        if (idref != null && manifestMap.containsKey(idref)) {
          final href = manifestMap[idref]!.$1;
          final resolvedPath = _normalizePath(
            opfDir.isEmpty ? href.path : '$opfDir/${href.path}',
          );
          spineList.add(idref);
          spineIndexMap[resolvedPath] = index;
          index++;
        }
      }

      // Step 2: Initialize anchor tracking map (index -> List<anchor>)
      final spineAnchors = <int, List<String>>{};
      for (int i = 0; i < spineIndexMap.length; i++) {
        spineAnchors[i] = [];
      }

      // Step 3: Try to parse NCX/NAV for chapter structure
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
          toc = _parseNcx(
            tocContent,
            manifestMap,
            opfDir,
            spineIndexMap,
            spineAnchors,
          );
        }
      }

      // Fallback: use spine order as flat chapter list
      if (toc.isEmpty) {
        toc = _parseSpineAsChapters(
          spineElement,
          manifestMap,
          opfDir,
          spineIndexMap,
        );
      } else {
        // Step 4: Smart hydration - fill gaps in TOC
        toc = _fillTocGaps(toc, spineList, manifestMap, opfDir, spineAnchors);
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
        spine: spineElement
            .findElements('itemref')
            .map((e) => e.getAttribute('idref')!)
            .toList(),
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

  /// Parse NCX file for chapter structure
  static List<TocItem> _parseNcx(
    String content,
    Map<String, (Href, String?)> manifestMap,
    String opfDir,
    Map<String, int> spineIndexMap,
    Map<int, List<String>> spineAnchors,
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
        spineAnchors,
      );
    } catch (e) {
      return [];
    }
  }

  /// Parse navPoint elements recursively
  static List<TocItem> _parseNavPoints(
    Iterable<XmlElement> navPoints,
    Map<String, (Href, String?)> manifestMap,
    int depth,
    String opfDir,
    Map<String, int> spineIndexMap,
    Map<int, List<String>> spineAnchors,
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

      // Track spine index and anchors
      int spineIdx = -1;
      if (href != null) {
        final normalizedPath = _normalizePath(href.path);
        spineIdx = spineIndexMap[normalizedPath] ?? -1;

        // Record anchor usage (empty/null anchor means "TOP")
        if (spineIdx >= 0) {
          final anchor = href.anchor ?? 'TOP';
          if (anchor.isEmpty) {
            spineAnchors[spineIdx]!.add('TOP');
          } else {
            spineAnchors[spineIdx]!.add(anchor);
          }
        }
      }

      final children = _parseNavPoints(
        navPoint.findElements('navPoint'),
        manifestMap,
        depth + 1,
        opfDir,
        spineIndexMap,
        spineAnchors,
      );

      if (children.isNotEmpty && children.first.href == href) {
        href = null;
      }

      chapters.add(
        TocItem()
          ..label = label
          ..href = href ?? Href()
          ..depth = depth
          ..spineIndex = spineIdx
          ..children = children,
      );
    }

    return chapters;
  }

  /// Parse spine as flat chapter list (fallback)
  static List<TocItem> _parseSpineAsChapters(
    XmlElement spineElement,
    Map<String, (Href, String?)> manifestMap,
    String opfDir,
    Map<String, int> spineIndexMap,
  ) {
    final chapters = <TocItem>[];
    int chapterNum = 1;

    for (final itemref in spineElement.findElements('itemref')) {
      final idref = itemref.getAttribute('idref');
      if (idref != null && manifestMap.containsKey(idref)) {
        final href = manifestMap[idref]!.$1;
        final resolvedHrefPath = opfDir.isEmpty
            ? href.path
            : '$opfDir/${href.path}';
        final resolvedHref = Href()
          ..path = resolvedHrefPath
          ..anchor = href.anchor;

        final normalizedPath = _normalizePath(resolvedHrefPath);
        final spineIdx = spineIndexMap[normalizedPath] ?? -1;

        chapters.add(
          TocItem()
            ..label = 'Chapter $chapterNum'
            ..href = resolvedHref
            ..depth = 0
            ..spineIndex = spineIdx
            ..children = [],
        );
        chapterNum++;
      }
    }

    return chapters;
  }

  static Href? _resolveHref(String? href) {
    if (href == null) return null;
    final parts = href.split('#');
    return Href()
      ..path = parts[0]
      ..anchor = parts.length > 1 ? parts[1] : null;
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

  /// Fill gaps in TOC by comparing with spine
  /// Handles two cases:
  /// - Case A (Ghost Chapter): Spine file completely missing from NCX
  /// - Case B (Missing Start): Spine file referenced but no TOP anchor
  static List<TocItem> _fillTocGaps(
    List<TocItem> toc,
    List<String> spine,
    Map<String, (Href, String?)> manifestMap,
    String opfDir,
    Map<int, List<String>> spineAnchors,
  ) {
    final result = List<TocItem>.from(toc);

    // Iterate through spine indices to detect gaps
    for (int i = 0; i < spine.length; i++) {
      final idref = spine[i];
      if (!manifestMap.containsKey(idref)) continue;

      final href = manifestMap[idref]!.$1;
      final filePath = opfDir.isEmpty ? href.path : '$opfDir/${href.path}';
      final anchors = spineAnchors[i] ?? [];

      // Case A: Ghost Chapter (completely missing from NCX)
      if (anchors.isEmpty) {
        final idref = spine[i];
        final ghostItem = _createGhostChapter(filePath, i, idref);
        _insertGhostChapter(result, ghostItem, i);
      }
      // Case B: Missing Start (no TOP anchor)
      else if (!anchors.contains('TOP')) {
        final idref = spine[i];
        final startItem = _createMissingStart(filePath, i, idref);
        _insertMissingStart(result, startItem, i);
      }
    }

    return result;
  }

  /// Create a ghost chapter item for a spine file not in NCX
  static TocItem _createGhostChapter(
    String filePath,
    int spineIndex,
    String idref,
  ) {
    final label = idref.isNotEmpty ? idref : 'Chapter ${spineIndex + 1}';
    return TocItem()
      ..label = '$label (Missing from TOC)'
      ..href = (Href()
        ..path = filePath
        ..anchor = null)
      ..depth = 0
      ..spineIndex = spineIndex
      ..children = [];
  }

  /// Create a missing start item for a spine file without TOP anchor
  static TocItem _createMissingStart(
    String filePath,
    int spineIndex,
    String idref,
  ) {
    final label = idref.isNotEmpty ? idref : 'Chapter ${spineIndex + 1}';
    return TocItem()
      ..label = 'Start (Missing Anchor) - $label'
      ..href = (Href()
        ..path = filePath
        ..anchor = null)
      ..depth = 0
      ..spineIndex = spineIndex
      ..children = [];
  }

  /// Insert ghost chapter at the correct position in TOC
  /// Finds the last root-level node with spineIndex = i-1 and inserts after it
  static void _insertGhostChapter(
    List<TocItem> toc,
    TocItem ghostItem,
    int targetSpineIndex,
  ) {
    if (targetSpineIndex == 0) {
      // Insert at beginning
      toc.insert(0, ghostItem);
      return;
    }

    // Find the last root-level item with spineIndex = targetSpineIndex - 1
    int insertPosition = -1;
    for (int i = toc.length - 1; i >= 0; i--) {
      if (toc[i].depth == 0 && toc[i].spineIndex == targetSpineIndex - 1) {
        insertPosition = i + 1;
        break;
      }
    }

    if (insertPosition >= 0 && insertPosition <= toc.length) {
      toc.insert(insertPosition, ghostItem);
    } else {
      // Fallback: find any item with lower spine index
      for (int i = 0; i < toc.length; i++) {
        if (toc[i].spineIndex >= targetSpineIndex) {
          toc.insert(i, ghostItem);
          return;
        }
      }
      // If all items are before target, append at end
      toc.add(ghostItem);
    }
  }

  /// Insert missing start item before the first occurrence of targetSpineIndex
  /// Does NOT modify the existing item, just inserts before it
  static void _insertMissingStart(
    List<TocItem> toc,
    TocItem startItem,
    int targetSpineIndex,
  ) {
    // Find first item (at any depth) with matching spineIndex
    final insertPosition = _findFirstItemWithSpineIndex(toc, targetSpineIndex);

    if (insertPosition >= 0) {
      toc.insert(insertPosition, startItem);
    } else {
      // Fallback: shouldn't happen if anchors tracking is correct
      toc.add(startItem);
    }
  }

  /// Recursively find the first item with given spineIndex
  /// Returns the position in the flattened root list
  static int _findFirstItemWithSpineIndex(
    List<TocItem> toc,
    int targetSpineIndex,
  ) {
    for (int i = 0; i < toc.length; i++) {
      if (toc[i].spineIndex == targetSpineIndex) {
        return i;
      }
      // Check children recursively
      final childPos = _findFirstItemWithSpineIndex(
        toc[i].children,
        targetSpineIndex,
      );
      if (childPos >= 0) {
        // Found in child, but we need to insert at parent level
        // Insert before the parent that contains this child
        return i;
      }
    }
    return -1;
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
  final List<String> spine;
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
