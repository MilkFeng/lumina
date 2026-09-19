/// Version of the library backup package format.
///
/// The version is stamped into `shelf.json` and into every per-book manifest
/// (`manifests/{hash}.json`), so a restore can tell which build wrote a package
/// *before* it touches the library on the device. `shelf.json` is the
/// authoritative one: it describes the package as a whole.
///
/// A package is restorable only while its version is known and is not newer
/// than [current]. A newer package may rely on fields — or on a folder layout —
/// that this build cannot read, and because a restore is a full replacement
/// (the current library is erased before the backup is applied), accepting it
/// would destroy the library on behalf of data that cannot be read back. A
/// folder without a version field was not written by the exporter and is
/// rejected for the same reason.
///
/// Bump [current] whenever the backup payload or its folder layout changes.
class BackupFormat {
  BackupFormat._();

  /// Format version written by the exporter and accepted by the importer.
  ///
  /// - v1: original folder format.
  /// - v2: current format.
  static const int current = 2;
}
