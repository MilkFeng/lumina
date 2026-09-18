import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'isar_database.dart';
import 'isar_database_impl.dart';

part 'providers.g.dart';

/// Provider for IsarDatabase interface
/// Use this to access the database throughout the app
@Riverpod(keepAlive: true)
IsarDatabase isarDatabase(IsarDatabaseRef ref) {
  return IsarDatabaseImpl();
}

/// Provider for Isar instance
/// Convenience provider that returns the actual Isar instance
@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  final database = ref.watch(isarDatabaseProvider);
  return await database.getInstance();
}
