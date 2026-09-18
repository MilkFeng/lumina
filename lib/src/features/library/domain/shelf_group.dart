/// Folder-like grouping for organizing shelf books.
/// Uses a flat structure (no nesting) with UUID-based sync.
class ShelfGroup {
  /// Primary key. `0` means "not persisted yet"; the database assigns the real
  /// id on insert.
  int id = 0;

  /// Display name for the folder
  String name = '';

  /// Timestamp when the folder was created (milliseconds since epoch)
  int creationDate = 0;

  /// Last update timestamp (milliseconds since epoch)
  int updatedAt = 0;

  /// Soft delete flag for sync safety
  bool isDeleted = false;
}
