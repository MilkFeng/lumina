import 'package:isar_community/isar.dart';

part 'external_source.g.dart';

/// A source of books that lives outside the app: a WebDAV server today,
/// something else later.
///
/// The row stores only identity plus the secret-free half of the configuration
/// ([config]) as JSON. Secrets live in the platform keychain, keyed by [id], so
/// a database dump — including a backup export — never contains a password.
@collection
class ExternalSource {
  Id id = Isar.autoIncrement;

  /// Display name. Unique across sources; the editor enforces it and the home
  /// screen uses it as the import menu label.
  late String name;

  /// Id of the external source type this row is an instance of.
  ///
  /// Stored as a plain string rather than as an `@enumerated` enum so that a row
  /// written by a build that knew a type this one does not degrades to "no
  /// adapter" instead of failing to open the database. `ExternalSourceRegistry`
  /// is what turns it back into a type.
  ///
  /// Named `kindId` rather than `typeId` because the Isar generator flags any
  /// property whose name ends in `Type` as an enum reference.
  late String kindId;

  /// Serialised, secret-free configuration of this source.
  ///
  /// Kept as JSON on purpose: each source type owns its own configuration
  /// shape, and a column per field would make the collection a union of every
  /// type's fields.
  late String configJson;

  late DateTime createdAt;

  late DateTime updatedAt;
}
