import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lumina/src/features/external_sources/application/external_source_browser_notifier.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';
import 'package:lumina/src/features/external_sources/data/repositories/external_source_repository.dart';
import 'package:lumina/src/features/external_sources/data/repositories/external_source_repository_provider.dart';
import 'package:lumina/src/features/external_sources/data/services/external_source_credentials_store.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_credentials.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_failure.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_type.dart';
import 'package:lumina/src/providers.dart';

/// End-to-end test of browsing one WebDAV source.
///
/// Drives the real stack — browser notifier → notifier → registry → adapter →
/// `WebDavClient` — against a fake HTTP layer installed with [HttpOverrides],
/// and asserts on the exact `PROPFIND` URLs the client produces. That last part
/// matters: a listing can succeed locally while requesting the wrong URL, which
/// is exactly the class of bug this covers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWebDavServer server;

  setUpAll(() {
    HttpOverrides.global = _FakeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    server = _FakeWebDavServer(
      // A Nextcloud-style deployment: the WebDAV root lives under a path, and
      // the books live in a folder below it.
      baseUrl: 'https://dav.example.com/remote.php/dav/files/me',
      entries: {
        '': ['books/', 'root.epub'],
        'books/': ['travel/', 'sci-fi/'],
        'books/travel/': ['japan.epub'],
        'books/sci-fi/': ['dune.epub'],
      },
    );
    _FakeHttpOverrides.current = server;
  });

  ExternalSource source() {
    return ExternalSource()
      ..id = 1
      ..name = 'Test'
      ..kindId = ExternalSourceType.webdav.id
      ..configJson = jsonEncode({
        'baseUrl': 'https://dav.example.com',
        'basePath': 'remote.php/dav/files/me',
        'username': 'reader',
      })
      ..createdAt = DateTime(2024)
      ..updatedAt = DateTime(2024);
  }

  Future<ProviderContainer> container() async {
    final container = ProviderContainer(
      overrides: [
        externalSourceRepositoryProvider.overrideWithValue(
          _SingleSourceRepository(source()),
        ),
        externalSourceCredentialsStoreProvider.overrideWithValue(
          _EmptyCredentialsStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Wait for the source list's first emission before browsing. The provider's
    // `.future` cannot be used for that: it resolves when the underlying watch
    // stream *closes*, which an Isar watch never does.
    final ready = Completer<void>();
    final subscription = container.listen<AsyncValue<List<ExternalSource>>>(
      externalSourcesProvider,
      (_, next) {
        if (next.value != null && !ready.isCompleted) ready.complete();
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await ready.future;

    return container;
  }

  /// Lets the notifier's async work run to completion.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('lists the root through the configured base path', () async {
    final c = await container();
    final browser = c.read(externalSourceBrowserProvider(1).notifier);
    await browser.refresh();
    await settle();

    expect(server.requestedPaths, ['/remote.php/dav/files/me/']);
    expect(c.read(externalSourceBrowserProvider(1)).items.map((i) => i.path), [
      'books',
      'root.epub',
    ]);
  });

  test('lists one nested folder', () async {
    final c = await container();
    final browser = c.read(externalSourceBrowserProvider(1).notifier);
    await browser.refresh();
    await settle();

    await browser.open(
      c
          .read(externalSourceBrowserProvider(1))
          .items
          .firstWhere((i) => i.path == 'books'),
    );
    await settle();

    expect(server.requestedPaths.last, '/remote.php/dav/files/me/books/');
    // Directories first, then alphabetically — the order `list` promises.
    expect(c.read(externalSourceBrowserProvider(1)).items.map((i) => i.path), [
      'books/sci-fi',
      'books/travel',
    ]);
  });

  test('lists two nested folders deep', () async {
    final c = await container();
    final browser = c.read(externalSourceBrowserProvider(1).notifier);
    await browser.refresh();
    await settle();

    await browser.open(
      c
          .read(externalSourceBrowserProvider(1))
          .items
          .firstWhere((i) => i.path == 'books'),
    );
    await settle();
    await browser.open(
      c
          .read(externalSourceBrowserProvider(1))
          .items
          .firstWhere((i) => i.path == 'books/travel'),
    );
    await settle();

    expect(
      server.requestedPaths.last,
      '/remote.php/dav/files/me/books/travel/',
    );
    expect(c.read(externalSourceBrowserProvider(1)).items.map((i) => i.path), [
      'books/travel/japan.epub',
    ]);
    expect(c.read(externalSourceBrowserProvider(1)).failure, isNull);
  });

  test('goes back up without refetching the parent', () async {
    final c = await container();
    final browser = c.read(externalSourceBrowserProvider(1).notifier);
    await browser.refresh();
    await settle();

    await browser.open(
      c
          .read(externalSourceBrowserProvider(1))
          .items
          .firstWhere((i) => i.path == 'books'),
    );
    await settle();
    final requestsAfterOpen = server.requestedPaths.length;

    browser.goUp();

    expect(server.requestedPaths, hasLength(requestsAfterOpen));
    expect(c.read(externalSourceBrowserProvider(1)).items.map((i) => i.path), [
      'books',
      'root.epub',
    ]);
    expect(c.read(externalSourceBrowserProvider(1)).path.canGoUp, isFalse);
  });
}

/// Serves canned WebDAV responses and records the URLs that were requested.
class _FakeWebDavServer {
  _FakeWebDavServer({required this.baseUrl, required this.entries});

  /// Path prefix the WebDAV root lives under.
  final String baseUrl;

  /// Collection path (relative to [baseUrl]) mapped to its child names. A name
  /// ending in `/` is a collection.
  final Map<String, List<String>> entries;

  final List<String> requestedPaths = [];

  /// Handles one `PROPFIND`, in WebDAV terms.
  _FakeResponse respond(String method, Uri uri, String body) {
    requestedPaths.add(uri.path);

    // The collection addressed by the request, relative to the WebDAV root.
    final rootPrefix = Uri.parse(baseUrl).path;
    var relative = uri.path;
    if (relative.startsWith(rootPrefix)) {
      relative = relative.substring(rootPrefix.length);
    }
    relative = relative.replaceAll(RegExp(r'^/+'), '');

    final children = entries[relative];
    if (children == null) {
      return _FakeResponse(404, 'Not Found', '');
    }

    final base = '$rootPrefix/$relative';
    final buffer = StringBuffer(
      '<?xml version="1.0"?><d:multistatus xmlns:d="DAV:">',
    );
    void response(String href, {required bool isCollection, int? size}) {
      buffer.write('<d:response><d:href>$href</d:href><d:propstat><d:prop>');
      buffer.write(
        isCollection
            ? '<d:resourcetype><d:collection/></d:resourcetype>'
            : '<d:resourcetype/>',
      );
      if (size != null) {
        buffer.write('<d:getcontentlength>$size</d:getcontentlength>');
      }
      buffer.write('</d:prop><d:status>HTTP/1.1 200 OK</d:status>');
      buffer.write('</d:propstat></d:response>');
    }

    // The collection describes itself first, exactly as servers do.
    response(base, isCollection: true);
    for (final child in children) {
      final isCollection = child.endsWith('/');
      response(
        '$base$child',
        isCollection: isCollection,
        size: isCollection ? null : 1024,
      );
    }
    buffer.write('</d:multistatus>');

    return _FakeResponse(207, 'Multi-Status', buffer.toString());
  }
}

class _FakeResponse {
  const _FakeResponse(this.statusCode, this.reason, this.body);

  final int statusCode;
  final String reason;
  final String body;
}

class _FakeHttpOverrides extends HttpOverrides {
  static _FakeWebDavServer? current;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(current!);
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.server);

  final _FakeWebDavServer server;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest(server, method, url);

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not used by WebDavClient',
  );
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.server, this.method, this.requestUri);

  final _FakeWebDavServer server;

  @override
  final String method;

  final Uri requestUri;
  final BytesBuilder _body = BytesBuilder();

  // `IOClient` configures these before sending; they are recorded but unused.
  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  bool bufferOutput = true;

  @override
  Uri get uri => requestUri;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  void add(List<int> data) => _body.add(data);

  /// `package:http` pumps the body into the request with `pipe`, which calls
  /// this. The body itself is unused by the fake: only the URL and method
  /// matter.
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async => response();

  @override
  Future<HttpClientResponse> get done async => response();

  @override
  noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not used by WebDavClient',
  );

  /// The canned answer for this request.
  HttpClientResponse response() {
    return _FakeHttpClientResponse(server.respond(method, requestUri, ''));
  }
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this.result);

  final _FakeResponse result;

  @override
  int get statusCode => result.statusCode;

  @override
  String get reasonPhrase => result.reason;

  @override
  int get contentLength => utf8.encode(result.body).length;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(result.body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not used by WebDavClient',
  );
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = ['$value'];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values.putIfAbsent(name.toLowerCase(), () => []).add('$value');
  }

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  String? value(String name) => _values[name.toLowerCase()]?.first;

  @override
  noSuchMethod(Invocation invocation) => null;
}

/// Credentials store that holds nothing and touches no keychain.
class _EmptyCredentialsStore implements ExternalSourceCredentialsStore {
  @override
  Future<ExternalSourceCredentials> read(
    int sourceId,
    List<String> keys,
  ) async => const ExternalSourceCredentials();

  @override
  Future<void> write(
    int sourceId,
    Map<String, String> values,
    List<String> secretKeys,
  ) async {}

  @override
  Future<void> delete(int sourceId, List<String> keys) async {}
}

/// Repository holding exactly one source, with no database behind it.
class _SingleSourceRepository implements ExternalSourceRepository {
  _SingleSourceRepository(this.source);

  final ExternalSource source;

  @override
  Stream<List<ExternalSource>> watchAll() => Stream.value([source]);

  @override
  Future<List<ExternalSource>> getAll() async => [source];

  @override
  Future<ExternalSource?> getById(int id) async =>
      id == source.id ? source : null;

  @override
  Future<bool> nameExists(String name, {int? excludingId}) async => false;

  @override
  Future<Either<ExternalSourceFailure, ExternalSource>> save(
    ExternalSource source,
  ) async => right(source);

  @override
  Future<Either<ExternalSourceFailure, Unit>> delete(int id) async =>
      right(unit);
}
