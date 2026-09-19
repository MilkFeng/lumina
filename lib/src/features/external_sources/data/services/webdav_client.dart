import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../domain/external_source_item.dart';
import 'webdav_exception.dart';

/// How deep a `PROPFIND` should look.
enum WebDavDepth {
  /// Only the collection itself: enough to prove the URL, credentials and
  /// permissions are all usable.
  zero('0'),

  /// The collection plus its direct children.
  one('1');

  const WebDavDepth(this.headerValue);

  final String headerValue;
}

/// A minimal WebDAV client: just the verbs this app needs.
///
/// Deliberately not a general-purpose WebDAV library — the abstraction that
/// matters here is `ExternalSourceAdapter`, and a small client keeps the HTTP
/// details (Basic auth, `Depth`, `207 Multi-Status` parsing) in one reviewable
/// place.
class WebDavClient {
  WebDavClient({
    required this.baseUrl,
    this.basePath = '',
    this.username = '',
    this.password = '',
    this.timeout = const Duration(seconds: 20),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  /// Server root, for example `https://dav.example.com`.
  final String baseUrl;

  /// Collection inside [baseUrl]; empty means the server root.
  final String basePath;

  final String username;
  final String password;
  final Duration timeout;

  final http.Client _httpClient;
  final bool _ownsClient;

  /// Hard ceiling on a single download.
  ///
  /// A guard against a hostile or broken server filling the device: the app's
  /// own EPUB pipeline refuses entries above 50 MiB, so a file anywhere near
  /// this size is not a book this app could open anyway.
  static const int maxDownloadBytes = 512 * 1024 * 1024;

  static const String _propFindBody =
      '<?xml version="1.0" encoding="utf-8"?>'
      '<D:propfind xmlns:D="DAV:">'
      '<D:prop>'
      '<D:resourcetype/>'
      '<D:getcontentlength/>'
      '<D:getlastmodified/>'
      '</D:prop>'
      '</D:propfind>';

  /// Proves the source is reachable and usable.
  ///
  /// `PROPFIND Depth: 0` is the cheapest request that exercises the whole path
  /// a real listing takes: URL building, authentication and XML parsing.
  /// Throws a [WebDavException] when it fails.
  Future<void> testConnection() async {
    final uri = resolve('');
    final response = await _send('PROPFIND', uri, body: _propFindBody);
    // 207 is the only success status a PROPFIND may answer with.
    if (response.statusCode != 207) {
      throw WebDavStatusException(
        response.statusCode,
        response.reasonPhrase ?? '',
      );
    }
  }

  /// Lists the direct children of the collection at [path] (`''` is the source
  /// root).
  ///
  /// [path] may be written either way — `books` or `books/` — and is
  /// canonicalised to the trailing-slash form below. That is not cosmetic: a
  /// `PROPFIND` without the trailing slash addresses the resource as a plain
  /// member, which several servers answer with a redirect or a body that
  /// describes no children at all, so nested folders would appear not to exist.
  ///
  /// The collection itself is never part of the result, and directories come
  /// first.
  Future<List<ExternalSourceItem>> list([String path = '']) async {
    final collectionPath = _asCollectionPath(path);
    final uri = resolve(collectionPath);
    final response = await _send(
      'PROPFIND',
      uri,
      body: _propFindBody,
      depth: WebDavDepth.one,
    );

    if (response.statusCode != 207) {
      throw WebDavStatusException(
        response.statusCode,
        response.reasonPhrase ?? '',
      );
    }

    final items = parseMultiStatus(
      utf8.decode(response.bodyBytes, allowMalformed: true),
      // The absolute URLs of the collection that was listed and of the source
      // root. Response hrefs are absolute too, so all three only line up once
      // resolved.
      collectionUri: uri,
      sourceUri: resolve(''),
    );
    items.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }

  /// The form of [path] that addresses a collection: exactly one trailing
  /// slash, and none at all for the root.
  static String _asCollectionPath(String path) {
    final trimmed = path.replaceAll(RegExp(r'/+$'), '');
    return trimmed.isEmpty ? '' : '$trimmed/';
  }

  /// Streams the file at [path] into [target].
  ///
  /// Streamed rather than buffered: an EPUB is easily larger than is
  /// comfortable to hold in memory on a phone, and the import pipeline wants a
  /// file on disk anyway.
  Future<void> downloadTo(String path, File target) async {
    final uri = resolve(path);
    final request = http.Request('GET', uri);
    _authorize(request);

    final response = await _httpClient.send(request).timeout(timeout);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw WebDavAuthException(response.statusCode);
    }
    if (response.statusCode == 404) {
      throw const WebDavNotFoundException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavStatusException(
        response.statusCode,
        response.reasonPhrase ?? '',
      );
    }

    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > maxDownloadBytes) {
      throw const WebDavTooLargeException(maxDownloadBytes);
    }

    final sink = target.openWrite();
    var written = 0;
    try {
      await for (final chunk in response.stream) {
        written += chunk.length;
        if (written > maxDownloadBytes) {
          throw const WebDavTooLargeException(maxDownloadBytes);
        }
        sink.add(chunk);
      }
      await sink.flush();
    } finally {
      // Closing in `finally` keeps a failed or aborted download from leaking the
      // file handle; the partially written file is the caller's to delete.
      await sink.close();
    }
  }

  /// Releases the underlying HTTP client. A no-op when the caller supplied one.
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  /// Builds the absolute URI of [path] inside this source.
  ///
  /// Segments are percent-encoded with `encodeFull`, which leaves the
  /// sub-delimiters that are legal in a path untouched: a name like `My Book`
  /// or `图书.epub` survives, while `%`, `#` and `?` — the three characters
  /// that would otherwise corrupt the request — are escaped.
  Uri resolve(String path) {
    final root = baseUrl.trim();
    Uri parsed;
    try {
      parsed = Uri.parse(root);
    } on FormatException {
      throw WebDavInvalidUrlException(root);
    }
    if (!parsed.hasScheme || parsed.host.isEmpty) {
      throw WebDavInvalidUrlException(root);
    }

    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw WebDavInvalidUrlException(root);
    }

    final segments = <String>[
      ..._split(parsed.path),
      ..._split(basePath),
      ..._split(path),
    ];

    final isCollection = path.isEmpty || path.endsWith('/');
    // Exactly one separator, whether or not [segments] is empty: joining an
    // empty list would otherwise leave the root as `//`.
    //
    // `Uri.encodeComponent` rather than `Uri.encodeFull` because the result is
    // fed back through `Uri.parse`, which treats a literal `#` or `?` as a
    // delimiter and would cut the path short.
    final encodedPath =
        '/${segments.map(Uri.encodeComponent).join('/')}'
        '${isCollection && segments.isNotEmpty ? '/' : ''}';

    // The authority is rebuilt by hand so that user info, and any `@` or `:`
    // inside it, cannot leak into the path through `Uri.replace`.
    final authority = parsed.hasPort
        ? '${parsed.host}:${parsed.port}'
        : parsed.host;

    return Uri.parse('$scheme://$authority$encodedPath');
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    String? body,
    WebDavDepth? depth,
  }) async {
    final request = http.Request(method, uri);
    if (body != null) {
      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.bodyBytes = utf8.encode(body);
    }
    if (depth != null) {
      request.headers['Depth'] = depth.headerValue;
    }
    _authorize(request);

    final streamed = await _httpClient.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw WebDavAuthException(response.statusCode);
    }
    if (response.statusCode == 404) {
      throw const WebDavNotFoundException();
    }
    return response;
  }

  void _authorize(http.BaseRequest request) {
    if (username.isEmpty && password.isEmpty) return;
    final token = base64Encode(utf8.encode('$username:$password'));
    request.headers['Authorization'] = 'Basic $token';
  }

  static List<String> _split(String path) => path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  /// Parses a `207 Multi-Status` body into [ExternalSourceItem]s.
  ///
  /// [sourceUri] is the source's base URL — the root of the `relativePath`s a
  /// caller works with — and [collectionUri] is the absolute URL that was
  /// listed.
  ///
  /// Every `href` is made relative to [sourceUri] first, because that is the
  /// form callers navigate further with; the entry whose relative path equals
  /// the collection's own is then dropped, since a collection always describes
  /// itself first in the response.
  ///
  /// Namespace handling is intentionally lenient: elements are matched by local
  /// name across any namespace, because servers disagree about prefixes (`D:`,
  /// `d:`, `lp1:`, or none at all).
  static List<ExternalSourceItem> parseMultiStatus(
    String xml, {
    Uri? collectionUri,
    Uri? sourceUri,
  }) {
    XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException {
      throw const WebDavMalformedResponseException();
    }

    final sourcePath = _split(_decode(sourceUri?.path ?? '')).toList();
    // The collection is compared against entry paths *after* those have been
    // made source-relative, so its own path must be made source-relative too.
    // Without that step the two sides are only equal when the source has no
    // base path — which is the case that decides whether the root listing keeps
    // its entries or discards all of them.
    final collectionPath =
        _removePrefix(
          _split(_decode(collectionUri?.path ?? '')).join('/'),
          sourcePath,
        ) ??
        '';
    final items = <ExternalSourceItem>[];

    for (final response in document.findAllElements(
      'response',
      namespaceUri: '*',
    )) {
      final href = _firstText(response, 'href');
      if (href == null || href.isEmpty) continue;

      final path = _normalizePath(_decode(href));
      if (path.isEmpty) continue;

      final resourceType = response.findAllElements(
        'resourcetype',
        namespaceUri: '*',
      );
      final isDirectory = resourceType.any(
        (element) =>
            element.findAllElements('collection', namespaceUri: '*').isNotEmpty,
      );

      // Absolute server path → path relative to the source root. This is the
      // only form the caller can navigate further with, so it is what the item
      // carries. An entry that is not inside the source is not ours to show, so
      // `null` (rather than "empty") is what filters it out.
      final relative = _removePrefix(path, sourcePath);
      if (relative == null || relative.isEmpty) continue;

      // The listed collection describes itself first, and it is not a child of
      // itself. Compared against the collection's own source-relative path,
      // which is empty for the root — hence the `isDirectory` guard: without it
      // a root listing would discard every entry, since the root *is* the
      // collection. The comparison is exact, which keeps a sibling that merely
      // shares a name prefix (`books-old` next to `books`).
      if (isDirectory && relative == collectionPath) continue;

      final sizeText = _firstText(response, 'getcontentlength');
      final modifiedText = _firstText(response, 'getlastmodified');

      items.add(
        ExternalSourceItem(
          name: relative.split('/').last,
          path: relative,
          isDirectory: isDirectory,
          size: sizeText == null ? null : int.tryParse(sizeText.trim()),
          lastModified: modifiedText == null
              ? null
              : _parseHttpDate(modifiedText.trim()),
        ),
      );
    }

    return items;
  }

  /// Text of the first descendant with local name [name].
  static String? _firstText(XmlElement parent, String name) {
    final elements = parent.findAllElements(name, namespaceUri: '*');
    if (elements.isEmpty) return null;
    return elements.first.innerText;
  }

  /// Percent-decodes [value], leaving it untouched when it is not valid
  /// percent-encoding (some servers return raw paths).
  static String _decode(String value) {
    try {
      return Uri.decodeFull(value);
    } on ArgumentError {
      return value;
    }
  }

  /// Reduces a server-returned path to the `a/b/c` form used by
  /// [ExternalSourceItem.path].
  static String _normalizePath(String path) {
    var normalized = path;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      try {
        normalized = Uri.parse(normalized).path;
      } on FormatException {
        // Keep the raw value; it simply will not match a prefix.
      }
    }
    return normalized
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .join('/');
  }

  /// [path] with [prefix] removed, or `null` when [path] is not inside
  /// [prefix].
  ///
  /// Both sides are `/`-separated, source-relative paths. The comparison is
  /// segment-wise, so `books-old/x` is not treated as living inside `books`, and
  /// [path] being equal to [prefix] yields an empty string rather than a
  /// failure — which is how "this entry *is* the collection" is detected.
  static String? _removePrefix(String path, List<String> prefix) {
    if (prefix.isEmpty) return path;

    final segments = path.split('/');
    if (segments.length < prefix.length) return null;

    for (var index = 0; index < prefix.length; index++) {
      if (segments[index] != prefix[index]) return null;
    }
    return segments.sublist(prefix.length).join('/');
  }

  /// Parses the two date formats servers actually send, or returns `null`.
  ///
  /// A date is never critical to a listing, so an unparseable one is dropped
  /// rather than failing the whole response.
  static DateTime? _parseHttpDate(String value) {
    // RFC 1123, the format RFC 4918 asks for:
    // "Wed, 21 Oct 2015 07:28:00 GMT".
    try {
      return HttpDate.parse(value);
    } catch (_) {
      // Fall through to the format some servers emit instead.
    }

    // ISO 8601 with a UTC offset, e.g. "2015-10-21T07:28:00Z".
    return DateTime.tryParse(value);
  }
}
