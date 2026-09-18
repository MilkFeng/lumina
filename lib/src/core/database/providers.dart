import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'lumina_database.dart';
import 'lumina_database_impl.dart';
import 'lumina_db.dart';

part 'providers.g.dart';

/// Provider for the database lifecycle abstraction
/// Use this to access the database throughout the app
@Riverpod(keepAlive: true)
LuminaDatabase luminaDatabase(Ref ref) {
  return LuminaDatabaseImpl();
}

/// Provider for the opened drift database
/// Convenience provider that returns the actual database instance
@Riverpod(keepAlive: true)
Future<LuminaDb> database(Ref ref) async {
  final database = ref.watch(luminaDatabaseProvider);
  return await database.getInstance();
}
