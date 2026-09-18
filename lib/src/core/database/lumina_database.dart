import 'lumina_db.dart';

/// Abstract interface for database operations.
/// This allows for dependency injection and testing with mocks.
abstract class LuminaDatabase {
  /// Get the opened drift database.
  /// Implementations should handle initialization and caching.
  Future<LuminaDb> getInstance();

  /// Close the database connection
  Future<void> close();
}
