/// Enumeration of supported book formats
enum BookType {
  /// EPUB format - flowing HTML/XML content
  epub,

  /// PDF format - fixed-page documents
  pdf;

  /// Convert enum to string representation
  String toJson() {
    switch (this) {
      case BookType.epub:
        return 'epub';
      case BookType.pdf:
        return 'pdf';
    }
  }

  /// Parse string to BookType enum
  static BookType fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'epub':
        return BookType.epub;
      case 'pdf':
        return BookType.pdf;
      default:
        return BookType.epub; // Default fallback
    }
  }
}