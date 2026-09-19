import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/external_source_credentials.dart';

/// Stores the secret half of an external source's configuration.
///
/// Kept out of the database on purpose: the Isar file is copied verbatim by the
/// backup export, and a password has no business travelling inside a library
/// backup. Values land in the platform keychain (Android Keystore-backed
/// encrypted preferences, iOS Keychain) instead.
class ExternalSourceCredentialsStore {
  ExternalSourceCredentialsStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Namespace for the keys this feature owns in the shared keychain.
  static const String _keyPrefix = 'external_source.credentials.';

  /// Reads every secret of the source with [sourceId].
  ///
  /// Also used to discover which keys exist: [keys] is passed in by the caller
  /// because only the source type knows which fields are secret.
  Future<ExternalSourceCredentials> read(
    int sourceId,
    List<String> keys,
  ) async {
    final values = <String, String>{};
    for (final key in keys) {
      final value = await _storage.read(key: _storageKey(sourceId, key));
      if (value != null) values[key] = value;
    }
    return ExternalSourceCredentials(values: values);
  }

  /// Replaces the stored secrets of the source with [sourceId].
  ///
  /// [secretKeys] is the full set of secret fields the source type declares:
  /// any key absent from [values] — or mapped to an empty string — is deleted
  /// rather than left behind, so switching a source's type cannot resurrect an
  /// old password.
  Future<void> write(
    int sourceId,
    Map<String, String> values,
    List<String> secretKeys,
  ) async {
    for (final key in secretKeys) {
      final storageKey = _storageKey(sourceId, key);
      final value = values[key];
      if (value == null || value.isEmpty) {
        await _storage.delete(key: storageKey);
      } else {
        await _storage.write(key: storageKey, value: value);
      }
    }
  }

  /// Deletes every secret of the source with [sourceId].
  Future<void> delete(int sourceId, List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: _storageKey(sourceId, key));
    }
  }

  static String _storageKey(int sourceId, String fieldKey) =>
      '$_keyPrefix$sourceId.$fieldKey';
}
