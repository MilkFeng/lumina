import 'external_source_config.dart';
import 'external_source_type.dart';

/// Configuration of a WebDAV external source.
///
/// The connection is described by [baseUrl] plus an optional [basePath] inside
/// that server. Keeping the two apart (instead of forcing one long URL) lets the
/// editor validate the URL and show the collected path separately, and keeps
/// path joining in one place — see `WebDavClient.resolve`.
class WebDavConfig extends ExternalSourceConfig {
  const WebDavConfig({
    this.baseUrl = '',
    this.basePath = '',
    this.username = '',
  });

  /// Server root, for example `https://dav.example.com`. Never carries a path.
  final String baseUrl;

  /// Collection inside [baseUrl] that holds the books, for example `books`.
  /// Empty means the server root itself.
  final String basePath;

  /// User name for HTTP Basic authentication. Empty means anonymous.
  final String username;

  @override
  ExternalSourceType get type => ExternalSourceType.webdav;

  @override
  List<ExternalSourceField> get fields => [
    ExternalSourceField(
      key: WebDavConfigField.baseUrlKey,
      labelKey: 'externalSourceWebdavUrl',
      value: baseUrl,
      type: ExternalSourceFieldType.url,
      hint: 'externalSourceWebdavUrlHint',
      required: true,
    ),
    ExternalSourceField(
      key: WebDavConfigField.basePathKey,
      labelKey: 'externalSourceWebdavPath',
      value: basePath,
      hint: 'externalSourceWebdavPathHint',
    ),
    ExternalSourceField(
      key: WebDavConfigField.usernameKey,
      labelKey: 'externalSourceUsername',
      value: username,
    ),
  ];

  WebDavConfig copyWith({String? baseUrl, String? basePath, String? username}) {
    return WebDavConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      basePath: basePath ?? this.basePath,
      username: username ?? this.username,
    );
  }
}

/// Keys of the WebDAV configuration, so persistence and the editor never rely
/// on scattered string literals.
///
/// [baseUrlKey] and friends exist as constants because a switch pattern's case
/// must be a compile-time constant, and `WebDavConfigField.baseUrlKey` is a
/// property access on a const object — which Dart does not accept there.
enum WebDavConfigField {
  baseUrl(baseUrlKey),
  basePath(basePathKey),
  username(usernameKey),
  password(passwordKey);

  const WebDavConfigField(this.key);

  final String key;

  static const String baseUrlKey = 'baseUrl';
  static const String basePathKey = 'basePath';
  static const String usernameKey = 'username';
  static const String passwordKey = 'password';
}

/// Editable WebDAV configuration.
class WebDavConfigDraft extends ExternalSourceConfigDraft {
  const WebDavConfigDraft({
    this.baseUrl = '',
    this.basePath = '',
    this.username = '',
    this.password = '',
  });

  final String baseUrl;
  final String basePath;
  final String username;
  final String password;

  /// Builds a draft from a saved configuration plus its stored secret.
  factory WebDavConfigDraft.from(WebDavConfig config, {String password = ''}) {
    return WebDavConfigDraft(
      baseUrl: config.baseUrl,
      basePath: config.basePath,
      username: config.username,
      password: password,
    );
  }

  @override
  ExternalSourceType get type => ExternalSourceType.webdav;

  @override
  List<ExternalSourceField> get fields => [
    ...WebDavConfig(
      baseUrl: baseUrl,
      basePath: basePath,
      username: username,
    ).fields,
    ExternalSourceField(
      key: WebDavConfigField.passwordKey,
      labelKey: 'externalSourcePassword',
      value: password,
      type: ExternalSourceFieldType.password,
    ),
  ];

  @override
  String valueOf(String key) => switch (key) {
    WebDavConfigField.baseUrlKey => baseUrl,
    WebDavConfigField.basePathKey => basePath,
    WebDavConfigField.usernameKey => username,
    WebDavConfigField.passwordKey => password,
    _ => '',
  };

  @override
  WebDavConfigDraft copyWithField(String key, String value) => switch (key) {
    WebDavConfigField.baseUrlKey => WebDavConfigDraft(
      baseUrl: value,
      basePath: basePath,
      username: username,
      password: password,
    ),
    WebDavConfigField.basePathKey => WebDavConfigDraft(
      baseUrl: baseUrl,
      basePath: value,
      username: username,
      password: password,
    ),
    WebDavConfigField.usernameKey => WebDavConfigDraft(
      baseUrl: baseUrl,
      basePath: basePath,
      username: value,
      password: password,
    ),
    WebDavConfigField.passwordKey => WebDavConfigDraft(
      baseUrl: baseUrl,
      basePath: basePath,
      username: username,
      password: value,
    ),
    _ => this,
  };

  @override
  List<String> get secretKeys => const [WebDavConfigField.passwordKey];

  @override
  Map<String, String> get secrets => {WebDavConfigField.passwordKey: password};

  @override
  bool get isComplete => baseUrl.trim().isNotEmpty;

  @override
  WebDavConfig materialize() => WebDavConfig(
    baseUrl: baseUrl.trim(),
    basePath: normalizeBasePath(basePath),
    username: username.trim(),
  );

  /// Reduces a user-typed collection path to the form the client expects:
  /// no leading or trailing slash, no repeated separators.
  ///
  /// `"/books/"`, `"books"` and `"//books//"` all mean the same collection.
  static String normalizeBasePath(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'/+$'), '');
  }
}
