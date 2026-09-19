import 'dart:io';

/// Represents an EPUB file that has been cached and hashed
///
/// This class encapsulates the result of processing a platform-specific
/// file path into a local cache file with a computed hash for deduplication.
class ImportableEpub {
  /// The cached file in the app's import cache directory
  final File cacheFile;

  /// SHA-256 hash of the file content for deduplication
  final String hash;

  /// The original file name from the source
  final String originalName;

  const ImportableEpub({
    required this.cacheFile,
    required this.hash,
    required this.originalName,
  });

  @override
  String toString() =>
      'ImportableEpub(originalName: $originalName, cacheFile: ${cacheFile.path}, hash: $hash)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportableEpub &&
          runtimeType == other.runtimeType &&
          cacheFile.path == other.cacheFile.path &&
          hash == other.hash &&
          originalName == other.originalName;

  @override
  int get hashCode => Object.hash(cacheFile.path, hash, originalName);

  /// Creates a copy with optional field replacements
  ImportableEpub copyWith({
    File? cacheFile,
    String? hash,
    String? originalName,
  }) {
    return ImportableEpub(
      cacheFile: cacheFile ?? this.cacheFile,
      hash: hash ?? this.hash,
      originalName: originalName ?? this.originalName,
    );
  }
}
