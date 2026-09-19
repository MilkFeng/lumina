import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumina/src/features/external_sources/data/adapters/webdav_config_codec.dart';
import 'package:lumina/src/features/external_sources/data/services/webdav_client.dart';
import 'package:lumina/src/features/external_sources/data/services/webdav_exception.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_type.dart';
import 'package:lumina/src/features/external_sources/domain/webdav_config.dart';

/// Unit tests for the external sources data layer.
///
/// The pure parts — URL building, `207 Multi-Status` parsing and configuration
/// serialisation — need nothing behind them. Downloading is covered against a
/// canned HTTP layer and a temporary directory, so it stays hermetic too: no
/// database, no keychain, no network.
void main() {
  group('WebDavClient.resolve', () {
    test('appends a trailing slash for a collection', () {
      final client = WebDavClient(baseUrl: 'https://dav.example.com');

      expect(client.resolve('').toString(), 'https://dav.example.com/');
      expect(
        client.resolve('books/').toString(),
        'https://dav.example.com/books/',
      );
    });

    test('keeps a file path free of a trailing slash', () {
      final client = WebDavClient(baseUrl: 'https://dav.example.com');

      expect(
        client.resolve('books/book.epub').toString(),
        'https://dav.example.com/books/book.epub',
      );
    });

    test('joins base path and path with single separators', () {
      final client = WebDavClient(
        baseUrl: 'https://dav.example.com/',
        basePath: 'remote.php/dav/files/me',
      );

      expect(
        client.resolve('books/book.epub').toString(),
        'https://dav.example.com/remote.php/dav/files/me/books/book.epub',
      );
    });

    test('percent-encodes characters that would corrupt the request', () {
      final client = WebDavClient(baseUrl: 'https://dav.example.com');

      expect(
        client.resolve('books/50% off #1?.epub').toString(),
        'https://dav.example.com/books/50%25%20off%20%231%3F.epub',
      );
    });

    test('percent-encodes a non-ASCII name for the wire', () {
      final client = WebDavClient(baseUrl: 'https://dav.example.com');

      final uri = client.resolve('books/图书.epub');

      // The request line carries UTF-8 percent-encoding, and the path can be
      // decoded back to the original name.
      expect(
        uri.toString(),
        'https://dav.example.com/books/%E5%9B%BE%E4%B9%A6.epub',
      );
      expect(Uri.decodeFull(uri.path), '/books/图书.epub');
    });

    test('preserves an explicit port', () {
      final client = WebDavClient(baseUrl: 'http://192.168.1.5:8080');

      expect(
        client.resolve('books/').toString(),
        'http://192.168.1.5:8080/books/',
      );
    });

    test('rejects a URL without a scheme or host', () {
      expect(
        () => WebDavClient(baseUrl: 'dav.example.com').resolve(''),
        throwsA(isA<WebDavInvalidUrlException>()),
      );
      expect(
        () => WebDavClient(baseUrl: 'ftp://dav.example.com').resolve(''),
        throwsA(isA<WebDavInvalidUrlException>()),
      );
    });
  });

  group('WebDavClient.parseMultiStatus', () {
    // A Nextcloud-shaped body: namespaced elements, an absolute href for the
    // collection itself, and one of each child kind.
    const body = '''
<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/remote.php/dav/files/me/books/</d:href>
    <d:propstat>
      <d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/files/me/books/Sub%20Folder/</d:href>
    <d:propstat>
      <d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/files/me/books/My%20Book.epub</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:getcontentlength>12345</d:getcontentlength>
        <d:getlastmodified>Wed, 21 Oct 2015 07:28:00 GMT</d:getlastmodified>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/files/me/books/notes.txt</d:href>
    <d:propstat>
      <d:prop><d:resourcetype/><d:getcontentlength>7</d:getcontentlength></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';

    // The `books` collection as the source root, which is what the hrefs below
    // are absolute against — exactly the pairing a real `PROPFIND` produces.
    final sourceUri = Uri.parse(
      'https://dav.example.com/remote.php/dav/files/me/books/',
    );
    final collectionUri = Uri.parse(
      'https://dav.example.com/remote.php/dav/files/me/books/',
    );

    test('drops the collection itself and keeps its children', () {
      final items = WebDavClient.parseMultiStatus(
        body,
        collectionUri: collectionUri,
        sourceUri: sourceUri,
      );

      expect(items.map((item) => item.path), [
        'Sub Folder',
        'My Book.epub',
        'notes.txt',
      ]);
    });

    test('percent-decodes hrefs and names entries by their last segment', () {
      final items = WebDavClient.parseMultiStatus(
        body,
        collectionUri: collectionUri,
        sourceUri: sourceUri,
      );

      final file = items.firstWhere((item) => item.isEpub);
      expect(file.name, 'My Book.epub');
      expect(file.size, 12345);
      expect(file.lastModified, DateTime.utc(2015, 10, 21, 7, 28));
      expect(
        items.firstWhere((item) => item.name == 'Sub Folder').isDirectory,
        isTrue,
      );
      expect(
        items.firstWhere((item) => item.name == 'notes.txt').isEpub,
        isFalse,
      );
    });

    test('handles a body without namespace prefixes', () {
      const plain = '''
<multistatus>
  <response>
    <href>/books/</href>
    <propstat><prop><resourcetype><collection/></resourcetype></prop></propstat>
  </response>
  <response>
    <href>/books/plain.epub</href>
    <propstat><prop><resourcetype/><getcontentlength>10</getcontentlength></prop></propstat>
  </response>
</multistatus>
''';

      final items = WebDavClient.parseMultiStatus(
        plain,
        collectionUri: Uri.parse('https://dav.example.com/books/'),
        sourceUri: Uri.parse('https://dav.example.com/books/'),
      );

      expect(items.single.path, 'plain.epub');
      expect(items.single.size, 10);
    });

    test('keeps a sibling whose name shares the collection prefix', () {
      const sibling = '''
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/books-old/other.epub</d:href>
    <d:propstat><d:prop><d:resourcetype/></d:prop></d:propstat>
  </d:response>
</d:multistatus>
''';

      // The collection was /books/, so /books-old/other.epub is not a child and
      // must not be reported as one.
      final items = WebDavClient.parseMultiStatus(
        sibling,
        collectionUri: Uri.parse('https://dav.example.com/books/'),
        sourceUri: Uri.parse('https://dav.example.com/books/'),
      );

      expect(items, isEmpty);
    });

    test('lists the server root when no collection was given', () {
      const root = '''
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/a.epub</d:href>
    <d:propstat><d:prop><d:resourcetype/></d:prop></d:propstat>
  </d:response>
</d:multistatus>
''';

      final items = WebDavClient.parseMultiStatus(root);

      expect(items.single.path, 'a.epub');
    });

    test('reports unreadable XML as a malformed response', () {
      expect(
        () => WebDavClient.parseMultiStatus('<not-xml'),
        throwsA(isA<WebDavMalformedResponseException>()),
      );
    });
  });

  group('WebDavClient.downloadTo', () {
    late Directory cacheDir;

    setUp(() async {
      cacheDir = await Directory.systemTemp.createTemp('lumina_webdav_test_');
    });

    tearDown(() async {
      if (cacheDir.existsSync()) await cacheDir.delete(recursive: true);
    });

    /// A client whose `GET` answers with [chunks], declaring [declaredLength] as
    /// the `Content-Length` (`null` for a server that declares none).
    WebDavClient clientServing(
      List<List<int>> chunks, {
      int? declaredLength,
    }) {
      return WebDavClient(
        baseUrl: 'https://dav.example.com',
        httpClient: MockClient.streaming(
          (request, bodyStream) async => http.StreamedResponse(
            Stream.fromIterable(chunks),
            200,
            contentLength: declaredLength,
          ),
        ),
      );
    }

    File target() => File('${cacheDir.path}/book.epub');

    test('reports the bytes received after every chunk', () async {
      final ticks = <(int, int?)>[];
      final client = clientServing([
        List.filled(3, 0x41),
        List.filled(4, 0x42),
      ], declaredLength: 7);

      await client.downloadTo(
        'books/book.epub',
        target(),
        onProgress: (received, total) => ticks.add((received, total)),
      );

      expect(ticks, [(3, 7), (7, 7)]);
      expect(await target().length(), 7);
    });

    test('reports a null total when no length was declared', () async {
      final ticks = <(int, int?)>[];
      final client = clientServing([
        List.filled(5, 0x41),
      ]);

      await client.downloadTo(
        'books/book.epub',
        target(),
        onProgress: (received, total) => ticks.add((received, total)),
      );

      // A chunked response: the caller still gets the running total, and still
      // gets the file.
      expect(ticks, [(5, null)]);
      expect(await target().length(), 5);
    });

    test('downloads when no one is listening for progress', () async {
      final client = clientServing([
        List.filled(2, 0x41),
      ], declaredLength: 2);

      await client.downloadTo('books/book.epub', target());

      expect(await target().length(), 2);
    });
  });

  group('WebDavConfigCodec', () {
    const codec = WebDavConfigCodec();

    test('declares the WebDAV type', () {
      expect(codec.type, ExternalSourceType.webdav);
    });

    test('never stores the password', () {
      const draft = WebDavConfigDraft(
        baseUrl: 'https://dav.example.com',
        basePath: '/books/',
        username: 'reader',
        password: 'hunter2',
      );

      final json = codec.encode(draft);

      expect(json, isNot(contains('hunter2')));
      expect(json, contains('reader'));
      // The path is normalised on the way out.
      expect(json, contains('"basePath":"books"'));
    });

    test('round-trips a configuration through JSON', () {
      const draft = WebDavConfigDraft(
        baseUrl: 'https://dav.example.com',
        basePath: 'books',
        username: 'reader',
      );

      final config = codec.decode(codec.encode(draft));

      expect(config, isA<WebDavConfig>());
      final webdav = config as WebDavConfig;
      expect(webdav.baseUrl, 'https://dav.example.com');
      expect(webdav.basePath, 'books');
      expect(webdav.username, 'reader');
    });

    test('rebuilds a draft with the password handed back in', () {
      const config = WebDavConfig(baseUrl: 'https://dav.example.com');

      final draft = codec.draftFrom(config, secrets: {'password': 'hunter2'});

      expect(draft, isA<WebDavConfigDraft>());
      expect((draft as WebDavConfigDraft).password, 'hunter2');
      expect(draft.secretKeys, ['password']);
    });

    test('rejects JSON that is not a WebDAV configuration object', () {
      expect(() => codec.decode('[]'), throwsA(isA<FormatException>()));
    });

    test('normalises a user-typed path', () {
      expect(WebDavConfigDraft.normalizeBasePath('  //books//  '), 'books');
      expect(WebDavConfigDraft.normalizeBasePath('a/b/'), 'a/b');
      expect(WebDavConfigDraft.normalizeBasePath(''), '');
    });

    test('is incomplete without a server URL', () {
      expect(const WebDavConfigDraft().isComplete, isFalse);
      expect(const WebDavConfigDraft(baseUrl: '  ').isComplete, isFalse);
      expect(
        const WebDavConfigDraft(baseUrl: 'https://dav.example.com').isComplete,
        isTrue,
      );
    });
  });
}
