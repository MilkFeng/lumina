import 'package:isar/isar.dart';

part 'shelf_group.g.dart';

/// Folder-like grouping for organizing shelf books.
/// Now uses flat structure (no nesting) with UUID-based sync.
@collection
class ShelfGroup {
  /// Auto-increment primary key
  Id id = Isar.autoIncrement;

  /// Display name for the folder
  @Index(unique: true)
  late String name;

  /// Timestamp when the folder was created (milliseconds since epoch)
  @Index()
  late int creationDate;

  /// Last update timestamp (milliseconds since epoch)
  @Index()
  late int updatedAt;

  /// Soft delete flag for sync safety
  @Index()
  bool isDeleted = false;
}
