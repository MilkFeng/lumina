import 'package:isar/isar.dart';

part 'shelf_book.g.dart';

/// Lightweight Isar collection for UI display and sync operations.
/// Contains only essential metadata and reading progress.
/// Uses "stream-from-zip" strategy: EPUB remains compressed on disk.
@collection
class ShelfBook {
  /// Auto-increment primary key
  Id id = Isar.autoIncrement;

  /// SHA-256 hash of the original EPUB file (unique identifier)
  @Index(unique: true)
  late String fileHash;

  // ==================== PATHS ====================

  /// Absolute path to the compressed .epub file
  /// e.g., "/books/{fileHash}.epub"
  /// Can be null during sync (waiting for download)
  String? filePath;

  /// Absolute path to the extracted cover image
  /// e.g., "/covers/{fileHash}.jpg"
  /// Can be null during sync (waiting for generation)
  String? coverPath;

  // ==================== METADATA ====================

  /// Book title
  @Index()
  late String title;

  /// Primary author (first author if multiple)
  @Index()
  late String author;

  /// All authors as a list
  late List<String> authors;

  /// Book description/summary
  String? description;

  /// Subject tags/genres
  late List<String> subjects;

  /// Total number of chapters/navigation points
  late int totalChapters;

  /// EPUB version (e.g., "2.0", "3.0")
  late String epubVersion;

  /// Timestamp when book was imported (milliseconds since epoch)
  @Index()
  late int importDate;

  /// Reading direction (from spine "page-progression-direction" attribute)
  /// Possible values: "ltr" (left-to-right), "rtl" (right-to-left)
  /// LTR = 0, RTL = 1 for easier handling in the reader
  late int direction;

  // ==================== READING PROGRESS ====================

  /// Current chapter index (0-based, flattened spine order)
  @Index()
  int currentChapterIndex = 0;

  /// Overall reading progress (0.0 to 1.0)
  @Index()
  double readingProgress = 0.0;

  /// Scroll position within current chapter (0.0 to 1.0)
  double? chapterScrollPosition = 0.0;

  /// Last time the book was opened (milliseconds since epoch)
  @Index()
  int? lastOpenedDate;

  /// Whether the book has been marked as finished
  bool isFinished = false;

  // ==================== BOOKSHELF MANAGEMENT ====================

  /// Group name for organizing books (replaces groupId)
  /// Null means root level
  @Index()
  String? groupName;

  /// Soft delete flag (for trash/sync safety)
  @Index()
  bool isDeleted = false;

  // ==================== SYNC ====================

  /// Last modification timestamp (milliseconds since epoch, for conflict resolution)
  @Index()
  late int updatedAt;

  /// Sync status: null = not synced, timestamp = last sync time
  int? lastSyncedDate;

  // ==================== UI STATE (NOT SYNCED) ====================

  /// Whether the book is currently being downloaded (transient UI state)
  @ignore
  bool isDownloading = false;
}
