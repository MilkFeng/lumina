/// One entry inside an external source.
///
/// Source-agnostic: the WebDAV adapter maps a `<D:response>` block onto it, and
/// any future adapter maps whatever its protocol returns. Paths are relative to
/// the source's own base path (see `WebDavConfig.basePath`) so that callers
/// never have to know how a particular protocol addresses a file.
class ExternalSourceItem {
  const ExternalSourceItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.lastModified,
  });

  /// Last segment of [path]; what a list row shows.
  final String name;

  /// Path relative to the source root, `/`-separated.
  final String path;

  /// Whether the entry is a collection (WebDAV: `<D:collection/>`).
  final bool isDirectory;

  /// Size in bytes when the server reported one.
  final int? size;

  /// Server-reported modification time, when it could be parsed.
  final DateTime? lastModified;

  /// Whether this entry looks like an EPUB file.
  bool get isEpub => !isDirectory && name.toLowerCase().endsWith('.epub');
}
