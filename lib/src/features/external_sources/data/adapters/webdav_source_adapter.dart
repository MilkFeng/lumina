import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../domain/external_source_credentials.dart';
import '../../domain/external_source_failure.dart';
import '../../domain/external_source_item.dart';
import '../../domain/external_source_type.dart';
import '../../domain/webdav_config.dart';
import '../services/webdav_client.dart';
import '../services/webdav_exception.dart';
import 'external_source_adapter.dart';

/// Speaks WebDAV on behalf of one stored source.
class WebDavSourceAdapter extends ExternalSourceAdapter {
  WebDavSourceAdapter(
    super.source, {
    required WebDavConfig config,
    required ExternalSourceCredentials credentials,
  }) : _config = config,
       _credentials = credentials;

  final WebDavConfig _config;
  final ExternalSourceCredentials _credentials;

  @override
  ExternalSourceType get type => ExternalSourceType.webdav;

  /// Builds a client for this source's configuration.
  ///
  /// A client per call keeps the adapter stateless, which is what lets the
  /// editor test edited-but-unsaved values through the same code path as a
  /// saved source (see [ExternalSourceAdapterFactory]).
  WebDavClient createClient() {
    return WebDavClient(
      baseUrl: _config.baseUrl,
      basePath: _config.basePath,
      username: _config.username,
      password: _credentials[WebDavConfigField.password.key],
    );
  }

  @override
  Future<ExternalSourceFailure?> testConnection() async {
    final client = createClient();
    try {
      await client.testConnection();
      return null;
    } catch (error) {
      return describeError(error);
    } finally {
      client.close();
    }
  }

  @override
  Future<Either<ExternalSourceFailure, List<ExternalSourceItem>>> list([
    String path = '',
  ]) async {
    final client = createClient();
    try {
      return right(await client.list(path));
    } catch (error) {
      return left(describeError(error));
    } finally {
      client.close();
    }
  }

  @override
  Future<Either<ExternalSourceFailure, Unit>> downloadTo(
    String path,
    File target,
  ) async {
    final client = createClient();
    try {
      await client.downloadTo(path, target);
      return right(unit);
    } catch (error) {
      return left(describeError(error));
    } finally {
      client.close();
    }
  }

  /// Translates any thrown object into a typed [ExternalSourceFailure].
  static ExternalSourceFailure describeError(Object error) {
    return switch (error) {
      WebDavAuthException(:final statusCode) => ExternalSourceFailure.auth(
        statusCode: statusCode,
      ),
      WebDavNotFoundException() => ExternalSourceFailure.notFound(),
      WebDavInvalidUrlException(:final input) =>
        ExternalSourceFailure.invalidUrl(input),
      WebDavMalformedResponseException() =>
        ExternalSourceFailure.invalidResponse(),
      WebDavTooLargeException(:final limitBytes) =>
        ExternalSourceFailure.tooLarge(limitBytes),
      WebDavStatusException(:final statusCode, :final reasonPhrase) =>
        ExternalSourceFailure(
          kind: ExternalSourceFailureKind.status,
          statusCode: statusCode,
          detail: reasonPhrase.isEmpty ? null : reasonPhrase,
        ),
      TimeoutException() => ExternalSourceFailure.timeout(),
      HandshakeException(:final message) => ExternalSourceFailure.tls(message),
      SocketException(:final message) => ExternalSourceFailure.network(message),
      HttpException(:final message) => ExternalSourceFailure.network(message),
      _ => ExternalSourceFailure.unknown(error.toString()),
    };
  }
}
