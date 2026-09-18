/// Lightweight entity for UI display and sync operations.
/// Contains only essential metadata and reading progress.
/// Uses "stream-from-zip" strategy: EPUB remains compressed on disk.
class ShelfBook {
  /// Primary key. `0` means "not persisted yet"; the database assigns the real
  /// id on insert.
  int id = 0;

  /// SHA-256 hash of the original EPUB file (unique identifier)
  String fileHash = '';

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
  String title = '';

  /// Primary author (first author if multiple)
  String author = '';

  /// All authors as a list
  List<String> authors = [];

  /// Book description/summary
  String? description;

  /// Subject tags/genres
  List<String> subjects = [];

  /// Total number of chapters/navigation points
  int totalChapters = 0;

  /// EPUB version (e.g., "2.0", "3.0")
  String epubVersion = '';

  /// Timestamp when book was imported (milliseconds since epoch)
  int importDate = 0;

  /// Reading direction (from spine "page-progression-direction" attribute)
  /// Possible values: "ltr" (left-to-right), "rtl" (right-to-left)
  /// LTR = 0, RTL = 1 for easier handling in the reader
  int direction = 0;

  // ==================== READING PROGRESS ====================

  /// Current chapter index (0-based, flattened spine order)
  int currentChapterIndex = 0;

  /// Overall reading progress (0.0 to 1.0)
  double readingProgress = 0.0;

  /// Scroll position within current chapter (0.0 to 1.0)
  double? chapterScrollPosition = 0.0;

  /// Last time the book was opened (milliseconds since epoch)
  int? lastOpenedDate;

  /// Whether the book has been marked as finished
  bool isFinished = false;

  // ==================== BOOKSHELF MANAGEMENT ====================

  /// Group name for organizing books (replaces groupId)
  /// Null means root level
  String? groupName;

  /// Soft delete flag (for trash/sync safety)
  bool isDeleted = false;

  // ==================== SYNC ====================

  /// Last modification timestamp (milliseconds since epoch, for conflict resolution)
  int updatedAt = 0;

  /// Sync status: null = not synced, timestamp = last sync time
  int? lastSyncedDate;

  // ==================== UI STATE (NOT PERSISTED) ====================

  /// Whether the book is currently being downloaded (transient UI state)
  bool isDownloading = false;
}

String directionToString(int direction) {
  switch (direction) {
    case 1:
      return 'RTL';
    case 0:
    default:
      return 'LTR';
  }
}
