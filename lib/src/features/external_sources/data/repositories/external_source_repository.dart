import 'package:fpdart/fpdart.dart';
import 'package:isar_community/isar.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_failure.dart';

/// Persistence for [ExternalSource] rows.
///
/// Mirrors the repository style used by the library feature: an `Either` on the
/// boundary, so a storage failure becomes a value the caller can localize
/// rather than an exception thrown across layers.
class ExternalSourceRepository {
  ExternalSourceRepository(this._isar);

  final Isar _isar;

  /// Emits the full list whenever any row changes.
  Stream<List<ExternalSource>> watchAll() {
    return _isar.externalSources.where().watch(fireImmediately: true);
  }

  Future<List<ExternalSource>> getAll() {
    return _isar.externalSources.where().findAll();
  }

  Future<ExternalSource?> getById(int id) {
    return _isar.externalSources.get(id);
  }

  Future<Either<ExternalSourceFailure, ExternalSource>> save(
    ExternalSource source,
  ) async {
    try {
      final id = await _isar.writeTxn(() => _isar.externalSources.put(source));
      source.id = id;
      return right(source);
    } catch (error) {
      return left(ExternalSourceFailure.unknown('$error'));
    }
  }

  Future<Either<ExternalSourceFailure, Unit>> delete(int id) async {
    try {
      await _isar.writeTxn(() => _isar.externalSources.delete(id));
      return right(unit);
    } catch (error) {
      return left(ExternalSourceFailure.unknown('$error'));
    }
  }

  /// Whether [name] is already used by a source other than [excludingId].
  ///
  /// The comparison ignores case and surrounding whitespace, so `Books` and
  /// `books ` collide — two menu entries that read the same would defeat the
  /// purpose of requiring unique names.
  ///
  /// [excludingId] is what makes renaming a source to its own name legal while
  /// every other collision stays an error.
  Future<bool> nameExists(String name, {int? excludingId}) async {
    final normalized = normalizeName(name);
    final all = await _isar.externalSources.where().findAll();
    return all.any(
      (source) =>
          source.id != excludingId && normalizeName(source.name) == normalized,
    );
  }

  /// Canonical form of a source name, used for both storage and comparison.
  static String normalizeName(String name) => name.trim().toLowerCase();
}
