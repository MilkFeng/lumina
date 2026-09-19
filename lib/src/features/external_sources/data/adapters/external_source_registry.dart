import '../../domain/external_source.dart';
import '../../domain/external_source_config.dart';
import '../../domain/external_source_credentials.dart';
import '../../domain/external_source_type.dart';
import '../../domain/webdav_config.dart';
import 'external_source_adapter.dart';
import 'webdav_config_codec.dart';
import 'webdav_source_adapter.dart';

/// The single place that knows every supported source type.
///
/// Supporting a new protocol is: add an [ExternalSourceType] member, write its
/// configuration + codec + adapter, and register the pair here. Nothing above
/// this layer needs to change.
///
/// Registration is a plain static map rather than generated code: the set is
/// tiny, and an explicit table is what makes "which types exist" a single,
/// greppable answer.
class ExternalSourceRegistry {
  const ExternalSourceRegistry();

  static final Map<ExternalSourceType, ExternalSourceTypeRegistration>
  _registrations = {
    ExternalSourceType.webdav: ExternalSourceTypeRegistration(
      codec: const WebDavConfigCodec(),
      createAdapter: _createWebDavAdapter,
    ),
  };

  /// Registration for [type], or `null` when this build does not support it.
  ExternalSourceTypeRegistration? registrationFor(ExternalSourceType type) =>
      _registrations[type];

  /// Types this build can create, in the order the editor offers them.
  List<ExternalSourceType> get supportedTypes => _registrations.keys.toList();

  /// Reads the stored configuration of [source].
  ///
  /// Throws [FormatException] when the row's type is unknown or its JSON is
  /// unreadable, so that a damaged row surfaces as an error instead of being
  /// silently coerced into another type's configuration.
  ExternalSourceConfig decodeConfig(ExternalSource source) {
    return _registrationFor(source).codec.decode(source.configJson);
  }

  /// Serialises [draft] for storage, together with the type it belongs to.
  (String typeId, String configJson) encodeDraft(
    ExternalSourceConfigDraft draft,
  ) {
    final registration = _registrations[draft.type];
    if (registration == null) {
      throw FormatException(
        'No registration for external source type: ${draft.type}',
      );
    }
    return (draft.type.id, registration.codec.encode(draft));
  }

  /// Rebuilds the editable form of [source], with secrets from the keychain
  /// already folded in.
  ExternalSourceConfigDraft draftFrom(
    ExternalSource source, {
    ExternalSourceCredentials credentials = const ExternalSourceCredentials(),
  }) {
    return _registrationFor(
      source,
    ).codec.draftFrom(decodeConfig(source), secrets: credentials.values);
  }

  /// Creates the adapter that talks to [source].
  ExternalSourceAdapter createAdapter(
    ExternalSource source, {
    ExternalSourceCredentials credentials = const ExternalSourceCredentials(),
  }) {
    return _registrationFor(source).createAdapter(source, credentials);
  }

  /// Builds an adapter for configuration that has not been saved yet.
  ///
  /// Implemented by carrying the draft through a detached [ExternalSource] row:
  /// the adapter then sees exactly the shape it will see after saving, which is
  /// the point of testing before saving. The probe is never persisted.
  ExternalSourceAdapter createAdapterForDraft(
    ExternalSourceConfigDraft draft, {
    ExternalSourceCredentials credentials = const ExternalSourceCredentials(),
  }) {
    final (typeId, configJson) = encodeDraft(draft);
    final now = DateTime.now();
    final probe = ExternalSource()
      ..name = ''
      ..kindId = typeId
      ..configJson = configJson
      ..createdAt = now
      ..updatedAt = now;
    return createAdapter(probe, credentials: credentials);
  }

  /// The type [source] declares, or `null` when this build does not know it.
  ExternalSourceType? typeOf(ExternalSource source) =>
      ExternalSourceType.fromId(source.kindId);

  ExternalSourceTypeRegistration _registrationFor(ExternalSource source) {
    final type = typeOf(source);
    final registration = type == null ? null : _registrations[type];
    if (registration == null) {
      throw FormatException(
        'Unsupported external source type: ${source.kindId}',
      );
    }
    return registration;
  }

  static ExternalSourceAdapter _createWebDavAdapter(
    ExternalSource source,
    ExternalSourceCredentials credentials,
  ) {
    // Checked cast, not an assumed one: `decode` is declared to return the
    // generic `ExternalSourceConfig`, so wiring this adapter to the wrong codec
    // has to fail loudly here rather than reach the HTTP client as a wrong
    // shape.
    final config =
        const WebDavConfigCodec().decode(source.configJson) as WebDavConfig;
    return WebDavSourceAdapter(
      source,
      config: config,
      credentials: credentials,
    );
  }
}
