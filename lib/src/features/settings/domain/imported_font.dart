/// Represents a user-imported font file stored in the app's fonts directory.
class ImportedFont {
  /// The file name including extension, e.g. "MyFont.ttf".
  final String fileName;

  const ImportedFont({required this.fileName});

  /// Human-readable display name derived from the file name (extension stripped).
  String get displayName {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return fileName;
    return fileName.substring(0, dot);
  }

  factory ImportedFont.fromFileName(String fileName) =>
      ImportedFont(fileName: fileName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportedFont && other.fileName == fileName);

  @override
  int get hashCode => fileName.hashCode;
}
