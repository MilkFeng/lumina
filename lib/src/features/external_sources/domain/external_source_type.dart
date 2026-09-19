import 'external_source.dart';

/// The kinds of external source the app can talk to.
///
/// A type is a stable, persisted identity: [id] is what lands in the database,
/// so renaming a member is safe but changing an [id] is a breaking change for
/// every already-stored row.
///
/// Adding a type is meant to be additive: add a member here, register an
/// adapter for it in `data/adapters/external_source_registry.dart`, and give it
/// a configuration class in `external_source_config.dart`. Everything above
/// that layer — persistence, the editor dialog, the import menu — is generic.
enum ExternalSourceType {
  /// A WebDAV collection (`https://host/path`).
  webdav('webdav');

  const ExternalSourceType(this.id);

  /// Stable identifier persisted in the database.
  final String id;

  /// Resolves a persisted [id] back to its type, or `null` when the id belongs
  /// to a type this build does not know (for example a row written by a newer
  /// version, or by a build that had a type this one dropped).
  static ExternalSourceType? fromId(String id) {
    for (final type in ExternalSourceType.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

/// Type declared by a stored source row.
///
/// A free function rather than a getter on the entity: the Isar generator flags
/// any entity property whose type is an enum and demands `@Enumerated` for it,
/// and this value is derived from a string column instead.
ExternalSourceType? externalSourceTypeOf(ExternalSource source) =>
    ExternalSourceType.fromId(source.kindId);
