import 'package:drift/drift.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';

import 'converters.dart';

part 'lumina_db.g.dart';

// =============================================================================
// Tables
//
// The table classes live in the same library as the database so that the
// generated `part` file resolves the column types directly.
// =============================================================================

/// SQLite table backing the lightweight shelf entity used by the library UI.
///
/// Mirrors the previous Isar collection: only metadata and reading progress,
/// while the EPUB itself stays compressed on disk.
@DataClassName('ShelfBookRow')
class ShelfBooks extends Table {
  /// Auto-increment primary key. Kept as [IntColumn] so existing ids stay valid
  /// when a row is updated through [ShelfBookRow].
  IntColumn get id => integer().autoIncrement()();

  /// SHA-256 hash of the original EPUB file (unique identifier).
  TextColumn get fileHash => text().unique()();

  // ==================== PATHS ====================

  /// Absolute path to the compressed .epub file.
  /// Null while a synced book is still waiting for download.
  TextColumn get filePath => text().nullable()();

  /// Absolute path to the extracted cover image.
  TextColumn get coverPath => text().nullable()();

  // ==================== METADATA ====================

  TextColumn get title => text()();

  TextColumn get author => text()();

  /// All authors as a JSON array.
  TextColumn get authors => text().map(const StringListConverter())();

  TextColumn get description => text().nullable()();

  /// Subject tags/genres as a JSON array.
  TextColumn get subjects => text().map(const StringListConverter())();

  IntColumn get totalChapters => integer()();

  TextColumn get epubVersion => text()();

  /// Import timestamp (milliseconds since epoch).
  IntColumn get importDate => integer()();

  /// Reading direction from the spine: 0 = LTR, 1 = RTL.
  IntColumn get direction => integer()();

  // ==================== READING PROGRESS ====================

  IntColumn get currentChapterIndex =>
      integer().withDefault(const Constant(0))();

  /// Overall reading progress (0.0 to 1.0).
  RealColumn get readingProgress => real()();

  /// Scroll position within the current chapter (0.0 to 1.0).
  RealColumn get chapterScrollPosition => real().nullable()();

  /// Last time the book was opened (milliseconds since epoch).
  IntColumn get lastOpenedDate => integer().nullable()();

  BoolColumn get isFinished => boolean().withDefault(const Constant(false))();

  // ==================== BOOKSHELF MANAGEMENT ====================

  /// Group name for organizing books; null means root level.
  TextColumn get groupName => text().nullable()();

  /// Soft delete flag (for trash/sync safety).
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // ==================== SYNC ====================

  /// Last modification timestamp (milliseconds since epoch).
  IntColumn get updatedAt => integer()();

  /// Sync status: null = never synced, timestamp = last sync time.
  IntColumn get lastSyncedDate => integer().nullable()();
}

/// SQLite table backing the flat, non-nested shelf groups.
@DataClassName('ShelfGroupRow')
class ShelfGroups extends Table {
  /// Auto-increment primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Display name for the folder.
  TextColumn get name => text().unique()();

  /// Creation timestamp (milliseconds since epoch).
  IntColumn get creationDate => integer()();

  /// Last update timestamp (milliseconds since epoch).
  IntColumn get updatedAt => integer()();

  /// Soft delete flag for sync safety.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// SQLite table backing the heavy reader entity: the complete EPUB structure
/// (spine, TOC, manifest) needed for navigation.
@DataClassName('BookManifestRow')
class BookManifests extends Table {
  /// Auto-increment primary key.
  IntColumn get id => integer().autoIncrement()();

  /// SHA-256 hash of the original EPUB file, linking back to `ShelfBooks`.
  TextColumn get fileHash => text().unique()();

  // ==================== EPUB STRUCTURE ====================

  /// Path to the OPF file within the ZIP, e.g. `OEBPS/content.opf`.
  TextColumn get opfRootPath => text()();

  /// Linear reading order from the OPF spine, stored as a JSON array.
  TextColumn get spine => text().map(const SpineListConverter())();

  /// Nested navigation tree parsed from NCX (EPUB 2) or NAV (EPUB 3),
  /// stored as a JSON array.
  TextColumn get toc => text().map(const TocListConverter())();

  /// Manifest entries (id → resource path) used for CSS/image/font resolution,
  /// stored as a JSON array.
  TextColumn get manifest => text().map(const ManifestListConverter())();

  // ==================== METADATA ====================

  /// EPUB version, e.g. `2.0` or `3.0`.
  TextColumn get epubVersion => text()();

  /// Timestamp when the manifest was last updated.
  DateTimeColumn get lastUpdated => dateTime()();
}

// =============================================================================
// Database
// =============================================================================

/// The generated drift database backing every persisted Lumina entity.
///
/// Use [LuminaDatabaseImpl] (see `lumina_database.dart`) to open it inside the
/// app; pass an in-memory [QueryExecutor] in tests.
@DriftDatabase(tables: [ShelfBooks, ShelfGroups, BookManifests])
class LuminaDb extends _$LuminaDb {
  LuminaDb(super.e);

  @override
  int get schemaVersion => 1;
}
