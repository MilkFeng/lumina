/// Secret half of an external source's configuration.
///
/// Held in the platform keychain rather than in the database, and carried
/// around as a value object so that the domain stays free of storage concerns.
class ExternalSourceCredentials {
  const ExternalSourceCredentials({this.values = const {}});

  /// Secret values keyed by field key (for WebDAV: `password`).
  final Map<String, String> values;

  /// Value of [key], or an empty string when unset.
  String operator [](String key) => values[key] ?? '';

  bool get isEmpty => values.values.every((value) => value.isEmpty);

  ExternalSourceCredentials copyWith(String key, String value) {
    return ExternalSourceCredentials(values: {...values, key: value});
  }
}
