import 'package:lumina/src/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'external_source_repository.dart';

part 'external_source_repository_provider.g.dart';

/// Provider for [ExternalSourceRepository].
///
/// Reads through the app-level [isarProvider], which is what lets external
/// sources live in their own feature without the library feature having to know
/// about them.
@riverpod
ExternalSourceRepository externalSourceRepository(Ref ref) {
  return ref
      .watch(isarProvider)
      .when(
        data: (isar) => ExternalSourceRepository(isar),
        loading: () => throw StateError(
          'Database is still initializing. '
          'Ensure the app awaits database initialization before accessing repositories.',
        ),
        error: (e, stack) => Error.throwWithStackTrace(
          StateError('Database initialization failed: $e'),
          stack,
        ),
      );
}
