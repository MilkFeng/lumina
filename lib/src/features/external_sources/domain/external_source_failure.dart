/// Why an external source operation failed.
///
/// Adapters report one of these instead of user-facing text, so that the
/// message the user finally sees is built by the UI layer from localized
/// strings — while the raw platform detail (a socket error, a status line) is
/// still available for the cases no localized sentence can cover.
class ExternalSourceFailure {
  const ExternalSourceFailure({
    required this.kind,
    this.statusCode,
    this.limitBytes,
    this.detail,
  });

  /// The server rejected the credentials (HTTP 401 / 403).
  factory ExternalSourceFailure.auth({int? statusCode, String? detail}) {
    return ExternalSourceFailure(
      kind: ExternalSourceFailureKind.auth,
      statusCode: statusCode,
      detail: detail,
    );
  }

  /// The configured URL is not a usable http(s) URL.
  factory ExternalSourceFailure.invalidUrl([String? detail]) {
    return ExternalSourceFailure(
      kind: ExternalSourceFailureKind.invalidUrl,
      detail: detail,
    );
  }

  /// The collection or file does not exist (HTTP 404).
  factory ExternalSourceFailure.notFound() =>
      const ExternalSourceFailure(kind: ExternalSourceFailureKind.notFound);

  /// The server answered something that is not WebDAV XML.
  factory ExternalSourceFailure.invalidResponse() =>
      const ExternalSourceFailure(
        kind: ExternalSourceFailureKind.invalidResponse,
      );

  /// The request did not complete in time.
  factory ExternalSourceFailure.timeout() =>
      const ExternalSourceFailure(kind: ExternalSourceFailureKind.timeout);

  /// DNS, TCP or TLS failed before any HTTP exchange happened.
  factory ExternalSourceFailure.network(String detail) => ExternalSourceFailure(
    kind: ExternalSourceFailureKind.network,
    detail: detail,
  );

  /// Certificate validation failed.
  factory ExternalSourceFailure.tls(String detail) => ExternalSourceFailure(
    kind: ExternalSourceFailureKind.tls,
    detail: detail,
  );

  /// A download exceeded the client's size ceiling.
  factory ExternalSourceFailure.tooLarge(int limitBytes) =>
      ExternalSourceFailure(
        kind: ExternalSourceFailureKind.tooLarge,
        limitBytes: limitBytes,
      );

  /// Another source already uses this name.
  factory ExternalSourceFailure.duplicateName() => const ExternalSourceFailure(
    kind: ExternalSourceFailureKind.duplicateName,
  );

  /// Any other HTTP failure.
  factory ExternalSourceFailure.status(int statusCode) => ExternalSourceFailure(
    kind: ExternalSourceFailureKind.status,
    statusCode: statusCode,
  );

  /// A failure that does not fit the known kinds.
  factory ExternalSourceFailure.unknown(String detail) => ExternalSourceFailure(
    kind: ExternalSourceFailureKind.unknown,
    detail: detail,
  );

  final ExternalSourceFailureKind kind;

  /// HTTP status, when the failure came from a response.
  final int? statusCode;

  /// Size ceiling in bytes, for [ExternalSourceFailureKind.tooLarge].
  final int? limitBytes;

  /// Raw platform message, shown as a secondary detail line when present.
  final String? detail;
}

/// Category of an [ExternalSourceFailure]; one kind per localized message.
enum ExternalSourceFailureKind {
  auth,
  notFound,
  invalidUrl,
  invalidResponse,
  timeout,
  network,
  tls,
  tooLarge,
  status,
  duplicateName,
  unknown,
}
