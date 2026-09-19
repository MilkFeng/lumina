import 'package:isar_community/isar.dart';
import 'package:lumina/src/core/database/isar_database.dart';
import 'package:lumina/src/core/database/isar_database_impl.dart';
import 'package:lumina/src/features/external_sources/data/services/external_source_credentials_store.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/features/library/domain/shelf_group.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Assembly-layer providers: the handful of things that inherently have to name
/// more than one feature.
///
/// They live at the `src/` root next to `app.dart` and `router.dart` for the
/// same reason those do — a database schema list and a keychain-backed
/// credential store span features, and putting them inside any single feature
/// would make that feature import the others.

/// Provider for the [IsarDatabase] interface.
///
/// **This is where collections get registered.** A new `@collection` class that
/// is not listed in [appDatabaseSchemas] will silently not persist.
@Riverpod(keepAlive: true)
IsarDatabase isarDatabase(Ref ref) {
  return IsarDatabaseImpl(schemas: appDatabaseSchemas);
}

/// Every Isar collection the app opens.
const List<CollectionSchema<dynamic>> appDatabaseSchemas = [
  ShelfBookSchema, // Lightweight UI entity
  ShelfGroupSchema, // Folder/group entity
  BookManifestSchema, // Heavy reader entity
  ExternalSourceSchema, // External book source (WebDAV, …)
];

/// Provider for the live [Isar] instance.
@Riverpod(keepAlive: true)
Future<Isar> isar(Ref ref) async {
  final database = ref.watch(isarDatabaseProvider);
  return await database.getInstance();
}

/// Provider for the secure store holding external source passwords.
///
/// Declared here so that tests can swap the keychain out; the feature itself
/// only depends on the store's own class.
@Riverpod(keepAlive: true)
ExternalSourceCredentialsStore externalSourceCredentialsStore(Ref ref) {
  return ExternalSourceCredentialsStore();
}
