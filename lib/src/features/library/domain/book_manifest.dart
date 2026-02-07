import 'package:isar/isar.dart';

part 'book_manifest.g.dart';

/// Heavy Isar collection for the reading engine.
/// Contains complete EPUB structure (spine, TOC) for navigation.
/// Only queried when opening the reader.
@collection
class BookManifest {
  /// Auto-increment primary key
  Id id = Isar.autoIncrement;

  /// SHA-256 hash of the original EPUB file (unique identifier, links to ShelfBook)
  @Index(unique: true)
  late String fileHash;

  // ==================== EPUB STRUCTURE ====================

  /// Path to the OPF file within the ZIP
  /// e.g., "OEBPS/content.opf" or "content.opf"
  late String opfRootPath;

  /// Ordered list of content file paths (from spine element)
  /// Each entry is a path relative to the OPF root directory
  /// e.g., ["chapter1.xhtml", "chapter2.xhtml", ...]
  late List<String> spine;

  /// Table of Contents structure (nested navigation)
  /// Parsed from NCX (EPUB 2.0) or NAV document (EPUB 3.0)
  late List<TocItem> toc;

  /// Manifest map entries (id -> file path)
  /// Used for resource resolution (CSS, images, fonts)
  late List<ManifestItem> manifest;

  // ==================== METADATA ====================

  /// EPUB version (e.g., "2.0", "3.0")
  late String epubVersion;

  /// Timestamp when manifest was last updated
  late DateTime lastUpdated;
}

/// Embedded object representing a file reference with optional anchor
@embedded
class Href {
  /// File path relative to OPF root
  late String path;

  /// Optional anchor (e.g., "chapter1.xhtml#section2")
  String? anchor;
}

/// Embedded object representing a single manifest entry
@embedded
class ManifestItem {
  /// Item ID (referenced by spine)
  late String id;

  /// File path relative to OPF root
  late Href href;

  /// Media type (e.g., "application/xhtml+xml", "image/jpeg")
  late String mediaType;

  /// Properties (EPUB 3.0 only, e.g., "cover-image", "nav")
  String? properties;
}

/// Embedded object representing a TOC navigation point
/// Supports nested structure for hierarchical chapters
@embedded
class TocItem {
  /// Display label (e.g., "Chapter 1: Introduction")
  late String label;

  /// Content file path (with optional anchor)
  /// e.g., "chapter1.xhtml" or "chapter1.xhtml#section2"
  late Href href;

  /// Nesting level (0 = top level, 1 = first nested, etc.)
  late int depth;

  /// Index in the spine (for navigation and gap detection)
  /// -1 means not found in spine
  int spineIndex = -1;

  /// Nested sub-items (for hierarchical TOC)
  late List<TocItem> children;

  List<TocItem> flatten() {
    final result = <TocItem>[];
    if (href.path.isNotEmpty) {
      result.add(this);
    }
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }

  List<TocItem> safeFlatten() {
    final result = <TocItem>[this];
    for (final child in children) {
      result.addAll(child.safeFlatten());
    }
    return result;
  }
}
