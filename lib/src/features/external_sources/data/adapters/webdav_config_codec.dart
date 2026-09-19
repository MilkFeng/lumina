import 'dart:convert';

import '../../domain/external_source_config.dart';
import '../../domain/external_source_type.dart';
import '../../domain/webdav_config.dart';
import 'external_source_adapter.dart';

/// JSON codec for [WebDavConfig].
///
/// Only the secret-free half lives here: the password is read from the keychain
/// and handed to [draftFrom] separately, so an encoded row is always safe to
/// store in the database and to export in a backup.
class WebDavConfigCodec implements ExternalSourceConfigCodec {
  const WebDavConfigCodec();

  @override
  ExternalSourceType get type => ExternalSourceType.webdav;

  @override
  ExternalSourceConfig decode(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('WebDAV config is not a JSON object');
    }

    return WebDavConfig(
      baseUrl: _string(decoded, WebDavConfigField.baseUrl),
      basePath: _string(decoded, WebDavConfigField.basePath),
      username: _string(decoded, WebDavConfigField.username),
    );
  }

  @override
  String encode(ExternalSourceConfigDraft draft) {
    final config = draft.materialize();
    if (config is! WebDavConfig) {
      // Only reachable if this codec is wired to another type's draft.
      throw const FormatException('Draft is not a WebDavConfigDraft');
    }
    return jsonEncode({
      WebDavConfigField.baseUrlKey: config.baseUrl,
      WebDavConfigField.basePathKey: config.basePath,
      WebDavConfigField.usernameKey: config.username,
    });
  }

  @override
  ExternalSourceConfigDraft draftFrom(
    ExternalSourceConfig config, {
    Map<String, String> secrets = const {},
  }) {
    if (config is! WebDavConfig) {
      throw const FormatException('Config is not a WebDavConfig');
    }
    return WebDavConfigDraft.from(
      config,
      password: secrets[WebDavConfigField.password.key] ?? '',
    );
  }

  static String _string(Map<String, dynamic> json, WebDavConfigField field) {
    final value = json[field.key];
    return value is String ? value : '';
  }
}
