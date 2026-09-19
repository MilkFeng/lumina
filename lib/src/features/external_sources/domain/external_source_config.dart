import 'external_source_type.dart';

/// Secret-free configuration of an external source.
///
/// One class per source type rather than a bag of fields: each type owns its own
/// configuration shape, and every generic layer above (persistence, the editor
/// dialog, the import menu) works through this interface plus the per-type
/// adapter, never through `if (type == webdav)`.
///
/// Plain `abstract` rather than `sealed`: a source type is a plugin point, and
/// sealing would force every future type — including one added from outside this
/// library — to live in this file.
abstract class ExternalSourceConfig {
  const ExternalSourceConfig();

  /// The type this configuration belongs to.
  ExternalSourceType get type;

  /// Configuration fields carrying no secret, in display order.
  ///
  /// Secrets (passwords, tokens) are deliberately absent: they are persisted in
  /// the platform keychain and never in the database, so re-serialising a row
  /// can never leak one.
  List<ExternalSourceField> get fields;
}

/// A single, type-agnostic editable configuration field.
///
/// The editor dialog builds its inputs from these descriptors, which is what
/// keeps the dialog free of per-type knowledge: adding a field to a
/// configuration class automatically adds an input to the form.
class ExternalSourceField {
  const ExternalSourceField({
    required this.key,
    required this.labelKey,
    required this.value,
    this.type = ExternalSourceFieldType.text,
    this.hint,
    this.required = false,
  });

  /// Stable key of the field inside its configuration.
  final String key;

  /// l10n key naming this field.
  final String labelKey;

  /// Current value, already normalised to a non-null string.
  final String value;

  final ExternalSourceFieldType type;

  /// Optional l10n key with an example value, shown as the input's hint.
  final String? hint;

  /// Whether the field must be non-empty for the configuration to be complete.
  final bool required;
}

/// Input kinds the editor dialog knows how to render.
enum ExternalSourceFieldType {
  /// Plain single-line text.
  text,

  /// Single-line text with URL keyboard and URL autofill hints.
  url,

  /// Single-line text that is obscured by default.
  password,
}

/// Editable, in-progress state of an [ExternalSourceConfig].
///
/// Values are held as raw strings because that is exactly what a text field
/// produces; each configuration class decides what those strings mean and which
/// of them are secret ([secretKeys]).
abstract class ExternalSourceConfigDraft {
  const ExternalSourceConfigDraft();

  ExternalSourceType get type;

  /// Every field this draft can be edited through, in display order.
  ///
  /// Includes the secrets ([secretKeys]), which [ExternalSourceConfig.fields]
  /// deliberately omits: the form edits both, while only the non-secret half is
  /// ever serialised.
  List<ExternalSourceField> get fields;

  /// Current value of [key], or an empty string when unknown.
  String valueOf(String key);

  /// Returns a copy of this draft with [key] set to [value].
  ExternalSourceConfigDraft copyWithField(String key, String value);

  /// Keys whose values must be stored in secure storage instead of the
  /// database.
  List<String> get secretKeys;

  /// Secret values, keyed by [secretKeys] entries. Empty values are kept so
  /// that clearing a stored secret is expressible.
  Map<String, String> get secrets;

  /// Whether every required value is present.
  bool get isComplete;

  /// The immutable configuration described by this draft.
  ///
  /// Only meaningful when [isComplete] is true.
  ExternalSourceConfig materialize();
}
