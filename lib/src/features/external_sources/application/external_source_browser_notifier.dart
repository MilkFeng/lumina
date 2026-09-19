import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_failure.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_item.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_path.dart';

part 'external_source_browser_notifier.g.dart';

/// What one source's browser is showing.
class ExternalSourceBrowserState {
  const ExternalSourceBrowserState({
    this.path = const ExternalSourcePath(),
    this.isLoading = true,
    this.failure,
  });

  /// Folder stack currently shown.
  final ExternalSourcePath path;

  /// Whether the visible level's listing is in flight.
  final bool isLoading;

  /// Why the last listing attempt failed, or `null` when it succeeded.
  final ExternalSourceFailure? failure;

  /// Entries of the visible level.
  List<ExternalSourceItem> get items => path.items;

  /// Whether the visible level has been listed and came back empty.
  bool get isEmpty => !isLoading && failure == null && items.isEmpty;

  ExternalSourceBrowserState copyWith({
    ExternalSourcePath? path,
    bool? isLoading,
    ExternalSourceFailure? failure,
    bool clearFailure = false,
  }) {
    return ExternalSourceBrowserState(
      path: path ?? this.path,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// Folder navigation for one external source.
///
/// Holds only the folder stack and its listing state — not the selection and not
/// the import progress. Those are per-screen concerns, and putting them here
/// would rebuild the whole list on every import tick.
///
/// Kept alive per source so that leaving the screen and coming back resumes
/// where the user was.
@Riverpod(keepAlive: true)
class ExternalSourceBrowserNotifier extends _$ExternalSourceBrowserNotifier {
  /// Incremented for every listing started, so a slow one cannot publish over a
  /// newer one the user triggered in the meantime (tapping two folders quickly,
  /// or pulling to refresh twice).
  ///
  /// A counter rather than a comparison against `state.path`, because
  /// [ExternalSourcePath] has no value equality: two structurally identical
  /// paths are different objects, which would make a comparison both reject
  /// valid results and accept stale ones.
  int _requestToken = 0;

  @override
  ExternalSourceBrowserState build(int sourceId) {
    // Kick the root listing off without awaiting it: `build` must return
    // synchronously, and the UI renders its loading state until this lands.
    unawaited(Future.microtask(refresh));
    return const ExternalSourceBrowserState();
  }

  /// Lists the level currently shown again.
  ///
  /// Used for the first load, for pull-to-refresh, and after a failed listing.
  Future<void> refresh() => _list(state.path);

  /// Opens [item] as a folder. A no-op for files.
  Future<void> open(ExternalSourceItem item) {
    if (!item.isDirectory) return Future.value();
    return _list(state.path.pushed(item));
  }

  /// Goes back to the parent folder.
  ///
  /// Restored from the stack without touching the network: the parent's entries
  /// were fetched on the way down.
  void goUp() {
    if (!state.path.canGoUp) return;
    // Any in-flight listing belongs to the level being left.
    _requestToken++;
    state = state.copyWith(
      path: state.path.popped(),
      isLoading: false,
      clearFailure: true,
    );
  }

  /// Lists [target], publishing the outcome.
  ///
  /// The target always carries the levels below it, so a failed listing keeps
  /// the parent chain that [goUp] walks back through.
  Future<void> _list(ExternalSourcePath target) async {
    final token = ++_requestToken;
    state = state.copyWith(path: target, isLoading: true, clearFailure: true);

    final source = await _resolveSource();
    if (!_isCurrent(token)) return;
    if (source == null) {
      state = state.copyWith(
        isLoading: false,
        failure: ExternalSourceFailure.notFound(),
      );
      return;
    }

    final result = await ref
        .read(externalSourcesProvider.notifier)
        .list(source, target.path);

    // A newer listing may have started, or the user may have gone back up,
    // while this one was in flight. Replacing the state now would either show
    // the wrong folder's entries or undo the navigation.
    if (!_isCurrent(token)) return;

    result.match(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (items) => state = state.copyWith(
        path: target.replacingItems(items),
        isLoading: false,
        clearFailure: true,
      ),
    );
  }

  /// Whether the listing started with [token] is still the newest one.
  bool _isCurrent(int token) => token == _requestToken;

  /// The source being browsed, or `null` when it does not exist.
  ///
  /// Waits for the list's first emission before giving up: the database opens
  /// asynchronously, and the screen can be reached by route before it has, which
  /// would otherwise look identical to a deleted source.
  Future<ExternalSource?> _resolveSource() async {
    // Streams have no synchronous value before their first emission, and the
    // database opens asynchronously — so a cold read has to wait for it, or a
    // source that exists would look exactly like one that was deleted.
    if (ref.read(externalSourcesProvider).value case final sources?) {
      return sources.byId(sourceId);
    }
    final sources = await ref.read(externalSourcesProvider.future);
    return sources.byId(sourceId);
  }
}
