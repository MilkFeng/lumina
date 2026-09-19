/// Failures a WebDAV server can report, translated out of HTTP status codes.
///
/// The editor turns these into localized messages, so the client never builds
/// user-facing text itself.
sealed class WebDavException implements Exception {
  const WebDavException();
}

/// The server answered, but rejected the credentials (HTTP 401 / 403).
class WebDavAuthException extends WebDavException {
  const WebDavAuthException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'WebDavAuthException($statusCode)';
}

/// The collection does not exist (HTTP 404).
class WebDavNotFoundException extends WebDavException {
  const WebDavNotFoundException();

  @override
  String toString() => 'WebDavNotFoundException';
}

/// Any other non-success status.
class WebDavStatusException extends WebDavException {
  const WebDavStatusException(this.statusCode, this.reasonPhrase);

  final int statusCode;
  final String reasonPhrase;

  @override
  String toString() => 'WebDavStatusException($statusCode $reasonPhrase)';
}

/// The base URL could not be turned into a request URI.
class WebDavInvalidUrlException extends WebDavException {
  const WebDavInvalidUrlException(this.input);

  final String input;

  @override
  String toString() => 'WebDavInvalidUrlException($input)';
}

/// The response body was not usable WebDAV XML.
class WebDavMalformedResponseException extends WebDavException {
  const WebDavMalformedResponseException();

  @override
  String toString() => 'WebDavMalformedResponseException';
}

/// The download exceeded the client's size ceiling; likely not a book.
class WebDavTooLargeException extends WebDavException {
  const WebDavTooLargeException(this.limitBytes);

  final int limitBytes;

  @override
  String toString() => 'WebDavTooLargeException($limitBytes)';
}
