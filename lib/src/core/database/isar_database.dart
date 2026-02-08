/// Abstract interface for Isar database operations
/// This allows for dependency injection and testing with mocks
abstract class IsarDatabase {
  /// Get the Isar instance
  /// Implementations should handle initialization and caching
  Future<dynamic> getInstance();

  /// Close the database connection
  Future<void> close();
}
