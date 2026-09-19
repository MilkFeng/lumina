import 'package:fpdart/fpdart.dart';
import 'package:lumina/src/features/external_sources/data/adapters/external_source_registry.dart';
import 'package:lumina/src/features/external_sources/data/repositories/external_source_repository.dart';
import 'package:lumina/src/features/external_sources/data/repositories/external_source_repository_provider.dart';
import 'package:lumina/src/features/external_sources/data/services/external_source_credentials_store.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_config.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_credentials.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_failure.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_item.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_type.dart';
import 'package:lumina/src/features/external_sources/domain/webdav_config.dart';
import 'package:lumina/src/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'external_sources_notifier.g.dart';

/// The source types this build can create, in editor order.
@Riverpod(keepAlive: true)
ExternalSourceRegistry externalSourceRegistry(Ref ref) =>
    const ExternalSourceRegistry();

/// Every configured external source, ordered by name.
///
/// Kept alive because both the settings screen and the home screen's import
/// menu read it, and because building an adapter reads the keychain — an
/// `autoDispose` provider could be torn down in the middle of that.
///
/// It is a stream, so consumers that render the list synchronously read
/// `.value ?? const []`, the same way the bookshelf is read. Before the first
/// emission that is an empty list, which is what both call sites want while the
/// database is still opening.
@Riverpod(keepAlive: true)
class ExternalSourcesNotifier extends _$ExternalSourcesNotifier {
  @override
  Stream<List<ExternalSource>> build() {
    return ref.watch(externalSourceRepositoryProvider).watchAll().map(_sorted);
  }

  /// Creates a source from [draft] and stores its secrets.
  ///
  /// The name is re-checked here even though the editor validates it as the user
  /// types: the dialog is not the only possible caller, and a duplicate name
  /// would put two identical entries in the home screen's import menu.
  Future<Either<ExternalSourceFailure, ExternalSource>> add({
    required String name,
    required ExternalSourceConfigDraft draft,
  }) async {
    final repository = ref.read(externalSourceRepositoryProvider);
    final trimmed = name.trim();

    try {
      if (await repository.nameExists(trimmed)) {
        return left(_duplicateName);
      }

      final (typeId, configJson) = ref
          .read(externalSourceRegistryProvider)
          .encodeDraft(draft);
      final now = DateTime.now();
      final saved = await repository.save(
        ExternalSource()
          ..name = trimmed
          ..kindId = typeId
          ..configJson = configJson
          ..createdAt = now
          ..updatedAt = now,
      );

      if (saved.isLeft()) return left(saved.getLeft().toNullable()!);

      final source = saved.getRight().toNullable()!;
      try {
        await _writeCredentials(source.id, draft);
      } catch (error) {
        // The row without its secret is not a usable source: drop it rather
        // than leave an entry whose imports would fail with an auth error.
        await repository.delete(source.id);
        return left(ExternalSourceFailure.unknown('$error'));
      }
      return right(source);
    } catch (error) {
      return left(ExternalSourceFailure.unknown('$error'));
    }
  }

  /// Applies [name] and [draft] to an existing source, secrets included.
  ///
  /// Named `saveChanges` rather than `update` because Riverpod's
  /// `$StreamNotifier` already defines `update` for transforming state.
  Future<Either<ExternalSourceFailure, ExternalSource>> saveChanges({
    required ExternalSource source,
    required String name,
    required ExternalSourceConfigDraft draft,
  }) async {
    final repository = ref.read(externalSourceRepositoryProvider);
    final trimmed = name.trim();

    // Captured so the row can be put back if the keychain refuses the secrets:
    // a half-applied edit would leave the stored configuration and the stored
    // password describing different servers.
    final previous = (
      name: source.name,
      kindId: source.kindId,
      configJson: source.configJson,
      updatedAt: source.updatedAt,
    );

    try {
      if (await repository.nameExists(trimmed, excludingId: source.id)) {
        return left(_duplicateName);
      }

      final (typeId, configJson) = ref
          .read(externalSourceRegistryProvider)
          .encodeDraft(draft);

      final saved = await repository.save(
        source
          ..name = trimmed
          ..kindId = typeId
          ..configJson = configJson
          ..updatedAt = DateTime.now(),
      );

      if (saved.isLeft()) return left(saved.getLeft().toNullable()!);

      final updated = saved.getRight().toNullable()!;
      try {
        await _writeCredentials(updated.id, draft);
      } catch (error) {
        final restored = await repository.save(
          updated
            ..name = previous.name
            ..kindId = previous.kindId
            ..configJson = previous.configJson
            ..updatedAt = previous.updatedAt,
        );
        if (restored.isLeft()) return left(restored.getLeft().toNullable()!);
        return left(ExternalSourceFailure.unknown('$error'));
      }
      return right(updated);
    } catch (error) {
      return left(ExternalSourceFailure.unknown('$error'));
    }
  }

  /// Deletes [source] together with the secrets it stored.
  Future<Either<ExternalSourceFailure, Unit>> delete(
    ExternalSource source,
  ) async {
    final result = await ref
        .read(externalSourceRepositoryProvider)
        .delete(source.id);
    if (result.isLeft()) return result;

    // Keychain cleanup is best-effort: a stale entry for a deleted row is
    // harmless, whereas failing the delete because of it would not be.
    try {
      await _credentialsStore.delete(source.id, _secretKeysOf(source));
    } catch (_) {
      // Ignored on purpose; see above.
    }
    return right(unit);
  }

  /// Whether [name] is free. Used by the editor for live field validation.
  Future<bool> isNameAvailable(String name, {int? excludingId}) async {
    try {
      return !await ref
          .read(externalSourceRepositoryProvider)
          .nameExists(name, excludingId: excludingId);
    } catch (_) {
      // A storage problem must not block the field; the notifier re-checks on
      // save, which is the check that actually protects the data.
      return true;
    }
  }

  /// The configuration of [source] in editable form, secrets included.
  Future<ExternalSourceConfigDraft> draftFor(ExternalSource source) async {
    final registry = ref.read(externalSourceRegistryProvider);
    return registry.draftFrom(
      source,
      credentials: await _credentialsFor(source),
    );
  }

  /// An empty configuration of [type], for a source being created.
  ///
  /// Produced by encoding and decoding a blank draft so that a brand-new form
  /// has exactly the shape a saved source will have.
  ExternalSourceConfigDraft emptyDraft(ExternalSourceType type) {
    final registry = ref.read(externalSourceRegistryProvider);
    final (_, configJson) = registry.encodeDraft(_blankDraft(type));
    return registry
        .registrationFor(type)!
        .codec
        .draftFrom(registry.registrationFor(type)!.codec.decode(configJson));
  }

  /// A free name for a source being created.
  ///
  /// The caller supplies the localized pattern (localizations live in the UI
  /// layer). This picks the lowest unused number, so deleting the second of
  /// three sources and adding a new one reuses `2` instead of counting upwards
  /// forever.
  Future<String> suggestName(String Function(int number) pattern) async {
    final sources = await ref.read(externalSourceRepositoryProvider).getAll();
    final taken = sources
        .map((source) => ExternalSourceRepository.normalizeName(source.name))
        .toSet();

    for (var number = 1; number <= taken.length + 1; number++) {
      final candidate = pattern(number).trim();
      if (!taken.contains(ExternalSourceRepository.normalizeName(candidate))) {
        return candidate;
      }
    }
    // Unreachable: one of the checked numbers is always free. Kept so the
    // method has a total return.
    return pattern(taken.length + 1);
  }

  /// Tests a stored source as it is saved.
  Future<ExternalSourceFailure?> testConnection(ExternalSource source) async {
    final adapter = ref
        .read(externalSourceRegistryProvider)
        .createAdapter(source, credentials: await _credentialsFor(source));
    try {
      return await adapter.testConnection();
    } finally {
      adapter.dispose();
    }
  }

  /// Tests configuration that has not been saved yet.
  Future<ExternalSourceFailure?> testDraft(
    ExternalSourceConfigDraft draft,
  ) async {
    final adapter = ref
        .read(externalSourceRegistryProvider)
        .createAdapterForDraft(
          draft,
          credentials: ExternalSourceCredentials(values: draft.secrets),
        );
    try {
      return await adapter.testConnection();
    } finally {
      adapter.dispose();
    }
  }

  /// Lists the contents of [source], optionally inside [path].
  ///
  /// The (not yet built) source screen is the only intended consumer; it lives
  /// on the notifier rather than in the UI so that the credential lookup stays
  /// in one place.
  Future<Either<ExternalSourceFailure, List<ExternalSourceItem>>> list(
    ExternalSource source, [
    String path = '',
  ]) async {
    final adapter = ref
        .read(externalSourceRegistryProvider)
        .createAdapter(source, credentials: await _credentialsFor(source));
    try {
      return await adapter.list(path);
    } finally {
      adapter.dispose();
    }
  }

  Future<ExternalSourceCredentials> _credentialsFor(
    ExternalSource source,
  ) async {
    final keys = _secretKeysOf(source);
    if (keys.isEmpty) return const ExternalSourceCredentials();
    return _credentialsStore.read(source.id, keys);
  }

  /// Secret field keys declared by [source]'s own configuration type.
  List<String> _secretKeysOf(ExternalSource source) {
    return ref
        .read(externalSourceRegistryProvider)
        .draftFrom(source)
        .secretKeys;
  }

  Future<void> _writeCredentials(
    int sourceId,
    ExternalSourceConfigDraft draft,
  ) {
    return _credentialsStore.write(sourceId, draft.secrets, draft.secretKeys);
  }

  ExternalSourceCredentialsStore get _credentialsStore =>
      ref.read(externalSourceCredentialsStoreProvider);

  static const ExternalSourceFailure _duplicateName = ExternalSourceFailure(
    kind: ExternalSourceFailureKind.duplicateName,
  );

  static List<ExternalSource> _sorted(List<ExternalSource> sources) {
    return [...sources]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static ExternalSourceConfigDraft _blankDraft(ExternalSourceType type) {
    return switch (type) {
      ExternalSourceType.webdav => const WebDavConfigDraft(),
    };
  }
}
