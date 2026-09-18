/// Heavy entity for the reading engine.
/// Contains complete EPUB structure (spine, TOC) for navigation.
/// Only loaded when opening the reader.
class BookManifest {
  /// Primary key. `0` means "not persisted yet"; the database assigns the real
  /// id on insert.
  int id = 0;

  /// SHA-256 hash of the original EPUB file (unique identifier, links to ShelfBook)
  String fileHash = '';

  // ==================== EPUB STRUCTURE ====================

  /// Path to the OPF file within the ZIP
  /// e.g., "OEBPS/content.opf" or "content.opf"
  String opfRootPath = '';

  /// Linear reading order (from spine element in OPF)
  /// Determines sequential navigation (Next/Previous page logic)
  /// Each item contains the complete spine metadata
  List<SpineItem> spine = [];

  /// Table of Contents structure (nested navigation tree)
  /// Parsed from NCX (EPUB 2.0) or NAV document (EPUB 3.0)
  /// Pure hierarchical navigation - does NOT need to cover every spine item
  /// Each TocItem points to a specific location (href + anchor) and references
  /// a spineIndex for quick lookup and progress tracking
  List<TocItem> toc = [];

  /// Manifest map entries (id -> file path)
  /// Used for resource resolution (CSS, images, fonts)
  List<ManifestItem> manifest = [];

  // ==================== METADATA ====================

  /// EPUB version (e.g., "2.0", "3.0")
  String epubVersion = '';

  /// Timestamp when manifest was last updated
  late DateTime lastUpdated;
}

/// Embedded object representing a single spine entry
/// Spine defines the linear reading order (Next/Previous navigation)
class SpineItem {
  /// Sequential order in the spine (0-based)
  int index;

  /// Relative path to the content resource (e.g., "text/chap1.xhtml")
  /// Path is relative to OPF root directory
  String href;

  /// ID reference from the OPF manifest
  /// Links this spine item to a manifest entry
  String idref;

  /// Linear reading flag (from EPUB spine itemref "linear" attribute)
  /// If false, content is auxiliary (e.g., footnotes) and should be skipped
  /// during sequential navigation. Defaults to true.
  bool linear;

  /// Optional properties (e.g., "duokan-page-fitwindow")
  String? properties;

  SpineItem({
    this.index = 0,
    this.href = '',
    this.idref = '',
    this.linear = true,
    this.properties,
  });
}

/// Embedded object representing a file reference with optional anchor
class Href {
  /// File path relative to OPF root
  late String path;

  /// Optional anchor (e.g., "chapter1.xhtml#section2")
  String anchor = 'top';

  @override
  bool operator ==(Object other) {
    return other is Href && other.path == path && other.anchor == anchor;
  }

  @override
  int get hashCode {
    return Object.hash(path, anchor);
  }

  @override
  String toString() {
    return '$path#$anchor';
  }
}

/// Embedded object representing a single manifest entry
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
/// Represents a pure navigation tree entry - NOT every spine item needs a TocItem
/// Used exclusively for rendering the navigation drawer/menu
class TocItem {
  /// Unique ID for this TOC item
  /// Used for identification and state management
  late int id;

  /// Display label (e.g., "Chapter 1: Introduction")
  late String label;

  /// Content file path with optional anchor
  /// e.g., "chapter1.xhtml" or "chapter1.xhtml#section2"
  /// This href can point anywhere in the book, including mid-chapter locations
  late Href href;

  /// Nesting level (0 = top level, 1 = first nested, etc.)
  late int depth;

  /// Index in the spine list for quick lookup and progress tracking
  /// Used to map TOC entries to sequential reading positions
  /// -1 means the href doesn't correspond to a spine item start (e.g., deep link)
  int spineIndex = -1;

  /// Parent TOC item ID (-1 for top-level items)
  late int parentId;

  /// Nested sub-items (for hierarchical TOC)
  List<TocItem> children = [];

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
