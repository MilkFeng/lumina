import 'package:isar_community/isar.dart';
import 'package:lumina/src/core/database/isar_database.dart';
import 'package:lumina/src/core/database/isar_database_impl.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/features/library/domain/shelf_group.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'isar_providers.g.dart';

/// Provider for the [IsarDatabase] interface.
///
/// **This is where collections get registered.** The schema list lives here
/// rather than in `core/` because the entities belong to features; a new
/// `@collection` class must be added to [_schemas] or it will silently not
/// persist.
@Riverpod(keepAlive: true)
IsarDatabase isarDatabase(Ref ref) {
  return IsarDatabaseImpl(schemas: _schemas);
}

/// Every Isar collection the app opens.
const List<CollectionSchema<dynamic>> _schemas = [
  ShelfBookSchema, // Lightweight UI entity
  ShelfGroupSchema, // Folder/group entity
  BookManifestSchema, // Heavy reader entity
];

/// Provider for the live [Isar] instance.
@Riverpod(keepAlive: true)
Future<Isar> isar(Ref ref) async {
  final database = ref.watch(isarDatabaseProvider);
  return await database.getInstance();
}
