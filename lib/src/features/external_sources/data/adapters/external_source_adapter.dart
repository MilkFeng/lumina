import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../domain/external_source.dart';
import '../../domain/external_source_config.dart';
import '../../domain/external_source_credentials.dart';
import '../../domain/external_source_failure.dart';
import '../../domain/external_source_item.dart';
import '../../domain/external_source_type.dart';

/// Everything the generic layers need in order to talk to one kind of external
/// source.
///
/// This is the seam the feature is built around: persistence, the editor dialog
/// and the home screen's import menu all drive sources through this interface,
/// so supporting a new protocol means writing one adapter and registering it —
/// no changes to any of those layers.
abstract class ExternalSourceAdapter {
  ExternalSourceAdapter(this.source);

  /// The stored source this adapter was built for.
  final ExternalSource source;

  /// The configuration type this adapter understands.
  ExternalSourceType get type;

  /// Proves the source is reachable and usable with its current configuration.
  ///
  /// `null` means success. Adapters report a typed failure and never build
  /// user-facing text — localizing it is the UI's job.
  Future<ExternalSourceFailure?> testConnection();

  /// Lists the contents of a collection.
  ///
  /// [path] is relative to the source root (`''` means the root itself).
  Future<Either<ExternalSourceFailure, List<ExternalSourceItem>>> list([
    String path,
  ]);

  /// Downloads the entry at [path] into [target].
  ///
  /// [onProgress] is called as the transfer advances, with the bytes received so
  /// far and the total size when the protocol knows it ([ExternalSourceItem.size]
  /// is the fallback for a transport that does not declare one). An adapter whose
  /// protocol cannot report progress may ignore it, so callers must treat the
  /// counter as best-effort rather than as something that always arrives.
  Future<Either<ExternalSourceFailure, Unit>> downloadTo(
    String path,
    File target, {
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  });

  /// Releases any transport held open by this adapter.
  void dispose() {}
}

/// The configuration codec of one source type.
///
/// Serialisation is per type because each type owns its configuration shape;
/// the repository only ever moves opaque JSON around.
abstract class ExternalSourceConfigCodec {
  ExternalSourceType get type;

  /// Reads the secret-free configuration out of a stored row.
  ///
  /// Throws a [FormatException] when [json] cannot be decoded, which the
  /// repository reports as a data error rather than guessing a default.
  ExternalSourceConfig decode(String json);

  /// Writes the secret-free configuration of [draft].
  String encode(ExternalSourceConfigDraft draft);

  /// Turns a draft into a list/editor form, given the secrets read from the
  /// keychain.
  ExternalSourceConfigDraft draftFrom(
    ExternalSourceConfig config, {
    Map<String, String> secrets = const {},
  });
}

/// How to build the adapter for one source type.
///
/// The credentials are passed in rather than looked up, so the same factory
/// serves a stored source (secrets from the keychain) and an unsaved draft
/// (secrets from the editor form).
typedef ExternalSourceAdapterFactory =
    ExternalSourceAdapter Function(
      ExternalSource source,
      ExternalSourceCredentials credentials,
    );

/// Registration entry for a source type: its persistable configuration codec
/// plus the adapter that speaks its protocol.
class ExternalSourceTypeRegistration {
  const ExternalSourceTypeRegistration({
    required this.codec,
    required this.createAdapter,
  });

  final ExternalSourceConfigCodec codec;
  final ExternalSourceAdapterFactory createAdapter;
}
